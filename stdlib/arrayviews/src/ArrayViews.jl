


module ArrayViews

export  AbstractView,
        make_next_view,
        make_zero_view,
        #
        ArrayPointer,
        ArrayView,
        #
        PtrArrayView
        


# =========================================================================== #
# ArrayPointer
# =========================================================================== #

struct ArrayPointer{A}
    ptr::A
    index::Int

    function ArrayPointer{A}(array::A, index = firstindex(array)) where {A <: AbstractArray}
        return new(vec, index)
    end

    function ArrayPointer(array::A, index = firstindex(array)) where {A <: AbstractArray}
        return ArrayPointer{A}(array, index)
    end

    function ArrayPointer(ptr::ArrayPointer, new_index::Int)
        return ArrayPointer(ptr.ptr, new_index)
    end
end

function Base.eltype(array_ptr::ArrayPointer)
    return eltype(array_ptr.ptr)
end

function Base.length(array_ptr::ArrayPointer)
    return length(array_ptr.ptr)
end

function Base.size(array_ptr::ArrayPointer)
    return size(array_ptr.ptr)
end


function Base.getindex(array_ptr::ArrayPointer)
    return array_ptr.ptr[array_ptr.index]
end

function Base.getindex(array_ptr::ArrayPointer, index::Int)
    return array_ptr.ptr[index]
end

function Base.:(+)(array_ptr::ArrayPointer, rhs::Int)
    return ArrayPointer(array_ptr, array_ptr.index + rhs)
end

function Base.:(-)(array_ptr::ArrayPointer, rhs::Int)
    return ArrayPointer(array_ptr, array_ptr.index - rhs)
end







# =========================================================================== #
# ArrayView
# =========================================================================== #

abstract type AbstractView{T} <: AbstractArray{T, 1}
end


function make_next_view(array_view::AV, first_increment::Int = 1) where {AV <: AbstractView}
    new_view = AV(array_view, first_increment)
    return new_view
end

function make_zero_view(array_view::AV) where {AV <: AbstractView}
    return AV(array_view.ptr, 0, 0)
end





const __array_type        = Vector{Int}
const __zero_length_array = Vector{Int}(undef, 0)

struct ArrayView{A} <: AbstractView{A}
    ptr::A
    first::Int
    last::Int

    function ArrayView{A}(
        array::A,
        first = firstindex(array),
        last = lastindex(array)) where {A <: AbstractArray}

        return new(array, first, last)
    end

    function ArrayView(
        array::A,
        first::Int = firstindex(array),
        last::Int = lastindex(array)) where {A <: AbstractArray}
        return ArrayView{A}(array, first, last)
    end

    function ArrayView{T}(
        array_view::ArrayView{T},
        first::Int,
        last::Int) where {T}

        return ArrayView(array_view.ptr, first, last)
    end


    function ArrayView()
        return ArrayView{__array_type}(__zero_length_array, 0, 0)
    end

    function ArrayView(array_view::ArrayView, first_increment::Int = 1)
        return ArrayView(array_view.ptr, array_view.first + first_increment, array_view.last)
    end

    function ArrayView(array_view::ArrayView, first::Int, last::Int)
        return ArrayView(array_view.ptr, first, last)
    end

    function ArrayView(first::ArrayPointer, last::ArrayPointer)
        return ArrayView(first.ptr, first.index, last.index)
    end
end

function Base.eltype(array_view::ArrayView{T}) where {T}
    return T
end

function Base.length(array_view::ArrayView)
    return array_view.last - array_view.first + 1
end

function Base.size(array_view::ArrayView)
    return (length(array_view), )
end

function Base.firstindex(array_view::ArrayView)
    # array_view.first
    return 1 
end

function Base.lastindex(array_view::ArrayView)
    # array_view.last
    return array_view.last - array_view.first + 1
end

function Base.IndexStyle(::Type{ArrayView})
    return IndexLinear()
end

function Base.IndexStyle(array_view::ArrayView)
    return IndexStyle(ArrayView)
end

function Base.getindex(array_view::ArrayView, index::Int)
    return array_view.ptr[index - 1 + array_view.first]
end


function Base.:(+)(array_view::ArrayView, index::Int)
    next_first = array_view.first + index
    return ArrayView(array_view.ptr, next_first, array_view.last)
end

function Base.:(-)(array_view::ArrayView, index::Int)
    next_first = array_view.first - index
    return ArrayView(array_view.ptr, next_first, array_view.last)
end





# =========================================================================== #
# PtrArrayView
# =========================================================================== #

struct PtrArrayView{T} <: AbstractView{T}
    ptr::Ptr{T}
    first::Int
    last::Int

    function PtrArrayView{T}(
        array::AbstractArray{T, 1},
        first = firstindex(array),
        last = lastindex(array)) where {T}

        ptr = pointer(array)
        return new(ptr, first, last)
    end

    function PtrArrayView(
        array::AbstractArray{T, 1},
        first = firstindex(array),
        last = lastindex(array)) where {T}

        return PtrArrayView{A}(array, first, last)
    end

    function PtrArrayView{T}(ptr::Ptr{T}, first, last) where {T}
        return new(ptr, first, last)
    end

    function PtrArrayView()
        def_ptr = Ptr{Nothing}()
        return PtrArrayView{Nothing}(def_ptr, 0, 0)
    end

    function ArrayView(array_view::PtrArrayView, first, last)
        return PtrArrayView(array_view.ptr, first, last)
    end

    function PtrArrayView(ptrarray_view::PtrArrayView, first_increment::Int = 1)
        return PtrArrayView(
            ptrarray_view.ptr, 
            ptrarray_view.first + first_increment,
            ptrarray_view.last)
    end

    function PtrArrayView(first::ArrayPointer, last::ArrayPointer)
        return PtrArrayView(first.ptr, first.index, last.index)
    end

    # this constructor somehow doesnt work
    # function PtrArrayView(array_view::ArrayView{A}) where {A}
    #     return PtrArrayView(array_view.ptr, array_view.first, array_view.last)
    # end
end


function Base.eltype(ptrarray_view::PtrArrayView{T}) where {T}
    return T
end

function Base.length(ptrarray_view::PtrArrayView)
    return ptrarray_view.last - ptrarray_view.first + 1
end

function Base.size(ptrarray_view::PtrArrayView)
    return (length(ptrarray_view), )
end

function Base.firstindex(array_view::PtrArrayView)
    # array_view.first
    return 1 
end

function Base.lastindex(array_view::PtrArrayView)
    # array_view.last
    return array_view.last - array_view.first + 1
end

function Base.IndexStyle(::Type{PtrArrayView})
    return IndexLinear()
end

function Base.IndexStyle(ptrarray_view::PtrArrayView)
    return IndexStyle(PtrArrayView)
end

function Base.getindex(ptrarray_view::PtrArrayView, index::Int)
    global_index = index - 1 + ptrarray_view.first
    return unsafe_load(global_index, global_index)
end




function Base.:(+)(array_view::PtrArrayView, index::Int)
    next_first = array_view.first + index
    return PtrArrayView(array_view.ptr, next_first, array_view.last)
end

function Base.:(-)(array_view::PtrArrayView, index::Int)
    next_first = array_view.first - index
    return PtrArrayView(array_view.ptr, next_first, array_view.last)
end



end # module



