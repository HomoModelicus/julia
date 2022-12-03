


# Nullable / StdOptional
# https://discourse.julialang.org/t/nullable-fields-current-recommendation/11258/12
# https://docs.juliahub.com/Nullables/h0jn0/1.0.0/autodocs/#
# https://docs.julialang.org/en/v1/base/base/#Base.Some
# https://docs.julialang.org/en/v1/manual/faq/#faq-nothing 

# Nullable -> check what it did in the past https://github.com/JuliaLang/julia/issues/22682
# Union{T, Nothing} for Optional?
# Optional -> look at the C++ implementation

# optional - can be implemented by basically a pair<value, bool>; Maybe in Haskell

# =========================================================================== #
# - StdOptional
# =========================================================================== #

# operations on a pair
# - eltype
# - convert
# - promote_rule
#
# - hash
# 
# - ==
# - isequal
# - isless
#
# operator*, operator->
# has_value
# value
# value_or
# and_then
# transform -> same as and_then and convert
# or_else
# reset



struct BadOptionalAccess <: Exception end

"""
StdOptional{T}
something or nothing
"""
struct StdOptional{T}
    engaged::Bool
    value::T

    function StdOptional{T}(value::T) where {T}
        return new(true, value)
    end
    
    function StdOptional{T}(bool::Bool, value::T) where {T}
        return new(bool, value)
    end
    
    function StdOptional{T}() where {T}
        return new(false)
    end

    function StdOptional(value::T) where {T}
        return StdOptional{T}(value)
    end

    function StdOptional(bool::Bool, value::T) where {T}
        return StdOptional{T}(bool, value)
    end

end

function make_optional(value::T) where {T}
    return StdOptional{T}(value)
end

function make_optional(::Type{T}) where {T}
    return StdOptional{T}()
end


function Base.eltype(opt::StdOptional{T}) where {T}
    return T
end

function Base.eltype(::Type{StdOptional{T}}) where {T}
    return T
end

function has_value(opt::StdOptional{T}) where {T}
    return opt.engaged
end

function unsafe_value(opt::StdOptional)
    return opt.value
end

function value(opt::StdOptional)
    if has_value(opt)
        return unsafe_value(opt)
    else
        throw( BadOptionalAccess() )
    end 
end

function Base.:(==)(opt1::StdOptional, opt2::StdOptional)
    return ifelse(  has_value(opt1) & has_value(opt2),
                    opt1.value == opt2.value,
                    false)
end

function Base.isequal(opt1::StdOptional, opt2::StdOptional)
    return ifelse(  has_value(opt1) & has_value(opt2),
                    isequal(opt1.value, opt2.value),
                    false)
end

function Base.isless(opt1::StdOptional, opt2::StdOptional)
    return ifelse(  has_value(opt1) & has_value(opt2),
                    isless(opt1.value, opt2.value),
                    false)
end

function Base.convert(::Type{StdOptional{T}}, opt::StdOptional{T} ) where {T}
    return opt
end

function Base.convert(::Type{StdOptional{U}}, opt::StdOptional{T} ) where {U, T}
    return StdOptional( convert(U, opt.value) )
end

function Base.promote_rule(::Type{StdOptional{U}}, ::Type{StdOptional{T}} ) where {U, T}
    S = promote_type(U, T)
    return StdOptional{S}
end

function reset(opt::StdOptional{T}) where {T}
    return StdOptional{T}()
end

function Base.hash(opt::StdOptional, h::UInt)
    return ifelse( has_value(opt), hash(opt.value, h), h )
end

function value_or(opt::StdOptional, default)
    if has_value(opt)
        return opt.value
    else
        return default
    end
end

function Base.get(opt::StdOptional, default)
    return value_or(opt, default)
end

function and_then(opt::StdOptional{T}, f::F) where {T, F <: Function}
    if has_value(opt)
        return f(opt.value)
    else
        return opt
    end
end

function Base.:(|>)(opt::StdOptional, f::F) where {F <: Function}
    return and_then(opt, f)
end

function or_else(opt::StdOptional{T}, f::F) where {T, F <: Function}
    if has_value(opt)
        return opt
    else
        return f()
    end
end



# =========================================================================== #
# - Nullable
# =========================================================================== #

# sizeof Nullable{Int} is still 16
# it seems to me, this is the same as [ptr | value] where ptr points to the DataType
# but basically to me at least, it seems that there is not much difference between 
# Nullable{T} and StdOptional{T}

struct Nullable{T}
    value::Union{T, Nothing}

    function Nullable{T}(value::T) where {T}
        return new(value)
    end

    function Nullable(value::T) where {T}
        return Nullable{T}(value)
    end

    function Nullable{T}() where {T}
        return new(nothing)
    end

end






