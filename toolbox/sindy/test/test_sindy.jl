

include("../../__lib__/math/ode/src/ode_module.jl")
include("../../__lib__/math/ode/ode_test_functions/ode_test_functions.jl")
include("../../__lib__/math/common/numder/src/noisy_discrete_diff.jl")

include("../src/Sindy.jl")



# create from the Xi matrix a diffeq
# solve the ode on the same interval and settings
# check the error in the time domain



module stest
using ..Sindy
using ..noisydiff
using ..odesample
using ..ode
using PyPlot
PyPlot.pygui(true)




enable_plot_diffs  = true
enable_plot_odesol = false



function exitation(t)
    return 3 * sin(10 * t)
end


# --------------------------------------------------------------------------- #
# problem definition and parameters
# --------------------------------------------------------------------------- #

omega = 4
D = 0.05
m = 1.0
c = m * omega^2
d = 2 * D * omega # 2*0.05*3 = 3 

params = odesample.HarmonicOscillatorOptions(;
    m = m,
    d = d,
    c = c,
    f = odesample.std_zero)  # exitation
ode_fcn(der_q, t, q) = odesample.harmonic_oscillator!(der_q, t, q, params)


# --------------------------------------------------------------------------- #
# ode solving
# --------------------------------------------------------------------------- #

time_interval = ode.TimeInterval(35.0)
init_cond     = [0.0, 1.0]


ode_problem = ode.OdeProblem(
    ode_fcn,
    time_interval,
    init_cond)

# ode_solver = ode.BogaczkiShampine23()
# ode_solver = ode.DormandPrince45()
ode_solver = ode.Tsitouras45()

basic_options = ode.BasicOdeOptions(
    ode_problem;
    abs_tol = 1e-15,
    rel_tol = 1e-15,
    max_iter = 10_000_000
)

step_size_controller = ode.ClassicalStepSizeControl()

stepper_options = ode.StepperOptions(;
    max_step_size = 5.0)
    
@time (ode_res, step_stat) = ode.solve(
    ode_problem,
    ode_solver;
    basic_options        = basic_options,
    step_size_controller = step_size_controller,
    stepper_options      = stepper_options
    ) 




ode_time = ode.time(ode_res)
ode_vars = ode.variables(ode_res)




# --------------------------------------------------------------------------- #
# Sindy
# --------------------------------------------------------------------------- #

window_size = 3
t_mids = ode_time[window_size+1:end]

dx1 = noisydiff.diff_sliding_least_squares_d1(ode_time, ode_vars[1,:], w = window_size)
dx2 = noisydiff.diff_sliding_least_squares_d1(ode_time, ode_vars[2,:], w = window_size)




dermat  = [dx1 dx2]
datamat = ode_vars[:, (window_size+1):end]'
u       = params.f.( ode_time )
u       = u[(window_size+1):end]
datamat = [datamat u]


poly_order = 2
(libmat, names) = sindy.create_poly_lib(datamat, polyorder = poly_order)


sparsifing_opt = sindy.SparsifingOptions(
    threshold = 0.1,
    max_iter = 10)

Xi = sindy.sparsify_dynamics(dermat, libmat, sparsifing_opt)

# dxdt = v
# dvdt = 1/m * (f(t) - c * x - d * v )

# dxdt = v
# dvdt = -c/m * x - d/m * v


Xi_theo = [
            0 0;
            0 -c/m;
            1 -d/m]

# --------------------------------------------------------------------------- #
# Visualize
# --------------------------------------------------------------------------- #


if enable_plot_odesol
    PyPlot.figure()
    PyPlot.subplot(2,1,1)
    PyPlot.grid()
    PyPlot.plot( ode_res.t, ode_res.q[:, 1] )

    PyPlot.subplot(2,1,2)
    PyPlot.grid()
    PyPlot.plot( ode_res.t, ode_res.q[:, 2] )
    PyPlot.plot(t_mids, dx1)
end


if enable_plot_diffs
    PyPlot.figure()

    PyPlot.subplot(2,1,1)
    PyPlot.grid()
    PyPlot.plot(t_mids, dx1)


    PyPlot.subplot(2,1,2)
    PyPlot.grid()
    PyPlot.plot(t_mids, dx2)
end


end

