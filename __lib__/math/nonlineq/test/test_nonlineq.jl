

module ntest
using  ..nonlineq

function test_broyden()

    fcn(x) = [ (x[1] + 3) * (x[2]^2 - 7) + 18,  sin( x[2] * exp(x[1]) - 1) ]

    x0 = [-0.5, 1.4]

    (x_sol, iter) = nonlineq.broyden(fcn, x0)

    println("Solution at: $(x_sol)")
    println("Iter: $(iter)" )

end



end # ntest
