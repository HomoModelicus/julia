
include("../src/autodiff_module.jl")
include("../../__lib__/math/opti/src/opti_module.jl")
include("../../__lib__/math/opti/opti_test_functions/testfunctions.jl")


module optitest
using ..optitestfun
using ..autodiff
using ..opti


function quadratic(x)
    y = zero(x[1])
    for ii in eachindex(x)
        y += x[ii]^2
    end
    return y
    # y = mapreduce(t -> t^2, +, x)
end 

function quadratic(x, x0)
    y = zero(x[1])
    for ii in eachindex(x)
        y += (x[ii] - x0[ii])^2
    end
    return y
end 



# x1a = autodiff.DualNumber(3.0)
# x2a = autodiff.DualNumber(4.0)

# x_vec = [x1a, x2a]
# g = autodiff.gradient(quadratic, x_vec)



# x0 = [3.0, 4.0]
x0 = [-1.8, -2.0]

# c = [5.0, 6.0]
# obj_fcn(x)              = quadratic(x, c)
obj_fcn(x)              = optitestfun.rosenbrock(x, 2.0)

grad_fcn(objfcn, x)     = autodiff.gradient(autodiff.ReverseMode(), objfcn, x)
dir_diff_fcn(fcn, x, s) = autodiff.directional_derivative(fcn, x, s)

tol_options      = opti.ToleranceOptions(
    step_size_tol = 1e-15,
    f_abs_tol = 1e-15,
    f_rel_tol = 1e-15,
    g_abs_tol = 1e-15,
    max_iter = 100)


(x_sol, y_sol, iter, stopping_crit) = opti.quasi_newton(
    obj_fcn,
    x0;
    tol_options          = tol_options,
    gradient_fcn         = grad_fcn,
    directional_diff_fcn = dir_diff_fcn)

# stat = opti.cg_pr(
#     obj_fcn,
#     x0;
#     tol_options          = tol_options,
#     gradient_fcn         = grad_fcn,
#     directional_diff_fcn = dir_diff_fcn)




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


