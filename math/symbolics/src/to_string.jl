
function to_string(ex::SymbolicExpression)
# s expression style is easy, but not very nice
    if is_binary_operator(ex.head)
        __to_string_binary_op(ex)
    elseif is_unary_operator(ex.head)
        __to_string_unary_op(ex)
    else
        __to_string_k_ary_expression(ex)
    end
end

function to_string(s::String)
    return s
end

function __to_string_minus_op(ex::SymbolicExpression)
    if is_variable(ex.args[1])
        rhs = ex.args[1].name
    else
        rhs = to_string(ex.args[1])
    end

    do_paren = true
    if is_variable(ex.args[1]) || is_constant(ex.args[1])
        do_paren = false
    end

    left_paren  = "("
    right_paren = ")"

    if do_paren
        total_str = "-" * left_paren * rhs * right_paren
    else
        total_str = "-" * rhs
    end
    
    
    return total_str
end

function __to_string_unary_op(ex::SymbolicExpression)
    if is_minus_operator(ex.head)
        return __to_string_minus_op(ex)
    end
    arg_str   = to_string(ex.args[1])
    total_str = string(ex.head) * "(" * arg_str * ")"
    return total_str
end

function __to_string_k_ary_expression(ex)
    op = string(ex.head)

end

function __to_string_binary_op(ex::SymbolicExpression)

    L = length(ex.args)
    if L < 2
       return __to_string_unary_op(ex)
    end

    # op  = string(ex.head)
    # lhs = ex.args[1]
    # rhs = ex.args[2]

    # c op c
    # var op var
    # comp op comp -> hard case
    # 
    # c op var | var op c
    #
    # c op comp

    # rule: unary minus


    # rule: const op const
    if is_constant(ex.args[1]) && is_constant(ex.args[2])
        return __to_string_const_op_const(ex)
    end

    # rule: var op var
    if is_variable(ex.args[1]) && is_variable(ex.args[2])
        return __to_string_var_op_var(ex)
    end

    # rule: c op var | var op c
    if (is_variable(ex.args[1]) || is_constant(ex.args[1])) &&
        (is_variable(ex.args[2]) || is_constant(ex.args[2]))
        return __to_string_var_op_var(ex)
    end

    # c op comp
    if (is_constant(ex.args[1]) || is_variable(ex.args[1])) && is_composite_expression(ex.args[2])
        return __to_string_const_op_comp(ex, true)
    end
    if (is_constant(ex.args[2]) || is_variable(ex.args[2])) && is_composite_expression(ex.args[1])
        return __to_string_const_op_comp(ex, false)
    end

    # rule: constant */^ var or comp both way
    if (is_product_operator(ex.head) || is_divide_operator(ex.head) || is_power_operator(ex.head)) && 
        ( is_constant(ex.args[1]) || is_constant(ex.args[2]) ||
          is_variable(ex.args[1]) || is_variable(ex.args[2]) )
        return __to_string_constant_op_composite_expression(ex)
    end

    # rule: composite + composite
    if is_plus_operator(ex.head) & is_composite_expression(ex.args[1]) & is_composite_expression(ex.args[2])
        return __to_string_comp_plus_comp(ex)
    end

    # rule: composite - composite
    if is_minus_operator(ex.head) & is_composite_expression(ex.args[1]) & is_composite_expression(ex.args[2])
        return __to_string_comp_minus_comp(ex)
    end

    # rule: composite * composite
    if is_product_operator(ex.head) & is_composite_expression(ex.args[1]) & is_composite_expression(ex.args[2])
        return __to_string_comp_prod_comp(ex)
    end


    return __to_string_fallback(ex)
end

function __to_string_fallback(ex)

    op        = string(ex.head)
    lhs       = ex.args[1]
    rhs       = ex.args[2]
    lhs_str   = to_string(lhs)
    rhs_str   = to_string(rhs)
    ws        = " "

    left_paren   = "("
    right_paren  = ")"

    return left_paren * lhs_str * right_paren * ws * op * ws * left_paren * rhs_str * right_paren
end

function __to_string_const_op_const(ex)
    op        = string(ex.head)
    ws        = " "

    if is_plus_operator(ex.head) || is_product_operator(ex.head)
        return __to_string_plus_or_prod(ex)
    end

    lhs       = ex.args[1]
    rhs       = ex.args[2]
    lhs_str   = to_string(lhs)
    rhs_str   = to_string(rhs)
    total_str = lhs_str * ws * op * ws * rhs_str

    return total_str
end

function __to_string_var_op_var(ex::SymbolicExpression)

    if is_plus_operator(ex.head) || is_product_operator(ex.head)
        return __to_string_plus_or_prod(ex)
    end

    op        = string(ex.head)
    lhs       = ex.args[1]
    rhs       = ex.args[2]
    lhs_str   = to_string(lhs)
    rhs_str   = to_string(rhs)
    ws        = is_power_operator(ex.head) ? "" : " "
    total_str = lhs_str * ws * op * ws * rhs_str

    return total_str
end

function __to_string_const_op_comp(ex, lhs_is_const::Bool)

    if is_plus_operator(ex.head) || is_product_operator(ex.head)
        return __to_string_plus_or_prod(ex)
    end

    op        = ex.head
    op_str    = string(op)
    lhs       = ex.args[1]
    rhs       = ex.args[2]
    lhs_str   = to_string(lhs)
    rhs_str   = to_string(rhs)
    ws        = " "
    left_paren   = "("
    right_paren  = ")"


    if is_plus_operator(op)
        # c + ex
        return lhs_str * ws * op_str * ws * rhs_str
    end
    if is_minus_operator(op)
        # c - ex
        # c - (a +- b)
        # paren if the next op is +-
        
        if lhs_is_const
            if is_plus_operator(rhs.head) || is_minus_operator(rhs.head)
                return lhs_str * ws * op_str * ws * left_paren * rhs_str * right_paren
            else
                return left_paren * lhs_str * right_paren * ws * op_str * ws * rhs_str
            end
        else
            return lhs_str * ws * op_str * ws * rhs_str
        end
    end


    rhs_is_const = !lhs_is_const

    if lhs_is_const
        if is_product_operator(op) && (is_product_operator(rhs.head) || is_divide_operator(rhs.head))
            # dont paren if the next op is also * or /
            return lhs_str * ws * op_str * ws * rhs_str
        else
            return lhs_str * ws * op_str * ws * left_paren * rhs_str * right_paren
        end
    end
    if rhs_is_const
        if is_product_operator(op) && (is_product_operator(lhs.head) || is_divide_operator(lhs.head))
            # dont paren if the next op is also * or /
            return lhs_str * ws * op_str * ws * rhs_str
        else
            return left_paren * lhs_str * right_paren * ws * op_str * ws * rhs_str
        end
    end

end

function __to_string_constant_op_composite_expression(ex::SymbolicExpression)

    if is_plus_operator(ex.head) || is_product_operator(ex.head)
        return __to_string_plus_or_prod(ex)
    end

    op  = string(ex.head)
    lhs = ex.args[1]
    rhs = ex.args[2]

    if is_constant(lhs) || is_variable(lhs)
        return __to_string_constant_op_composite_expression_constvarleft(ex)
    end

    if is_constant(rhs) || is_variable(rhs)
        return __to_string_constant_op_composite_expression_constvarright(ex)
    end
end

function __to_string_constant_op_composite_expression_constvarleft(ex)

    # a * (b +- c)
    # a / (b +- c)
    # a ^ (b +-*/ c)
    # 
    # a * b */ c
    # a / b */ c

    op        = ex.head
    op_str    = string(op)
    lhs       = ex.args[1]
    rhs       = ex.args[2]
    lhs_str   = to_string(lhs)
    rhs_str   = to_string(rhs)
    ws        = " "
    left_paren   = "("
    right_paren  = ")"

    b1 = is_plus_operator(rhs.head) || is_minus_operator(rhs.head)

    do_paren = false
    if (is_product_operator(op) ||  is_divide_operator(op)) && b1
        do_paren = true
    end

    omit_ws = false
    if is_power_operator(op)
        do_paren = true
        omit_ws  = true
    end

    ws          = omit_ws ? "" : ws
    left_paren  = do_paren ? left_paren : ""
    right_paren = do_paren ? right_paren : ""
    
    return lhs_str * ws * op_str * ws * left_paren * rhs_str * right_paren
end

function __to_string_constant_op_composite_expression_constvarright(ex)

    # (a +- b) * c
    # (a +- b) / c
    # (a +- b) ^ c
    # 
    # a * b */ c

    
    op        = ex.head
    op_str    = string(op)
    lhs       = ex.args[1]
    rhs       = ex.args[2]
    lhs_str   = to_string(lhs)
    rhs_str   = to_string(rhs)
    ws        = " "
    left_paren   = "("
    right_paren  = ")"

    b1 = is_plus_operator(lhs.head) || is_minus_operator(lhs.head)

    do_paren = false
    if (is_product_operator(op) ||  is_divide_operator(op)) && b1
        do_paren = true
    end

    omit_ws = false
    if is_power_operator(op)
        do_paren = true
        omit_ws  = true
    end

    ws          = omit_ws ? "" : ws
    left_paren  = do_paren ? left_paren : ""
    right_paren = do_paren ? right_paren : ""
    
    return left_paren * lhs_str * right_paren * ws * op_str * ws * rhs_str 
end


function __to_string_plus_or_prod(ex)

    op        = string(ex.head)
    strs      = map(to_string, ex.args)
    ws        = " "
    L         = length(ex.args)
    Ltotal    = L + L-1
    total_str = Vector{String}(undef, Ltotal)

    for ii = 1:L-1
        total_str[2*ii-1] = strs[ii]
        total_str[2*ii]   = ws * op * ws
    end

    total_str[Ltotal] = strs[L]
    reduced_total_str = reduce(*, total_str)

    return reduced_total_str
end

function __to_string_comp_plus_comp(ex)
    # op        = string(ex.head)
    # lhs       = ex.args[1]
    # rhs       = ex.args[2]
    # lhs_str   = to_string(lhs)
    # rhs_str   = to_string(rhs)
    # total_str = lhs_str * ws * op * ws * rhs_str

    return __to_string_plus_or_prod(ex)
end

function __to_string_comp_minus_comp(ex)

    # a + b - (c +- d)
    # a + b - c */ d

    # if the rhs op is 
    # +, - -> paren
    # *, / -> dont paren if the rhs.args are either const or var
    op        = string(ex.head)
    lhs       = ex.args[1]
    rhs       = ex.args[2]
    lhs_str   = to_string(lhs)
    rhs_str   = to_string(rhs)
    ws        = " "
    always_paren   = is_plus_operator(rhs.head) || is_minus_operator(rhs.head)
    possibly_paren = ( is_product_operator(rhs.head) ||
                       is_divide_operator(rhs.head) ) && 
                       !(is_constant(rhs.args[1]) || is_variable(rhs.args[1]))
    do_paren    = always_paren | possibly_paren
    left_paren  = do_paren ? "(" : ""
    right_paren = do_paren ? ")" : ""

    total_str = lhs_str * ws * op * ws * left_paren * rhs_str * right_paren

    return total_str
end

function __to_string_comp_prod_comp(ex)

    # special rule (not implemented yet)
    # if in one branch only * -> no paren is needed

    # (a +- b) * (c +- d)
    # a*/b * c*/d

    # if the rhs op is
    # +, - -> paren
    # *, / -> dont paren if the rhs.args are either const or var
    op        = string(ex.head)
    lhs       = ex.args[1]
    rhs       = ex.args[2]
    lhs_str   = to_string(lhs)
    rhs_str   = to_string(rhs)
    ws        = " "

    always_paren   = is_plus_operator(rhs.head) || is_minus_operator(rhs.head)
    possibly_paren = ( is_product_operator(rhs.head) ||
                       is_divide_operator(rhs.head) ) && 
                       !(is_constant(rhs.args[1]) || is_variable(rhs.args[1]))
    do_paren_right  = always_paren | possibly_paren

    always_paren   = is_plus_operator(lhs.head) || is_minus_operator(lhs.head)
    possibly_paren = ( is_product_operator(lhs.head) ||
                       is_divide_operator(lhs.head) ) && 
                       !(is_constant(lhs.args[1]) || is_variable(lhs.args[1]))
    do_paren_left  = always_paren | possibly_paren


    left_paren  = "("
    right_paren = ")"

    left_str  = do_paren_left ? (left_paren * lhs_str * right_paren) : lhs_str
    right_str = do_paren_right ? (left_paren * rhs_str * right_paren) : rhs_str
    total_str = left_str *  ws * op * ws * right_str

    return total_str
end
