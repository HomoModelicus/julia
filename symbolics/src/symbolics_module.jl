

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

module symbolics


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





module stest
using ..symbolics



# symbolics.@variable x 10
# symbolics.@variable y 0.2
# symbolics.@variable z 3
# e1 = x + y
# e2 = x / y
# e3 = z ^ (x + y)
# e4 = -x
# e5 = -x - y
# e6 = sin(x + y - z * x)
# e3_val = symbolics.evaluate(e3)
# str1 = symbolics.to_string( stest.e1 )
# str2 = symbolics.to_string( stest.e2 )
# str3 = symbolics.to_string( stest.e3 )
# str4 = symbolics.to_string( stest.e4 )
# str5 = symbolics.to_string( stest.e5 )
# str6 = symbolics.to_string( stest.e6 )
# e7 = y * 10
# str7 = symbolics.to_string( stest.e7 )
# e8 = 10 * y
# str8 = symbolics.to_string( stest.e8 )
# e9 = 10 + (x - y)
# str9 = symbolics.to_string( stest.e9 )
# # !!!
# # this doesnt work correctly now
# # e10 = y * 10 * (x * 2 - 3*z)
# e10 = x * y * x * (x * 2 - 3*z)
# str10 = symbolics.to_string( stest.e10 ) 




function paren_test()

    symbolics.@variable x 10
    symbolics.@variable y 0.2
    symbolics.@variable z 3


    e1 = x + y
    e2 = x / y

    e3 = z ^ (x + y)

    e4 = -x
    e5 = -x - y
    e6 = sin(x + y - z * x)

    # e3_val = symbolics.evaluate(e3)


    # str1 = symbolics.to_string( stest.e1 )
    # str2 = symbolics.to_string( stest.e2 )
    # str3 = symbolics.to_string( stest.e3 )
    # str4 = symbolics.to_string( stest.e4 )
    # str5 = symbolics.to_string( stest.e5 )
    # str6 = symbolics.to_string( stest.e6 )

    # e7 = y * 10
    # str7 = symbolics.to_string( stest.e7 )
    # e8 = 10 * y
    # str8 = symbolics.to_string( stest.e8 )

    # e9 = 10 + (x - y)
    # str9 = symbolics.to_string( stest.e9 )


    # !!!
    # this doesnt work correctly now
    # e7 = y * 10 * (x * 2 - 3*z)
    e7 = x * y * x * (x * 2 - 3*z)
    str7 = symbolics.to_string( stest.e7 ) 




    # str = symbolics.to_string( stest.e6 ) 

    # x_val = symbolics.evaluate(x)
    # y_val = symbolics.evaluate(x)

    # e1_val = symbolics.evaluate(e1)


end

function test_derivative_simpli()
    symbolics.@variable x 10
    symbolics.@variable y 0.2
    symbolics.@variable z 3
    symbolics.@variable w 5


    u = -x

    ex1 = x + y
    ex2 = x * y + z
    ex3 = x + y + z
    ex4 = x * y * z
    ex5 = sin(x)

    # str = symbolics.to_string(ex2)


    der_ex3       = symbolics.derivative(stest.ex3, stest.x)
    der_str3      = symbolics.to_string(der_ex3)
    @time s_der_ex3     = symbolics.simplify(der_ex3)
    str_s_der_ex3 = symbolics.to_string(s_der_ex3)



    der_ex4       = symbolics.derivative(stest.ex4, stest.x)
    der_str4      = symbolics.to_string(der_ex4)
    @time s_der_ex4     = symbolics.simplify(der_ex4)
    str_s_der_ex4 = symbolics.to_string(s_der_ex4)
end



function harmonic_osc(der_q, time, q)
    der_q[1] = q[2]
    der_q[2] = -5.0 * q[1] - q[2]

    return der_q
end




# symbolics.@variable x 10
# symbolics.@variable v 0.2

# q = Vector{symbolics.Variable}(undef, 2)
# der_q = Vector{Any}(undef, 2)

# q[1] = x
# q[2] = v


# der_q = harmonic_osc(der_q, 0.0, q)

# jac = symbolics.jacobian(der_q, q)
# sjac = symbolics.simplify(jac)
# sjac = symbolics.simplify(sjac)






# symbolics.@variable a 30.0

# expr1 = a + 1.0


end