

include("../opti_test_functions/testfunctions.jl")
include("../../numder/src/numder_module.jl")

module opti
using ..numder
using LinearAlgebra

include("../src/line_search.jl")

struct ToleranceOptions
    step_size_tol::Float64
    f_abs_tol::Float64
    f_rel_tol::Float64
    g_abs_tol::Float64
    max_iter::Int
end
function ToleranceOptions(;
    step_size_tol = 1e-15,
    f_abs_tol = 1e-15,
    f_rel_tol = 1e-15,
    g_abs_tol = 1e-15,
    max_iter = 100)

    ToleranceOptions(
        step_size_tol,
        f_abs_tol,
        f_rel_tol,
        g_abs_tol,
        max_iter)
end


struct BfgsOptions

end

function bfgs(fcn, x0, grad_fcn, options = ToleranceOptions() )

    n_dim = length(x0)
    H     = Matrix{Float64}(I, n_dim, n_dim)
    eye   = Matrix{Float64}(I, n_dim, n_dim)

    # first step is the steepest gradient descent
    g0        = grad_fcn(fcn, x0)
    step_size = line_search(fcn, x0, -g0)
    x1        = x0 - step_size * g0
    g1        = grad_fcn(fcn, x1)

    y            = g1 - g0
    s            = step_size * g0
    scale_factor = dot(y, s) / dot(y, y)
    for ii = 1:n_dim
        H[ii, ii] *= scale_factor
    end

    # main loop
    iter = 0
    for outer iter = 1:options.max_iter

        # update of the matrix
        s       = x1 - x0
        y       = g1 - g0
        sdy     = dot(s, y)
        rho     = 1 / sdy
        rhos    = rho * s
        Hy      = H * y
        Hyst    = Hy * rhos'
        sytHyst = rhos * (y' * Hyst)
        sst     = rhos * s'
        Hnew    = -(Hyst + Hyst') + sytHyst + sst
        Htest   = (eye - rho * s * y') * H * (eye - rho * y * s') + rho * s * s'

        dH = norm(Htest - Hnew)
        println(dH)

        x0        = x1
        p         = -(Hnew * g1)
        step_size = line_search(fcn, x0, p)
        dx        = p * step_size
        x1        = x0 + dx

        if norm(dx) <= options.step_size_tol
            break
        end
        
        # options.f_abs_tol
        # options.f_rel_tol
        
        g0        = g1
        g1        = grad_fcn(fcn, x1)

        if norm(g1) <= options.g_abs_tol
            break
        end


        H = Hnew
    end

    return (x1, iter)
end



end



module otest
using ..opti
using ..numder


grad_fcn(fcn, x) = numder.gradient_fw(fcn, x)

w = [1.0 3.0]
fcn(x) = sum(x .* x .* w)

x0 = [-2.0, -3.0]
t_sol = opti.bfgs(fcn, x0, grad_fcn)


end





