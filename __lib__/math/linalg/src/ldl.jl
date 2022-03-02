

function ldl_decomp(A)
    # assumption: the matrix A is positive definite (Hermitian)
    # not explicitly checked but assumed: n_row == n_col
    # only the lower left part is used from A

    (n_row, n_col) = size(A)
    L = UnitLowerTriangular( zeros(n_row, n_col) )
    d = zeros(n_col)

    # initial d element
    @inbounds d[1] = A[1,1]
    @inbounds for jj = 1:(n_col-1)

        # determine the next column of L
        @inbounds for ii = (jj+1):n_row
            internal_sum = zero(eltype(A))
            @inbounds @simd for kk = 1:(jj-1)
                @fastmath internal_sum += d[kk] * L[jj,kk] * L[ii,kk]
            end
            @fastmath L[ii, jj] = (A[ii, jj] - internal_sum)/ d[jj]
        end
        

        # determine the next d element
        diag_sum = zero(eltype(A))
        @inbounds @simd for kk = 1:jj
            @fastmath diag_sum += d[kk] * L[jj+1, kk]^2
        end
        @fastmath d[jj+1] = A[jj+1, jj+1] - diag_sum
    end

    return (L, d)
end



function linsolve_ldl(A, b)

    (L, d) = ldl_decomp(A)
    y = triangular_solve_lower_colwise(L, b)
    @fastmath y ./= d
    x = triangular_solve_upper_colwise_transposed(L, y)

    return x
end
