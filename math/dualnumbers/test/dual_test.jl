

include("../src/DualNumbers.jl")



module dtest
using ..DualNumbers
using PyPlot
PyPlot.pygui(true)



fcn(x) = [1/2 * x[1]^2.0, 1/3 * x[2]^3.0, 1/4 * x[3]^4]

x0 = [4.0, 2, 3]
d0 = zeros(DualNumber{Float64}, 3)

jac = DualNumbers.jacobian(fcn, x0)


function gradient_test()
    fcn(x) = x[1]^2 + x[2]^2 

    x0 = [1.0, -1]
    g = DualNumbers.gradient(fcn, x0)
end


d1 = DualNumbers.DualNumber(1.0, 5)
d2 = DualNumbers.DualNumber(2.0, 3)

function test_and_plot()

    d1 = DualNumber(1.0, 5)
    d2 = DualNumber(2.0, 3)
    d3 = DualNumber(4, 7)


    fcn(x) = x^2.0 # exp(-0.5 * x) # sin(x)

    x0 = 0.0
    d0 = DualNumbers.derivative(fcn, x0)

    xx = -pi/2:0.1:2*pi |> collect
    yy = DualNumbers.derivative.(fcn, xx)
    yytheo = 2 * xx # -0.5 .* exp.(-0.5 .* xx) # cos.(xx)



    PyPlot.figure()
    PyPlot.grid()

    PyPlot.subplot(2, 1, 1)
    PyPlot.plot(xx, yy)
    PyPlot.plot(xx, yytheo)


    PyPlot.subplot(2, 1, 2)
    PyPlot.plot(xx, yy .- yytheo)

end


end


