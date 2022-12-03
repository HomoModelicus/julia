




module ntest
using ..Roots
using BenchmarkTools


# fcn(x)  = sin(x)
# x_lower = -pi/2 - 0.1
# x_upper = +pi/2



fcn(x)  = exp(x^2+7*x-30) - 1
x_lower = -10.5
x_upper = -9.0


# fcn(x)  = x^2 - 4
# x_lower = 0.1
# x_upper = 5.0


options = Roots.Rootsolving1dOptions(x_lower, x_upper; max_iter = 10_000)

# b = @benchmark (x_sol, stat) = Roots.bisection(fcn, options)
(x_sol_bis,    stat_bis)    = Roots.bisection(           fcn, options )
(x_sol_regf,   stat_regf)   = Roots.regulafalsi(         fcn, options )
(x_sol_regfil, stat_regfil) = Roots.regulafalsi_ilinois( fcn, options )
(x_sol_rid, stat_rid)       = Roots.ridders(             fcn, options )

#=
using PyPlot
PyPlot.pygui(true)

dx = 1e-2
xx = collect(x_lower:dx:x_upper)
yy = fcn.(xx)

PyPlot.figure()
PyPlot.grid()
PyPlot.plot(xx, yy)
=#


end




#=

module ntest
using  ..Roots

function test_broyden()

    fcn(x) = [ (x[1] + 3) * (x[2]^2 - 7) + 18,  sin( x[2] * exp(x[1]) - 1) ]

    x0 = [-0.5, 1.4]

    (x_sol, iter) = nonlineq.broyden(fcn, x0)

    println("Solution at: $(x_sol)")
    println("Iter: $(iter)" )

end



end # ntest

=#


