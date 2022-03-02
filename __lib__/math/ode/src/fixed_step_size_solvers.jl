
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



end
