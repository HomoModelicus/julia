

include("../src/autodiff_module.jl")
include("../../__lib__/math/common/numder/src/numder_module.jl")


module dtest
using PyPlot
PyPlot.pygui(true)
using ..autodiff
using ..numder



x = autodiff.DualNumber(1.0)
y = autodiff.DualNumber(3.0)

z = x + y

fcn1(x) = 1/3 * x^3 + 1/2 * x^2 + 5 * x + 10.0
fcn2_a(x) = x[1] + x[2]
fcn2_b(x) = x[1] * x[2]
fcn2_c(x) = x[1] / x[2]
fcn3(x) = [fcn2_a(x), fcn2_b(x), fcn2_c(x)]

x0 = 2.0
d1 = autodiff.derivative(fcn1, x0)

mode = autodiff.ForwardMode()

x0_a = [1.0, 3]
g2_a = autodiff.gradient(mode, fcn2_a, x0_a)
g2_b = autodiff.gradient(mode, fcn2_b, x0_a)
g2_c = autodiff.gradient(mode, fcn2_c, x0_a)


jac = autodiff.jacobian(mode, fcn3, x0_a)


end