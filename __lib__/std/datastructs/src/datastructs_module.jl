

# dependencies:
# - none

module datastructs

include("error_handling.jl")
include("stack.jl")
include("queue.jl")
include("linked_list.jl")
include("binary_tree.jl")
include("red_black_tree.jl")

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



export Stack, MatrixStack


end # datastructs
