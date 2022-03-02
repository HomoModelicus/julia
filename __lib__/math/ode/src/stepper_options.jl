
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
    step_growth = max(step_growth, stepper_options.min_step_growth)
	step_growth = min(step_growth, stepper_options.max_step_growth)
	step_size   = step_size * step_growth
    step_size   = max(step_size, stepper_options.min_step_size)
	step_size   = min(step_size, stepper_options.max_step_size)
    return step_size
end





# =========================================================================== #
# StepperTemporaries
# =========================================================================== #

abstract type AbstractStepperTemporaries
end

mutable struct StepperTemporaries <: AbstractStepperTemporaries
    t_old::Float64
    t_new::Float64
    dt::Float64

    x_old::Vector{Float64}
    x_new::Vector{Float64}
    x_est::Vector{Float64}
    der_x::Matrix{Float64}
    x_tmp::Matrix{Float64}

    function StepperTemporaries(n_dim::Int, n_intermediates::Int, n_tmp::Int)
        t_old = 0.0
        t_new = 0.0
        dt    = 0.0
        x_old = Vector{Float64}(undef, n_dim)
        x_new = Vector{Float64}(undef, n_dim)
        x_est = Vector{Float64}(undef, n_dim)
        der_x = Matrix{Float64}(undef, n_dim, n_intermediates)
        x_tmp = Matrix{Float64}(undef, n_dim, n_tmp)
        
        return new(t_old, t_new, dt, x_old, x_new, x_est, der_x, x_tmp)
    end
end

function n_dim(stepper_temp::S) where {S <: AbstractStepperTemporaries}
    return length(stepper_temp.x_old)
end

function n_intermediates(stepper_temp::S) where {S <: AbstractStepperTemporaries}
    return size(stepper_temp.der_x, 2)
end

function n_temporaries(stepper_temp::S) where {S <: AbstractStepperTemporaries}
    return size(stepper_temp.x_tmp, 2)
end

function set_t_old!(stepper_temp::S, t_old::Float64) where {S <: AbstractStepperTemporaries}
    stepper_temp.t_old = t_old
    return stepper_temp
end

function set_t_new!(stepper_temp::S, t_new::Float64) where {S <: AbstractStepperTemporaries}
    stepper_temp.t_new = t_new
    return stepper_temp
end

function set_dt!(stepper_temp::S, dt::Float64) where {S <: AbstractStepperTemporaries}
    stepper_temp.dt = dt
    return stepper_temp
end

function set_x_old!(stepper_temp::S, x_old) where {S <: AbstractStepperTemporaries}
    copy!(stepper_temp.x_old, x_old)
    return stepper_temp
end

function set_x_new!(stepper_temp::S, x_new) where {S <: AbstractStepperTemporaries}
    stepper_temp.x_new = x_new
    return stepper_temp
end

function set_x_est!(stepper_temp::S, x_est) where {S <: AbstractStepperTemporaries}
    stepper_temp.x_est = x_est
    return stepper_temp
end

function swap_x!(stepper_temp::S) where {S <: AbstractStepperTemporaries}
    stepper_temp.x_old = stepper_temp.x_new
    return stepper_temp
end

function swap_fsal!(stepper_temp::S) where {S <: AbstractStepperTemporaries}
    # copy the last column into the first column
    L = n_intermediates(stepper_temp)
    for ii = 1:n_dim(stepper_temp)
        stepper_temp.der_x[ii, 1] = stepper_temp.der_x[ii, L]
    end
    return stepper_temp
end




mutable struct RosenbrockStepperTemporaries <: AbstractStepperTemporaries
    t_old::Float64
    t_new::Float64
    dt::Float64

    x_old::Vector{Float64}
    x_new::Vector{Float64}
    x_est::Vector{Float64}
    x_tmp::Vector{Float64}
    der_x::Matrix{Float64}
    jac::Matrix{Float64}
    dfdt::Vector{Float64}
    tmp::Matrix{Float64}


    function RosenbrockStepperTemporaries(n_dim::Int, n_intermediates::Int, n_tmp::Int)
        t_old = 0.0
        t_new = 0.0
        dt    = 0.0

        x_old = Vector{Float64}(undef, n_dim)
        x_new = Vector{Float64}(undef, n_dim)
        x_est = Vector{Float64}(undef, n_dim)
        x_tmp = Vector{Float64}(undef, n_dim)
        der_x = Matrix{Float64}(undef, n_dim, n_intermediates)
        jac   = Matrix{Float64}(undef, n_dim, n_dim)
        dfdt  = Vector{Float64}(undef, n_dim)
        tmp   = Matrix{Float64}(undef, n_dim, n_tmp)
        
        return new(t_old, t_new, dt, x_old, x_new, x_est, x_tmp, der_x, jac, dfdt, tmp)
    end
end













