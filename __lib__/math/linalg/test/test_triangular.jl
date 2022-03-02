

# =========================================================================== #
# Test
# =========================================================================== #

function test_triangular_solve_upper()

    U = [
        4.0     2       7   9;
        0       12      2   8;
        0       0       1   10;
        0       0       0   6
    ]
    b = [10.0,  2,  5,  6]

    x_row = linalg.triangular_solve_upper_rowwise(U, b)
    x_col = linalg.triangular_solve_upper_colwise(U, b)
    x_theo = U \ b
    println( "x rowwise: $(x_row)" )
    println( "x colwise: $(x_col)" )
    println( "x_theo rowwise: $(x_theo)" )
    println( "residuum norm x rowwise:  $(norm( U * x_row - b )) " )
    println( "residuum norm x colwise:  $(norm( U * x_col - b )) " )
    println( "residuum norm x_theo:  $(norm( U * x_theo - b )) ")
end

function test_triangular_solve_lower()

    L = [
        6.0     0   0   0
        10      1   0   0;
        8       2   12  0;
        9       7   2   4;
    ]
    
    b = [10.0,  2,  5,  6]

    x_row = linalg.triangular_solve_lower_rowwise(L, b)
    x_col = linalg.triangular_solve_lower_colwise(L, b)
    x_theo = L \ b
    println( "x rowwise: $(x_row)" )
    println( "x colwise: $(x_col)" )
    println( "x_theo rowwise: $(x_theo)" )
    println( "residuum norm x rowwise:  $(norm( L * x_row - b )) " )
    println( "residuum norm x colwise:  $(norm( L * x_col - b )) " )
    println( "residuum norm x_theo:  $(norm( L * x_theo - b )) ")
end



# =========================================================================== #
# Benchmark
# =========================================================================== #

function benchmark_trisolve_default_upper(U, b)
    b = @benchmark $U \ $b

    println("=== benchmark_trisolve_default ===")
    show(
            stdout,
            MIME("text/plain"),
            b )
    println("\n\n")
end

function benchmark_trisolve_rowwise_upper(U, b)
    b = @benchmark linalg.triangular_solve_upper_rowwise($U, $b)

    println("=== benchmark_trisolve_rowwise ===")
    show(
            stdout,
            MIME("text/plain"),
            b )
    println("\n\n")
end

function benchmark_trisolve_colwise_upper(U, b)
    b = @benchmark linalg.triangular_solve_upper_colwise($U, $b)

    println("=== benchmark_trisolve_colwise ===")
    show(
            stdout,
            MIME("text/plain"),
            b )
    println("\n\n")
end

function benchmark_trisolve_upper()
    N = 30_000
    U = UpperTriangular( rand(N, N) )
    b = rand(N)

    benchmark_trisolve_default_upper(U, b)
    benchmark_trisolve_colwise_upper(U, b)
    benchmark_trisolve_rowwise_upper(U, b)

end





function benchmark_trisolve_default_lower(U, b)
    b = @benchmark $U \ $b

    println("=== benchmark_trisolve_default ===")
    show(
            stdout,
            MIME("text/plain"),
            b )
    println("\n\n")
end

function benchmark_trisolve_rowwise_lower(U, b)
    b = @benchmark linalg.triangular_solve_lower_rowwise($U, $b)

    println("=== benchmark_trisolve_rowwise ===")
    show(
            stdout,
            MIME("text/plain"),
            b )
    println("\n\n")
end

function benchmark_trisolve_colwise_lower(U, b)
    b = @benchmark linalg.triangular_solve_lower_colwise($U, $b)

    println("=== benchmark_trisolve_colwise ===")
    show(
            stdout,
            MIME("text/plain"),
            b )
    println("\n\n")
end

function benchmark_trisolve_lower()
    N = 30_000
    U = LowerTriangular( rand(N, N) )
    b = rand(N)

    benchmark_trisolve_default_lower(U, b)
    benchmark_trisolve_colwise_lower(U, b)
    benchmark_trisolve_rowwise_lower(U, b)

end