

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


# what not easy?
# simplify!
# rewriting rules
# trivial cases: 
#   if x - x -> 0
#   if x / x -> 1
#   if x*x -> x^2
#   if x^i / x^j -> x^(i-j)
#   if x^0 -> 1
#   math operations on constants should be evaluated
#   if c1 + c2 -> c3(c1.value + c2.value)

# implement constants

module symbolics


function default_variable_value()
    return 0.0
end


abstract type AbstractVariable end
abstract type AbstractSymbolicExpression end
abstract type AbstractConstant end

# ============================================================================ #
# Constant
# ============================================================================ #


struct Constant <: AbstractConstant
    value::Float64

    function Constant(value)
        return new( value )
    end
end

function evaluate(x::Constant)
    return x.value
end

function to_string(x::Constant)
    return string(x.value)
end

# ============================================================================ #
# Variable
# ============================================================================ #


mutable struct Variable <: AbstractVariable
    name::String
    value::Float64

    function Variable(name, value = 0.0)
        return new(string(name), value)
    end
end

macro variable(varname, value = default_variable_value())
    lhs = esc(varname)
    rhs = :(     Variable( $(QuoteNode(varname)), $value)   )
    ex  = :($(lhs) = $(rhs))

    return ex
end

function evaluate(x::Variable)
    return x.value
end

function to_string(x::Variable)
    return x.name
end

# ============================================================================ #
# SymbolicExpression
# ============================================================================ #

mutable struct SymbolicExpression <: AbstractSymbolicExpression
    value::Float64
    head::Symbol
    args::Vector{Any}
    
    function SymbolicExpression(head, args...)
        return new(default_variable_value(), head, collect(args)) # [args...])
    end
end

for op in (:+, :-, :/, :*, :^)
    @eval function Base.$(op)(
        x::Tx, y::Ty) where {
            Tx <: Union{Constant, Variable, SymbolicExpression},
            Ty <: Union{Constant, Variable, SymbolicExpression}}
            
        ex = SymbolicExpression(Symbol(Base.$op), x, y)
        return ex
    end

    @eval function Base.$(op)(
        x::Tx, y::Ty) where {
            Tx <: Number,
            Ty <: Union{Constant, Variable, SymbolicExpression}}
        
        c = Constant(x)
        ex = SymbolicExpression(Symbol(Base.$op), c, y)
        return ex
    end

    @eval function Base.$(op)(
        x::Tx, y::Ty) where {
            Tx <: Union{Constant, Variable, SymbolicExpression},
            Ty <: Number}
        
        c = Constant(y)
        ex = SymbolicExpression(Symbol(Base.$op), x, c)
        return ex
    end
end

function Base.:(+)(
    x::Tx) where {Tx <: Union{Constant, Variable, SymbolicExpression}}
    return x
end

function Base.:(-)(
    x::Tx) where {Tx <: Union{Constant, Variable, SymbolicExpression}}
    ex = SymbolicExpression(:(-), x)
    return ex
end

for op in (:sqrt, :cbrt, :exp, :log, :log2, :log10, :sin, :cos, :tan)
    @eval function Base.$(op)(
        x::Tx) where {Tx <: Union{Constant, Variable, SymbolicExpression}}
            
        ex = SymbolicExpression(Symbol(Base.$op), x)
        return ex
    end
end

function evaluate(ex::SymbolicExpression)

    values = Vector{Any}(undef, length(ex.args))
    for (ii, arg) in enumerate(ex.args)
        values[ii] = evaluate(arg)
    end

    ex2call  = Expr(:call, ex.head, values...)
    val      = eval(ex2call)
    ex.value = val
    return val
end

function substitute!(
    ex::SymbolicExpression,
    old_var::T,
    new_ex::U) where {
        T  <: Union{Constant, Variable, SymbolicExpression},
        U <: Union{Constant, Variable, SymbolicExpression}}

    for (ii, ee) in enumerate(ex.args)
        if ee isa Variable || ee isa Constant
            if ee == old_var
                ex.args[ii] = new_ex
            end
        elseif ee isa SymbolicExpression
            substitute!(ee, old_var, new_ex)
        else
            error("something went wrong")
        end
    end

    return ex
end

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


function to_string(ex::SymbolicExpression)
# s expression style is easy, but not very nice
    if is_binary_operator(ex.head)
        __to_string_binary_op(ex)
    elseif is_unary_operator(ex.head)
        __to_string_unary_op(ex)
    else
        __show_k_ary_expression(ex)
    end
end

function __to_string_minus_op(ex::SymbolicExpression)
    total_str = "-" * ex.args[1].name
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

function __show_k_ary_expression(ex)
    op = string(ex.head)

end

function __to_string_binary_op(ex::SymbolicExpression)

    L = length(ex.args)
    if L < 2
       return __to_string_unary_op(ex)
    end

    op  = string(ex.head)
    lhs = ex.args[1]
    rhs = ex.args[2]

    # c op c
    # var op var
    # comp op comp -> hard case
    # 
    # c op var | var op c
    #
    # c op comp

    # rule const op const
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
    if is_constant(ex.args[1]) && is_composite_expression(ex.args[2])
        return __to_string_const_op_comp(ex, true)
    end
    if is_constant(ex.args[2]) && is_composite_expression(ex.args[1])
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
    lhs       = ex.args[1]
    rhs       = ex.args[2]
    lhs_str   = to_string(lhs)
    rhs_str   = to_string(rhs)
    ws        = " "

    total_str = lhs_str * ws * op * ws * rhs_str

    return total_str
end

function __to_string_var_op_var(ex::SymbolicExpression)
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
        if is_plus_operator(rhs.head) || is_minus_operator(rhs.head)
            if lhs_is_const
                return lhs_str * ws * op_str * ws * left_paren * rhs_str * right_paren
            else
                return left_paren * lhs_str * right_paren * ws * op_str * ws * rhs_str
            end
        else
            return lhs_str * ws * op_str * ws * rhs_str
        end
    end
    if is_product_operator(op) || is_divide_operator(rhs.head)
        # dont paren if the next op is also * or /
        if is_product_operator(rhs.head) || is_divide_operator(rhs.head)
            return lhs_str * ws * op_str * ws * rhs_str
        else
            if lhs_is_const
                return lhs_str * ws * op_str * ws * left_paren * rhs_str * right_paren
            else
                return left_paren * lhs_str * right_paren * ws * op_str * ws * rhs_str
            end
        end
    end

end

function __to_string_constant_op_composite_expression(ex::SymbolicExpression)
    op  = string(ex.head)
    lhs = ex.args[1]
    rhs = ex.args[2]

    if is_constant(lhs) || is_variable(lhs)
        return __to_string_constant_op_composite_expression_constvarleft(ex)
    end

    if is_constant(rhs) || is_variable(rhs)
        return __to_string_constant_op_composite_expression_constvarright(ex)
    end

#=
    op  = string(ex.head)
    lhs = ex.args[1]
    rhs = ex.args[2]

    always_paren = is_power_operator(ex.head)
    rather_paren = is_composite_expression(lhs) || is_composite_expression(rhs) 
    do_paren     = always_paren | rather_paren
    left_paren   = do_paren ? "(" : ""
    right_paren  = do_paren ? ")" : ""
    ws           = is_power_operator(ex.head) ? "" : " "

    lhs_str   = to_string(lhs)
    rhs_str   = to_string(rhs)

    if is_constant(lhs) || is_variable(lhs)
        total_str = lhs_str * ws * op * ws * left_paren * rhs_str * right_paren
    end

    if is_constant(rhs) || is_variable(rhs)
        total_str = left_paren * lhs_str * right_paren * ws * op * ws * rhs_str
    end

    return total_str
=#
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




function __to_string_comp_plus_comp(ex)
    op        = string(ex.head)
    lhs       = ex.args[1]
    rhs       = ex.args[2]
    lhs_str   = to_string(lhs)
    rhs_str   = to_string(rhs)
    ws        = " "

    total_str = lhs_str * ws * op * ws * rhs_str

    return total_str
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





include("is_operators.jl")

end # module





module stest
using ..symbolics


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