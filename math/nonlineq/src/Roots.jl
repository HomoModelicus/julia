



module Roots

struct BracketingOptions
    init_step_size::Float64
    growth_factor::Float64
    max_iter::Int
    

    function BracketingOptions(;
        init_step_size = 1e-2,
        growth_factor = 2.0,
        max_iter = 50)
        
        return new(
            init_step_size,
            growth_factor,
            max_iter
        )
    end
end

function bracket(fcn, x0, options = BracketingOptions())

    x_a = x0
    x_b = x0 + options.init_step_size

    y_a = fcn(x_a)
    y_b = fcn(x_b)

    for iter = 1:options.max_iter

        if sign(y_a) != sign(y_b)
            break
        end

        dx = abs(x_b - x_a)
        if abs(y_a) <= abs(y_b)
            x_a -= options.growth_factor * dx
            y_a  = fcn(x_a)
        else
            x_b += options.growth_factor * dx
            y_b  = fcn(x_b)
        end

    end

    return (x_a, x_b)
end


function __midpoint(a, b)
    (x, y) = minmax(a, b)
    return (y - x) / 2 + x
end

@enum StoppingCriterionKind begin
    sc_error_t
    sc_max_iter_t
    sc_dx_abs_tol_t
    sc_f_abs_tol_t
end

struct NonlinearStatistics
    y::Float64
    iter::Int
    stopping_crit::StoppingCriterionKind
end

struct Rootsolving1dOptions
    x_lower::Float64
    x_upper::Float64
    
    max_iter::Int
    dx_abs_tol::Float64
    f_abs_tol::Float64

    function Rootsolving1dOptions(
        x_lower, x_upper; 
        max_iter   = 100,
        dx_abs_tol = 1e-16,
        f_abs_tol  = 1e-10)

        return new(
            x_lower,
            x_upper,
            max_iter,
            dx_abs_tol,
            f_abs_tol)
    end
end

function __initialization(fcn, options)

    (x_a, x_b) = minmax(options.x_lower, options.x_upper)
    y_a = fcn(x_a)
    y_b = fcn(x_b)

    is_done = false

    x_sol = x_a
    stat  = NonlinearStatistics(
        y_a,
        0,
        sc_f_abs_tol_t::StoppingCriterionKind)

    if abs(y_a) <= options.f_abs_tol
        x_sol = x_a
        stat  = NonlinearStatistics(
            y_a,
            0,
            sc_f_abs_tol_t::StoppingCriterionKind)
        is_done = true
    end

    if abs(y_b) <= options.f_abs_tol
        x_sol = x_b
        stat  = NonlinearStatistics(
                y_b,
                0,
                sc_f_abs_tol_t::StoppingCriterionKind)
        is_done = true
    end

    if sign(y_a) == sign(y_b)
        error("The supplied bracket doesnt have different signs")
    end

    return (is_done, x_a, x_b, y_a, y_b, x_sol, stat)

end

function __f_tol_check(x_m, y_m, iter, options)
    is_done = false

    x_sol = x_m
    stat  = NonlinearStatistics(
        y_m,
        iter,
        sc_f_abs_tol_t::StoppingCriterionKind)

    if abs(y_m) <= options.f_abs_tol
        # x_sol = x_m
        # stat  = NonlinearStatistics(
        #     y_m,
        #     iter,
        #     sc_f_abs_tol_t::StoppingCriterionKind)
        is_done = true
    end
    
    return (is_done, x_sol, stat)
end

function __dx_tol_check(x_a, x_b, x_m, y_m, iter, options)
    is_done = false

    x_sol = x_m
    stat  = NonlinearStatistics(
        y_m,
        iter,
        sc_dx_abs_tol_t::StoppingCriterionKind)

    if abs(x_b - x_a) <= options.dx_abs_tol
        # x_sol = x_m
        # stat  = NonlinearStatistics(
        #     y_m,
        #     iter,
        #     sc_dx_abs_tol_t::StoppingCriterionKind)
        is_done = true
    end

    return (is_done, x_sol, stat)
end

function __postloop(iter, max_iter, x_m, y_m)
    if iter == max_iter # options.max_iter
        x_sol = x_m
        stat  = NonlinearStatistics(
                y_m,
                iter,
                sc_max_iter_t::StoppingCriterionKind)
    end

    return (x_sol, stat)
end

function bisection(fcn, options::Rootsolving1dOptions)

    (is_done, x_a, x_b, y_a, y_b, x_sol, stat) = __initialization(fcn, options)
    if is_done
        return (x_sol, stat)
    end

    x_m = zero(typeof(x_a))
    y_m = zero(typeof(y_a))

    iter = 0
    for outer iter = 1:options.max_iter
        
        x_m = __midpoint(x_a, x_b)
        y_m = fcn(x_m)

        if abs(y_m) <= options.f_abs_tol
            x_sol = x_m
            stat  = NonlinearStatistics(
                y_m,
                iter,
                sc_f_abs_tol_t::StoppingCriterionKind)
            return (x_sol, stat)
        end

        if sign(y_m) == sign(y_a)
            # x_m and x_b brackets
            x_a = x_m
            y_a = y_m
        else
            # x_a and x_m brackets
            x_b = x_m
            y_b = y_m
        end

        if abs(x_b - x_a) <= options.dx_abs_tol
            x_sol = x_m
            stat  = NonlinearStatistics(
                y_m,
                iter,
                sc_dx_abs_tol_t::StoppingCriterionKind)
            return (x_sol, stat)
        end

    end

    (x_sol, stat) = __postloop(iter, options.max_iter, x_m, y_m)

    return (x_sol, stat)
end


function __linear_solution(x_a, x_b, y_a, y_b)
    x_m = (y_b * x_a - y_a * x_b) / (y_b - y_a)
    return x_m
end

function regulafalsi(fcn, options::Rootsolving1dOptions)

    (is_done, x_a, x_b, y_a, y_b, x_sol, stat) = __initialization(fcn, options)
    if is_done
        return (x_sol, stat)
    end

    x_m = zero(typeof(x_a))
    y_m = zero(typeof(y_a))

    iter = 0
    for outer iter = 1:options.max_iter
        
        x_m = __linear_solution(x_a, x_b, y_a, y_b)
        y_m = fcn(x_m)

        # to be corrected
        (is_done, x_sol, stat) = __f_tol_check(x_m, y_m, iter, options)
        if is_done
            return (x_sol, stat)
        end

        if sign(y_m) == sign(y_a)
            # x_m and x_b brackets
            x_a = x_m
            y_a = y_m
        else
            # x_a and x_m brackets
            x_b = x_m
            y_b = y_m
        end

        (is_done, x_sol, stat) = __dx_tol_check(x_a, x_b, x_m, y_m, iter, options)
        if is_done
            return (x_sol, stat)
        end
    end

    (x_sol, stat) = __postloop(iter, options.max_iter, x_m, y_m)

    return (x_sol, stat)
end







@enum PrevCaseKind begin
    pc_undefined_t
    pc_left_t
    pc_right_t
end


function regulafalsi_ilinois(fcn, options::Rootsolving1dOptions)

    (is_done, x_a, x_b, y_a, y_b, x_sol, stat) = __initialization(fcn, options)
    if is_done
        return (x_sol, stat)
    end

    x_m = zero(typeof(x_a))
    y_m = zero(typeof(y_a))

    prev  = pc_undefined_t::PrevCaseKind
    pprev = pc_undefined_t::PrevCaseKind

    iter = 0
    for outer iter = 1:options.max_iter
        
        factor_a = 1.0
        factor_b = 1.0

        if pprev == prev && prev == pc_left_t::PrevCaseKind
            factor_a = 0.5
            factor_b = 1.0
        end

        if pprev == prev && prev == pc_right_t::PrevCaseKind
            factor_a = 1.0
            factor_b = 0.5
        end

        x_m = __linear_solution(x_a, x_b, factor_a * y_a, factor_b * y_b)
        y_m = fcn(x_m)

        if iter > 2
            pprev = prev
        end

        (is_done, x_sol, stat) = __f_tol_check(x_m, y_m, iter, options)
        if is_done
            return (x_sol, stat)
        end

        if sign(y_m) == sign(y_a)
            # x_m and x_b brackets
            x_a = x_m
            y_a = y_m
            prev = pc_right_t::PrevCaseKind
        else
            # x_a and x_m brackets
            x_b = x_m
            y_b = y_m
            prev = pc_left_t::PrevCaseKind
        end

        (is_done, x_sol, stat) = __dx_tol_check(x_a, x_b, x_m, y_m, iter, options)
        if is_done
            return (x_sol, stat)
        end
    end

    (x_sol, stat) = __postloop(iter, options.max_iter, x_m, y_m)

    return (x_sol, stat)
end



function ridders(fcn, options::Rootsolving1dOptions)

    (is_done, x_a, x_b, y_a, y_b, x_sol, stat) = __initialization(fcn, options)
    if is_done
        return (x_sol, stat)
    end


    iter = 0
    for outer iter = 1:options.max_iter

        x_m = __midpoint(x_a, x_b)
        y_m = fcn(x_m)
        d   = 0.5 * abs(x_b - x_a)

        alpha  = y_m / y_a
        beta   = y_b / y_a
        x_next = x_m + d * alpha / sqrt(alpha^2 - beta)
        y_next = fcn(x_next)


        (is_done, x_sol, stat) = __f_tol_check(x_next, y_next, iter, options)
        if is_done
            return (x_sol, stat)
        end

        (is_done, x_sol, stat) = __f_tol_check(x_m, y_m, iter, options)
        if is_done
            return (x_sol, stat)
        end

        has_new_bracket = false
        if x_a <= x_next <= x_m
            
            if sign(y_next) != sign(y_m)
                # x_m and x_next brackets
                x_a, y_a = x_next, y_next
                x_b, y_b = x_m, y_m
            elseif sign(y_a) != sign(y_next)
                # x_a and x_next brackets
                x_b, y_b = x_next, y_next
            end

        elseif x_m <= x_next <= x_b

            if sign(y_next) != sign(y_m)
                # x_m and x_next brackets
                x_a, y_a = x_next, y_next
                x_b, y_b = x_m, y_m
            elseif sign(y_next) != sign(y_b)
                # x_next and x_b brackets
                x_a, y_a = x_next, y_next
            end

        end

        if !has_new_bracket && sign(y_m) == sign(y_a)
            # x_m and x_b brackets
            x_a = x_m
            y_a = y_m
            prev = pc_right_t::PrevCaseKind
        else
            # x_a and x_m brackets
            x_b = x_m
            y_b = y_m
            prev = pc_left_t::PrevCaseKind
        end
        
        (is_done, x_sol, stat) = __dx_tol_check(x_a, x_b, x_m, y_m, iter, options)
        if is_done
            return (x_sol, stat)
        end
    end

    (x_sol, stat) = __postloop(iter, options.max_iter, x_m, y_m)


    return (x_sol, stat)
end




end # module




