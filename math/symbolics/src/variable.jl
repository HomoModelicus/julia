
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

function evaluate(x::A) where {A <: AbstractArray{<: Variable}}
    s = similar(x)
    for ii in eachindex(x)
        s[ii] = x[ii].value
    end
    return s
end

function to_string(x::Variable)
    return x.name
end

function clone(x::Variable)
    y = Variable(x.name, x.value)
    return y
end


