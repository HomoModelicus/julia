
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

function SymbolicExpression(x::Constant)
    return SymbolicExpression(:+, x)
end

function SymbolicExpression(x::Variable)
    return SymbolicExpression(:+, x)
end


for op in (:+, :-, :/, :*, :^)
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

for op in (:-, :/, :^) # (:+, :-, :/, :*, :^)
    @eval function Base.$(op)(
        x::Tx, y::Ty) where {
            Tx <: Union{Constant, Variable, SymbolicExpression},
            Ty <: Union{Constant, Variable, SymbolicExpression}}
            
        ex = SymbolicExpression(Symbol(Base.$op), x, y)
        return ex
    end
end

for op in (:+, :*)
    @eval function Base.$(op)(
        x::Tx, y::Ty) where {
            Tx <: Union{Variable, Constant},
            Ty <: Union{Variable, Constant}}
            
        ex = SymbolicExpression(Symbol(Base.$op), x, y)
        return ex
    end
end

for op in (:+, :*, :-, :/, :^)
    @eval function Base.$(op)(
        x::Tx, y::Ty) where {
            Tx <: Constant,
            Ty <: Constant}
        
        ee = Expr(:call, $(op), x.value, y.value)
        val = eval(ee)
        ex = Constant( val )
        # ex = SymbolicExpression(Symbol(Base.$op), x, y)
        return ex
    end
end


function Base.:(+)(
    x::Tx, y::Ty) where {
        Tx <: Union{Constant, Variable},
        Ty <: SymbolicExpression}
    if is_plus_operator(y.head)
        ex = SymbolicExpression(:+, x, y.args...)
    else
        ex = SymbolicExpression(:+, x, y)
    end
    return ex
end
function Base.:(+)(
    x::Tx, y::Ty) where {
        Tx <: SymbolicExpression,
        Ty <: Union{Constant, Variable}}
    if is_plus_operator(x.head)
        ex = SymbolicExpression(:+, x.args..., y)
    else
        ex = SymbolicExpression(:+, x, y)
    end
    return ex
end
function Base.:(+)(
    x::Tx, y::Ty) where {
        Tx <: SymbolicExpression,
        Ty <: SymbolicExpression}
    if is_plus_operator(x.head) && is_plus_operator(y.head)
        ex = SymbolicExpression(:+, x.args..., y.args...)
    else
        ex = SymbolicExpression(:+, x, y)
    end
    return ex
end

function Base.:(*)(
    x::Tx, y::Ty) where {
        Tx <: Union{Constant, Variable},
        Ty <: SymbolicExpression}
    if is_product_operator(y.head)
        ex = SymbolicExpression(:*, x, y.args...)
    else
        ex = SymbolicExpression(:*, x, y)
    end
    return ex
end
function Base.:(*)(
    x::Tx, y::Ty) where {
        Tx <: SymbolicExpression,
        Ty <: Union{Constant, Variable}}
    if is_product_operator(x.head)
        ex = SymbolicExpression(:*, x.args..., y)
    else
        ex = SymbolicExpression(:*, x, y)
    end
    return ex
end
function Base.:(*)(
    x::Tx, y::Ty) where {
        Tx <: SymbolicExpression,
        Ty <: SymbolicExpression}
    if is_product_operator(x.head) && is_product_operator(y.head)
        ex = SymbolicExpression(:*, x.args..., y.args...)
    else
        ex = SymbolicExpression(:*, x, y)
    end
    return ex
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

for op in (:sqrt, :cbrt, :exp, :log, :log2, :log10, :sin, :cos, :tan, :abs, :sign)
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

function evaluate(ex::A) where {A <: AbstractArray}
    s = similar(ex)
    for ii in eachindex(ex)
        s[ii] = evaluate(ex[ii])
    end

    return s
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



function clone(ex::SymbolicExpression)
    head = ex.head
    L    = length(ex.args)

    cloned_args = Vector{Any}(undef, L)

    for ii = 1:L
        cloned_args[ii] = clone(ex.args[ii])
    end
    y = SymbolicExpression(head, cloned_args...)
    
    # if L == 1
    #     cloned_arg = clone(ex.args[1])
    #     y = SymbolicExpression(head, cloned_arg)
    # elseif L == 2
    #     cloned_lhs = clone(ex.args[1])
    #     cloned_rhs = clone(ex.args[2])
    #     y = SymbolicExpression(head, cloned_lhs, cloned_rhs)
    # else
    #     error("something went wrong")
    # end

    return y
end





