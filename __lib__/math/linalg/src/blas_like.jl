

# include("../utilities.jl")


module linalg

using LinearAlgebra # for triu/l
# using ..util


# =========================================================================== #
# Level 1 Vector Vector
# =========================================================================== #

# scalar + vector
# scalar * vector
# elementwise vector vector
# vector + scalar * vector
# norm2
# dot prod

function blas_update_add!(a, x)
    # x <- a + x
    @inbounds @simd for ii = eachindex(x)
        @fastmath x[ii] += a
    end

    return x
end

function blas_add!(y, a, x)
    # x <- a + x
    @inbounds @simd for ii = eachindex(x)
        @fastmath y[ii] = x[ii] + a
    end

    return x
end

function blas_update_scale!(a, x)
    # x <- a * x
    @inbounds @simd for ii = eachindex(x)
        @fastmath x[ii] *= a
    end

    return x
end

function blas_scale!(y, a, x)
    # y <- a * x
    @inbounds @simd for ii = eachindex(x)
        @fastmath y[ii] = x[ii] * a
    end

    return y
end

function blas_elementwise_scale!(y, x)
    # y <- yi * xi
    @inbounds @simd for ii = eachindex(y)
        @fastmath y[ii] *= x[ii]
    end
end


function blas_update_scale_add!(y, a, x)
    # y <- y + a * x
    @inbounds @simd for ii = eachindex(y) #    
    # Threads.@threads for ii = eachindex(y)
        @fastmath y[ii] += x[ii] * a # @fastmath 
    end

    return x
end


function blas_norm2(x)
    s = zero(Float64);

    @inbounds @simd for ii = eachindex(x)
        @fastmath s += x[ii] * x[ii]
    end

    return sqrt(s)
end

function blas_dot_prod(x, y)
    d = zero(Float64)
    @inbounds @simd for ii = eachindex(x)
        @fastmath d += x[ii] * y[ii]
    end
    return d
end

# =========================================================================== #
# Level 2 - Matrix Vector
# =========================================================================== #

# matrix vector prod
# M + a * v * v' rank one update
# M + a * u * v' rank two update

function blas_matrixview_update_scale_add!(y, a, mat, col)
    # y <- y + a * mat[:, col]
    @inbounds @simd for ii = 1:size(mat,1)  
        @fastmath y[ii] += mat[ii, col] * a
    end

    return y
end

function blas_matrix_vector_prod(mat, x)
    # y <- A * x

    (n_row, n_col) = size(mat);

    y = zeros(n_row)
    @inbounds for cc = 1:n_col
		y = blas_matrixview_update_scale_add!(y, x[cc], mat, cc)
    end

	return y;

end


# =========================================================================== #
# Level 3 - Matrix Matrix
# =========================================================================== #

# matrix matrix prod

function blas_matrix_matrix_prod(A, B)
    # C <- A * B

    (n_row, n_inner) = size(A);
    n_col = size(B,2);
    

    C = zeros(n_row, n_col)
    @inbounds for cc = 1:n_col
        # y = zeros(n_row)
        @inbounds for icc = 1:n_inner
            # C[:, cc] = blas_matrixview_update_scale_add!(C[:, cc], B[icc, cc], A, icc)
            # y = blas_matrixview_update_scale_add!(y, B[icc, cc], A, icc)
            blas_matrixview_update_scale_add!( @view(C[:, cc]) , B[icc, cc], A, icc)
        end
        # C[:,cc] = y
    end

	return C;

end



#=
function saxpy_matrixview(scalar, mat, col, y)
    # y <- y + scalar * mat[:, col]
	# unsafe, dimensions are not checked
	@inbounds @simd for ii = 1:size(y, 1) # 
		@fastmath y[ii] += scalar * mat[ii, col];
        # y[ii] += scalar * mat[ii, col];
    end
    return y
end



function matrix_vector_prod(mat, vec)

	n_row = size(mat, 1);
	n_col = size(mat, 2);

    #=
	res = Vector{eltype(vec)}(undef, n_row);
	@inbounds @simd for rr = 1:n_row
		@fastmath res[rr] = mat[rr, 1] * vec[1];
    end

	# @inbounds Threads.@threads for cc = 1:n_col
    @inbounds for cc = 2:n_col
		res = saxpy_matrixview(vec[cc], mat, cc, res);
    end

    =#

    res = zeros(n_row)
    @inbounds for cc = 1:n_col
		res = saxpy_matrixview(vec[cc], mat, cc, res);
    end

	return res;
end
=#

end # linalg


module ltest 

using ..linalg
using LinearAlgebra
using BenchmarkTools


function test_blas_update_scale_add!()
    n = 10
    y = zeros(n)
    x = collect(1:n)
    a = 10

    n = 100_000_000 # 1_000_000_000 -> doesnt fit into the memory!!!
    y = rand(n)
    x = rand(n)
    a = rand()
 
    # y_theo = x .* a .+ y
    
    @time linalg.blas_update_scale_add!(y, a, x)

    # println( all( (y_theo - y) .<= 1e-16 ) )

end

function benchmark_blas_update_scale_add!(y, a, x)

    b_ = @benchmark linalg.blas_update_scale_add!($y, $a, $x)

    println("=== blas_update_scale_add! ===")
    show(
            stdout,
            MIME("text/plain"),
            b_ )
    println("\n\n")
end

function benchmark_blas_update_scale_add_default(y, a, x)
    # b_ = @benchmark $y = $y .+ $a .* $x;
    b_ = @benchmark $y .+= $a .* $x;


    println("=== blas_update_scale_add_default ===")
    show(
            stdout,
            MIME("text/plain"),
            b_ )
    println("\n\n")
end


function benchmark_blas_update_scale_add_all()
    n = 1_000_000 # for 10_000_000 ~10ms
    y = rand(n)
    x = rand(n)
    a = rand()

    benchmark_blas_update_scale_add!(y, a, x)
    benchmark_blas_update_scale_add_default(y, a, x)
end















function test_matrix_vector_prod()

    mat = reshape( collect(0:14), (5,3) )
    vec = collect(1:3)

    x_theo = mat * vec

    x_mine = linalg.blas_matrix_vector_prod(mat, vec)

    println("norm dx: $(norm(x_theo - x_mine))" )

end


function benchmark_matrix_vector_prod()

    n_row = 1000 # 100000;
	n_col = 100000 # 1000;

    mat = rand(n_row, n_col)
    vec = rand(n_col)

    b_ = @benchmark linalg.blas_matrix_vector_prod($mat, $vec);


    println("=== matrix_vector_prod ===")
    show(
            stdout,
            MIME("text/plain"),
            b_ )
    println("\n\n")

    b_ = @benchmark $mat * $vec;

    println("=== matrix_vector_prod_default ===")
    show(
            stdout,
            MIME("text/plain"),
            b_ )
    println("\n\n")
end



function test_blas_matrix_matrix_prod()

    n_row = 100
    n_inner = 150000
    n_col = 500
    A = rand(n_row, n_inner)
    B = rand(n_inner, n_col)

    @time C = linalg.blas_matrix_matrix_prod(A, B)

    @time C_theo = A * B;

    dC = C_theo - C

    println( all( dC .<= 1e-10 )  )

end

function benchmark_blas_matrix_matrix_prod()

    linalg.blas_matrix_matrix_prod(A, B)

end





#=

function benchmark_linsolve_all()
    N = 6_00
    A = rand(N, N)
    A = diagm( diag(A) ) .+ A
    A = A .+ A'
    b = rand(N)

    benchmark_linsolve_lu(A, b)
    benchmark_linsolve_ldl(A, b)
    benchmark_linsolve_default(A, b)
    
end


function benchmark_linsolve_default(A, b)
    b_ = @benchmark $A \ $b

    println("=== benchmark_linsolve_default ===")
    show(
            stdout,
            MIME("text/plain"),
            b_ )
    println("\n\n")
end
=#


end # ltest

