
module simpleode

include("utils.jl")
include("time_interval.jl")
include("ode_problem.jl")
include("ode_result.jl")
include("ode_stat.jl")
include("fixed_step_solvers.jl")


# struct OdeProblem
#     # add mass matrix
#     # add event_fcn
#     # add output_fcn
#     ode_fcn
#     time_interval::TimeInterval
#     init_cond::Vector{Float64}
# end






mutable struct FixedStepOdeOptions
    step_size::Float64
end
function FixedStepOdeOptions(; step_size = 1e-2)
    FixedStepOdeOptions(step_size)
end




function ode_solver_explicit_euler(fcn, time_interval::TimeInterval, initial_values::Vector{T}, options::FixedStepOdeOptions) where {T}

    step_size = options.step_size

    t     = time_interval.t_start
    q     = initial_values

    ode_res = init_ode_result(q)

    while true

        dqdt  = fcn(t, q)
        q_new = q + step_size * dqdt

        t = t + step_size
        q = q_new

        push!(ode_res, t, q)

        if t >= time_interval.t_end
            break
        end

    end

    return ode_res
end


function ode_solver_semiimplicit_euler(fcn, time_interval::TimeInterval, initial_values::Vector{T}, options::FixedStepOdeOptions) where {T}

    step_size = options.step_size

    t     = time_interval.t_start
    q     = initial_values

    ode_res = init_ode_result(q)

    n_dim = length(initial_values)
    id = Matrix{T}( one(T) * I , n_dim, n_dim )

    while true

        t_new = t + step_size
        jac = numder.jacobian_fw( q->fcn(t_new, q), q)

        mat = id - step_size * jac
        dq = step_size .*( mat \ fcn(t_new, q) )
        
        t = t_new
        q = q + dq

        push!(ode_res, t, q)

        if t >= time_interval.t_end
            break
        end

    end

    return ode_res

end


function ode_solver_implicit_euler(fcn, time_interval::TimeInterval, initial_values::Vector{T}, options::FixedStepOdeOptions) where {T}

    step_size = options.step_size

    t     = time_interval.t_start
    q     = initial_values

    ode_res = init_ode_result(q)

    n_dim = length(initial_values)
    # id = Matrix{T}( one(T) * I , n_dim, n_dim )

    while true

        t_new = t + step_size
        nonlin_fcn(y) = step_size .* fcn(t_new, y) - y + q

        q_try = q + step_size * fcn(t_new, q)

        (q_new, nonlineq_iter) = nonlineq.broyden( nonlin_fcn, q_try )

        t = t_new
        q = q_new

        push!(ode_res, t, q)

        if t >= time_interval.t_end
            break
        end

    end

    return ode_res

end


function ode_solver_rk4(
    fcn,
    time_interval::TimeInterval,
    initial_values::Vector{T},
    options::FixedStepOdeOptions) where {T}

# https://en.wikipedia.org/wiki/Runge%E2%80%93Kutta_methods#Explicit_Runge%E2%80%93Kutta_methods
# 1/6
# 2/6
# 2/6
# 1/6


end





function solve(
    ode_problem::OdeProblem,
    ode_solver::S;
    basic_options::BasicOdeOptions = BasicOdeOptions(n_dim(ode_problem)),
    stepper_options::StepperOptions = StepperOptions()
    ) where {S <: Union{AbstractAdaptiveExplicitSolver}, SSC <: AbstractStepSizeControl}
end



end 

module stest
using ..simpleode





end