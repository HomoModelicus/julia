

# source code representation cannot be recovered, but code_lowered yes
# see for example Symbolics.jl or Cassette.jl

# unary minus, plus

# some unary functions:
# sqrt, cbrt, exp, log, log2, log10

# some trig functions:
# sin    cos    tan    cot    sec    csc
# sinh   cosh   tanh   coth   sech   csch
# asin   acos   atan   acot   asec   acsc
# asinh  acosh  atanh  acoth  asech  acsch
# sinc   cosc

# Implement:
# unary minus, plus
# sqrt, cbrt, exp, log, log2, log10
# sin    cos    tan






# simplifying unary minus

module Symbolics


function default_variable_value()
    return 0.0
end

abstract type AbstractVariable end
abstract type AbstractSymbolicExpression end
abstract type AbstractConstant end


include("is_operators.jl")
include("constant.jl")
include("variable.jl")
include("symbolic_expression.jl")
include("basic_operations.jl")
include("to_string.jl")
include("derivative.jl")



function is_equal(x, y)
    return false
end

function is_equal(x::Constant, y::Constant)
    return x.value == y.value
end

function is_equal(x::Variable, y::Variable)
    return x.name == y.name
end

function is_equal(x::SymbolicExpression, y::SymbolicExpression)
    # how to deal with permutations on expressions?
    # e.g. 
    # a + b ?= b + a, should be, but
    # (a + b) + c ?= a + (b + c); this should be also true, but much harder to operate on
    # a + b + c + d -> possibly could be represented as +(a, b, c, d)
    # but then it is required to rethink the binary operations
    return false
end



# this is not what I want
# I dont want to compare variables by pointer -> already provided by Julia
# but I'd like to compare whether they are equaivalent
# 
# function Base.:(==)(x::Constant, y::Constant)
#     # by value
#     return x.value == y.value
# end

# function Base.:(==)(x::Variable, y::Variable)
#     # by pointer
#     return x == y
# end

# function Base.:(==)(x::SymbolicExpression, y::SymbolicExpression)
#     # by pointer
#     return x == y
# end



function __simplify_plus(ex)
    # op +
    # ex + 0 -> ex
    # 0 + ex -> ex
    # c1 + c2 -> c3(c1.value + c2.value)
    # x + x -> 2 * x
    # ex + ex -> 2 * ex

    is_zero = is_zero_constant.(ex.args)
    if all(is_zero)
        return Constant(0.0)
    end

    is_not_zero = .!is_zero
    if any(is_not_zero)
        arg_vec = ex.args[is_not_zero]
        if length(arg_vec) == 1
            simpli_expr = arg_vec[1]
        else
            b_consts = is_constant.(arg_vec)
            idx      = findall(b_consts)
            if !isempty(idx)
                c        = reduce(+, arg_vec[idx])
                arg_vec  = [arg_vec[.!b_consts]; c]
            end
            simpli_expr = SymbolicExpression(:+, arg_vec...)
        end
        return simpli_expr
    end

    return ex
end

function __simplify_minus(ex)
    # op -
    # ex - 0 -> ex
    # 0 - ex -> -ex
    # c1 - c2 -> c3(c1.value - c2.value)
    # x - x -> 0
    # ex - ex -> 0

    

    L = length(ex.args)
    if L == 1
        if is_constant(ex.args[1])
            return Constant( -ex.args[1].value )
        else
            return ex
        end
    end

    if is_zero_constant(ex.args[1])
        return -ex.args[2]
    end

    if is_zero_constant(ex.args[2])
        return ex.args[1]
    end

    if is_equal(ex.args[1], ex.args[2])
        return Constant(0.0)
    end

    lhs = ex.args[1]
    rhs = ex.args[2]
    if is_constant(lhs) && is_constant(rhs)
        return lhs - rhs
    end
    
    return ex
end

function __simplify_product(ex)
    # op *
    # 0 * ex -> 0
    # ex * 0 -> 0
    # 1 * ex -> ex
    # ex * 1 -> ex

    is_zero = is_zero_constant.(ex.args)
    if any(is_zero)
        return Constant(0.0)
    end

    is_one     = is_one_constant.(ex.args)
    is_not_one = .!is_one
    if any(is_not_one)
        arg_vec = ex.args[is_not_one]
        if length(arg_vec) == 1
            simpli_expr = arg_vec[1]
        else

            b_consts = is_constant.(arg_vec)
            idx      = findall(b_consts)
            if !isempty(idx)
                c        = reduce(*, arg_vec[idx])
                arg_vec  = [arg_vec[.!b_consts]; c]
            end
            simpli_expr = SymbolicExpression(:*, arg_vec...)
        end
        return simpli_expr
    end

    return ex
end

function __simplify_divide(ex)
    # op /
    # ex / ex -> 1
    # 0 / rhs -> 0
    # rhs / 0 -> inf
    # 
    # if (subexpr1 * subexpr2) / (subexpr1 * subexpr3)
    # -> subexpr2 / subexpr3

    if is_zero_constant(ex.args[1])
        return Constant(0.0)
    end

    if is_zero_constant(ex.args[2])
        return Constant(Inf)
    end

    if is_equal(ex.args[1], ex.args[2])
        return Constant(1.0)
    end

    lhs = ex.args[1]
    rhs = ex.args[2]
    if is_constant(lhs) && is_constant(rhs)
        return lhs / rhs
    end

    return ex
end

function __simplify_power(ex)
    # op ^
    # x^i / x^j -> x^(i-j)
    # x^0 -> 1
    # x^1 -> x
    # 1^x

    if is_zero_constant(ex.args[2])
        return simpli_expr = Constant(1.0)
    end

    if is_one_constant(ex.args[1])
        return simpli_expr = Constant(1.0)
    end

    if is_one_constant(ex.args[2])
        return simpli_expr = ex.args[1]
    end

    lhs = ex.args[1]
    rhs = ex.args[2]
    if is_constant(lhs) && is_constant(rhs)
        return lhs^rhs
    end

    return ex
end


function simplify(ex::Constant)
    return ex
end

function simplify(ex::Variable)
    return ex
end

function simplify(ex::SymbolicExpression)

    # rewriting rules
    # zero element 
    # one element
    #
    # harder ones
    # commutative laws
    # associative laws
    # 
    # a + b -> b + a
    # (a + b) + c -> a + (b + c)

    
    return __rec_simplify(ex)
end

function __rec_simplify(ex::Constant)
    return ex
end

function __rec_simplify(ex::Variable)
    return ex
end

function __rec_simplify(ex::SymbolicExpression)

    L           = length(ex.args)
    sym         = ex.head
    simpli_args = Vector{Any}(undef, L)

    for ii = 1:L
        simpli_args[ii] = __rec_simplify(ex.args[ii])
    end

    simpli_expr = SymbolicExpression(sym, simpli_args...)

    if is_plus_operator(sym)
        simpli_expr = __simplify_plus(simpli_expr)
    elseif is_minus_operator(sym)
        simpli_expr = __simplify_minus(simpli_expr)
    elseif is_product_operator(sym)
        simpli_expr = __simplify_product(simpli_expr)
    elseif is_divide_operator(sym)
        simpli_expr = __simplify_divide(simpli_expr)
    elseif is_power_operator(sym)
        simpli_expr = __simplify_power(simpli_expr)
    # else
    #     simpli_expr = ex
    end

    return simpli_expr
end


function simplify(ex_vec::Vector)
    L = length(ex_vec)
    simpli_vec = Vector{Any}(undef, L)
    for ii = 1:L
        simpli_vec[ii] = simplify(ex_vec[ii])
    end
    return simpli_vec
end

function simplify(ex_mat::Matrix)
    L = length(ex_mat)
    (n_row, n_col) = size(ex_mat)
    simpli_mat = Matrix{Any}(undef, n_row, n_col)
    for ii = 1:L
        simpli_mat[ii] = simplify(ex_mat[ii])
    end
    return simpli_mat
end



end # module




