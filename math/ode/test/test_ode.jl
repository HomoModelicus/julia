

# include("../../distributions/src/distributions_module.jl")
include("../ode_test_functions/modelling_module.jl")
include("../src/ode_module.jl")
include("../ode_test_functions/ode_test_functions.jl")


module odetest
using ..modelling
using ..ode
using ..odesample
using ..numder
# using ..distributions
using PyPlot
PyPlot.pygui(true)
using BenchmarkTools


function force_fcn(t)
    t_start = 1.5
    t_end  = 3.5 # 0.8
    F_amplitude = 30
    return F_amplitude * (modelling.step(t - t_start) - modelling.step(t - t_end))
end


# implement cash karp
# look for rosenbrock23

function test_rk23()

    omega = 30
    D = 0.1
    m = 1.0
    c = m * omega^2
    d = 2 * D * omega
    params = odesample.HarmonicOscillatorOptions(;
        m = m,
        d = d,
        c = c,
        f = force_fcn)
    # ode_fcn(der_q, t, q) = odesample.harmonic_oscillator!(der_q, t, q, params)

    params = odesample.VanDerPolOptions(1_000.0)
    ode_fcn(der_q, t, q) = odesample.van_der_pol!(der_q, t, q, params)

    # ode_fcn = odesample.stiff_test_v1

    time_interval = ode.TimeInterval(5.0) # 50
    
    # time_interval = ode.TimeInterval(50.0) # 50
    time_interval = ode.TimeInterval(3_000.0) # 50
    init_cond     = [0.0, 1.0]
    # init_cond     = [1.0, 1.0, 0.0]


    ode_problem = ode.OdeProblem(
        ode_fcn,
        time_interval,
        init_cond)

    # ode_solver = ode.BogaczkiShampine23()
    # ode_solver = ode.DormandPrince45()
    ode_solver = ode.Tsitouras45()
    # ode_solver = ode.Ros23()
    
    
    basic_options = ode.BasicOdeOptions(
        ode_problem;
        abs_tol = 1e-9,
        rel_tol = 1e-9,
        max_iter = 10_000_000
    )

    step_size_controller = ode.ClassicalStepSizeControl()
    # step_size_controller = ode.PIStepSizeControl()

    stepper_options = ode.StepperOptions(;
        max_step_size = 5.0)
        
    @time (ode_res, step_stat) = ode.solve(
        ode_problem,
        ode_solver;
        basic_options = basic_options,
        step_size_controller = step_size_controller,
        stepper_options = stepper_options
        ) # 

    t = ode.time(ode_res)
    q = ode.variables(ode_res)

# #=    
    PyPlot.figure()

    a1 = PyPlot.subplot(2,1,1)
    PyPlot.grid()
    PyPlot.plot( t, q[1, :] )

    PyPlot.subplot(2,1,2, sharex = a1)
    PyPlot.grid()
    PyPlot.plot( t, q[2, :] )



    dt = diff(t)
    tmids = 0.5 * (t[1:end-1] + t[2:end])
    
    PyPlot.figure()
    PyPlot.plot(tmids, dt)
    PyPlot.grid()
# =#

    return step_stat
end

# test_rk23()



function test()
    x  = [1.0, 0.0]
    k2 = zeros(2)
    f_tmp = zeros(2)
    h_tmp = zeros(2)
    t = 10.0

    params = odesample.VanDerPolOptions(10.0)
    ode_fcn(der_q, t, q) = odesample.van_der_pol!(der_q, t, q, params)

    f_q(q) = ode_fcn(k2, t, q) # k2 is just a dummy

    L = length(x)
    J = zeros(L, L)
    # J      = numder.jacobian_fw!(J, f_q, x)
    J      = ode.jacobian_fw!(f_q, x, J, h_tmp, f_tmp)
    f_t(t) = ode_fcn(k2, t, x) # k2 is just a dummy
    # dfdt   = numder.numdiff_fw(f_t, t)

end


# test()

# x  = [1.0, 0.0]
# k2 = zeros(2)
# t = 10.0

# params = odesample.VanDerPolOptions(10.0)
# ode_fcn(der_q, t, q) = odesample.van_der_pol!(der_q, t, q, params)

# f_q(q) = ode_fcn(k2, t, q) # k2 is just a dummy


end # odetest




















#=
module old_odetest



function force_fcn(t)
    t_start = 1.5
    t_end  = 3.5 # 0.8
    F_amplitude = 30
    return F_amplitude * (modelling.step(t - t_start) - modelling.step(t - t_end))
end

struct HarmonicalOscillatorOptions
    m
    D
    omega
    F
end
function HarmonicalOscillatorOptions(; m = 1, D = 0.1, omega = 3, F = force_fcn)
    HarmonicalOscillatorOptions(
        m,
        D,
        omega,
        F)
end

function simple_ode_fcn(der_q, t, q, options::HarmonicalOscillatorOptions = HarmonicalOscillatorOptions() )

    der_x = q[2]
    der_v =  options.F(t) / options.m  - options.omega^2 * q[1] - 2 * options.D * options.omega * q[2]

    der_q[1] = der_x
    der_q[2] = der_v

    return der_q

end


function test_exp_euler()

    
    time_interval   = ode.TimeInterval(5.0)
    initial_values  = [0.0, 1.0]
    options         = ode.OdeOptions(step_size = 1e-3)

    params = HarmonicalOscillatorOptions(; omega = 30, D = 0.1, F = force_fcn)
    fcn(t, q) = simple_ode_fcn(t, q, params)

    ode_res = ode.ode_solver_explicit_euler(fcn, time_interval, initial_values, options)


    
    PyPlot.figure()

    PyPlot.subplot(2,1,1)
    PyPlot.grid()
    PyPlot.plot( ode_res.t, ode_res.q[:, 1] )

    PyPlot.subplot(2,1,2)
    PyPlot.grid()
    PyPlot.plot( ode_res.t, ode_res.q[:, 2] )


end



function test_semiimp_euler()

    
    time_interval   = ode.TimeInterval(5.0)
    initial_values  = [0.0, 1.0]
    options         = ode.OdeOptions(step_size = 1e-3)

    params = HarmonicalOscillatorOptions(; omega = 50, D = 0.1, F = force_fcn)
    fcn(t, q) = simple_ode_fcn(t, q, params)

    ode_res = ode.ode_solver_semiimplicit_euler(fcn, time_interval, initial_values, options)


    
    PyPlot.figure()

    PyPlot.subplot(2,1,1)
    PyPlot.grid()
    PyPlot.plot( ode_res.t, ode_res.q[:, 1] )

    PyPlot.subplot(2,1,2)
    PyPlot.grid()
    PyPlot.plot( ode_res.t, ode_res.q[:, 2] )


end



function test_imp_euler()

    
    time_interval   = ode.TimeInterval(5.0)
    initial_values  = [0.0, 1.0]
    options         = ode.OdeOptions(step_size = 1e-3)

    params = HarmonicalOscillatorOptions(; omega = 30, D = 0.1, F = force_fcn)
    fcn(t, q) = simple_ode_fcn(t, q, params)

    ode_res = ode.ode_solver_implicit_euler(fcn, time_interval, initial_values, options)


    
    PyPlot.figure()

    a1 = PyPlot.subplot(2,1,1)
    PyPlot.grid()
    PyPlot.plot( ode_res.t, ode_res.q[:, 1] )

    PyPlot.subplot(2,1,2, sharex = a1)
    PyPlot.grid()
    PyPlot.plot( ode_res.t, ode_res.q[:, 2] )


end






function add_noise()

    no_force_fcn(t) = 0.0

    time_interval   = ode.TimeInterval(5.0)
    initial_values  = [0.0, 1.0]
    options         = ode.OdeOptions(step_size = 1e-3)

    params = HarmonicalOscillatorOptions(; omega = 30, D = 0.1, F = no_force_fcn)
    fcn(t, q) = simple_ode_fcn(t, q, params)

    ode_res = ode.ode_solver_implicit_euler(fcn, time_interval, initial_values, options)


    # add noise
    n_points = length(ode_res.t)


    (min_x, max_x) = extrema(ode_res.q[:,1])
    (min_v, max_v) = extrema(ode_res.q[:,2])


    x_noise_distr = distributions.NormalDistribution(0.0, 1.0)
    v_noise_distr = distributions.NormalDistribution(0.0, 1.0)

    x_mult_noise_level = 0.05
    v_mult_noise_level = 0.05

    x_add_noise_level = 0.05 * (max_x - min_x)
    v_add_noise_level = 0.05 * (max_v - min_v)


    x_mult_noise = distributions.random(x_noise_distr, n_points)
    v_mult_noise = distributions.random(v_noise_distr, n_points)
    x_add_noise  = distributions.random(x_noise_distr, n_points)
    v_add_noise  = distributions.random(v_noise_distr, n_points)


    t_orig = copy(ode_res.t)
    q_mod = similar(ode_res.q)
    q_mod[:,1] = ode_res.q[:,1] .* (1 .+ x_mult_noise_level .* x_mult_noise) .+ x_add_noise_level .* x_add_noise
    q_mod[:,2] = ode_res.q[:,2] .* (1 .+ v_mult_noise_level .* v_mult_noise) .+ v_add_noise_level .* v_add_noise
    mod_ode_res = ode.OdeResult(t_orig, q_mod)




    PyPlot.figure()

    a1 = PyPlot.subplot(2,1,1)
    PyPlot.grid()
    PyPlot.plot( mod_ode_res.t, mod_ode_res.q[:, 1] )
    PyPlot.plot( ode_res.t, ode_res.q[:, 1], linewidth = 2 )


    PyPlot.subplot(2,1,2, sharex = a1)
    PyPlot.grid()
    PyPlot.plot( mod_ode_res.t, mod_ode_res.q[:, 2] )
    PyPlot.plot( ode_res.t, ode_res.q[:, 2], linewidth = 2 )

end




end

=#