
@enum GradientDescentStoppingCrit begin
    unknown
    max_iter_reached
    small_gradient
    small_step_size
    small_function_value_delta
end

struct GradientDescentStatistics
    x_sol
    y_sol
    iter
    stopping_crit
end

function Base.show(io::IO, stat::GradientDescentStatistics)
    print("Min search with $(stat.iter)-iterations\n")
    println("Cause of termination: $(stat.stopping_crit)")
    println("f: $(stat.y_sol)")
    print("x: ")
    show(
            stdout,
            MIME("text/plain"),
            stat.x_sol )
    print("\n")

end


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

mutable struct OptiSearchSpacePath{T}
    x::Matrix{T}
end
function OptiSearchSpacePath(x0)
    obj = OptiSearchSpacePath{ eltype(x0) }( zeros( eltype(x0), length(x0), 1 ) )
    obj.x[:, 1] = x0
    return obj
end


abstract type DescentMethod
end


function gradient_descent_template(
    m::T,
    init_fcn!,
    step_direction_fcn!,
    update_fcn!,
    fcn,
    x0;
    tol_options::ToleranceOptions       = ToleranceOptions(),
    search_options::LineSearchOptions   = LineSearchOptions(),
    gradient_fcn                        = numder.gradient_fw,
    line_search_fcn                     = line_search,
    directional_diff_fcn                = numder.directional_diff_fw,
    log_path                            = false) where {T <: DescentMethod}



    if log_path
        opti_search_path = OptiSearchSpacePath(x0)
    end
    
   
    mach_eps = tol_options.f_abs_tol * 1e-5

    init_fcn!(m, x0)
    m.f = fcn(m.x)

    stopping_crit = unknown::GradientDescentStoppingCrit
    x_sol = m.x
    y_sol = m.f

    iter = 0
    for outer iter = 1:tol_options.max_iter

        # m.g = gradient_fcn(fcn, m.x)

        # step direction algorithm
        step_direction_fcn!(m, fcn, gradient_fcn)

        # stopping criterion based on the gradient norm
        norm_g = norm(m.g)
        if norm_g <= tol_options.g_abs_tol
            x_sol = m.x
            y_sol = m.f
            stopping_crit = small_gradient::GradientDescentStoppingCrit
            break
        end

        # line search for step size
        step_size = line_search_fcn(fcn, m.x, m.step_direction, m.f, search_options; directional_diff_fcn = directional_diff_fcn)
        

        # stopping criterion based on the step size
        abs_step_size = norm( step_size * m.step_direction )
        if abs_step_size <= tol_options.step_size_tol
            x_sol = m.x
            y_sol = m.f
            stopping_crit = small_step_size::GradientDescentStoppingCrit
            break
        end

        # next step
        x1 = m.x + step_size * m.step_direction
        f1 = fcn(x1)

        # stopping criteria for function value
        if abs(f1 - m.f) <= tol_options.f_abs_tol || abs(f1 - m.f) / ( abs(m.f) == 0 ? mach_eps : abs(m.f)) < tol_options.f_rel_tol
            x_sol = x1
            y_sol = f1
            stopping_crit = small_function_value_delta::GradientDescentStoppingCrit
            break
        end

        # update for the next iteration
        update_fcn!(m, x1, f1)
        if log_path
            # push!(opti_search_path.x, x1)
            opti_search_path.x = hcat(opti_search_path.x, x1)
        end
    end

    # last step: iterations run out
    if iter == tol_options.max_iter
        x_sol = m.x
        y_sol = m.f
        stopping_crit = max_iter_reached::GradientDescentStoppingCrit
    end

    stat = GradientDescentStatistics(x_sol, y_sol, iter, stopping_crit)
    if log_path
        return (stat, opti_search_path)
    else
        return stat
    end

end




mutable struct SteepestGradientDescentMethod <: DescentMethod
    x
    f

    g
    step_direction
end
function SteepestGradientDescentMethod()
    empty_array = zeros(Float64, 0)
    empty_scalar = zero(Float64)
    SteepestGradientDescentMethod( empty_array, empty_scalar, empty_array, empty_array )
end

function init!(m::SteepestGradientDescentMethod, x0)
    m.g = zeros(eltype(x0), size(x0))
    m.x = x0
end

function step_direction_fcn_steepestgrad!(m, fcn, gradient_fcn)
    m.g = gradient_fcn(fcn, m.x)
    m.step_direction = -m.g ./ norm(m.g)
end

function update_fcn_steepestgrad!(m, x1, f1)
    m.f                   = f1
    m.x                   = x1
end



function steepest_gradient_descent(
    fcn,
    x0;
    tol_options::ToleranceOptions       = ToleranceOptions(),
    search_options::LineSearchOptions   = LineSearchOptions(),
    gradient_fcn                        = numder.gradient_fw,
    line_search_fcn                     = line_search,
    directional_diff_fcn                = numder.directional_diff_fw,
    log_path                            = false)


    m                   = SteepestGradientDescentMethod();
    init_fcn            = init!
    step_direction_fcn  = step_direction_fcn_steepestgrad!
    update_fcn          = update_fcn_steepestgrad!

    stat = gradient_descent_template(
        m,
        init_fcn,
        step_direction_fcn,
        update_fcn,
        fcn,
        x0;
        tol_options          = tol_options,
        search_options       = search_options,
        gradient_fcn         = gradient_fcn,
        line_search_fcn      = line_search_fcn,
        directional_diff_fcn = directional_diff_fcn,
        log_path             = log_path)

    return stat

end





mutable struct ConjugateGradientDescentMethod <: DescentMethod
    x                   # current position
    f                   # current function value

    g                   # gradient 
    g_prev              # previous gradient
    step_direction      # step direction
    step_direction_prev # previous step direction

    beta                # prev step direction effect
end
function ConjugateGradientDescentMethod()
    empty_array = zeros(Float64, 0)
    empty_scalar = zero(Float64)
    ConjugateGradientDescentMethod( empty_array, empty_scalar, empty_array, empty_array, empty_array, empty_array, empty_scalar )
end


function init!(m::ConjugateGradientDescentMethod, x0)
    m.g_prev              = zeros(eltype(x0), size(x0))
    m.step_direction_prev = zeros(eltype(x0), size(x0))
    m.beta                = zero(eltype(x0))

    m.x = x0
end

function step_direction_fcn_cg_pr!(m, fcn, gradient_fcn)
    # conjugate gradient
    # polak-ribiere method

    # step direction algo
    m.g = gradient_fcn(fcn, m.x)
    g_prev_normsq = sum(m.g_prev .* m.g_prev)
    if g_prev_normsq <= 1e-15
        m.beta = 0
    else
        m.beta = sum(m.g .* (m.g - m.g_prev)) / g_prev_normsq
        m.beta = max(m.beta, 0)
    end
    m.step_direction = -m.g + m.beta * m.step_direction_prev

    return m.step_direction
end

function update_fcn_cg_pr!(m, x1, f1)
    m.f                   = f1
    m.x                   = x1
    m.g_prev              = m.g
    m.step_direction_prev = m.step_direction
end


function cg_pr(
    fcn,
    x0;
    tol_options::ToleranceOptions     = ToleranceOptions(),
    search_options::LineSearchOptions = LineSearchOptions(),
    gradient_fcn                      = numder.gradient_fw,
    line_search_fcn                   = line_search,
    directional_diff_fcn              = numder.directional_diff_fw,
    log_path                          = false)


    m                   = ConjugateGradientDescentMethod();
    init_fcn            = init!
    step_direction_fcn  = step_direction_fcn_cg_pr!
    update_fcn          = update_fcn_cg_pr!

    stat = gradient_descent_template(
        m,
        init_fcn,
        step_direction_fcn,
        update_fcn,
        fcn,
        x0;
        tol_options          = tol_options,
        search_options       = search_options,
        gradient_fcn         = gradient_fcn,
        line_search_fcn      = line_search_fcn,
        directional_diff_fcn = directional_diff_fcn,
        log_path             = log_path)

    return stat

end



function steepest_gradient_descent_original(
    fcn,
    x0;
    tol_options::ToleranceOptions = ToleranceOptions(),
    search_options::LineSearchOptions = LineSearchOptions())

    # max_iter = 100, step_size_tol = 1e-15, f_abs_tol = 1e-15, f_rel_tol = 1e-15, g_abs_tol = 1e-16)

    max_iter      = tol_options.max_iter
    step_size_tol = tol_options.step_size_tol
    f_abs_tol     = tol_options.f_abs_tol
    f_rel_tol     = tol_options.f_rel_tol
    g_abs_tol     = tol_options.g_abs_tol



    mach_eps = f_abs_tol * 1e-5

    f0 = fcn(x0)
    iter = 0
    for outer iter = 1:max_iter
        g = numder.gradient_fw(fcn, x0)

        norm_g = norm(g)
        if norm_g <= g_abs_tol
            x_sol = x0
            y_sol = f0
            return GradientDescentStatistics(x_sol, y_sol, iter, small_gradient::GradientDescentStoppingCrit)
        end

        # step direction algo
        step_direction = -g ./ norm_g

        step_size = line_search(fcn, x0, step_direction, f0, search_options)
        if abs(step_size) <= step_size_tol
            x_sol = x0
            y_sol = f0
            return GradientDescentStatistics(x_sol, y_sol, iter, small_step_size::GradientDescentStoppingCrit)
        end

        x1 = x0 + step_size * step_direction
        f1 = fcn(x1)
        if abs(f1 - f0) <= f_abs_tol || abs(f1 - f0) / ( abs(f0) == 0 ? mach_eps : abs(f0)) < f_rel_tol
            x_sol = x1
            y_sol = f1
            return GradientDescentStatistics(x_sol, y_sol, iter, small_function_value_delta::GradientDescentStoppingCrit)
        end

        # update for the next iteration
        f0 = f1
        x0 = x1
    end
    if iter == max_iter
        return GradientDescentStatistics(x0, f0, iter, max_iter_reached::GradientDescentStoppingCrit)
    end

end


# include("accelerated_grad_descent.jl")












