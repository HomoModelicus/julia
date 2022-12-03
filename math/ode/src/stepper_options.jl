
# =========================================================================== #
# StepperOptions
# =========================================================================== #

struct StepperOptions
    init_step_size::Float64
    min_step_size::Float64
    max_step_size::Float64
    min_step_growth::Float64
    max_step_growth::Float64
    step_safety_factor::Float64
end

function StepperOptions(;
    init_step_size = 0.0, # indicates recalculation
    min_step_size = 1e-12,
    max_step_size = 1.0,
    min_step_growth = 0.1,
    max_step_growth = 5.0,
    step_safety_factor = 0.9)

    return StepperOptions(
        init_step_size,
        min_step_size,
        max_step_size,
        min_step_growth,
        max_step_growth,
        step_safety_factor)
end


abstract type AbstractStepSizeControl
end

struct ClassicalStepSizeControl <: AbstractStepSizeControl
end

struct PIStepSizeControl <: AbstractStepSizeControl
    alpha_coeff::Float64
    beta_coeff::Float64
end
function PIStepSizeControl()
    alpha_coeff = 0.7
    beta_coeff  = 0.3
    return PIStepSizeControl(alpha_coeff, beta_coeff)
end


function step_size_control(
    step_size_controller::SC,
    ode_solver,
    stepper_temp,
    error_estimation::ErrorEstimation,
    rejection_break_flag,
    stepper_options::StepperOptions) where {SC <: AbstractStepSizeControl}
    error("Default implementation")
end

function step_size_control(
    step_size_controller::ClassicalStepSizeControl,
    ode_solver,
    stepper_temp,
    error_estimation::ErrorEstimation,
    rejection_break_flag,
    stepper_options::StepperOptions)
    
    solver_order    = order(ode_solver)
    step_size       = stepper_temp.dt
	err_est         = error_estimation.current + eps(error_estimation.current)

    s               = stepper_options.step_safety_factor
    e               = 1 / (1 + solver_order)
	step_growth     = s * (1 / err_est) ^ e

    step_size       = __bound_step_size(step_growth, step_size, stepper_options)
    stepper_temp.dt = step_size

    return step_size
end


function step_size_control(
    step_size_controller::PIStepSizeControl,
    ode_solver,
    stepper_temp,
    error_estimation::ErrorEstimation,
    rejection_break_flag,
    stepper_options::StepperOptions)
    
    solver_order    = order(ode_solver)
    step_size       = stepper_temp.dt
	err_est         = error_estimation.current + eps(error_estimation.current)
    err_est_prev    = error_estimation.last    + eps(error_estimation.last)
    alpha           = step_size_controller.alpha_coeff / solver_order
    beta            = step_size_controller.beta_coeff / solver_order
    s               = stepper_options.step_safety_factor
	step_growth     = s * (1 / err_est)^alpha * err_est_prev^beta
    step_size       = __bound_step_size(step_growth, step_size, stepper_options)
    stepper_temp.dt = step_size

    return step_size
end


function __bound_step_size(step_growth, step_size, stepper_options::StepperOptions)
    step_growth    = max(step_growth, stepper_options.min_step_growth)
	step_growth    = min(step_growth, stepper_options.max_step_growth)
	step_size      = step_size * step_growth
    time_direction = sign(step_size)
    step_size      = max(abs(step_size), stepper_options.min_step_size)
	step_size      = min(abs(step_size), stepper_options.max_step_size)
    return step_size * time_direction
end



include("stepper_temporaries.jl")













