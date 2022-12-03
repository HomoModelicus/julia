

module Rawmemories


"""
    StdPtr{T}
    a small unsafe ptr abstraction for
        - getting the pointed object
        - setting the pointed object
    both are unsafe operations
"""
struct StdPtr{T}
    data::Ptr{T}

    function StdPtr{T}(data::Ptr{T}) where {T}
        return new(data)
    end
    
    function StdPtr(data::Ptr{T}) where {T}
        return StdPtr{T}(data)
    end
end

function Base.getindex(ptr::StdPtr{T}) where {T}
    return unsafe_load(ptr.data)
end

function unsafe_set!(ptr::StdPtr{T}, x) where {T}
    return unsafe_store!(ptr.data, x)
end






# alignment?
# in case of the vector, no padding between elements
# but of course, if the elements are structs, 
# the fields might not be contiguously arranged
#
# maybe throw an error?
# if voidptr == C_NULL
#     error("Allocation failed")
# end
mutable struct MemoryAllocator{T}

    data::Ptr{T}
    n_elements::Int

    function MemoryAllocator{T}(n_elements::Int) where {T}
        sz      = sizeof(T)
        n_bytes = n_elements * sz
        obj     = new()
        finalizer(memory_allocator_finalizer, obj)

        voidptr        = Libc.malloc(n_bytes)
        tptr           = convert(Ptr{T}, voidptr)
        obj.data       = tptr
        obj.n_elements = n_elements
        return obj
    end
end

function memory_allocator_finalizer(memallocator::MemoryAllocator)
    @async println("Finalizing the memory allocator with ptr: $(mema.data)")
    Libc.free(memallocator.data)
    memallocator.data       = C_NULL
    memallocator.n_elements = 0
end

function Base.eltype(::MemoryAllocator{T}) where {T}
    return T
end

function type_size(::MemoryAllocator{T}) where {T}
    return sizeof(T)
end

function n_bytes(mema::MemoryAllocator{T}) where {T}
    return mema.n_elements * type_size(mema)
end

function zeros!(mema::MemoryAllocator{T}) where {T}
    _0         = zero(UInt8)
    size_bytes = n_bytes(mema)
    outptr     = ccall(:memset, Ptr{Cvoid}, (Ptr{Cvoid}, Cint, Csize_t), mema.data, _0, size_bytes)
    return outptr
end

function ones!(mema::MemoryAllocator{T}) where {T}
    _1 = one(T)
    for ii in 1:mema.n_elements
        unsafe_store!(mema.data, _1, ii)
    end
    return mema.ptr
end

function make_owning_array(mema::MemoryAllocator{T}) where {T}
    array = unsafe_wrap(Vector{Int}, mema.data, (mema.n_elements,); own = true)
    finalize(mema)
    return array
end

function make_nonowning_array(mema::MemoryAllocator{T}) where {T}
    array = unsafe_wrap(Vector{Int}, mema.data, (mema.n_elements,); own = false)
    return array
end

function at(mema::MemoryAllocator{T}, index::Int) where {T}
    return unsafe_load(mema.data, index)
end

function Base.getindex(mema::MemoryAllocator{T}, index::Int) where {T}
    return at(mema, index)
end

function beginptr(mema::MemoryAllocator{T}) where {T}
    return mema.data
end

function endptr(mema::MemoryAllocator{T}) where {T}
    return mema.data + sizeof(T) * mema.n_elements
end

function endptrincl(mema::MemoryAllocator{T}) where {T}
    return mema.data + sizeof(T) * (mema.n_elements - 1)
end










abstract type AbstractStdRange end

struct PtrRange{T} # <: AbstractArray{T, 1} # AbstractStdRange
    beginptr::Ptr{T}
    endptr::Ptr{T}
    
    function PtrRange{T}(beginptr::Ptr{T}, endptr::Ptr{T}) where {T}
        return new(beginptr, endptr)
    end
end

function PtrRange{T}(mema::MemoryAllocator{T}) where {T}
    bptr = beginptr(mema)
    eptr = endptrincl(mema)
    return PtrRange{T}(bptr, eptr)
end

function PtrRange(beginptr::Ptr{T}, endptr::Ptr{T}) where {T}
    return PtrRange{T}(beginptr, endptr)
end

function PtrRange(mema::MemoryAllocator{T}) where {T}
    return PtrRange{T}(mema)
end

function Base.length(ptrrange::PtrRange{T}) where {T}
    ptrdifft = convert(Int, ptrrange.endptr) - convert(Int, ptrrange.beginptr)
    return div(ptrdifft, sizeof(T)) - 1
end

function Base.size(ptrrange::PtrRange{T}) where {T}
    return length(ptrrange,)
end

function Base.IndexStyle(::Type{PtrRange{T}}) where {T}
    return IndexLinear()
end

function Base.IndexStyle(ptrrange::PtrRange{T}) where {T}
    return IndexLinear()
end

function Base.getindex(ptrrange::PtrRange{T}, index::Int) where {T}
    return unsafe_load(ptrrange.beginptr, index)
end

function nextptr(ptrrange::PtrRange{T}, index) where {T}
    return ptrrange.beginptr + sizeof(T) * (index - 1)
end

function nexttobeginptr(ptrrange::PtrRange{T}) where {T}
    return ptrrange.beginptr + sizeof(T)
end

function Base.show(io::IO, mime::MIME{Symbol("text/plain")}, ptrrange::PtrRange{T}) where {T}
    println("PtrRange{$(T)} with properties:")
    println("   beginptr: $(ptrrange.beginptr)")
    println("     endptr: $(ptrrange.endptr)")
end

function Base.iterate(ptrrange::PtrRange{T}, state = 1) where {T}
    next = nextptr(ptrrange, state)
    if next >= ptrrange.endptr
        return nothing
    else
        return (next, state + 1)
    end 
end



end # module
