
include("../src/autodiff_module.jl")
include("../../__lib__/math/opti/src/opti_module.jl")

module optitest
using ..autodiff
using ..opti


function quadratic(x)
    y = zero(eltype(x))
    for ii in eachindex(x)
        y += x[ii]^2
    end
    return y
end 

function quadratic(x, x0)
    y = zero(eltype(x))
    for ii in eachindex(x)
        y += (x[ii] - x0[ii])^2
    end
    return y
end 



# x1a = autodiff.DualNumber(3.0)
# x2a = autodiff.DualNumber(4.0)

# x_vec = [x1a, x2a]
# g = autodiff.gradient(quadratic, x_vec)


x0 = [3.0, 4.0]

c = [5.0, 6.0]
obj_fcn(x)              = quadratic(x, c)
grad_fcn(objfcn, x)     = autodiff.gradient(autodiff.ForwardMode(), objfcn, x)
dir_diff_fcn(fcn, x, s) = autodiff.directional_derivative(fcn, x, s)

tol_options      = opti.ToleranceOptions(
    step_size_tol = 1e-15,
    f_abs_tol = 1e-15,
    f_rel_tol = 1e-15,
    g_abs_tol = 1e-15,
    max_iter = 100)


# (x_sol, y_sol, iter, stopping_crit) = opti.quasi_newton(
#     obj_fcn,
#     x0;
#     tol_options          = tol_options,
#     gradient_fcn         = grad_fcn,
#     directional_diff_fcn = dir_diff_fcn)

stat = opti.cg_pr(
    obj_fcn,
    x0;
    tol_options          = tol_options,
    gradient_fcn         = grad_fcn,
    directional_diff_fcn = dir_diff_fcn)




# directional diff
# lim[h -> 0] (fcn(x + h * s) - fcn(x)) / h


# x0 = [3.0, 4.0]
# obj_fcn(x) = quadratic(x)

# # s = [-4.0, 3.0]
# # s = -[-3.0, 4.0]
# s = [0.0, 5.0]
# s = [5.0, 0.0]

# dg = autodiff.directional_derivative(obj_fcn, x0, s)

end


