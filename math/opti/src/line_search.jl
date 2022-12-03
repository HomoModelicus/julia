
struct LineSearchOptions
    sufficient_decrease::Float64
    curvature::Float64
    max_iter::Int
end

function LineSearchOptions(; sufficient_decrease = 1e-4, curvature = 0.1, max_iter = 100)
    LineSearchOptions(sufficient_decrease, curvature, max_iter)
end


function line_search(
    fcn,
    x0,
    step_direction,
    f0 = fcn(x0),
    search_options::LineSearchOptions = LineSearchOptions();
    directional_diff_fcn = numder.directional_diff_fw)
    # suff_decrease = 1e-4, curvature = 0.1, max_iter = 100)

    # rename for ease of refactoring
    suff_decrease = search_options.sufficient_decrease
    curvature     = search_options.curvature
    max_iter      = search_options.max_iter

    # strong wolfe condition
    step_size_prev = zero(eltype(x0))
    step_size      = one(eltype(x0))
    step_size_lo   = step_size_prev
    step_size_hi   = step_size_prev
    f_prev         = NaN
    dphi0          = directional_diff_fcn(fcn, x0, step_direction)
    # dphi0          = numder.directional_diff_fw(fcn, x0, step_direction)

    # bracket phase
    for iter = 1:max_iter

        f1 = fcn(x0 + step_direction * step_size)
        if f1 > f0 + suff_decrease * step_size * dphi0 || (iter > 1 && f1 >= f_prev)
            step_size_lo, step_size_hi = step_size_prev, step_size
            break
        end

        # dphi = numder.directional_diff_fw(fcn, x0 + step_direction * step_size, step_direction)
        x0_prime = x0 + step_direction * step_size
        dphi     = directional_diff_fcn(fcn, x0_prime, step_direction)
        if abs(dphi) <= abs(dphi0) * curvature
            return step_size
        elseif dphi >= 0
            step_size_lo, step_size_hi = step_size, step_size_prev
            break
        end

        f_prev = f1
        step_size_prev, step_size = step_size, step_size * 2
    end

    # zoom phase
    f_lo = fcn(x0 + step_size_lo * step_direction)
    for iter = 1:max_iter
        step_size = 0.5 * (step_size_lo + step_size_hi)
        f1 = fcn(x0 + step_size * step_direction)
        if f1 > f0 + suff_decrease * step_size * dphi0 || f1 >= f_lo
            step_size_hi = step_size
        else
            # dphi = numder.directional_diff_fw(fcn, x0 + step_direction * step_size, step_direction)
            x0_prime = x0 + step_direction * step_size
            dphi     = directional_diff_fcn(fcn, x0_prime, step_direction)
            if abs(dphi) <= abs(dphi0) * curvature
                return step_size
            elseif dphi * (step_size_hi - step_size_lo) >= 0
                step_size_hi = step_size_lo
            end
            step_size_lo = step_size
        end

    end

    return step_size
end



#=
function armijo_backtracking(fcn, x0, direction, f0 = fcn(x0), alpha_0 = 1, step_factor = 0.5, max_iteration = 20, beta = 1e-4)
    # sufficient decrease condition shall be satisfied
    phi_0 = f0
    dphi_dalpha_0 = NumDiff.directional_diff_fw(fcn, x0, direction)

    alpha = alpha_0
    for iter = 1:max_iteration
        phi_alpha = fcn( x0 + direction .* alpha)
        if phi_alpha <= phi_0 + beta * alpha * phi_alpha
            break
        end
        alpha = alpha * step_factor
    end
end
=#

