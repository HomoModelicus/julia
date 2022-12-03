


function linsolve_tridiagonal(left_diag, main_diag, right_diag, rhs)
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
    @inbounds for ii = 2:n_row
        a[ii] -= left_diag[ii-1] * right_diag[ii-1] / a[ii-1]
        r[ii] -= left_diag[ii-1] * r[ii-1] / a[ii-1]
    end

    # bw elimination
    x[n_row] = r[n_row] / a[n_row]
    @inbounds for ii = (n_row-1):-1:1
        x[ii] = (r[ii] - x[ii+1] * right_diag[ii]) / a[ii]
    end

    return x
end