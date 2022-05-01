
# ============================================================================ #
# Operations
# ============================================================================ #

function is_constant(x)
    return false
end
function is_constant(x::Constant)
    return true
end

function is_variable(x)
    return false
end
function is_variable(x::Variable)
    return true
end

function is_expression(x)
    return false
end
function is_expression(x::SymbolicExpression)
    return true
end

function is_composite_expression(x::T) where {T <: Union{Constant, Variable}}
    return false
end
function is_composite_expression(ex::SymbolicExpression)
    return true
end

function is_commutative(ex::SymbolicExpression)
    return  is_plus_operator(ex.head) ||
            is_product_operator(ex.head)
end
