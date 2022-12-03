

module SmallArrays

export  SmallArray,
        make_array,
        MutableSmallArray,
        make_mutable_array,
        Vec2,
        Vec3



# Sequence containers
# std::array, std::vector - how to automatically add a block of memory to the GC?
# 
# immutable fixed size array
# no modification after creation in normal circumstances
# in case of if the object is heap allocated, unsafe_load and unsafe_store! can be used


# mutable fixed size array
# this object is heap allocated, but its content is stored inside this object
# because this object lives on the heap, it has stable memory address -> 
# pointer arithmetic, unsafe_load and unsafe_store! can be used to modify its elements



# std::vector is basically a stack implementation, but a simpler alternative is 
# just using the built-in Vector{T}
# const StdVector{T} = Vector{T}






# mutable fixed sized array
# - heap allocated, 
# - with NTuple
# - can be in-place modified due to its having a stable memory address
# - get a pointer, unsafe_load and unsafe_store would work
#
# immutable fixed sized array - size should be small to be efficient
# - making an NTuple, in case of modification -> create a new small array







# basically there is no good way to get where data begins in a Vector

# container must be mutable object with stable memory address
# but generally these two functions are rather sus
function unsafe_getindex(container::AbstractArray{T, 1}, index::Int) where {T}
    ptr = pointer_from_objref(container)
    ptr = convert(Ptr{T}, ptr)
    unsafe_array_offset = 48
    return unsafe_load(ptr + unsafe_array_offset, index)
end

function unsafe_setindex!(container::AbstractArray{T, 1}, value::T, index::Int) where {T}
    ptr = pointer_from_objref(container)
    ptr = convert(Ptr{T}, ptr)
    unsafe_array_offset = 48
    unsafe_store!(ptr + unsafe_array_offset, value, index)
    return container
end



# =========================================================================== #
# Immutable Fixed Size Array
# =========================================================================== #



struct SmallArray{T, N} <: AbstractArray{T, 1}
    value::NTuple{N, T}

    function SmallArray{T, N}(value::NTuple{N, T}) where {T, N}
        return new(value)
    end

    function SmallArray(value::NTuple{N, T}) where {T, N}
        return SmallArray{T, N}(value)
    end

    function SmallArray{T, N}(value::Vector{T}) where {T, N}
        return SmallArray{T, N}( tuple(value[1:N]...) )
    end

    function SmallArray{T, N}(x::Vararg{T, N}) where {T, N}
        return new(x)
    end
end

function make_array(value::Vector{T}) where {T}
    N = length(value)
    return SmallArray{T, N}(value)
end

function make_array(x::Vararg{T, N}) where {T, N}
    return SmallArray{T, N}(x)
end


function Base.length(array::SmallArray{T, N}) where {T, N}
    return N
end

function Base.size(array::SmallArray{T, N}) where {T, N}
    return (N, )
end

function Base.getindex(array::SmallArray{T, N}, index::Int) where {T, N}
    return array.value[index]
end

function Base.IndexStyle(array::SmallArray)
    return IndexStyle(typeof(array))
end

function Base.IndexStyle(::Type{SmallArray})
    return IndexLinear()
end

function Base.firstindex(array::SmallArray{T, N}) where {T, N}
    return 1
end

function Base.lastindex(array::SmallArray{T, N}) where {T, N}
    return N
end

function set_at_index(array::SmallArray{T, N}, value::T, index::Int) where {T, N}
    tmp = ( array.value[1:index-1]..., value, array.value[index+1:end]... )
    return SmallArray{T, N}(tmp)
end





const Vec2{T} = SmallArray{T, 2} where T

function Vec2{T}(x1::T, x2::T) where {T}
    make_array((x1, x2))
end

function Vec2(x1::T, x2::T) where {T}
    make_array((x1, x2))
end

function Vec2(t::NTuple{2, T}) where {T}
    make_array(t)
end

function Vec2(v::Vector{T}) where {T}
    make_array(v)
end



const Vec3{T} = SmallArray{T, 3} where T

function Vec3{T}(x1::T, x2::T, x3::T) where {T}
    make_array((x1, x2, x3))
end

function Vec3(x1::T, x2::T, x3::T) where {T}
    make_array((x1, x2, x3))
end

function Vec3(t::NTuple{3, T}) where {T}
    make_array(t)
end

function Vec3(v::Vector{T}) where {T}
    make_array(v)
end










#=
struct SmallMatrix{T, Nrow, Ncol, N} <: AbstractArray{T, 2}
    value::NTuple{N, T}

    function SmallMatrix{T, N, Nrow, Ncol}(value::NTuple{N, T}) where {T, N, Nrow, Ncol}
        return new(value)
    end

    # function SmallMatrix(value::NTuple{N, T}) where {T, N}
    #     return SmallArray{T, N}(value)
    # end

    # function SmallMatrix{T, N}(value::Vector{T}) where {T, N}
    #     return SmallArray{T, N}( tuple(value[1:N]...) )
    # end

    # function SmallMatrix{T, N}(x::Vararg{T, N}) where {T, N}
    #     return new(x)
    # end
end

function make_matrix(value::Vector{T}) where {T}
    N = length(value)
    return SmallArray{T, N}(value)
end

# function make_array(x::Vararg{T, N}) where {T, N}
#     return SmallArray{T, N}(x)
# end


function Base.length(array::SmallMatrix{T, Nrow, Ncol}) where {T, Nrow, Ncol}
    return Nrow * Ncol
end

function Base.size(array::SmallMatrix{T, Nrow, Ncol}) where {T, Nrow, Ncol}
    return (Nrow, Ncol)
end

function Base.size(array::SmallMatrix{T, Nrow, Ncol}, dim) where {T, Nrow, Ncol}
    if dim == 1
        return Nrow
    elseif dim == 2
        return Ncol
    else
        return 1
    end
end

function Base.getindex(array::SmallMatrix{T, Nrow, Ncol}, index::Int) where {T, Nrow, Ncol}
    return array.value[index]
end

function Base.getindex(array::SmallMatrix{T, Nrow, Ncol}, indextuple::Vararg{Int, 2}) where {T, Nrow, Ncol}
    row = indextuple[1]
    col = indextuple[2]
    index = (col - 1) * Nrow + row
    return array.value[index]
end

function Base.IndexStyle(array::SmallMatrix)
    return IndexStyle(typeof(array))
end

function Base.IndexStyle(::Type{SmallMatrix})
    return IndexLinear()
end

function Base.firstindex(array::SmallMatrix{T, Nrow, Ncol}) where {T, Nrow, Ncol}
    return 1
end

function Base.lastindex(array::SmallMatrix{T, Nrow, Ncol}) where {T, Nrow, Ncol}
    return Nrow * Ncol
end

function set_at_index(array::SmallMatrix{T, Nrow, Ncol}, value::T, index::Int) where {T, Nrow, Ncol}
    tmp = ( array.value[1:index-1]..., value, array.value[index+1:end]... )
    return SmallMatrix{T, Nrow, Ncol}(tmp)
end
=#

# =========================================================================== #
# Mutable Fixed Size Array
# =========================================================================== #


mutable struct MutableSmallArray{T, N} <: AbstractArray{T, 1}
    value::NTuple{N, T}


    function MutableSmallArray{T, N}(value::NTuple{N, T}) where {T, N}
        return new(value)
    end

    function MutableSmallArray(value::NTuple{N, T}) where {T, N}
        return MutableSmallArray{T, N}(value)
    end

    function MutableSmallArray{T, N}(value::Vector{T}) where {T, N}
        return MutableSmallArray{T, N}( tuple(value[1:N]...) )
    end

    function MutableSmallArray{T, N}(x::Vararg{T, N}) where {T, N}
        return new(x)
    end
end

function make_mutable_array(value::Vector{T}) where {T}
    N = length(value)
    return MutableSmallArray{T, N}(value)
end

function make_mutable_array(x::Vararg{T, N}) where {T, N}
    return MutableSmallArray{T, N}(x)
end

function Base.size(array::MutableSmallArray{T, N}) where {T, N}
    return (N, )
end

function Base.getindex(array::MutableSmallArray{T, N}, index::Int) where {T, N}
    return array.value[index]
end

# no Base.setindex!, but only unsafe_setindex!

function pointer(array::MutableSmallArray{T, N}) where {T, N}
    return convert(Ptr{T}, pointer_from_objref(array))
end

function unsafe_getindex(array::MutableSmallArray, index::Int)
    ptr = pointer(array)
    return unsafe_load(ptr, index)
end

function unsafe_setindex!(array::MutableSmallArray{T, N}, value::T, index::Int) where {T, N}
    ptr = pointer(array)
    unsafe_store!(ptr, value, index)
    return array
end

function Base.IndexStyle(array::MutableSmallArray)
    return IndexStyle(typeof(array))
end

function Base.IndexStyle(::Type{MutableSmallArray})
    return IndexLinear()
end

function Base.length(array::MutableSmallArray{T, N}) where {T, N}
    return N
end

function Base.similar(array::MutableSmallArray{T, N}, ::Type{S}, dims::Dims) where {T, N, S}
    new_array = MutableSmallArray{S, dims[1]}( convert(S, array.value[1:dims[1]] ) )
    return new_array
end

function Base.firstindex(array::MutableSmallArray{T, N}) where {T, N}
    return 1
end

function Base.lastindex(array::MutableSmallArray{T, N}) where {T, N}
    return N
end


end # module



