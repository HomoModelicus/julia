
module Scalars

export  Zero,
        One


struct Zero{T}
    value::T

    function Zero{T}() where {T}
        return new(zero(T))
    end

    function Zero(::Type{T}) where {T}
        return Zero{T}()
    end
end

function Base.getindex(obj::Zero, index::Int)
    return obj.value
end

function Base.getindex(obj::Zero, I::Vararg{Int, N}) where {N}
    return ntuple( i -> obj.value, N)
end




struct One{T}
    value::T

    function One{T}() where {T}
        return new(one(T))
    end

    function One(::Type{T}) where {T}
        return One{T}()
    end
end

function Base.getindex(obj::One, idx::Int)
    return obj.value
end

function Base.getindex(obj::One, I::Vararg{Int, N}) where {N}
    return ntuple( i -> obj.value, N)
end

end # module