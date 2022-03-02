
include("../../util/src/util_module.jl")


module dev



module matrix_vector_prod
using LinearAlgebra

function matrix_vector_prod_default(A::Matrix{T}, x::Vector{T}) where {T<:Float64}
    sz_a = size(A)
    sz_b = size(x)
    
    if length(sz_a) != 2
        error("A is not a matrix")
    end
    if length(sz_b) != 1
        error("B is not a vector")
    end
    if sz_a[2] != sz_b[1]
        error("A and B are not compatible (size mismatch) ")
    end
    c = A * x
    return c
end


function matrix_vector_prod_inner(A, x)
    # A in R^m-by-p
    # x in R^p-by-1
    # c = A * x in R^m-by-1
    sz_a = size(A)
    sz_b = size(x)
    
    if length(sz_a) != 2
        error("A is not a matrix")
    end
    if length(sz_b) != 1
        error("B is not a vector")
    end
    if sz_a[2] != sz_b[1]
        error("A and B are not compatible (size mismatch) ")
    end

    c = zeros(eltype(A), sz_a[1])
    @inbounds @simd for ii = 1:sz_a[1]
        # c[ii] = A[ii, :]' * x
        c[ii] =  dot( @view(A[ii, :]), x)
    end
    return c
end

function matrix_vector_prod_inner_loop(A, x)
    # A in R^m-by-p
    # x in R^p-by-1
    # c = A * x in R^m-by-1
    sz_a = size(A)
    sz_b = size(x)
    
    if length(sz_a) != 2
        error("A is not a matrix")
    end
    if length(sz_b) != 1
        error("B is not a vector")
    end
    if sz_a[2] != sz_b[1]
        error("A and B are not compatible (size mismatch) ")
    end

    c = zeros(eltype(A), sz_a[1])
    @inbounds @simd for ii = 1:sz_a[1]
        inner_sum = zero(eltype(x))
        @inbounds @simd for jj = 1:sz_a[2]
            inner_sum += A[ii, jj] * x[jj] 
        end
        c[ii] = inner_sum
    end
    return c
end

function matrix_vector_prod_outer(A, x)
    # A in R^m-by-p
    # x in R^p-by-1
    # c = A * x in R^m-by-1
    sz_a = size(A)
    sz_b = size(x)
    
    if length(sz_a) != 2
        error("A is not a matrix")
    end
    if length(sz_b) != 1
        error("B is not a vector")
    end
    if sz_a[2] != sz_b[1]
        error("A and B are not compatible (size mismatch) ")
    end

    c = zeros(eltype(A), sz_a[1])
    @inbounds @simd for jj = 1:sz_a[2]
        c .+= @view( A[:, jj] ) .* x[jj]
    end
    return c
end

function matrix_vector_prod_outer_loop(A, x)
    # A in R^m-by-p
    # x in R^p-by-1
    # c = A * x in R^m-by-1
    sz_a = size(A)
    sz_b = size(x)
    
    if length(sz_a) != 2
        error("A is not a matrix")
    end
    if length(sz_b) != 1
        error("B is not a vector")
    end
    if sz_a[2] != sz_b[1]
        error("A and B are not compatible (size mismatch) ")
    end

    c = zeros(eltype(A), sz_a[1])
    @inbounds @simd for jj = 1:sz_a[2]
        @inbounds @simd for ii = 1:sz_a[1]
            c[ii] += A[ii, jj] * x[jj]
        end
    end
    return c
end



function matrix_mult_inner(A, B)
    # A in R^m-by-p
    # B in R^p-by-n
    # C = A * B in R^m-by-n
    # [ma, p] = size(A)
    # [, p] = size(A)
    sz_a = size(A)
    sz_b = size(B)
    
    if length(sz_a) != 2
        error("A is not a matrix")
    end
    if length(sz_b) != 2
        error("B is not a matrix")
    end
    if sz_a[2] != sz_b[1]
        error("A and B are not compatible (size mismatch) ")
    end
    
    C = zeros(eltype(A), sz_a[1], sz_b[2])
    for ii = 1:sz_a[1]
        for jj = 1:sz_b[2]
            C[ii, jj] = dot( A[ii, :],  B[:, jj] )
            # C[ii, jj] = A[ii, :]' *  B[:, jj]
        end
    end
    return C
end

function matrix_mult_outer(A, B)
    # A in R^m-by-p
    # B in R^p-by-n
    # C = A * B in R^m-by-n
    # [ma, p] = size(A)
    # [, p] = size(A)
    sz_a = size(A)
    sz_b = size(B)
    
    if length(sz_a) != 2
        error("A is not a matrix")
    end
    if length(sz_b) != 2
        error("B is not a matrix")
    end
    if sz_a[2] != sz_b[1]
        error("A and B are not compatible (size mismatch) ")
    end
    
    C = zeros(eltype(A), sz_a[1], sz_b[2])
    for kk = 1:sz_a[2]
        C += A[:, kk] * B[kk, :]'
    end
    return C
end

function matrix_mult_default(A, B)
    # A in R^m-by-p
    # B in R^p-by-n
    # C = A * B in R^m-by-n
    # [ma, p] = size(A)
    # [, p] = size(A)
    sz_a = size(A)
    sz_b = size(B)
    
    if length(sz_a) != 2
        error("A is not a matrix")
    end
    if length(sz_b) != 2
        error("B is not a matrix")
    end
    if sz_a[2] != sz_b[1]
        error("A and B are not compatible (size mismatch) ")
    end
    C = A * B
    return C
end

function matrix_mult_inner_loop(A, B)
    # A in R^m-by-p
    # B in R^p-by-n
    # C = A * B in R^m-by-n
    # [ma, p] = size(A)
    # [, p] = size(A)
    sz_a = size(A)
    sz_b = size(B)
    
    if length(sz_a) != 2
        error("A is not a matrix")
    end
    if length(sz_b) != 2
        error("B is not a matrix")
    end
    if sz_a[2] != sz_b[1]
        error("A and B are not compatible (size mismatch) ")
    end
    C = zeros(eltype(A), sz_a[1], sz_b[2])

    for ii = 1:sz_a[1]
        for jj = 1:sz_b[2]
            inner_sum = zero(eltype(A))
            for kk = 1:sz_a[2]
                inner_sum += A[ii, kk] *  B[kk, jj]
            end
            C[ii, jj] = inner_sum
        end
    end
    return C
end

function matrix_mult_outer_loop(A, B)
    #
    # Algo probably wrong
    #
    # A in R^m-by-p
    # B in R^p-by-n
    # C = A * B in R^m-by-n
    # [ma, p] = size(A)
    # [, p] = size(A)
    sz_a = size(A)
    sz_b = size(B)
    
    if length(sz_a) != 2
        error("A is not a matrix")
    end
    if length(sz_b) != 2
        error("B is not a matrix")
    end
    if sz_a[2] != sz_b[1]
        error("A and B are not compatible (size mismatch) ")
    end
    C = zeros(eltype(A), sz_a[1], sz_b[2])

    #=
    for kk = 1:sz_a[2]
        for ii = 1:sz_a[1]
            C[ii, kk] += A[ii, kk] * B[kk, ii]
        end
    end
    =#
    for ii = 1:sz_b[2]
        for kk = 1:sz_a[2]
            C[:, ii] += A[:, kk] * B[kk, ii]
        end
    end

    return C
end


end # dev


module devtest
using ..dev
using BenchmarkTools

function benchmark_matrix_vector_prod_default(A, x)
    b = @benchmark dev.matrix_vector_prod_default($A, $x)

    println("=== matrix_vector_prod_default ===")
    show(
            stdout,
            MIME("text/plain"),
            b )
    println("\n\n")
end


function benchmark_matrix_vector_prod_inner(A, x)
    b = @benchmark dev.matrix_vector_prod_inner($A, $x)

    println("=== matrix_vector_prod_inner ===")
    show(
            stdout,
            MIME("text/plain"),
            b )
    println("\n\n")
end

function benchmark_matrix_vector_prod_outer(A, x)
    b = @benchmark dev.matrix_vector_prod_outer($A, $x)

    println("=== matrix_vector_prod_outer ===")
    show(
            stdout,
            MIME("text/plain"),
            b )
    println("\n\n")
end

function benchmark_matrix_vector_prod_inner_loop(A, x)
    b = @benchmark dev.matrix_vector_prod_inner_loop($A, $x)

    println("=== matrix_vector_prod_inner_loop ===")
    show(
            stdout,
            MIME("text/plain"),
            b )
    println("\n\n")
end

function benchmark_matrix_vector_prod_outer_loop(A, x)
    b = @benchmark dev.matrix_vector_prod_outer_loop($A, $x)

    println("=== matrix_vector_prod_outer_loop ===")
    show(
            stdout,
            MIME("text/plain"),
            b )
    println("\n\n")
end


function benchmark_all()

    # size definitions
    # m = 1000
    # p = 5000

    # m = 10
    # p = 500000

    m = 100000
    p = 50

    # allocate the matrices
    A = rand(m, p)
    x = rand(p)

    benchmark_matrix_vector_prod_default(A, x)
    benchmark_matrix_vector_prod_inner(A, x)
    benchmark_matrix_vector_prod_outer(A, x)
    benchmark_matrix_vector_prod_inner_loop(A, x)
    benchmark_matrix_vector_prod_outer_loop(A, x)

end



end

module devtest_matrix
    using ..dev
    using BenchmarkTools



function benchmark_matrix_mult_inner(A, B)
    b = @benchmark dev.matrix_mult_inner($A, $B)

    println("=== matrix_mult_inner ===")
    show(
            stdout,
            MIME("text/plain"),
            b )
    println("\n\n")
   end

function benchmark_matrix_mult_outer(A, B)
    b = @benchmark dev.matrix_mult_outer($A, $B)

    println("=== matrix_mult_outer ===")
    show(
            stdout,
            MIME("text/plain"),
            b )
    println("\n\n")
end

function benchmark_matrix_mult_default(A, B)
    b = @benchmark dev.matrix_mult_default($A, $B)

    println("=== matrix_mult_default ===")
    show(
            stdout,
            MIME("text/plain"),
            b )
    println("\n\n")
end

function benchmark_matrix_mult_inner_loop(A, B)
    b = @benchmark dev.matrix_mult_inner_loop($A, $B)

    println("=== matrix_mult_inner_loop ===")
    show(
            stdout,
            MIME("text/plain"),
            b )
    println("\n\n")
end

function benchmark_matrix_mult_outer_loop(A, B)
    b = @benchmark dev.matrix_mult_outer_loop($A, $B)

    println("=== matrix_mult_outer_loop ===")
    show(
            stdout,
            MIME("text/plain"),
            b )
    println("\n\n")
end





function benchmark_all()
    # size definitions
    m = 100
    p = 500
    n = 100

    # allocate the matrices
    A = rand(m, p)
    B = rand(p, n)


    benchmark_matrix_mult_inner(A, B)
    benchmark_matrix_mult_outer(A, B)
    benchmark_matrix_mult_default(A, B)
    benchmark_matrix_mult_inner_loop(A, B)
    # benchmark_matrix_mult_outer_loop(A, B)
end


   
    
    # multiply
    #= 
    Ci = dev.matrix_mult_inner(A, B)
    Co = dev.matrix_mult_outer(A, B)
    Cd = A * B;

    println( all( abs.( Ci .- Co ) .<= 1e-10 ) ) =#

end

#= 
module plottest
    
using PyPlot
PyPlot.pygui(true)

x = LinRange(-2, 2, 30) # [1, 2, 3]
y = LinRange(-4, 1, 30) # [10, 20, 30]
z = [i.^2 + j.^2 for i in x, j in y]
z2 = [50, 51, 52]

PyPlot.figure()
# PyPlot.plot3D(x, y, z2)
PyPlot.plot_surface(x, y, z, alpha = 0.5)


end =#


