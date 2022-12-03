

# ============================================================================ #
# Stack
# ============================================================================ #





# ============================================================================ #
# Typedefs
# ============================================================================ #


const StackDataType = Vector

mutable struct Stack{T} <: AbstractStack
    ptr::Int64              # points to the last valid element
    data::StackDataType{T}

    function Stack{T}(start_size) where {T}
        
        ptr        = 0

        start_size = convert(Int, start_size)
        capacity   = max(min_stack_capacity, start_size)

        data       = allocate_stack(T, capacity)

        return new(ptr, data)
    end

    function Stack{T}() where {T}
        start_size = min_stack_capacity
        return Stack{T}(start_size)
    end

    function Stack(init_element::T, start_size = min_stack_capacity) where {T}
        stack = Stack{T}(start_size)
        push!(stack, init_element)
        return stack
    end

    function Stack(::Type{T}, start_size = min_stack_capacity) where {T}
        return Stack{T}(start_size)
    end
end




function allocate_stack(::Type{T}, capacity) where {T}
    capacity = convert(Int, capacity)
    data     = StackDataType{T}(undef, capacity)
    return data
end

# ============================================================================ #
# Basics + Indexing
# ============================================================================ #


function Base.eltype(::Stack{T}) where {T}
    return T
end

function Base.length(stack::Stack{T}) where {T}
    return stack.ptr
end

function Base.size(stack::Stack{T}) where {T}
    return (length(stack), )
end

function capacity(stack::Stack{T}) where {T}
    return length(stack.data)
end

function Base.isempty(stack::Stack{T}) where {T}
    return length(stack) <= 0
end

function Base.IndexStyle(::Type{Stack{T}}) where {T}
    return IndexLinear()
end

function Base.IndexStyle(stack::Stack{T}) where {T}
    return IndexLinear()
end

function Base.firstindex(stack::Stack{T}) where {T}
    return 1
end

function Base.lastindex(stack::Stack{T}) where {T}
    return stack.ptr
end

function Base.getindex(stack::Stack{T}, index::I) where {T, I <: Integer}
    return stack.data[index]
end

# no setindex! -> not supported by the public interface


# ============================================================================ #
# Reallocations
# ============================================================================ #


function grow_stack!(stack::Stack{T}, policy = GrowthDouble) where {T}
    new_capa   = new_capacity(policy, capacity(stack))
    new_capa   = max(new_capa, min_stack_capacity)

    new_data   = similar(stack.data, T, new_capa)
    copyto!(new_data, stack.data)

    stack.data = new_data
    return stack
end


# ============================================================================ #
# Push and Pop
# ============================================================================ #


function Base.push!(stack::Stack{T}, new_element::T) where {T}
    stack.ptr += 1
    if is_capacity_reached(stack)
        grow_stack!(stack)
    end
    stack.data[stack.ptr] = new_element
    return stack
end

function Base.pop!(stack::Stack{T}) where {T}
    if isempty(stack)
        error("empty stack")
    end
    stack.ptr -= 1;
    return stack.data[stack.ptr+1]
end

function Base.peek(stack::Stack{T}) where {T}
    return stack.data[stack.ptr]
end



# ============================================================================ #
# Copying out the underlying data
# ============================================================================ #


function valid_data(stack::Stack{T}) where {T}
    return stack.data[1:stack.ptr] # this makes a copy from that view
end

function valid_view(stack::Stack{T}) where {T}
    return view(stack.data, 1:stack.ptr)
end

# maybe such things like
function copy_to_ntuple(stack::Stack{T}) where {T}
    return tuple(stack.data[1:stack.ptr]...)
end

function copy_to_array(stack::Stack{T}, to_array::AbstractArray{T}) where {T}
    for ii = eachindex(stack)
        to_array[ii] = stack.data[ii]
    end
end







# ============================================================================ #
# Misc
# ============================================================================ #


function reinit!(stack::S) where {S <: AbstractStack}
	stack.ptr = 0
	return stack
end

function shrink_to_fit!(stack::Stack{T}) where {T}
	vec        = similar(stack.data, stack.ptr)
	copyto!(vec, 1, stack.data, 1, stack.ptr)
    stack.data = vec
	return stack
end

function Base.copy(stack::Stack{T}) where {T}
    new_stack           = Stack{T}()
    new_stack.data      = copy(stack.data)
    new_stack.ptr       = stack.ptr
    return new_stack
end

function Base.merge!(stack::Stack{T}, vec::AbstractArray{T}) where {T}
    L = length(vec)
    L_needed = stack.ptr + L
    if L_needed > stack.capacity
        # allocate new array with the given size
        new_data = allocate_stack(T, L_needed)
        copyto!(new_data, 1, stack.data, stack.ptr)
        copyto!(new_data, stack.ptr+1, vec, 1, L)
    else
        # we have enough space to fit in the new array
        copyto!(stack.data, stack.ptr+1, vec, 1, L)
    end
    return stack
end




# ============================================================================ #
# Visualization
# ============================================================================ #

function Base.show(io::IO, mime::MIME"text/plain", stack::Stack{T}) where {T}
    println("Stack{$(T)} with properties:")
    println("   capacity: $(capacity(stack))")
    println("        ptr: $(stack.ptr)")
    # print("\t data:       Vector{$(T)}")
    # print( view(stack.data, 1:stack.ptr) )
    print("\n\n")
end

function showall(stack::Stack{T}) where {T}
    println("Stack{$(T)} with properties:")
    println("   capacity: $(capacity(stack))")
    println("        ptr: $(stack.ptr)")
    display(view(stack.data, 1:stack.ptr))
end










