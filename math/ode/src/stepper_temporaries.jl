
# =========================================================================== #
# StepperTemporaries
# =========================================================================== #

abstract type AbstractStepperTemporaries
end

mutable struct OneStepStepperTemporaries <: AbstractStepperTemporaries
    t_old::Float64
    t_new::Float64
    dt::Float64

    x_old::Vector{Float64}
    x_new::Vector{Float64}
    x_est::Vector{Float64}
    der_x::Matrix{Float64}
    x_tmp::Matrix{Float64}

    function OneStepStepperTemporaries(n_dim::Int, n_intermediates::Int, n_tmp::Int)
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
