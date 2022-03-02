
function linsolve_lu(A::Matrix{T}, b::Vector{T}) where {T}

    (n_row, n_col) = size(A)
    if n_row != n_col
        error("This function only works with the same dimensions")
    end
    x = zeros(eltype(b), n_row)

    (L, U, p) = lu_decomp_partialpivot(A)
    b_ = b[p]
    y_ = triangular_solve_lower_colwise(L, b_)
    x = triangular_solve_upper_colwise(U, y_)
    # y_ = triangular_solve_lower_rowwise(L, b_)
    # x = triangular_solve_upper_rowwise(U, y_)

    return x
end

function lu_decomp_partialpivot(A::Matrix{T}) where {T}

    (n_row, n_col) = size(A)

    M = copy(A)
    p = collect(1:n_row)

    for jj = 1:(n_col-1)

        @inbounds (max_elem, maxidx) = util.maximum( abs, @view( M[jj:n_row, jj] ) )
        if maxidx > 1
            maxidx = maxidx + jj - 1
            # swap the row
            @inbounds p[jj], p[maxidx] = p[maxidx], p[jj]
            @simd for cc = 1:n_col
                @inbounds M[jj, cc], M[maxidx, cc] = M[maxidx, cc], M[jj, cc]
            end

        end

        # calculate the L
        @fastmath @simd for rr = (jj+1):n_row
            M[rr, jj] /= M[jj, jj]
        end

        for cc = (jj+1):n_col
            @inbounds m_ = M[jj, cc]
            @simd for rr = (jj+1):n_row
                @fastmath @inbounds M[rr, cc] -= M[rr, jj] .* m_
            end
        end

    end

    L = UnitLowerTriangular(M);
    U = UpperTriangular(M);
    return (L, U, p)
end