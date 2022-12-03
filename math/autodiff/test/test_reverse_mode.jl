


include("../src/autodiff_module.jl")
include("../../__lib__/math/common/numder/src/numder_module.jl")

module dtest
using ..numder
using ..autodiff
using PyPlot
PyPlot.pygui(true)



t = autodiff.Tape()
x = autodiff.create_variable(t, pi)
y = autodiff.create_variable(t, 20.0)

# z = cos(x * y + sin(x))

z1 = x + y
z2 = x * y
z3 = exp(x)
z4 = sin(y)
z5 = abs(y)
z6 = z1^z2
z7 = 3 * z1
z8 = max(z1, z2)
z = z1 + z2 + z3 + z4 + z5 + z6 + z7


g = autodiff.grad(z)


end