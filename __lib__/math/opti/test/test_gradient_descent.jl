

include("../src/opti_module.jl")
include("../opti_test_functions/testfunctions.jl")

module gtest
using BenchmarkTools
using ..opti
using ..optitestfun



function test_steepest_gradient_descent()
    # fcn(x) = x[1]^2 + x[2]^2
    fcn(x) = optitestfun.rosenbrock(x, 2)
    # x0 = [1.0, 2]
    x0 = [-1.8, -2]
    stat = opti.steepest_gradient_descent(fcn, x0, tol_options = opti.ToleranceOptions(max_iter = 1000))

    # stat = opti.steepest_gradient_descent_original(fcn, x0, tol_options = opti.ToleranceOptions(max_iter = 1000))

    show(stat)

end


function test_steepest_gradient_descent_v2()

    fcn(x) = optitestfun.rosenbrock(x, 2)

    x0 = [-1.8, -2]
    (stat, opti_search_path) = opti.steepest_gradient_descent(fcn, x0, tol_options = opti.ToleranceOptions(max_iter = 1000), log_path = true)

    show(stat)

    optitestfun.plot_rosenbrock([-2, 5], [-2, 5])
    PyPlot.plot( opti_search_path.x[1, :], opti_search_path.x[2, :], marker = :., markersize = 15 )
end






function benchmark_steepestgrad()

    fcn(x) = optitestfun.rosenbrock(x, 2)
    x0 = [-1.8, -2]
    b = @benchmark opti.steepest_gradient_descent($fcn, $x0, tol_options = opti.ToleranceOptions(max_iter = 1000))

    println("=== steepest_gradient_descent ===")
    show(
            stdout,
            MIME("text/plain"),
            b )
    println("\n\n")
end

function benchmark_steepestgrad_orig()

    fcn(x) = optitestfun.rosenbrock(x, 2)
    x0 = [-1.8, -2]
    b = @benchmark opti.steepest_gradient_descent_original($fcn, $x0, tol_options = opti.ToleranceOptions(max_iter = 1000))

    println("=== steepest_gradient_descent_original ===")
    show(
            stdout,
            MIME("text/plain"),
            b )
    println("\n\n")
end

function benchmark_cg_pr()

    fcn(x) = optitestfun.rosenbrock(x, 2)
    x0 = [-1.8, -2]
    b = @benchmark opti.cg_pr($fcn, $x0)

    println("=== cg_pr ===")
    show(
            stdout,
            MIME("text/plain"),
            b )
    println("\n\n")
end



function test_cg_pr()
    # fcn(x) = x[1]^2 + x[2]^2
    fcn(x) = optitestfun.rosenbrock(x, 4)
    x0 = [-1.8, -2]

    stat = opti.cg_pr(fcn, x0; tol_options = opti.ToleranceOptions(f_abs_tol = 1e-10))

    show(stat)

end

function test_cg_pr_quad()
    fcn(x) = optitestfun.nd_quadratic(x)
    n_dim = 100
    x0 = 10 * rand(n_dim)

    stat = opti.cg_pr(fcn, x0; tol_options = opti.ToleranceOptions(f_abs_tol = 1e-10))

    show(stat)
end

function test_cg_pr_quadwithl1()
    
    n_dim = 10
    x_sol = ones(n_dim)
    fcn(x) = optitestfun.quad_with_norm_l1(x, x_sol, 0.8)
    
    x0 = 10 * rand(n_dim)

    stat = opti.cg_pr(fcn, x0; tol_options = opti.ToleranceOptions(f_abs_tol = 1e-10))

    show(stat)

end

function test_cg_pr_v2()
    # fcn(x) = x[1]^2 + x[2]^2
    fcn(x) = optitestfun.rosenbrock(x, 2)
    x0 = [-1.8, -2]

    (stat, opti_search_path) = opti.cg_pr(fcn, x0, log_path = true)

    show(stat)


    optitestfun.plot_rosenbrock([-2, 5], [-2, 5])
    PyPlot.plot( opti_search_path.x[1, :], opti_search_path.x[2, :], marker = :., markersize = 15 )
end



end