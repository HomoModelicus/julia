
struct Zero{T}
    _val::T
    function Zero{T}() where {T}
        return new(zero(T))
    end
end

function Base.getindex(obj::Zero, idx::Int)
    return obj._val
end

function Base.getindex(obj::Zero, I::Vararg{Int, N}) where {N}
    return ntuple( i -> obj._val, N)
end

struct One{T}
    _val::T
    function One{T}() where {T}
        return new(one(T))
    end
end

function Base.getindex(obj::Zero, idx::Int)
    return obj._val
end



