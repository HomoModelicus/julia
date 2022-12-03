


include("../src/opti_module.jl")
include("../opti_test_functions/testfunctions.jl")

module otest
using BenchmarkTools
using ..opti
using ..optitestfun
using PyPlot
PyPlot.pygui(true)

include("test_opti_1d.jl")
include("test_line_search.jl")
include("test_gradient_descent.jl")
# include("accelerated_grad_descent.jl")


function test_bfgs()
    fcn(x) = optitestfun.rosenbrock(x, 4, 100)
    x0 = [-1.8, -2]

    (x, f, iter) = opti.quasi_newton(fcn, x0)
    println("Solution at: $(x)")
    println("Iter: $(iter)" )
end






function test_nesterov()

    fcn(x) = optitestfun.rosenbrock(x, 2)
    x0 = [-1.8, -2]

    (stat, opti_search_path) = opti.nesterov_momentum_gradient_descent(
        fcn,
        x0,
        tol_options = opti.ToleranceOptions(max_iter = 1000),
        log_path = true,
        method_parameters = opti.NesterovGradientDescentMethod(max_v = 0.1, beta = 0.4, alpha = 0.05)
        )

    show(stat)


    optitestfun.plot_rosenbrock([-2, 5], [-2, 5])
    PyPlot.plot( opti_search_path.x[1, :], opti_search_path.x[2, :], marker = :., markersize = 15 )
end



#=
# something is wrong with the implementation
function test_hyper_nesterov()

    fcn(x) = optitestfun.rosenbrock(x, 2)
    x0 = [-1.8, -2]

    (stat, opti_search_path) = opti.hyper_nesterov_momentum_gradient_descent(
        fcn,
        x0,
        tol_options = opti.ToleranceOptions(max_iter = 1000),
        log_path = true,
        method_parameters = opti.HyperNesterovGradientDescentMethod(max_v = 0.1, beta = 0.4, alpha = 0.05)
        )

    show(stat)


    optitestfun.plot_rosenbrock([-2, 5], [-2, 5])
    PyPlot.plot( opti_search_path.x[1, :], opti_search_path.x[2, :], marker = :., markersize = 15 )
end
=#



fcn(x) = optitestfun.rosenbrock(x, 2)
# x0 = [-1.8, -2]


# fcn(x) = sum(x .* x)
x0 = [-1.8, -2.0]
# t_sol = opti.bfgs(fcn, x0)
t_sol = opti.cg_pr(fcn, x0)

# t_qn = opti.quasi_newton(fcn, x0)



end # otest
