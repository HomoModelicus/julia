




#=


include("../../common/numder/src/numder_module.jl")

module nonlineq1d
using ..numder

struct NonlineqTolerance
    max_iter::Int
    abs_step_size_tol::Float64
    rel_step_size_tol::Float64
end

function NonlineqTolerance(;
    max_iter = 10_000,
    abs_step_size_tol = 1e-15,
    rel_step_size_tol = 1e-10)
    
    return NonlineqTolerance(
        max_iter,
        abs_step_size_tol,
        rel_step_size_tol)
end

function __check_bracketing(fcn, x0, x1)
    f0    = fcn(x0)
    f1    = fcn(x1)
    if f0 * f1 > 0
        error("Initial bracket doesnt bracket a root with opposite sings")
    end

    return (f0, f1)
end

function __check_step_size(x0, x1, options)

    break_flag = false

    abs_tol = options.abs_step_size_tol
    rel_tol = options.rel_step_size_tol * max(abs(x0), abs(x1))

    dx = x1 - x0
    if abs(dx) <= max(abs_tol, rel_tol)
        break_flag = true
    end

    return break_flag
end


struct SolverStatistics
    iter::Int
end

function bisection(fcn, x0, x1; options = NonlineqTolerance() )

    
    (f0, f1) = __check_bracketing(fcn, x0, x1)

    x_sol = NaN64
    iter = 0
    for outer iter = 1:options.max_iter

        x_mid = 0.5 * x0 + 0.5 * x1

        break_flag = __check_step_size(x0, x1, options)
        if break_flag
            x_sol = x_mid
            break
        end

        f_mid = fcn(x_mid)

        if f_mid * f0 < 0.0
            x0, x1 = x0, x_mid
            f0, f1 = f0, f_mid
        elseif f_mid * f1 < 0.0
            x0, x1 = x_mid, x1
            f0, f1 = f_mid, f1
        else
            # exactly got to 0
            x_sol = x_mid
            break
        end

    end

    stat = SolverStatistics(iter)
    return (x_sol, stat)
end

function regula_falsi(fcn, x0, x1; options = NonlineqTolerance())

    (f0, f1) = __check_bracketing(fcn, x0, x1)

    x_sol = NaN64

    iter = 0
    for outer iter = 1:options.max_iter

        break_flag = __check_step_size(x0, x1, options)
        if break_flag
            x_sol = 0.5 * x0 + 0.5 * x1
            break
        end

        x_lin = x0 - f0 * (x1 - x0) / (f1 - f0)
        f_lin = fcn(x_lin)

        x_mid = 0.5 * x0 + 0.5 * x1
        f_mid = fcn(x_mid)

        if f_lin * f_mid < 0.0
            # take this interval
            x0, x1 = x_lin, x_mid
            f0, f1 = f_lin, f_mid

            continue
        end

        if f_mid * f0 < 0.0

            if x0 <= x_lin <= x_mid
                # f_lin has the same sign as f_mid
                x0, x1 = x0, x_lin
                f0, f1 = f0, f_lin
            else # not in the interval, no improvement achievable
                x0, x1 = x0, x_mid
                f0, f1 = f0, f_mid
            end

        elseif f_mid * f1 < 0.0
            x0, x1 = x_mid, x1
            f0, f1 = f_mid, f1

            if x_mid <= x_lin <= x1
                # f_lin has the same sign as f_mid
                x0, x1 = x_lin, x1
                f0, f1 = f_lin, f1
            else # not in the interval, no improvement achievable
                x0, x1 = x_mid, x1
                f0, f1 = f_mid, f1
            end

        else
            # exactly got to 0
            x_sol = x_mid
            break
        end

    end # for

    stat = SolverStatistics(iter)
    return (x_sol, stat)
end


function regula_falsi_ilinois(fcn, x0, x1; options = NonlineqTolerance())

    (f0, f1) = __check_bracketing(fcn, x0, x1)
    x_prev   = NaN64
    x_pprev  = NaN64
    x_sol    = NaN64

    iter = 0
    for outer iter = 1:options.max_iter

        break_flag = __check_step_size(x0, x1, options)
        if break_flag
            x_sol = 0.5 * x0 + 0.5 * x1
            break
        end

        if x_prev == x_pprev
            if x0 == x_prev
                y0, y1 = f0 * 0.5, f1
            else
                y0, y1 = f0, f1 * 0.5
            end
        else
            y0, y1 = f0, f1
        end

        x_lin = x0 - y0 * (x1 - x0) / (y1 - y0)
        f_lin = fcn(x_lin)

        if f_lin * f0 < 0.0
            x0, x1  = x0, x_lin
            f0, f1  = f0, f_lin
            x_pprev = iter >= 2 ? x_prev : NaN64
            x_prev  = x0
        elseif f_lin * f1 < 0.0
            x0, x1  = x_lin, x1
            f0, f1  = f_lin, f1
            x_pprev = iter >= 2 ? x_prev : NaN64
            x_prev  = x1
        else
            # exactly got to 0
            x_sol = x_lin
            break
        end

    end

    stat = SolverStatistics(iter)
    return (x_sol, stat)
end


function newton(fcn, x0, x1; options = NonlineqTolerance())

    xk    = 0.5 * x0 + 0.5 * x1
    x_sol = NaN64
    iter  = 0
    for outer iter = 1:options.max_iter

        fk = fcn(xk)
        df = numder.numdiff_fw(fcn, xk, sqrt(eps(xk)), fk)

        dx  = - fk / (df + eps(df))
        xk1 = xk + dx

        
        break_flag = __check_step_size(xk, xk1, options)
        if break_flag
            x_sol = xk1
            break
        end

        xk = xk1
    end

    stat = SolverStatistics(iter)
    return (x_sol, stat)
end


end # module


module ntest
using ..nonlineq1d


function test_1()
    fcn(x) = x^2 - 4

    x0 = 0.1
    x1 = 5

    x_bis      = nonlineq1d.bisection(fcn, x0, x1)
    x_regfal   = nonlineq1d.regula_falsi(fcn, x0, x1)
    x_regfalil = nonlineq1d.regula_falsi_ilinois(fcn, x0, x1)
    x_new      = nonlineq1d.newton(fcn, x0, x1)

end


fcn(x) = cos(x)

x0 = pi/2 - pi/4
x1 = pi/2 + pi/4

x_bis      = nonlineq1d.bisection(fcn, x0, x1)
x_regfal   = nonlineq1d.regula_falsi(fcn, x0, x1)
x_regfalil = nonlineq1d.regula_falsi_ilinois(fcn, x0, x1)
x_new      = nonlineq1d.newton(fcn, x0, x1)


end


=#