

include("../src/Polynomials.jl")



module ptest
using ..Polynomials
using PyPlot
PyPlot.pygui(true)

# cos ~ 1 - x^2 / 2 + x^4 / 24 + 

cos_poly2 = Polynomials.Polynomial(1.0, 0.0, -1/2)
cos_poly4 = Polynomials.Polynomial(1.0, 0.0, -1/2, 0.0, 1/24)
cos_poly6 = Polynomials.Polynomial(1.0, 0.0, -1/2, 0.0, 1/24, 0.0, -1/720)
cos_poly8 = Polynomials.Polynomial(1.0, 0.0, -1/2, 0.0, 1/24, 0.0, -1/720, 0.0, 1/40320)


# xx = -pi/2:0.01:pi/2
# yy2 = cos_poly2.(xx)
# yy4 = cos_poly4.(xx)
# yy6 = cos_poly6.(xx)
# yy8 = cos_poly8.(xx)


# PyPlot.figure()
# PyPlot.grid()
# PyPlot.plot(xx, yy2)
# PyPlot.plot(xx, yy4)
# PyPlot.plot(xx, yy6)
# PyPlot.plot(xx, yy8)


# xx = [-pi/2, -pi/4, 0, 0.1, 0.2]
xx = [-pi/2, 0, 0.1]
yy = cos_poly2.(xx)

# neville_poly = Polynomials.NevilleAitkenPolynomial(xx, yy)


# xx = -pi/2:0.01:pi/2
# yy2 = neville_poly.(xx)
# yyc = cos_poly2.(xx)

# PyPlot.figure()
# PyPlot.grid()

# PyPlot.subplot(2, 1, 1)
# PyPlot.plot(xx, yy2)
# PyPlot.plot(xx, yyc)

# PyPlot.subplot(2, 1, 2)
# PyPlot.plot(xx, yy2 .- yyc)


newton_poly = Polynomials.NewtonPolynomial(xx, yy)



xx = -pi/2:0.01:pi/2
yy2 = newton_poly.(xx)
yyc = cos_poly2.(xx)

PyPlot.figure()
PyPlot.grid()

PyPlot.subplot(2, 1, 1)
PyPlot.plot(xx, yy2)
PyPlot.plot(xx, yyc)

PyPlot.subplot(2, 1, 2)
PyPlot.plot(xx, yy2 .- yyc)

















# coeff = (1.0, 2.0, 3.0)
# # t_coeff = tuple(map(Float64, v_coeff)...)

# p_v = Polynomials.Polynomial(v_coeff)
# p_t = Polynomials.Polynomial(t_coeff)


# coeff = (1.0, 2.0, 3.0, 5.0)
# p = Polynomials.Polynomial(coeff)
# int_p = Polynomials.integrate(p)
# der_p = Polynomials.derivative(p)

# coeff1 = (3.0, 2.0, 4.0)
# p1 = Polynomials.Polynomial(coeff1)

# coeff2 = (5.0, 6.0, 3.0, 7.0)
# p2 = Polynomials.Polynomial(coeff2)

# # q = p1 * p2

# # p1_sq = p1^2
# # p2_sq = p2^2

# # z = Polynomials.roots(p1)
# # q = Polynomials.Polynomials_from_roots(z)

# z = [-3.0, 1.0, 5.0, 2.0 - im, 2.0 + im]
# q = Polynomials.poly_from_roots(z)
# z_c = Polynomials.roots(q)

end



