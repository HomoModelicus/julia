
# module stdpair


# =========================================================================== #
# - StdPair
# =========================================================================== #
# - make_pair




# operations on a pair
# - eltype
# - iterate
# - indexed_iterate
# - getindex with Int, with Real
# - reverse
# - firstindex, lastindex
# - length
# - first
# - last
# - convert
# - promote_rule
#
# - hash
# 
# - ==
# - isequal
# - isless

struct StdPair{T1, T2}
    first::T1
    second::T2

    function StdPair{T1, T2}(a::T1, b::T2) where {T1, T2}
        return new(a, b)
    end

    function StdPair(a::T1, b::T2) where {T1, T2}
        return StdPair{T1, T2}(a, b)
    end
end

function Base.Pair(p::StdPair{T1, T2}) where {T1, T2}
    return Pair{T1, T2}(p.first, p.second)
end

function make_pair(a::T1, b::T2) where {T1, T2}
    return StdPair(a, b)
end

function Base.eltype(::StdPair{T1, T2}) where {T1, T2}
    return Union{T1, T2}
end

function Base.getindex(p::StdPair{T1, T2}, index::Int) where {T1, T2}
    return getfield(p, index)
end

function Base.getindex(p::StdPair{T1, T2}, index) where {T1, T2}
    return getfield(p, convert(Int, index))
end

function Base.reverse(p::StdPair{T1, T2}) where {T1, T2}
    return StdPair{T2, T1}(p.second, p.first)
end

function Base.firstindex(p::StdPair)
    return 1
end

function Base.lastindex(p::StdPair)
    return 2
end

function Base.length(p::StdPair)
    return 2
end

function Base.first(p::StdPair)
    return p.first
end

function Base.last(p::StdPair)
    return p.second
end

function Base.convert(::Type{ StdPair{U1, U2} } , p::StdPair{T1, T2}) where {U1, U2, T1, T2}
    return StdPair( convert(U1, p.first), convert(U2, p.second) )
end

function Base.promote_rule(::Type{ StdPair{U1, U2} }, ::Type{StdPair{T1, T2}} ) where {U1, U2, T1, T2}
    return StdPair{promote_type(U1, T1), promote_type(U2, T2)}
end

function Base.hash(p::StdPair, h::UInt)
    h1 = hash(p.first, h)
    h2 = hash(p.second, h1)
    return h2
end

function Base.:(==)(p1::StdPair, p2::StdPair)
    # & simple and probably even faster than short-circuit
    bool = (p1.first == p2.first) & (p1.second == p2.second)
    return bool
end

function Base.isequal(p1::StdPair, p2::StdPair)
    return isequal(p1.first, p2.first) & isequal(p1.second, p2.second)
end

function Base.isless(p1::StdPair, p2::StdPair)
    return isless(p1.first, p2.first) & isless(p1.second, p2.second)
end

# end # module 

