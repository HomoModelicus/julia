
include("../src/linalg_module.jl")

module lutest
using ..linalg
using BenchmarkTools
using LinearAlgebra
using PyPlot
PyPlot.pygui(true)

function test_linsolve_lu()

    #=
    A = [
        1   4   -1;
        3   0   5;
        2   2   1.0
        ]
    b = [10.0, 2, 3]
    =#
    
    A = [
        3e-6    2       1;
        2       2       2;
        1       2       -1
        ]
    b = [3+3e-6, 6, 2]


    n_dim = 1000
    A = rand(n_dim, n_dim)
    b = rand(n_dim)
    
    x_lu = linalg.linsolve_lu(A, b)
    @time x_theo = A \ b


    println("x_lu:")
    # println(x_lu)
    println( "residuum norm x_lu:  $(norm( A * x_lu - b )) " )

    println("x_theo:")
    # println(x_theo)
    println( "residuum norm x_theo:  $(norm( A * x_theo - b )) " )

end




function test_lu_decomposition()
    A = [
        1   4   -1;
        3   0   5;
        2   2   1.0
        ]
    b = [10.0, 2, 3]

    (L, U, p) = linalg.lu_decomp_partialpivot(A)
    
    println("L:")
    show(stdout, MIME("text/plain"), L)
    println("\n")

    println("U:")
    show(stdout, MIME("text/plain"), U)
    println("\n")

    println("p:")
    show(stdout, MIME("text/plain"), p)
    println("\n")

    return (L, U, p)
end




function benchmark_linsolve_lu(A, b)
    b_ = @benchmark linalg.linsolve_lu($A, $b)

    println("=== benchmark_linsolve_lu ===")
    show(
            stdout,
            MIME("text/plain"),
            b_ )
    println("\n\n")
end

function profiler_linsolve_lu()

    N = 3_000
    A = rand(N, N)
    A = diagm( diag(A) ) .+ A
    b = rand(N)

    x = linalg.linsolve_lu(A, b)

end


end