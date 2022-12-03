

function is_binary_operator(sym::Symbol)
    return  is_plus_operator(sym)    ||
            is_minus_operator(sym)   ||
            is_divide_operator(sym)  ||
            is_product_operator(sym) ||
            is_power_operator(sym)
end
function is_plus_operator(sym::Symbol)
    return sym == :+
end
function is_minus_operator(sym::Symbol)
    return sym == :-
end
function is_divide_operator(sym::Symbol)
    return sym == :/
end
function is_product_operator(sym::Symbol)
    return sym == :*
end
function is_power_operator(sym::Symbol)
    return sym == :^
end
function is_unary_operator(sym::Symbol)
    return  is_sqrt_operator(sym) ||
            is_cbrt_operator(sym) ||
            is_exp_operator(sym) ||
            is_log_operator(sym) ||
            is_log2_operator(sym) ||
            is_log10_operator(sym) ||
            is_sin_operator(sym) ||
            is_cos_operator(sym) ||
            is_tan_operator(sym) ||
            is_abs_operator(sym) ||
            is_sign_operator(sym)
end
function is_sqrt_operator(sym::Symbol)
    return sym == :sqrt
end
function is_cbrt_operator(sym::Symbol)
    return sym == :cbrt
end
function is_exp_operator(sym::Symbol)
    return sym == :exp
end
function is_log_operator(sym::Symbol)
    return sym == :log
end
function is_log2_operator(sym::Symbol)
    return sym == :log2
end
function is_log10_operator(sym::Symbol)
    return sym == :log10
end
function is_sin_operator(sym::Symbol)
    return sym == :sin
end
function is_cos_operator(sym::Symbol)
    return sym == :cos
end
function is_tan_operator(sym::Symbol)
    return sym == :tan
end
function is_abs_operator(sym::Symbol)
    return sym == :abs
end
function is_sign_operator(sym::Symbol)
    return sym == :sign
end




