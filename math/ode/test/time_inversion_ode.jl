
include("../src/ode_module.jl")
include("../ode_test_functions/ode_test_functions.jl")
include("../ode_test_functions/modelling_module.jl")

module odetest
using ..modelling
using ..ode
using ..odesample
using PyPlot
PyPlot.pygui(true)


function test_time_inversion()

    F_ampl       = 30;
    F_t_start    = 1.5;
    F_t_end      = 3.5;

    omega = 30
    D = 0.1
    m = 1.0
    c = m * omega^2
    d = 2 * D * omega
    params = odesample.HarmonicOscillatorOptions(;
        m = m,
        d = d,
        c = c,
        f = t -> F_ampl * (modelling.step(t - F_t_start) - modelling.step(t - F_t_end)))

    ode_fcn(der_q, t, q) = odesample.harmonic_oscillator!(der_q, t, q, params)

    # params = odesample.VanDerPolOptions(1_000.0)
    # ode_fcn(der_q, t, q) = odesample.van_der_pol!(der_q, t, q, params)


    time_interval = ode.TimeInterval(5.0, 0.0)
    
    # time_interval = ode.TimeInterval(3_000.0) # 50
    init_cond     = [2.8726e-04,  -7.9677e-03] # [2.9395e-9; -1.1165e-7] # [1.0, 0.0]
    

    ode_problem = ode.OdeProblem(
        ode_fcn,
        time_interval,
        init_cond)

    ode_solver = ode.Tsitouras45()
    
    
    basic_options = ode.BasicOdeOptions(
        ode_problem;
        abs_tol = 1e-9,
        rel_tol = 1e-9,
        max_iter = 100_000
    )

    step_size_controller = ode.ClassicalStepSizeControl()
    # step_size_controller = ode.PIStepSizeControl()

    stepper_options = ode.StepperOptions(;
        max_step_size = 0.1)
        
    @time (ode_res, step_stat) = ode.solve(
        ode_problem,
        ode_solver;
        basic_options = basic_options,
        step_size_controller = step_size_controller,
        stepper_options = stepper_options
        )


    return (ode_res, step_stat)
end


(ode_res, step_stat) = odetest.test_time_inversion()

function plot_ode_res(ode_res)

    t = ode.time(ode_res)
    q = ode.variables(ode_res)



    PyPlot.figure()

    a1 = PyPlot.subplot(2,1,1)
    PyPlot.grid()
    PyPlot.plot( t, q[1, :] )

    PyPlot.subplot(2,1,2, sharex = a1)
    PyPlot.grid()
    PyPlot.plot( t, q[2, :] )



    # dt = diff(t)
    # tmids = 0.5 * (t[1:end-1] + t[2:end])
    
    # PyPlot.figure()
    # PyPlot.plot(tmids, dt)
    # PyPlot.grid()
end



end