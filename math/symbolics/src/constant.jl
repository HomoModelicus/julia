
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

function evaluate(x::A) where {A <: AbstractArray{<: Constant}}
    s = similar(x)
    for ii in eachindex(x)
        s[ii] = x[ii].value
    end
    return s
end


function to_string(x::Constant)
    return string(x.value)
end

function clone(x::Constant)
    y = x
    return y
end



function is_zero_constant(x, tol = 1e-30)
    return false
end

function is_one_constant(x, tol = 1e-30)
    return false
end

function is_zero_constant(x::Constant, tol = 1e-30)
    return abs(x.value) <= tol
end

function is_one_constant(x::Constant, tol = 1e-30)
    tmp = x.value - one(typeof(x.value))
    return abs(tmp) <= tol
end
