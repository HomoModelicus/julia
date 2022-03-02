

function triangular_solve_upper_rowwise(U, b)

    n_row = size(U, 1)
    x = zeros(eltype(b), n_row)

    @inbounds for ii = n_row:-1:1
        internal_sum = zero(eltype(b))
        @inbounds @simd for jj = n_row:-1:(ii+1)
            @fastmath internal_sum += U[ii, jj] * x[jj]
        end
        @fastmath x[ii] = (b[ii] - internal_sum) / U[ii, ii]
    end

    return x
end

function triangular_solve_upper_colwise(U, b)
# function triangular_solve_upper_colwise(U{T}, b::Array{T}) where {T}

    n_col = size(U, 2)
    x = copy(b)

    @inbounds for jj = n_col:-1:1
        @fastmath x[jj] = x[jj] / U[jj, jj]
        # @view( x[1:(jj-1)] ) = @view( x[1:(jj-1)] ) - @view( U[1:(jj-1), jj] ) .* x[jj]
        @inbounds @simd for ii = 1:(jj-1)
            @fastmath x[ii] -= U[ii, jj] .* x[jj]
        end
    end

    return x
end

function triangular_solve_upper_colwise_transposed(L, b)
    # the input matrix L is a lower triangular matrix
    # but it solved as it was U = L', L' * x = b

    #=
    n_row = size(L, 1)
    x = zeros(eltype(b), n_row)

    @inbounds for ii = n_row:-1:1
        internal_sum = zero(eltype(b))
        @inbounds @simd for jj = n_row:-1:(ii+1)
            @fastmath internal_sum += L[jj, ii] * x[jj]
        end
        @inbounds @fastmath x[ii] = (b[ii] - internal_sum) / L[ii, ii]
    end

    return x
    =#
    return triangular_solve_upper_colwise(L', b)
end

function triangular_solve_lower_rowwise(L, b)
# function triangular_solve_lower_rowwise(L{T}, b::Array{T}) where {T}

    n_row = size(L, 1)
    x = zeros(eltype(b), n_row)
    
    for ii = 1:n_row
        internal_sum = zero(eltype(b))
        @inbounds @simd for jj = 1:(ii-1)
            @fastmath internal_sum += L[ii, jj] * x[jj]
        end
        @fastmath x[ii] = (b[ii] - internal_sum) / L[ii, ii];
    end
    
    return x
end


function triangular_solve_lower_colwise(L, b)
# function triangular_solve_lower_colwise(L{T}, b::Array{T}) where {T}

    (n_row, n_col) = size(L)
    x = copy(b)

    # Single threaded
    @inbounds for jj = 1:n_col
        @fastmath x[jj] = x[jj] / L[jj, jj]
        @inbounds @simd for rr = (jj+1):n_row
            @fastmath x[rr] -= L[rr, jj] .* x[jj]
        end
    end

    return x
end


function triangular_solve_lower_sparse(spmat::SparseMatrixCSC, b)
    # forward substitution

    n_row = spmat.n_row
    n_col = spmat.n_col
    
    x = copy(b)
    L11 = spmat[1] # 1,1 location
    x[1] = x[1] / L11

    L::Int = length(spmat)
    idx_end::Int = 0

    for cc = 1:spmat.n_col
        
        idx_start = spmat.col_begins_index[cc]
        if idx_start == 0
            error("Singular matrix cannot be solved")
        end

        # find next nonzero index
        idx_end = find_next_nonempty_col_begin(spmat, cc)

        for rr = idx_start:(idx_end-1)
            a_ij = spmat.data[rr]
            ii = spmat.row_index[rr]
            x[ii] /= a_ij
        end

    end

    return x
end







