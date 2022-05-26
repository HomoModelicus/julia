

include("../src/autodiff_module.jl")

module dtest
using ..autodiff
using PyPlot
PyPlot.pygui(true)


fcn0_1(x) = 5 * x + 10.0

fcn1(x) = begin 
    c1 = x^3
    c2 = x^2
    c3 = x
    t1 = 1/3 * c1 
    return t1 + 1/2 * c2 + 5 * c3 + 10.0
end
fcn2(x) = sin(x) * exp(x) + x^5
fcn3(x) = sin(x)

mode = autodiff.ReverseMode()



# x0 = 2.1 # 5.0 #-1.5 # 4.6 # 3.2
# der_f = autodiff.derivative(autodiff.ForwardMode(), fcn1, x0)
# der_r = autodiff.derivative(autodiff.ReverseMode(), fcn1, x0)


x0 = collect(-3.0:0.1:5)
L = length(x0)
der_f = Vector{Float64}(undef, L)
der_r = Vector{Float64}(undef, L)
delta_der = Vector{Float64}(undef, L)

# der_f = zeros(Float64, L)
# der_r = zeros(Float64, L)
# delta_der = zeros(Float64, L)


for ii = 1:L
    der_r[ii] = autodiff.derivative(autodiff.ReverseMode(), fcn3, x0[ii])
end

for ii = 1:L
    der_f[ii] = autodiff.derivative(autodiff.ForwardMode(), fcn3, x0[ii])
end

delta_der = der_f - der_r

PyPlot.figure()
PyPlot.plot(x0, der_f, marker = :+)
PyPlot.plot(x0, der_r, marker = :o)

PyPlot.figure()
PyPlot.plot(x0, delta_der)


end

