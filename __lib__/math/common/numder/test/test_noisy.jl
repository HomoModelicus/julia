
include("../src/numder_module.jl")

module dtest
using PyPlot
PyPlot.pygui(true)
# using ..dev
using ..numder

function test_estimate_noise()
    # define function + number of evals
    fcn(x) = cos(x) + sin(x) + 1e-6 * rand() # sin(x) + 0.00001 * randn()
    n_eval = 7

    # initial point + step length
    x0 = 0.0 # 1 # pi/4
    h  = 0.01 # 1e3 * sqrt(eps(x0))
    # h = 1e3 .* sqrt.(eps.(x0))
    noise_est = numder.estimate_noise(
        fcn, 
        x0;
        n_eval = n_eval)
end


function test_estimate_noise_nd()
    fcn(x) = x[1].^2 + x[2].^2 + 0.5 * randn()
    n_eval = 7

    x0 = [1.0, 1.0]

    noise_est = numder.estimate_noise(
            fcn, 
            x0)
end


fcn(x) = sin(x) + 0.001 * randn()
fcn_theo(x) = sin(x)

x0 = 0.0
noise_est = numder.estimate_noise(fcn, x0)
h = noise_est




xs = collect( -pi/2:0.1:2*pi )
ys = fcn.(xs)
ys_theo = fcn_theo.(xs)
x_mids = 0.5 .* (xs[1:end-1] + xs[2:end])


dfdx = numder.numdiff_fw.(fcn, xs, sqrt(h) ) #, h 
dfdx_theo = cos.(xs)


dfdx_from_signal = (ys[2:end] - ys[1:end-1]) ./ diff(xs)


fig = PyPlot.figure()

ax1 = PyPlot.subplot(2,1,1)
PyPlot.grid()
PyPlot.plot( xs, ys_theo )
PyPlot.plot( xs, ys )

ax1 = PyPlot.subplot(2,1,2, sharex = ax1)
PyPlot.grid()
PyPlot.plot( xs, dfdx_theo )
PyPlot.plot( xs, dfdx )
PyPlot.plot( x_mids, dfdx_from_signal )





end # dtest