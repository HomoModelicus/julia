



module Linalg
using .Threads

function absmax_in_col(A::AbstractMatrix{T}, col; start_row = 1) where {T}

    absmax = typemin(T)
    index  = 0
    n_dim  = size(A, 1)

    for ii = start_row:n_dim
        @inbounds if abs(A[ii, col]) > absmax
            @inbounds absmax = abs(A[ii, col])
            index  = ii
        end 
    end

    return (absmax, index)
end

function swap_elements!(vec, row1, row2)
    @inbounds tmp       = vec[row1]
    @inbounds vec[row1] = vec[row2]
    @inbounds vec[row2] = tmp
    return nothing
end

function swap_rows_from!(U, row1, row2; start_col = 1)
    for jj = start_col:size(U, 2)
        @inbounds tmp         = U[row1, jj]
        @inbounds U[row1, jj] = U[row2, jj]
        @inbounds U[row2, jj] = tmp
    end
    return nothing
end

function swap_rows_to!(L, row1, row2; end_col = size(L, 2))
    for jj = 1:end_col
        @inbounds tmp         = L[row1, jj]
        @inbounds L[row1, jj] = L[row2, jj]
        @inbounds L[row2, jj] = tmp
    end
    return nothing
end

function swap_rows!(L, row1, row2; end_col = size(L, 2))
    for jj = 1:end_col
        @inbounds tmp         = L[row1, jj]
        @inbounds L[row1, jj] = L[row2, jj]
        @inbounds L[row2, jj] = tmp
    end
    return nothing
end


struct LUDecomposition{T}
    M::Matrix{T}
    p::Vector{Int}

    function LUDecomposition{T}(A::AbstractMatrix{T}) where {T}
        M     = copy(A)
        n_dim = size(A, 1)
        p     = collect(1:n_dim)
        return new(M, p)
    end
end

function lu(A::AbstractMatrix{T}) where {T}

    (n_row, n_col) = size(A)

    if n_row != n_col
        error("use it only for square matrices")
    end

    LUp = LUDecomposition{T}(A)

    for row = 1:(n_row-1)

        col = row
        (absmax, row_index) = absmax_in_col(LUp.M, col; start_row = row)
        
        # swap rows
        # these could be done basically synchronosly, or?
        swap_rows!(     LUp.M, row, row_index)
        swap_elements!( LUp.p, row, row_index)
        

        # update U
        # Threads.@spawn
        # Threads.@threads 
        for jj = (col+1):n_col
            for ii = (row+1):n_row
                @inbounds LUp.M[ii, jj] -= LUp.M[row, jj] * LUp.M[ii, col] / LUp.M[row, col]
            end
        end

        # update L
        for ii = (row+1):n_row
            @inbounds LUp.M[ii, col] = LUp.M[ii, col] / LUp.M[row, col]
        end

    end

    # return (L, U, permvec)
    return LUp
end

function fw_substitution(L, b)
    x = copy(b)
    fw_substitution!(L, b, x)
    return x
end

# x is assumed to be b vector at the first stage
# L[row, row] is 1, must be, even if implicitly
function fw_substitution!(L, b, x)
    n_dim = length(b)
    
    for row = 1:n_dim
        for ii = (row+1):n_dim
            x[ii] -= L[ii, row] * x[row]
        end
    end

    return x
end

function bw_substitution(R, b)
    x = copy(b)
    bw_substitution!(R, b, x)
    return x
end

# x is assumed to be b vector at the first stage
function bw_substitution!(R, b, x)
    n_dim = length(b)
    
    for row = n_dim:-1:1
        x[row] = x[row] / R[row, row]

        for ii = (row-1):-1:1
            x[ii] -= R[ii, row] * x[row]
        end
    end

    return x
end

function lu_solve!(LUp::LUDecomposition, b)
    x = copy(b)
    x = x[LUp.p]
    fw_substitution!(LUp.M, b, x)
    bw_substitution!(LUp.M, x, x)
    return x
end



# uses householder transformation
struct QRDecomposition{T}
    V::Matrix{T}
    R::Matrix{T}

    function QRDecomposition{T}(A::AbstractMatrix{T}) where {T}
        (n_row, n_col) = size(A)
        R              = copy(A)
        V              = zeros(T, n_row, n_col)
        return new(V, R)
    end
end

function to_q(QR::QRDecomposition)
    (n_row, n_col) = size(QR.V)
    T     = eltype(QR.V)
    
    _1    = zeros(T, n_row, n_row)
    for ii = 1:n_row
        _1[ii, ii] = one(T)
    end

    Q = copy(_1)
    for col = 1:n_col
        v       = QR.V[:, col]
        dot_vv  = 0.5 * (v' * v)
        dyad_vv = v * v'
        Qtmp    = _1 - dyad_vv ./ dot_vv
        Q       = Qtmp * Q # Q * Qtmp # 
    end

    Q = collect(Q')
    return Q
end

function __sign(x::T) where {T}
    return x >= zero(T) ? one(T) : -one(T)
end

function __norm(matrix, col)
    n = zero(eltype(matrix))
    for ii in col:size(matrix, 1)
        n += matrix[ii, col]^2
    end
    n = sqrt(n)
    return n
end

function qr(A::AbstractMatrix{T}) where {T}
    # householder trafo
    (n_row, n_col) = size(A)
    QR = QRDecomposition{T}(A)

    for col = 1:n_col
        y1     = QR.R[col, col]
        sa     = __sign(y1)
        na     = __norm(QR.R, col)
        alpha  = sa * na
        dot_vv = na^2 + alpha^2 + 2 * alpha * y1

        # v = a + alpha * e1
        for ii = col:n_row
            QR.V[ii, col] = QR.R[ii, col] / sqrt(dot_vv)
            QR.R[ii, col] = zero(T)
        end
        QR.R[col, col]  = -alpha
        QR.V[col, col] += alpha / sqrt(dot_vv)

        for jj = (col+1):n_col
            
            dot_va = zero(T)
            for kk = col:n_row
                dot_va += QR.V[kk, col] * QR.R[kk, jj]
            end

            for kk = col:n_row
                # QR.R[kk, jj] += -2 * dot_va / dot_vv * QR.V[kk, col]
                QR.R[kk, jj] += -2 * dot_va * QR.V[kk, col]
            end

        end

    end

    return QR
end

# res is assumed to be b at first
function q_mult_vector!(QR::QRDecomposition, res)
    # res <- b assumed
    # (1 - 2 * v dyadic v / v*v) * b
    # b - v * 2 * (v dot b) / (v dot v)
    # res += v * scale

    (n_row, n_col) = size(QR.V)
    T = eltype(QR.V)
    for col = n_col:-1:1
        dot_vb = zero(T)
        for ii = col:n_row
            dot_vb += QR.V[ii, col] * res[ii]
        end

        for ii = col:n_row
            res[ii] -= 2 * dot_vb * QR.V[ii, col]
        end
    end
    
    return res
end

# res is assumed to be b at first
function q_transpose_mult_vector!(QR::QRDecomposition, res)
    # res <- b assumed
    # (1 - 2 * v dyadic v / v*v) * b
    # b - v * 2 * (v dot b) / (v dot v)
    # res += v * scale

    (n_row, n_col) = size(QR.V)
    T = eltype(QR.V)
    for col = 1:n_col

        dot_vb = zero(T)
        for ii = col:n_row
            dot_vb += QR.V[ii, col] * res[ii]
        end

        for ii = col:n_row
            res[ii] -= 2 * dot_vb * QR.V[ii, col]
        end
    end
    
    return res
end

function qr_solve!(QR::QRDecomposition, b, x; tol = eps(1.0))

    (n_row, n_col) = size(QR.V)

    x = copy(b)
    q_transpose_mult_vector!(QR, x) # rhs

    # find last R index
    n_dim = 0
    for outer n_dim = n_col:-1:1
        if abs(QR.R[n_dim, n_col]) > tol
            break
        end
    end

    Rv = view(QR.R, 1:n_dim, 1:n_dim)
    bw_substitution!(Rv, x, x)

    return x
end



struct CholeskyDecomposition{T}
    L::Matrix{T} # diagonal entries are the d diagonal matrix elements, L * D * L'
    
    function CholeskyDecomposition{T}(A::AbstractMatrix{T}) where {T}
        return new(copy(A))
    end
end

function cholesky(A::AbstractMatrix{T}) where {T}
    (n_row, n_col) = size(A)
    Ch = CholeskyDecomposition{T}(A)

    for col = 1:n_col
        # d[col] = L[col, col] # implicitly implied

        # get the first column
        for ii = (col+1):n_row
            @inbounds Ch.L[ii, col] /= Ch.L[col, col]
        end

        # update the remaining matrix
        # Threads.@threads 
        for jj = (col+1):n_col
            @inbounds factor = -Ch.L[col, col] * Ch.L[jj, col]

            @simd for ii = jj:n_row
                @inbounds Ch.L[ii, jj] += factor * Ch.L[ii, col]
            end
        end
    end

    return Ch
end







function tridiagonal_solve(left_diag, main_diag, right_diag, rhs)
    n_row = length(main_diag)
    n = length(left_diag)
    if n+1 != n_row
        error("Invalid dimension for left diag")
    end
    if length(right_diag) != n
        error("Invalid dimension for right diag")
    end
    
    x = zeros(n_row)

    a = copy(main_diag)
    r = copy(rhs)

    # fw elimination
    for ii = 2:n_row
        @inboundsa [ii] -= left_diag[ii-1] * right_diag[ii-1] / a[ii-1]
        @inbounds r[ii] -= left_diag[ii-1] * r[ii-1] / a[ii-1]
    end

    # bw elimination
    x[n_row] = r[n_row] / a[n_row]
    for ii = (n_row-1):-1:1
        @inbounds x[ii] = (r[ii] - x[ii+1] * right_diag[ii]) / a[ii]
    end

    return x
end


end # module



module ltest
using ..Linalg
using LinearAlgebra
using BenchmarkTools

#=

n_dim = 3
A = zeros(Float64, n_dim, n_dim)

A[1,1] = 1
A[1,2] = 2
A[1,3] = 3

A[2,1] = 2
A[2,2] = 2
A[2,3] = 4

A[3,1] = 3
A[3,2] = 2
A[3,3] = 1


# (L, U, p) = Linalg.lu(A)
=#

# n_dim = 1000 # 1800 # 500
# B = rand(n_dim, n_dim)

# b = rand(n_dim)

# @time F       = lu(B)
# bthperm = b[F.p]
# @time xth     = F.U \ (F.L \ bthperm)

# println("==========")

# @time LUp = Linalg.lu(B)
# @time x   = Linalg.lu_solve!(LUp, b)


# @time (L, U, p) = Linalg.lu(B)

# b = @benchmark (L, U, p) = Linalg.lu(B)
# bt = @benchmark F = lu(B);


# F = lu(B);
# bthperm = b[F.p]
# xth = F.U \ (F.L \ bthperm)
# xth2 = B \ b

# (L, U, p) = Linalg.lu(B)

# bperm = b[p]
# y = Linalg.fw_substitution(L, bperm)
# x = Linalg.bw_substitution(U, y)










n_dim = 3
A = zeros(Float64, n_dim, n_dim)

A[1,1] = 1
A[1,2] = 2
A[1,3] = 3

A[2,1] = 2
A[2,2] = 2
A[2,3] = 4

A[3,1] = 3
A[3,2] = 2
A[3,3] = 1




# QR = Linalg.qr(A)




# println("The norm of the difference: $(norm(x - xth))")



# C = A' * A
# ch = Linalg.cholesky(C)

n_dim = 1500 # 1800 # 500
B = rand(n_dim, n_dim)
C = B' * B
b = @benchmark ch = Linalg.cholesky(C)

# Lt = UnitLowerTriangular(ch.L)
# D = Diagonal(ch.L)

# Cr = Lt * D * Lt'

# dC = Cr - C
# n = norm(dC)
# println("The norm of the difference: $(n)")


bth = @benchmark cholesky(C)

end





