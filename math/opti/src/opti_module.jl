

include("../../common/numder/src/numder_module.jl")
# include("testfunctions.jl")

module opti
using ..numder
using LinearAlgebra

include("opti_1d.jl")
include("line_search.jl")
include("gradient_descent.jl")


mutable struct BFGS <: DescentMethod
    B
end
function BFGS(x::Vector{T}) where {T}
    BFGS( Matrix(one(T)*I, length(x), length(x)) )
end

function init!(m::BFGS, x)
    m.B = Matrix(one(eltype(x))*I, length(x), length(x))
end

function bfgs_matrix_update(B, g, g_prev, x, x_prev)
    dg = g - g_prev
    dx = x - x_prev

    dxdg = dot(dx, dg)
    
    if dxdg < 0
        println("No update happens, some accuracy errors")
        println(" dxdg = $(dxdg) ")
        return B
    end

    t1 = (dx ./ dxdg) * (dg' * B)
    t1 = t1 + t1'

    t2f = 1 + (dg' * (B * dg)) / dxdg
    t2 = (dx .* (t2f / dxdg)) * dx'

    # B = B - t1 + t2
    B += (t2 - t1)
    return B
end

function quasi_newton(
    fcn,
    x0;
    tol_options::ToleranceOptions       = ToleranceOptions(),
    search_options::LineSearchOptions   = LineSearchOptions(),
    gradient_fcn                        = numder.gradient_fw,
    line_search_fcn                     = line_search,
    directional_diff_fcn                = numder.directional_diff_fw,
    log_path                            = false)

    m = BFGS(x0)

    x = x0
    f = fcn(x)
    g = gradient_fcn(fcn, x)

    step_direction  = -m.B * g
    step_size       = line_search_fcn(fcn, x, step_direction, f, search_options; directional_diff_fcn = directional_diff_fcn)
    dx              = step_size * step_direction
    g_new           = gradient_fcn(fcn, x + dx)
    dg              = g_new - g
    m.B             = m.B * dot(dg, dx) / dot(dg, dg)

    x_prev  = x
    x       = x_prev + dx
    f_prev  = f
    f       = fcn(x)
    g_prev  = g
    g       = g_new



    # out parameters
    x_sol = x
    y_sol = f
    stopping_crit = unknown::GradientDescentStoppingCrit



    iter = 0
    for outer iter = 1:tol_options.max_iter

        # update B
        # dg = g - g_prev
        # dx = x - x_prev

        # dxdg = dot(dx, dg)

        # t1 = (dx ./ dxdg) * (dg' * m.B)
        # t1 = t1 + t1'

        # t2f = 1 + (dg' * (m.B * dg)) / dxdg
        # t2 = (dx .* (t2f / dxdg)) * dx'

        # m.B = m.B - t1 + t2

        m.B = bfgs_matrix_update(m.B, g, g_prev, x, x_prev)

        # step dir
        step_direction = - m.B * g
        step_size      = line_search_fcn(fcn, x, step_direction, f, search_options; directional_diff_fcn = directional_diff_fcn)

        dx = step_direction * step_size


        # stopping criterion based on the step size
        abs_step_size = norm( dx )
        if abs_step_size <= tol_options.step_size_tol
            x_sol = x
            y_sol = f
            stopping_crit = small_step_size::GradientDescentStoppingCrit
            break
        end


        x_prev = x
        x      = x_prev + dx
        f_prev = f
        f      = fcn(x)
        g_prev = g


        # stopping criteria for function value
        if abs(f - f_prev) <= tol_options.f_abs_tol || abs(f - f_prev) / ( abs(f_prev) == 0 ? mach_eps : abs(f_prev)) < tol_options.f_rel_tol
            x_sol = x
            y_sol = f
            stopping_crit = small_function_value_delta::GradientDescentStoppingCrit
            break
        end


        # calculate the gradient at the new point
        g = gradient_fcn(fcn, x)


        # stopping criterion based on the gradient norm
        norm_g = norm(g)
        if norm_g <= tol_options.g_abs_tol
            x_sol = m.x
            y_sol = m.f
            stopping_crit = small_gradient::GradientDescentStoppingCrit
            break
        end

    end

    return (x_sol, y_sol, iter, stopping_crit)

end










function bfgs(
	fcn,
	x0;
	grad_fcn = numder.gradient_fw,
	options = ToleranceOptions() )

    n_dim = length(x0)
    H     = Matrix{Float64}(I, n_dim, n_dim)
    eye   = Matrix{Float64}(I, n_dim, n_dim)

    # first step is the steepest gradient descent
    g0        = grad_fcn(fcn, x0)
    step_size = line_search(fcn, x0, -g0)
    x1        = x0 - step_size * g0
    g1        = grad_fcn(fcn, x1)

    y            = g1 - g0
    s            = -step_size * g0
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
		Hs 		= H * s
		sHs     = dot(s, Hs)
		theta   = 1.0
		if sdy < 0.2 * sHs
			theta = 0.8 * sHs / (sHs - sdy)
		end

		r = theta * y + (1 - theta) * Hs

        Hy      = H * y
		rho     = 1 / sdy
        rhos    = rho * s
        Hyst    = Hy * rhos'
        sytHyst = rhos * (y' * Hyst)
        # sst     = rhos * s'
        sst 	= r * r' / dot(s, r)

		Hnew    = H - (Hyst + Hyst') + sytHyst + sst
        # Hnew   = (eye - rho * s * y') * H * (eye - rho * y * s') + rho * s * s'

        # dH = norm(Htest - Hnew)
        # println(dH)

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


end # opti


#=

function nonlinear_conjugate_gradient_descent_template(beta_method, fcn, x0, options, wolfe_condition_options)
	x_act = x0
	y_act = fcn(x_act)
	x_next = x_act
	x_sol = x_act

	# first step is a gradient descent step
	g_act = NumDiff.gradient_fw(fcn, x_act)
	direction_act = -g_act
	alpha = strong_wolfe_line_search(fcn, x_act, direction_act,
	 								wolfe_condition_options.alpha_0,
									wolfe_condition_options.beta,
									wolfe_condition_options.sigma)
	step = alpha * direction_act
	x_act = x_act + step
	y_act = fcn(x_act)
	g_prev = g_act
	direction_prev = direction_act

	# main loop
	println("x: $x_act")
	iter = 1
	for outer iter = 1:options.max_iter

		g_act = NumDiff.gradient_fw(fcn, x_act)

		## specific method is applied
		beta = beta_method(g_act, g_prev, direction_prev)


		direction_act = -g_act + beta .* direction_prev

		alpha = strong_wolfe_line_search(fcn, x_act, direction_act)
		step = alpha * direction_act
		x_next = x_act + step
		y_next = fcn(x_next)

		# convergence checks
		if norm(g_act) <= options.gradient_tolerance
			x_sol = x_next
			break
		end
		if norm(step) <= options.step_tolerance
			x_sol = x_next
			break
		end
		if abs(y_next - y_act) <= options.function_value_change_tolerance
			x_sol = x_next
			break
		end

		# updates
		y_act = y_next
		x_act = x_next
		direction_prev = direction_act
		println("x: $x_act")
	end

	if iter == options.max_iter
		x_sol = x_next
	end
	return x_sol
end

function beta_polak_ribiere(g_act, g_prev, direction_prev)
	y_hat = g_act - g_prev
	beta = dot(g_act, y_hat) / dot( g_prev, g_prev )
	beta = max(beta, 0)
	return beta
end


function beta_dai_yuan(g_act, g_prev, direction_prev)
	y_hat = g_act - g_prev
	beta = dot(g_act, g_act) / dot(y_hat, direction_prev)
	beta = max(beta, 0)
	return beta
end

function beta_hestenes_stiefel(g_act, g_prev, direction_prev)
	y_hat = g_act - g_prev
	beta = dot(y_hat, g_act) / dot(y_hat, direction_prev)
	beta = max(beta, 0)
	return beta
end

function beta_hager_zhang(g_act, g_prev, direction_prev)
	# probably implementation error
	y_hat = g_act - g_prev
	numer = dot(y_hat, direction_prev)
	t1 = y_hat - 2 .* direction_prev .* dot(y_hat, y_hat) ./ numer
	t2 = g_act ./ numer
	beta = dot(t1, t2)
	# beta = max(beta, 0)
	return beta
end


function nonlinear_conjugate_gradient_descent_polak_ribiere(
	fcn,
	x0,
	options::GradientDescentOptions = default_options(GradientDescentOptions),
	wolfe_condition_options = default_strong_wolfe_conditions_options()
	)
	x_sol = nonlinear_conjugate_gradient_descent_template(beta_polak_ribiere, fcn, x0, options, wolfe_condition_options)
end

function nonlinear_conjugate_gradient_descent_dai_yuan(
	fcn,
	x0,
	options::GradientDescentOptions = default_options(GradientDescentOptions),
	wolfe_condition_options = default_strong_wolfe_conditions_options()
	)
	x_sol = nonlinear_conjugate_gradient_descent_template(beta_dai_yuan, fcn, x0, options, wolfe_condition_options)
end

function nonlinear_conjugate_gradient_descent_hestenes_stiefel(
	fcn,
	x0,
	options::GradientDescentOptions = default_options(GradientDescentOptions),
	wolfe_condition_options = default_strong_wolfe_conditions_options()
	)
	x_sol = nonlinear_conjugate_gradient_descent_template(beta_hestenes_stiefel, fcn, x0, options, wolfe_condition_options)
end

function nonlinear_conjugate_gradient_descent_hager_zhang(
	fcn,
	x0,
	options::GradientDescentOptions = default_options(GradientDescentOptions),
	wolfe_condition_options = default_strong_wolfe_conditions_options()
	)
	x_sol = nonlinear_conjugate_gradient_descent_template(beta_hager_zhang, fcn, x0, options, wolfe_condition_options)
end

=#