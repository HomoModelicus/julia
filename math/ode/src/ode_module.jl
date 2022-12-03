

include("../../../std/datastructs/src/datastructs_module.jl")
include("../../common/numder/src/numder_module.jl")


# update the ode functions such that, they are of form: ode_fcn!(dqdt, t, q) where dqdt is a commonly used array -> avoid allocations


module ode
using LinearAlgebra
using ..numder
# using ..nonlineq
using ..datastructs
using PyPlot
PyPlot.pygui(true)

# currently commented out for later refactoring
# include("fixed_step_size_solvers.jl")


include("utils.jl")
include("time_interval.jl")
include("ode_problem.jl")
include("basic_options.jl")
include("ode_result.jl")
include("ode_stat.jl")
include("error_estimation.jl")
include("stepper_options.jl")
include("adaptive_solvers.jl")



function create_stepper_temporaries(ode_solver::S, n_prob_dim::Int) where {S <: AbstractAdaptiveExplicitSolver}
    stepper_temp = StepperTemporaries(
        n_prob_dim,
        n_intermediates(ode_solver),
        n_temporaries(ode_solver))

    return stepper_temp
end

function create_stepper_temporaries(ode_solver::S, n_prob_dim::Int) where {S <: AbstractRosenbrockSolver}
    stepper_temp = RosenbrockStepperTemporaries(
        n_prob_dim,
        n_intermediates(ode_solver),
        n_temporaries(ode_solver))

    return stepper_temp
end


function solve(
    ode_problem::OdeProblem,
    ode_solver::S;
    basic_options::BasicOdeOptions,
    stepper_options::StepperOptions = StepperOptions(),
    error_estimation_options::ErrorEstimationOptions = ErrorEstimationOptions()
    ) where {S <: AbstractOdeSolver}

    error("Default implementation")
end

function solve(ode_problem::OdeProblem)
    ode_solver = Tsitouras45()
    return solve(ode_problem, ode_solver)
end

function solve(
    ode_problem::OdeProblem,
    ode_solver::S;
    basic_options::BasicOdeOptions = BasicOdeOptions(n_dim(ode_problem)),
    stepper_options::StepperOptions = StepperOptions(),
    error_estimation_options::ErrorEstimationOptions = ErrorEstimationOptions(),
    step_size_controller::SSC = PIStepSizeControl()
    ) where {S <: Union{AbstractAdaptiveExplicitSolver, AbstractRosenbrockSolver}, SSC <: AbstractStepSizeControl}

    (ode_res, step_stat) = integrate_adaptive(
                                    ode_solver,
                                    ode_problem,
                                    basic_options;
                                    stepper_options          = stepper_options,
                                    error_estimation_options = error_estimation_options,
                                    step_size_controller     = step_size_controller)
    shrink_to_fit!(ode_res)


    return (ode_res, step_stat)
end


# add step size selection based on rejection/acceptance
# add event handling
# etc...

function do_nothing(x...)
    # [value, isterminal, direction] = my_event_fcn(t, y)
    return [nothing, nothing, nothing]
end

function integrate_adaptive(
    ode_solver::S,
    ode_problem::OdeProblem,
    basic_options::BasicOdeOptions;
    stepper_options::StepperOptions = StepperOptions(),
    error_estimation_options::ErrorEstimationOptions = ErrorEstimationOptions(),
    step_size_controller::SSC = PIStepSizeControl(),
    event_functions = [do_nothing],
    output_function = do_nothig,
    
    ) where {S <: Union{AbstractAdaptiveExplicitSolver, AbstractRosenbrockSolver}, SSC <: AbstractStepSizeControl}

    n_prob_dim   = n_dim(ode_problem)
    t_old        = ode_problem.time_interval.t_start
    x_old        = ode_problem.init_cond

    ode_res      = OdeResult(x_old)

    solver_order = order(ode_solver) # solver dependent
    step_stat    = OdeStat()

    der_x_old = similar(x_old)
    ode_problem.ode_fcn(der_x_old, t_old, x_old)

    stepper_temp = create_stepper_temporaries(ode_solver, n_prob_dim)
    set_t_old!( stepper_temp, t_old)
    set_x_old!( stepper_temp, x_old)
    stepper_temp.der_x[:,1] = der_x_old

    time_direction = sign(ode_problem.time_interval.t_end - ode_problem.time_interval.t_start)
    stepper_temp.dt = time_direction * init_step_size(
                        ode_problem.ode_fcn,
                        der_x_old,
                        t_old,
                        x_old,
                        solver_order,
                        stepper_options,
                        basic_options,
                        error_estimation_options) # @time

    error_est = ErrorEstimation()

    for iter = 1:basic_options.max_iter

		stepper!(ode_solver, ode_problem.ode_fcn, basic_options, stepper_temp) # solver dependent # @time 

		error_est.current = error_estimation(
                                        stepper_temp.x_new,
                                        stepper_temp.x_old,
                                        stepper_temp.x_est,
                                        basic_options,
                                        error_estimation_options) # @time 

		if is_step_acceptable(error_est)
			rejection_break_flag = handle_accepted_step!(ode_res, error_est, stepper_temp, step_stat)
            # handle_event_function!(event_functions, ode_res, stepper_temp)
            # here comes the event function
            # here comes the output function: could be useful for controller state estimation
        else
			rejection_break_flag = handle_rejected_step!(step_stat, basic_options) # @time 
		end
		
		if rejection_break_flag || is_stop_time_reached(stepper_temp, ode_problem.time_interval, time_direction)
			break
		end

        step_size_control(
            step_size_controller,
            ode_solver,
            stepper_temp,
            error_est,
            rejection_break_flag,
            stepper_options)

	end

    return (ode_res, step_stat)
end

function is_stop_time_reached(stepper_temp, time_interval, time_direction)
    if time_direction >= 0
        b = stepper_temp.t_new >= time_interval.t_end
    else
        b = stepper_temp.t_new <= time_interval.t_end
    end
    return b
end


function handle_accepted_step!(ode_res, error_est, stepper_temp, step_stat)

	reset_rejected!(    step_stat )
    increase_accepted!( step_stat )

    update!(error_est)

    push!(ode_res, stepper_temp.t_new, stepper_temp.x_new)
	
    set_t_old!(stepper_temp, stepper_temp.t_new)
    set_x_old!(stepper_temp, stepper_temp.x_new)
    swap_fsal!(stepper_temp)

    rejection_break_flag = false
    return rejection_break_flag
end


function handle_rejected_step!(step_stat, basic_options)

	increase_rejected!(step_stat)

    rejection_break_flag = false

	if step_stat.current_rejected_steps >= basic_options.max_rejection_streak
        rejection_break_flag = true
		println("Too many rejected steps")
	end

    return rejection_break_flag
end



function init_step_size(
    ode_fcn,
    der_x0,
    t0,
    x0,
    solver_order,
    stepper_options,
    basic_options,
    error_estimation_options)
    
    # allocations:
    # x1
    # der_x0
    # der_x1
    # der_diff

    
    der_x1 = similar(x0)

    
    # base case
    if stepper_options.init_step_size > 0.0
        h_init = stepper_options.init_step_size
        return h_init
    end

    x_est = datastructs.Zero{Float64}()

    d0 = error_estimation(x0,     x0,     x_est, basic_options, error_estimation_options)
    d1 = error_estimation(der_x0, der_x0, x_est, basic_options, error_estimation_options)
    
    # some black magic from the Hairer ode solving book
	if d0 <= 1e-5 || d1 <= 1e-5
		h0 = 1e-6;
	else
		h0 = 0.01 * d0 / d1;
	end

    # compute one step of explicit euler
	x1 = x0 .+ h0 .* der_x0;
	
	# approx the derivative norm
	t1     = t0 + h0;
	ode_fcn(der_x1, t1, x1);
	
	der_diff = der_x1 - der_x0;
	d2 = 1 / h0 * error_estimation(der_diff, der_diff, x_est, basic_options, error_estimation_options)
	
	if max(abs(d1), abs(d2)) <= 1e-15
		h1 = max(1e-6, h0 * 1e-3);
	else
		h1 = 1e-2 / max(abs(d1), abs(d2));
		h1 = h1^(1/(solver_order + 1));
	end	
	
	h_init = min(100 * h0, h1);

    return h_init
end


end # ode



