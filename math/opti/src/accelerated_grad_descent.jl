

function accelerated_gradient_line_search(fcn, x, step_direction, f, search_options)
    return 1.0
end




mutable struct NesterovGradientDescentMethod <: DescentMethod
    x
    f

    g
    v
    v_prev
    step_direction

    alpha # learning rate
    beta  # momentum decay
    max_v # maximum speed 
end
function NesterovGradientDescentMethod(;alpha = 0.8, beta = 0.61, max_v = 10)
    empty_array = zeros(Float64, 0)
    empty_scalar = zero(Float64)
    NesterovGradientDescentMethod( 
        empty_array, empty_scalar, empty_array, 
        empty_array, empty_array, empty_array,
        alpha, 
        beta,
        max_v)
end




function init!(m::NesterovGradientDescentMethod, x0)
    z        = zero(eltype(x0))
    za       = zeros(eltype(x0), size(x0))

    m.x      = x0
    m.f      = z

    m.g      = copy(za)
    m.v      = copy(za)
    m.v_prev = copy(za)
    m.step_direction = copy(za)

    # m.alpha   = 0.8
    # m.beta   = 0.61
end

function step_direction_fcn_nesterov!(m::NesterovGradientDescentMethod, fcn, gradient_fcn)
    # accelerated steepest gradient
    # nesterov momentum

    m.g                 = gradient_fcn( fcn, m.x + m.beta * m.v )
    v_                  = m.beta * m.v_prev - m.alpha * m.g
    max_v_norm          = min(m.max_v, norm(v_))
    normalize!(v_)
    m.v                 = max_v_norm * v_
    m.step_direction    = m.v
    m.x                 = m.x + m.v
end

function update_fcn_nesterov!(m::NesterovGradientDescentMethod, x1, f1)
    # m.x      = x1
    m.f      = f1
    m.v_prev = m.v
end




function nesterov_momentum_gradient_descent(
    fcn,
    x0;
    tol_options::ToleranceOptions       = ToleranceOptions(),
    search_options::LineSearchOptions   = LineSearchOptions(),
    gradient_fcn                        = numder.gradient_fw,
    line_search_fcn                     = accelerated_gradient_line_search,
    log_path                            = false,
    method_parameters                   = nothing)

    if isnothing(method_parameters)
        m = NesterovGradientDescentMethod();
    else
        m = method_parameters;
    end
    init_fcn            = init!
    step_direction_fcn  = step_direction_fcn_nesterov!
    update_fcn          = update_fcn_nesterov!

    stat = gradient_descent_template(
        m,
        init_fcn,
        step_direction_fcn,
        update_fcn,
        fcn,
        x0;
        tol_options     = tol_options,
        search_options  = search_options,
        gradient_fcn    = gradient_fcn,
        line_search_fcn = line_search_fcn,
        log_path        = log_path)

    return stat

end








#=
# something is wrong with the implementation


mutable struct HyperNesterovGradientDescentMethod <: DescentMethod
    x
    f

    g
    g_prev
    v
    v_prev
    step_direction

    alpha # learning rate
    beta  # momentum decay
    max_v # maximum speed 

    mu    # learning rate of the learning rate

end
function HyperNesterovGradientDescentMethod(;alpha = 0.8, beta = 0.61, max_v = 10, mu = 0.7)
    empty_array = zeros(Float64, 0)
    empty_scalar = zero(Float64)
    HyperNesterovGradientDescentMethod( 
        empty_array, empty_scalar, empty_array, 
        empty_array, empty_array, empty_array, empty_array,
        alpha, 
        beta,
        max_v,
        mu)
end




function hyper_nesterov_momentum_gradient_descent(
    fcn,
    x0;
    tol_options::ToleranceOptions       = ToleranceOptions(),
    search_options::LineSearchOptions   = LineSearchOptions(),
    gradient_fcn                        = numder.gradient_fw,
    line_search_fcn                     = accelerated_gradient_line_search,
    log_path                            = false,
    method_parameters                   = nothing)

    if isnothing(method_parameters)
        m = HyperNesterovGradientDescentMethod();
    else
        m = method_parameters;
    end
    init_fcn            = init!
    step_direction_fcn  = step_direction_fcn_nesterov!
    update_fcn          = update_fcn_nesterov!

    stat = gradient_descent_template(
        m,
        init_fcn,
        step_direction_fcn,
        update_fcn,
        fcn,
        x0;
        tol_options     = tol_options,
        search_options  = search_options,
        gradient_fcn    = gradient_fcn,
        line_search_fcn = line_search_fcn,
        log_path        = log_path)

    return stat

end


function init!(m::HyperNesterovGradientDescentMethod, x0)
    z        = zero(eltype(x0))
    za       = zeros(eltype(x0), size(x0))

    m.x      = x0
    m.f      = z

    m.g      = copy(za)
    m.g_prev      = copy(za)
    
    m.v      = copy(za)
    m.v_prev = copy(za)
    m.step_direction = copy(za)

    # m.alpha   = 0.8
    # m.beta   = 0.61
end

function step_direction_fcn_nesterov!(m::HyperNesterovGradientDescentMethod, fcn, gradient_fcn)
    # accelerated steepest gradient
    # hyper nesterov momentum

    # m.g                 = gradient_fcn( fcn, m.x + m.beta * m.v )
    m.g                 = gradient_fcn( fcn, m.x )

    tmp = m.g .* (m.g_prev + m.beta * m.v)
    stmp = sum(tmp)
    m.alpha = m.alpha + m.mu * stmp
    
    v_                  = m.beta * m.v_prev - m.alpha * m.g
    max_v_norm          = min(m.max_v, norm(v_))
    normalize!(v_)
    m.v                 = max_v_norm * v_


    m.step_direction    = m.v
    # m.x                 = m.x + m.v
    m.x                 = m.x - m.alpha * (m.g + m.beta * m.v)
end

function update_fcn_nesterov!(m::HyperNesterovGradientDescentMethod, x1, f1)
    m.f      = f1
    m.v_prev = m.v
    m.g_prev = m.g
end

=#