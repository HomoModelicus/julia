




# Either type - either A or B, but never null
# https://github.com/MasonProtter/SumTypes.jl
# one noteworthy idea is: @match macro for cases
# pattern matching on the different types
# automatic detection of being exhaustive! - Rust like feature
# expected - value or error; most likely very similar to optional; Result in Rust, Either in Haskell

struct StdUnexpected{T}
    value::T
    
    function StdUnexpected{T}(value::T) where {T}
        return new(value)
    end
    function StdUnexpected(value::T) where {T}
        return StdUnexpected{T}(value)
    end
end

function make_unexpected(value::T) where {T}
    return StdUnexpected{T}(value)
end


struct StdExpected{T, E}
    expected::Bool
    value::Union{T, E}

    function StdExpected{T, E}(value::U) where {T, E, U <: Union{T, E}}
        expected = typeof(value) == T ? true : false
        return new(expected, value)
    end
end

function make_expected(::Type{T}, ::Type{E}, value) where {T, E}
    return StdExpected{T, E}(value)
end

function Base.eltype(expected::StdExpected{T}) where {T}
    return T
end

function Base.eltype(::Type{StdExpected{T}}) where {T}
    return T
end

function has_value(expected::StdExpected)
    return expected.expected
end

function unsafe_value(expected::StdExpected)
    return expected.value
end

function value_or(expected::StdExpected, default)
    if has_value(expected)
        return expected.value
    else
        return default
    end
end

function Base.get(expected::StdExpected, default)
    return value_or(expected, default)
end






# my additions

function value(expected::StdExpected)
    return expected.value
end

function and_then(expected::StdExpected, f::Function)
    if has_value(expected)
        return f(expected.value)
    else
        return expected
    end
end


function expected_or(expected::StdExpected, default)
    if has_value(expected)
        return expected
    else
        return default
    end
end







