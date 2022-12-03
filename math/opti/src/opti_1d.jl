
struct BracketingInterval
    x_lo
    x_mid
    x_hi
    f_lo
    f_mid
    f_hi
    iter
    success::Bool
end

function Base.show(io::IO, bracket::BracketingInterval)
    if bracket.success
        print("Successful seach")
    else
        print("Failed seach")
    end
    print(" with $(bracket.iter)-iterations\n")
    println("\tx\tf(x)")
    println( "lo:\t$(bracket.x_lo)\t$(bracket.f_lo)" )
    println( "mid:\t$(bracket.x_mid)\t$(bracket.f_mid)" )
    println( "hi:\t$(bracket.x_hi)\t$(bracket.f_hi)" )
end



function bracket_min(
    fcn,
    x_lo,
    x_hi; 
    step = abs(x_hi-x_lo) * 1e-2, 
    step_factor = 1.61,
    max_iter = 1000)

    f_x_lo = fcn(x_lo)
    f_x_hi = fcn(x_hi)
    
    if f_x_lo < f_x_hi
        # swap the orders
        x_lo, x_hi = x_hi, x_lo
        f_x_lo, f_x_hi = f_x_hi, f_x_lo
        step = -step
    end

    iter = 1
    while iter <= max_iter
        x_next = x_hi + step
        f_next = fcn(x_next)
        if f_next > f_x_hi
            # bracketed interval found
            return BracketingInterval(x_lo, x_hi, x_next, f_x_lo, f_x_hi, f_next, iter, true)
        end
        
        x_lo, x_hi = x_hi, x_next
        f_x_lo, f_x_hi = f_x_hi, f_next


        step *= step_factor
        iter += 1
    end
    println("Failed to find a bracketing interval in the prescribed number of iterations")
    return BracketingInterval(x_lo, x_hi, x_next, f_x_lo, f_x_hi, f_next, iter, false)

end


struct GoldenSectionSearchStatistics
    x_sol
    y_sol
    iter
end

function golden_section_search(fcn, x_lo, x_hi; max_iter = 100, x_tol = 1e-10)

    rho = 0.5 * (sqrt(5)-1)
    if x_lo > x_hi
        # swap
        x_lo, x_hi = x_hi, x_lo
    end
    a = x_lo
    b = x_hi
    
    c_fcn(lo, hi) = rho * lo + (1 - rho) * hi
    d_fcn(lo, hi) = (1 - rho) * lo + rho * hi


    y_a = fcn(a)
    y_b = fcn(b)

    c = c_fcn(a, b)
    d = d_fcn(a, b)

    y_c = fcn(c)
    y_d = fcn(d)

    x_sol = NaN
    y_sol = NaN
    iter = 0
    for outer iter = 1:max_iter

        if y_c < y_d
            # choose (a, c, d)
            a, d, b = a, c, d
            y_a, y_d, y_b = y_a, y_c, y_d
            c = c_fcn(a, b)
            y_c = fcn(c)
        else
            # choose (c, d, b)
            a, c, b = c, d, b
            y_a, y_c, y_b = y_c, y_d, y_b
            d = d_fcn(a, b)
            y_d = fcn(d)
        end

        if abs(b - a) <= x_tol
            (x_sol, y_sol) = (y_c < y_d) ? (c, y_c) : (d, y_d) 
            break
        end

    end
    if iter == max_iter
        (x_sol, y_sol) = (y_c < y_d) ? (c, y_c) : (d, y_d) 
    end

    return GoldenSectionSearchStatistics(x_sol, y_sol, iter)

end