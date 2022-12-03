


module SimpleBlas

function unsafe_scale_add(alpha, x, y)
    z = similar(x)
    
    for ii in eachindex(x)
        z[ii] = alpha * x[ii] + y[ii]
    end

    return z
end

function unsafe_matrix_vector_mult(A, x::AbstractVector{T}) where {T}

    (n_row, n_col) = size(A)
    y = zeros(T, n_row)

    for jj = 1:n_col
        for ii = 1:n_row
            @inbounds y[ii] += A[ii, jj] * x[jj]
        end
    end

    return y
end

# tiled version could be tried
function unsafe_matrix_matrix_mult(A, B::AbstractMatrix{T}) where {T}

    (n_row_a, n_inner) = size(A)
    (n_row_b, n_col_b) = size(B)
    
    C = zeros(T, n_row_a, n_col_b)

    Threads.@threads for kk = 1:n_col_b
        for jj = 1:n_inner
            @simd for ii = 1:n_row_a
                @inbounds C[ii, kk] += A[ii, jj] * B[jj, kk]
            end
        end
    end

    return C
end


end



module btest
using ..SimpleBlas
using LinearAlgebra
using BenchmarkTools


n_row_a = 4000
n_col_a = 500
n_col_b = 300

A = rand(n_row_a, n_col_a)
B = rand(n_col_a, n_col_b)
x = rand(n_col_a)

# yth = A * x
# yb = SimpleBlas.unsafe_matrix_vector_mult(A, x)


# bth = @benchmark yth = A * x
# bb = @benchmark yb = SimpleBlas.unsafe_matrix_vector_mult(A, x)


# Cth = A * B
# Cb = SimpleBlas.unsafe_matrix_matrix_mult(A, B)

bth = @benchmark Cth = A * B
bb = @benchmark Cb = SimpleBlas.unsafe_matrix_matrix_mult(A, B)


# println("The norm of the difference: $(norm(yb - yth))")
# println("The norm of the difference: $(norm(Cb - Cth))")


end



