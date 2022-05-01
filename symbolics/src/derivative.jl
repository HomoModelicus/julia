

function derivative(ex::Constant, wrt::Variable)
    return Constant( default_variable_value() )
end

function derivative(ex::Variable, wrt::Variable)
    T   = typeof(wrt.value)
    val = default_variable_value()
    if ex == wrt
        val = one(T)
    end
    return Constant(val)
end

function derivative(ex::SymbolicExpression, wrt::Variable)

    if is_unary_operator(ex.head)
        der_ex = __derivative_unary(ex, wrt)
    elseif is_binary_operator(ex.head)
        der_ex = __derivative_binary(ex, wrt)
    else
        error("not implemented yet")
        # er_ex = __derivative_k_ary(ex, wrt)
    end

    return der_ex
end

function __derivative_unary(ex::SymbolicExpression, wrt::Variable)

    # dy/dz = sin(x)
    # dy/dz = cos(x) * dx/dz
    #
    # derivative of the arguments
    # derivative of the function itself

    arg = ex.args[1]
    der_arg = derivative(arg, wrt)

    sym = ex.head

    if is_sin_operator(sym)
        der_ex = der_arg * cos(arg)

    elseif is_cos_operator(sym)
        der_ex = -der_arg * sin(arg)

    elseif is_tan_operator(sym)
        der_ex = der_arg / (cos(arg) * cos(args))

    elseif is_sqrt_operator(sym)
        der_ex = der_arg / sqrt(arg)

    elseif is_cbrt_operator(sym)
        der_ex = der_arg * 1/3 * arg^(-2/3)

    elseif is_exp_operator(sym)
        der_ex = der_arg * exp(arg)

    elseif is_log_operator(sym)
        der_ex = der_arg / arg

    elseif is_log2_operator(sym)
        der_ex = der_arg / (arg * log(2))

    elseif is_log10_operator(sym)
        der_ex = der_arg / (arg * log(10))

    elseif is_abs_operator(sym)
        der_ex = der_arg * sign(arg) 

    elseif is_sign_operator(sym)
        der_ex = Constant(0.0)

    else
        error("not implemented yet")
    end


    return der_ex
end



function __derivative_binary(ex::SymbolicExpression, wrt::Variable)

    sym = ex.head

    if is_plus_operator(sym) || is_product_operator(sym)
        # der_ex = der_left_arg + der_right_arg
        # der_ex = der_left_arg * right_arg + left_arg * der_right_arg

        df(expr) = derivative(expr, wrt)
        der_args = map(df, ex.args)

        if is_plus_operator(sym)
            return reduce(+, der_args)
        end

        L = length(ex.args)
        if L == 2
            left_arg      = ex.args[1]
            right_arg     = ex.args[2]
            der_left_arg  = der_args[1]
            der_right_arg = der_args[2]

            return der_left_arg * right_arg + left_arg * der_right_arg
        else
            der_ex = der_args[1] * reduce(*, ex.args[2:end])
            for ii = 2:L
                # left   = reduce(*, ex.args[1:ii-1])
                # right  = reduce(*, ex.args[ii+1:end])
                args      = [ex.args[1:ii-1]; der_args[ii]; ex.args[ii+1:end]]
                left_expr = SymbolicExpression(:*, args...)
                der_ex    = der_ex + left_expr # left * der_args[ii] * right
            end
            return der_ex
        end
    end

    L = length(ex.args)
    if is_minus_operator(sym) && L == 1
        der_right_arg = derivative(ex.args[1], wrt)
        der_ex = -der_right_arg
        return der_ex
    end


    left_arg  = ex.args[1]
    right_arg = ex.args[2]

    der_left_arg  = derivative(left_arg, wrt)
    der_right_arg = derivative(right_arg, wrt)

    if is_minus_operator(sym)
        der_ex = der_left_arg - der_right_arg

    elseif is_divide_operator(sym)
        der_ex = (der_left_arg * right_arg - left_arg * der_right_arg) / (right_arg * right_arg)

    elseif is_power_operator(sym)
        # most complicated expression
        der_ex = ex * (der_left_arg * right_arg / left_arg + der_right_arg * log(left_arg))

    else
        error("not implemented yet")
    end

    return der_ex
end




function gradient(
    ex::S,
    wrt_vec::A) where {
        S <: Union{Constant, Variable, SymbolicExpression},
        A <: AbstractArray}
    
    L = length(wrt_vec)
    g = Vector{Any}(undef, L)

    for ii = 1:L
        g[ii] = symbolics.derivative(ex, wrt_vec[ii])
    end

    return g
end


function jacobian(
    ex_vec::S,
    wrt_vec::A) where {
        S <: AbstractArray,
        A <: AbstractArray}
    
    n_row = length(ex_vec)
    n_col = length(wrt_vec)
    jac   = Matrix{Any}(undef, n_row, n_col)

    for ii = 1:n_row
        ex = ex_vec[ii]
        for jj = 1:n_col
            jac[ii, jj] = symbolics.derivative(ex, wrt_vec[jj])
        end
    end

    return jac
end


