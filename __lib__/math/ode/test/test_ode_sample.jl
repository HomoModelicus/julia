

include("../ode_test_functions/ode_test_functions.jl")
include("../src/ode_module.jl")


module otest
using ..odesample
using ..ode
using PyPlot
PyPlot.pygui(true)


time_interval   = ode.TimeInterval(5.0)
initial_values  = [0.0, 1.0]
options         = ode.OdeOptions(step_size = 1e-3)

params = odesample.HarmonicOscillatorOptions(
    m = 1.0,
    d = 0.5,
    c = 10.0)
fcn(t, q) = odesample.harmonic_oscillator(t, q, params)

ode_res = ode.ode_solver_implicit_euler(fcn, time_interval, initial_values, options)



PyPlot.figure()
PyPlot.subplot(2,1,1)
PyPlot.grid()
PyPlot.plot( ode_res.t, ode_res.q[:, 1] )

PyPlot.subplot(2,1,2)
PyPlot.grid()
PyPlot.plot( ode_res.t, ode_res.q[:, 2] )




end





