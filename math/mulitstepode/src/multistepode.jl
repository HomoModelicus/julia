


include("../../dualnumbers/src/DualNumbers.jl")



include("../../../stdlib/stacks/src/Stacks.jl")


module MultiStepOde
using LinearAlgebra
using ..Stacks
using ..DualNumbers


struct TimeInterval
    t_start::Float64
    t_stop::Float64

    function TimeInterval(t_start, t_stop)
        return new(t_start, t_stop)
    end
end

struct AdamsOptions
    step_size::Float64
end

struct BwEulerOptions
    step_size::Float64
    abs_tol::Float64
    rel_tol::Float64
end


const adamsbashforth_alpha = (1, 2, 12, 24, 720, 1440)
const adamsbashforth_beta = (
    (1,),
    (3, -1),
    (23, -16, 5),
    (55, -59, 37, -9),
    (1901, -2774, 2616, -1274, 251),
    (4277, -7923, 9982, -7298, 2877, -475)
)


abstract type AbstractMultiStepSolver end

struct AdamsBashforthOrder1 <: AbstractMultiStepSolver end
struct AdamsBashforthOrder2 <: AbstractMultiStepSolver end
struct AdamsBashforthOrder3 <: AbstractMultiStepSolver end
struct AdamsBashforthOrder4 <: AbstractMultiStepSolver end
struct AdamsBashforthOrder5 <: AbstractMultiStepSolver end
struct AdamsBashforthOrder6 <: AbstractMultiStepSolver end


order(::T) where {T <: AbstractMultiStepSolver} = error("not implmented yet")
order(::AdamsBashforthOrder1) = 1
order(::AdamsBashforthOrder2) = 2
order(::AdamsBashforthOrder3) = 3
order(::AdamsBashforthOrder4) = 4
order(::AdamsBashforthOrder5) = 5
order(::AdamsBashforthOrder6) = 6



struct OdeResult
    time_stack::Stack{Float64}
    state_stack::MatrixStack{Float64}
    der_stack::MatrixStack{Float64}

    function OdeResult(vec_size, start_size = 8)
        time_stack  = Stack{Float64}(start_size)
        state_stack = MatrixStack{Float64}(vec_size, start_size)
        der_stack   = MatrixStack{Float64}(vec_size, start_size)

        return new(time_stack, state_stack, der_stack)
    end
end

#=
struct DaeResult
    time_stack::Stack{Float64}
    state_stack::MatrixStack{Float64}
    alg_stack::MatrixStack{Float64}
    der_stack::MatrixStack{Float64}
    
    function OdeResult(state_vec_size, alg_vec_size, start_size = 8)

        der_vec_size = state_vec_size + alg_vec_size

        time_stack  = Stack{Float64}(start_size)
        state_stack = MatrixStack(Float64, state_vec_size, start_size)
        alg_stack   = MatrixStack(Float64, alg_vec_size,   start_size)
        der_stack   = MatrixStack(Float64, der_vec_size,   start_size)
        

        return new(time_stack, state_stack, alg_stack, der_stack)
    end

end
=#

struct DaeResult
    time_stack::Stack{Float64}
    state_stack::MatrixStack{Float64}
    der_stack::MatrixStack{Float64}
    
    function OdeResult(state_vec_size, start_size = 8)

        time_stack  = Stack{Float64}(start_size)
        state_stack = MatrixStack{Float64}(state_vec_size, start_size)
        der_stack   = MatrixStack{Float64}(state_vec_size, start_size)
        
        return new(time_stack, state_stack, alg_stack, der_stack)
    end
end



mutable struct BwEulerStat
    n_jac::Int
    n_fcn::Int
    
    function BwEulerStat()
        n_jac = 0
        n_fcn = 0
        return new(n_jac, n_fcn)
    end
end


function bw_euler_ode(
    ode_fcn,
    time_interval::TimeInterval,
    initial_conditions,
    options::BwEulerOptions
    )


    max_iter_for_new_state = 5
    stat = BwEulerStat()

    h  = options.step_size
    t0 = time_interval.t_start
    x0 = copy(initial_conditions)


    n_dim   = length(initial_conditions)
    ode_res = OdeResult(n_dim)
    _1      = zeros(Float64, n_dim, n_dim)
    for ii = 1:n_dim
        _1[ii, ii] = one(Float64)
    end
    
    f0      = similar(x0)
    x_pred  = similar(x0)
    f1      = similar(x0)
    dx      = similar(x0)



    fd0    = map( x -> DualNumbers.DualNumber(x), f0 )
    fcn(x) = ode_fcn(fd0, t0, x)
    dfdx   = DualNumbers.jacobian(fcn, x0)
    Miter  = h .* dfdx .- _1
    LU     = lu!(Miter)

    ode_fcn(f0, t0, x0)

    # protocol
    push!(ode_res.time_stack,  t0)
    push!(ode_res.state_stack, x0)
    push!(ode_res.der_stack,   f0)

    stat.n_fcn += 1
    stat.n_jac += 1
    
    
    while t0 <= time_interval.t_stop

        # predictor step for faster convergence
        # dfdx * dx + f(t + h, x_pred) = 0
        x_pred .= x0 .+ h .* f0
        t1      = t0 + h

        # solve for new state
        iter = 1
        fresh_jacobian = false
        while true
            ode_fcn(f1, t1, x_pred)
            dx .= h .* f1 .- x_pred .+ x0
            ldiv!(LU, dx)
            x_pred .-= dx

            stat.n_fcn += 1

            eps = max(options.abs_tol, options.rel_tol * norm(x_pred))
            if norm(dx) <= eps
                break
            end

            iter += 1
            if iter >= max_iter_for_new_state
                
                if fresh_jacobian
                    error("convergence failed at time: $(t1)")
                end

                fresh_jacobian = true
                fcn2(x) = ode_fcn(fd0, t1, x)
                dfdx   = DualNumbers.jacobian(fcn2, x_pred)
                Miter  = h .* dfdx .- _1
                LU     = lu!(Miter)
                iter = 1

                stat.n_jac += 1
            end
        end

        # update state and time
        t0  = t1
        x0 .= x_pred
        f0 .= f1

        # protocol
        push!(ode_res.time_stack,  t0)
        push!(ode_res.state_stack, x0)
        push!(ode_res.der_stack,   f0)
    end # main loop

    return (ode_res, stat)
end




# dae_fcn(residuum, der_x, x, w, t) -> for later
# for now:
# no difference between algebraic and derivative variables
# dae_fcn(residuum, der_x, [x, w], t)
# dae_fcn(residuum, der_x, x, t)
# residuum is the zero vector if consistent

function bw_euler_dae(
    dae_fcn,
    time_interval::TimeInterval,
    der_x0, # consistent initial conditions
    x0,     # consistent initial conditions
    options::BwEulerOptions)


    max_iter_for_new_state = 10
    stat = BwEulerStat()

    h  = options.step_size
    t0 = time_interval.t_start

    state_vec_size = length(der_x0)
    der_vec_size   = state_vec_size
    dae_res        = DaeResult(state_vec_size)

    f0       = zeros(der_vec_size)
    f1       = zeros(der_vec_size)
    x_pred   = copy(x0) # zeros(state_vec_size)
    dx       = zeros(der_vec_size)
    residuum = zeros(der_vec_size)


    residuumd = map( x -> DualNumbers.DualNumber(x), residuum )
    der_xd0   = map( x -> DualNumbers.DualNumber(x), der_x0 )
    xd0       = map( x -> DualNumbers.DualNumber(x), x0 )
    # wd0     = map( x -> DualNumbers.DualNumber(x), w0 )

    derx_fcn(der_x) = dae_fcn(residuumd, der_x,   xd0, wd0, t0)
    x_fcn(x)        = dae_fcn(residuumd, der_xd0, x,   wd0, t0)
    # w_fcn(w)        = dae_fcn(der_xd0, xd0, w,   t0)

    dfdderx = DualNumbers.jacobian(derx_fcn, der_x0)
    dfdx    = DualNumbers.jacobian(x_fcn,    x0)
    # dfdw    = DualNumbers.jacobian(w_fcn,    w0)

    # jac = [dfdderx .+ h .* dfdx     dfdw] # assumption, that w is not the empty vector
    jac = dfdderx .+ h .* dfdx
    LU  = lu!(jac)


    # first iter solves basically the consistent initial values
    # expectation is that the initial residuum is almost zero
    # dae_fcn(residuum, der_x0, x0, t0)
    # solve_consistent_initial_conditions() -> to be written
    # 

    
    while t0 <= time_interval.t_stop

        # predictor step
        
        der_x_pred
        x_pred
        t1




        # solve for new state
        iter = 1
        fresh_jacobian = false
        while true

            dae_fcn(residuum, der_x0, x0, t0)
            ldiv!(LU, residuum)
        
            if norm(residuum) <= eps
                break
            end

        end

    end # main loop


    return (dae_res, stat)
end


#=
function first_bw_step(
    ode_fcn,
    t0,
    x0,
    ode_res,
    #
    x_pred,
    h,
    f0
    )

    # dfdx * dx + f(t + h, x_pred) = 0
    x_pred .= x0 .+ h .* f0
    t1      = t0 + h

    # solve for new state
    ode_fcn(f1, t1, x_pred)
    dx .= h .* f1 .- x_pred .+ x0
    ldiv!(LU, dx)
    x_pred .-= dx

end
=#

#=
function explicit_adamsbashforth(
    ode_fcn,
    solver::S,
    time_interval::TimeInterval,
    initial_conditions,
    options::AdamsOptions
    ) where {S <: AbstractMultiStepSolver}


    n_dim   = length(initial_conditions)
    ode_res = OdeResult(n_dim)

    
    n_order = order(solver)
    alpha   = adamsbashforth_alpha[ n_order ]
    beta    = adamsbashforth_beta[  n_order ]
    
    t = time_interval.t_start
    h = options.step_size

    der_x = zeros(n_dim)
    x     = copy(initial_conditions)
    x_pre = zeros(n_dim)

    # first n_order steps
    h1 = h / n_order


    # main loop
    while t <= time_interval.t_stop

        # update the state
        ptr = ode_res.der_stack.ptr
        for ii = 1:n_order
            x_pre .+= beta[ii] .* ode_res.der_stack.data[ptr - ii + 1]
        end

        ode_fcn(der_x, t, x)
        x .+= h / alpha .* x_pre

        # update the time
        t_next = t + h
        t      = t_next

        # protocol the result
        push!(ode_res.time_stack,  t)
        push!(ode_res.state_stack, x)
    end


    return ode_res
end
=#


end




module mtest
using ..Stacks
using ..MultiStepOde
using PyPlot
PyPlot.pygui(true)


#=
# PT1 example

function fcn_pt1(f, t, x, T)
# function fcn_pt1(f, t, x)
    # T * der(x) + x = 0
    # f = - x / T
    f[1] = -x[1] / T

    # f[1] = -x[1]

    return f
end



# T = 0.001
# ode_fcn(f, t, x) = fcn_pt1(f, t, x, T)


time_interval = MultiStepOde.TimeInterval(0.0, 3.0)
initial_conditions = [4.0]


abs_tol = 1e-4
rel_tol = 1e-4
options = MultiStepOde.BwEulerOptions(0.05, abs_tol, rel_tol)


ode_res = MultiStepOde.bw_euler_ode(
    ode_fcn,
    time_interval,
    initial_conditions,
    options)


t         = Stacks.valid_data(ode_res.time_stack)
state     = ode_res.state_stack.data[:, 1:ode_res.der_stack.ptr]
der_state = ode_res.der_stack.data[:, 1:ode_res.der_stack.ptr]

x     = state[1, :]
der_x = der_state[1, :]


    
PyPlot.figure()

PyPlot.subplot(2, 1, 1)
PyPlot.grid()
PyPlot.plot(t, x)

PyPlot.subplot(2, 1, 2)
PyPlot.grid()
PyPlot.plot(t, der_x)

=#



#=

function harmonic_ode(f, t, x, m, d, c, F)
    # m * der(v) + d * v + c * x = F
    # der(x) = v
    
    f[1] = x[2]
    f[2] = F(t)/m - (c * x[1] + d * x[2]) / m

    return f
end




m = 1.0
d = 2.0
c = 100.0
F(t) = 0.0
ode_fcn(f, t, x) = harmonic_ode(f, t, x, m, d, c, F)


time_interval = MultiStepOde.TimeInterval(0.0, 3.0)
initial_conditions = [0.0, 1.0]


abs_tol = 1e-4
rel_tol = 1e-4
options = MultiStepOde.BwEulerOptions(0.01, abs_tol, rel_tol)


(ode_res, stat) = MultiStepOde.bw_euler_ode(
    ode_fcn,
    time_interval,
    initial_conditions,
    options)


t         = Stacks.valid_data(ode_res.time_stack)
state     = ode_res.state_stack.data[:, 1:ode_res.der_stack.ptr]
der_state = ode_res.der_stack.data[:, 1:ode_res.der_stack.ptr]

x     = state[1, :]
der_x = der_state[1, :]


    
PyPlot.figure()

PyPlot.subplot(2, 1, 1)
PyPlot.grid()
PyPlot.plot(t, x)

PyPlot.subplot(2, 1, 2)
PyPlot.grid()
PyPlot.plot(t, der_x)

=#

#=

function vanderpol_ode(f, t, x, mu)
    # der(v) - mu * (1 - x^2) * v + x = 0
    f[1] = x[2]
    f[2] = mu * (1 - x[1]^2) * x[2] - x[1]

    return f
end


mu = 100.0
ode_fcn(f, t, x) = vanderpol_ode(f, t, x, mu)


time_interval = MultiStepOde.TimeInterval(0.0, 500.0)
initial_conditions = [2.0, 0.0]


abs_tol = 1e-6
rel_tol = 1e-6
options = MultiStepOde.BwEulerOptions(0.001, abs_tol, rel_tol)


(ode_res, stat) = MultiStepOde.bw_euler_ode(
    ode_fcn,
    time_interval,
    initial_conditions,
    options)


t         = Stacks.valid_data(ode_res.time_stack)
state     = ode_res.state_stack.data[:, 1:ode_res.der_stack.ptr]
der_state = ode_res.der_stack.data[:, 1:ode_res.der_stack.ptr]

x     = state[1, :]
der_x = der_state[1, :]


    
PyPlot.figure()

PyPlot.subplot(2, 1, 1)
PyPlot.grid()
PyPlot.plot(t, x)

PyPlot.subplot(2, 1, 2)
PyPlot.grid()
PyPlot.plot(t, der_x)
=#







end




