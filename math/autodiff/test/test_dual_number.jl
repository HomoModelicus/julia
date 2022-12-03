

include("../src/autodiff_module.jl")
include("../../__lib__/math/common/numder/src/numder_module.jl")


module dtest
using PyPlot
PyPlot.pygui(true)
using ..autodiff
using ..numder


x1 = autodiff.DualNumber(1.0)
x2 = autodiff.DualNumber(2.0)
x3 = autodiff.DualNumber(pi/2)

x4 = x1 * x2
x5 = sin(x3)
x6 = exp(x4)
x7 = x4 * x5
x8 = x6 + x7
x9 = x8 / x3







fcn(x) = begin
    x1 = x[1]
    x2 = x[2]
    x3 = x[3]
    (x1 * x2 * sin(x3) + exp(x1 * x2)) / x3
end

x_vec = [1.0, 2, pi/2]

L        = length(x_vec)
grad_vec = zeros(L)
e_i      = zeros(L)
for kk = 1:L
    e_i[kk]         = 1.0
    y_vec           = [autodiff.DualNumber(x_vec[kk], e_i[kk]) for kk = 1:L]
    grad_vec[kk]    = fcn(y_vec).v
    e_i[kk]         = 0.0
end







function test_elem()

    fcn(x)      = 3 * x^2 - 10 * x + 10 # log(x) # cos(x) # sin(x) # x^2
    theodiff(x) = 6 * x - 10 # 1 / x  # -sin(x) # cos(x)

    xs = collect( 0.0:0.1:3 )
    ds = autodiff.DualNumber.(xs)

    fs = fcn.(xs)
    theograd = theodiff.(xs)
    gs = fcn.(ds)

    f_from_d    = autodiff.value(gs)
    dfdx_from_d = autodiff.derivative(gs)
    

    PyPlot.figure()
    PyPlot.grid()
    PyPlot.plot(xs, fs, marker = :s)
    PyPlot.plot(xs, f_from_d, marker = :*)
    PyPlot.plot(xs, dfdx_from_d, marker = :o, markersize = 10)
    PyPlot.plot(xs, theograd, marker = :^, markersize = 10)
    
    
    
    # return (gs, f_from_d, dfdx_from_d)
end



function test_dual()

    add(x1, x2) = x1 + x2
    mult(x1, x2) = x1 * x2
    div(x1, x2) = x1 / x2

    addv(x) = x[1] + x[2]
    multv(x) = x[1] * x[2]
    divv(x) = x[1] / x[2]


    f1 = 3.0
    f2 = 2.0

    d1 = autodiff.DualNumber(2.0, 1.0)
    d2 = autodiff.DualNumber(3.0, 0.0)
    dp = autodiff.DualNumber(5.0, 1.0)
    d3 = autodiff.DualNumber(-2.0, -1.5)
    d4 = autodiff.DualNumber(-2.0, 1.5)


    pd = add(d1, d2)
    p1 = add(d1, f1)
    p2 = add(f2, d2)


    md = mult(d1, d2)
    m1 = mult(d1, f1)
    m2 = mult(f2, d2)

    n_md = numder.gradient_fw(multv, [d1.x, d2.x])


    did = div(d1, d2)
    did2 = div(d2, d1)

    di1 = div(d1, f1)
    di2 = div(f2, d2)

    n_dd = numder.gradient_fw(divv, [d1.x, d2.x])



    sq = d1^d2

    a1 = abs(d3)
    a2 = abs(d4)



    s = sin(d1)
    c = cos(d1)
    t = tan(d1)

    sh = sinh(d1)
    ch = cosh(d1)
    th = tanh(d1)

    e = exp(d1)
    l = log(d1)

    r = sqrt(d1)

end




end

