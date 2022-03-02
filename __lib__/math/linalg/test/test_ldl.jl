
function test_ldl_decomp()

    A = [
        4    3       1      5;
        1    2       1      0.1;
        1    2       16     3;
        -2   1       4      9 
        ]

    n = 20 # 200
    A = rand(n, n)
    A = A + A'


    (L, d) = linalg.ldl_decomp(A)

    A_dec = L * diagm(d) * L'

    println("L:")
    show(stdout, MIME("text/plain"), L)
    println("\n")

    println("d:")
    show(stdout, MIME("text/plain"), d)
    println("\n")

    #=
    println("A:")
    show(stdout, MIME("text/plain"), A)
    println("\n")
    
    println("A_dec:")
    show(stdout, MIME("text/plain"), A_dec)
    println("\n")
    =#

    println("A_dec - A:")
    show(stdout, MIME("text/plain"), norm( A_dec - A) <= 1e-10 )
    println("\n")    

end


function test_linsolve_ldl()
    A = [
        4    3       1      5;
        1    2       1      0.1;
        1    2       16     3;
        -2   1       4      9 
        ]

    n = 200 # 200
    A = rand(n, n)
    A = A + A'

    # b = [3.0, 6, 2, 10]
    b = rand(n)

    x_ldl = linalg.linsolve_ldl(A, b)

    x_theo = A \ b

    #=
    println("x_ldl:")
    println(x_ldl)
    println( "residuum norm x_lu:  $(norm( A * x_ldl - b )) " )

    println("x_theo:")
    println(x_theo)
    println( "residuum norm x_theo:  $(norm( A * x_theo - b )) " )

    println("dx:")
    println(x_ldl - x_theo)
    println( "norm dx:  $(norm(x_ldl - x_theo)) " )
    =#

    println("dx:")
    println( "norm dx:  $(norm(x_ldl - x_theo)) " )

end


function benchmark_linsolve_ldl(A, b)
    b_ = @benchmark linalg.linsolve_ldl($A, $b)

    println("=== benchmark_linsolve_ldl ===")
    show(
            stdout,
            MIME("text/plain"),
            b_ )
    println("\n\n")
end
