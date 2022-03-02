

# ============================================================================ #
# Stack
# ============================================================================ #


abstract type AbstractStack
end

mutable struct Stack{T} <: AbstractStack
    ptr::Int64 # points to the last valid element
    capacity::Int64
    data::Vector{T}

    function Stack{T}(start_size::Int) where {T}
        ptr      = 0
        capacity = start_size < 0 ? 0 : start_size
        data     = Vector{T}(undef, capacity)
        new(ptr, capacity, data)
    end
end
function Stack{T}() where {T}
    start_size = 0
    return Stack{T}(start_size)
end

function next_index(stack::S, index::Int) where {S <: AbstractStack}
    n = index + 1
    if n > stack.capacity
        n = 1
    end
    return n
end

function prev_index(stack::S, index::Int) where {S <: AbstractStack}
    n = index - 1
    if n < 1
        n = stack.capacity
    end
    return n
end

function is_capacity_reached(
    stack::S,
    index = stack.ptr) where {S <: AbstractStack}
    return stack.capacity == 0 || stack.capacity < index
end

function grow_stack!(stack::Stack{T}) where {T}
    growth_factor   = 2
    new_capa        = convert(Int, ceil(stack.capacity * growth_factor))
    stack.capacity  = stack.capacity == 0 ? 1 : new_capa
    new_data        = similar( stack.data, T, stack.capacity )
    copyto!(new_data, stack.data)
    stack.data      = new_data;
    return stack
end

function Base.push!(stack::Stack{T}, new_element::T) where {T}
    stack.ptr += 1;
    if is_capacity_reached(stack)
        grow_stack!(stack)
    end
    stack.data[stack.ptr] = new_element;
    return stack
end

function Base.pop!(stack::Stack{T})::T where {T}
    if isempty(stack)
        underflow_error("empty stack")
    end
    stack.ptr -= 1;
    return stack.data[stack.ptr+1]
end

function Base.peek(stack::Stack{T})::T where {T}
    return stack.data[stack.ptr]
end

function Base.peek(stack::Stack{T}, n::Int = 0)::T where {T}
    return stack.data[stack.ptr - n]
end

function Base.isempty(stack::S) where {S <: AbstractStack}
    return length(stack) <= 0
end

function Base.length(stack::S) where {S <: AbstractStack}
    return stack.ptr
end

function Base.size(stack::S) where {S <: AbstractStack}
    return (stack.ptr,)
end

function capacity(stack::S) where {S <: AbstractStack}
    return stack.capacity
end

function last_valid_index(stack::S) where {S <: AbstractStack}
    return stack.ptr
end


function Base.getindex(stack::Stack{T}, idx::Int) where {T}
    return stack.data[idx]
end

function Base.getindex(stack::Stack{T}, I::Vararg{Int, N}) where {T, N}
    return stack.data[I]
end

function Base.eltype(::Stack{T}) where {T}
    return T
end

function shrink_to_fit!(stack::Stack{T}) where {T}
	vec = similar(stack.data, stack.ptr)
	copyto!(vec, 1, stack.data, 1, stack.ptr)
	stack.data = vec
	stack.capacity = stack.ptr
	return stack
end

function copy(stack::Stack{T}) where {T}
    new_stack           = Stack{T}()
    new_stack.data      = copy(stack.data)
    new_stack.capacity  = stack.capacity
    new_stack.ptr       = stack.ptr
    return new_stack
end

function merge!(stack::Stack{T}, vec::AbstractArray{T}) where {T}
    L = length(vec)
    L_needed = stack.ptr + L
    if L_needed > stack.capacity
        # allocate new array with the given size
        new_data = Vector{T}(undef, L_needed)
        copyto!(new_data, 1, stack.data, stack.ptr)
        copyto!(new_data, stack.ptr+1, vec, 1, L)
    else
        # we have enough space to fit in the new array
        copyto!(stack.data, stack.ptr+1, vec, 1, L)
    end
    return stack
end


function Base.show(io::IO, stack::Stack{T}) where {T}
    println("Stack{$(T)} with properties:")
    println("\t capacity:\t$(stack.capacity)")
    println("\t ptr:\t\t$(stack.ptr)")
    print("\t data:\t\tVector{$(T)}")
    print( view(stack.data, 1:stack.ptr) )
    print("\n\n")
end












mutable struct MatrixStack{T} <: AbstractStack
    ptr::Int64
    capacity::Int64
    data::Matrix{T} # the columns are the items

    function MatrixStack{T}(vec_size::Int, start_size::Int) where {T}
        ptr = 0
        capacity = start_size < 0 ? 0 : start_size
        data     = Matrix{T}(undef, vec_size, capacity)
        new(ptr, capacity, data)
    end
end
function MatrixStack(vec_size::Int, start_size::Int)
    return MatrixStack{Float64}(vec_size, start_size)
end

function grow_stack!(stack::MatrixStack{T}) where {T}
    growth_factor   = 2
    new_capa        = convert(Int, ceil(stack.capacity * growth_factor))
    stack.capacity  = stack.capacity == 0 ? 1 : new_capa

    new_data        = similar( stack.data, size(stack.data,1), stack.capacity )

    copyto!(new_data, stack.data)
    stack.data      = new_data;
    return stack
end

function Base.push!(stack::MatrixStack{T}, new_element) where {T}
    stack.ptr += 1;
    if is_capacity_reached(stack)
        grow_stack!(stack)
    end
    stack.data[:, stack.ptr] = new_element;
    return stack
end

function Base.pop!(stack::MatrixStack{T}) where {T}
    if isempty(stack)
        underflow_error("empty stack")
    end
    stack.ptr -= 1;
    return stack.data[:, stack.ptr+1]
end

function Base.peek(stack::MatrixStack{T}) where {T}
    v = view(stack.data, 1:size(stack.data,1), stack.ptr)
    return v
end

function Base.peek(stack::MatrixStack{T}, n::Int = 0) where {T}
    v = view(stack.data, 1:size(stack.data,1), stack.ptr - n)
    return v
end

function Base.getindex(stack::MatrixStack{T}, idx::Int) where {T}
    return stack.data[idx]
end

function Base.getindex(stack::MatrixStack{T}, I::Vararg{Int, N}) where {T, N}
    return stack.data[I]
end

function shrink_to_fit!(stack::MatrixStack{T}) where {T}
    mat = similar(stack.data, size(stack.data, 1), stack.ptr)
	copyto!( mat, 1, stack.data, 1, stack.ptr * size(stack.data, 1) )
	stack.data     = mat
	stack.capacity = stack.ptr
	return stack
end


# function Base.show(io::IO, stack::MatrixStack{T}) where {T}
# end
