
include("../src/autodiff_module.jl")


module dtest
using PyPlot
PyPlot.pygui(true)
using ..autodiff
using BenchmarkTools


fcn2_a(x) = x[1] + x[2]
fcn2_b(x) = x[1] * x[2]
fcn2_c(x) = x[1] / x[2]
fcn3(x) = [fcn2_a(x), fcn2_b(x), fcn2_c(x)]


mode = autodiff.ReverseMode()

x0 = [1.0, 3.0]
g = autodiff.gradient(mode, fcn2_a, x0)

# x0 = [2.0, 3.0]
g = autodiff.gradient(mode, fcn2_b, x0)

# x0 = [0.0, 3.0]
g = autodiff.gradient(mode, fcn2_c, x0)
# gd = autodiff.gradient(autodiff.ForwardMode(), fcn2_c, x0)

# x0 = [1.0, 3.0]
# @btime jac = autodiff.jacobian(mode, fcn3, x0)
# @btime jacd = autodiff.jacobian(autodiff.ForwardMode(), fcn3, x0)

end