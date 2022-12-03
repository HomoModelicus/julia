




# ============================================================================ #
# Stack
# ============================================================================ #




# ============================================================================ #
# Typedefs
# ============================================================================ #



const MatrixStackDataType = Matrix



mutable struct MatrixStack{T} <: AbstractStack
    ptr::Int64                      # points to the last valid element
    data::MatrixStackDataType{T}    # the columns are the items

    function MatrixStack{T}(vec_size::I1, start_size::I2 = min_stack_capacity) where {T, I1 <: Integer, I2 <: Integer}
        ptr = 0

        start_size = convert(Int, start_size)
        capacity   = max(min_stack_capacity, start_size)

        data       = allocate_matrixstack(T, vec_size, capacity)

        # new(ptr, capacity, data)
        new(ptr, data)
    end

    function MatrixStack(init_element::T, start_size = min_stack_capacity) where {T}
        vec_size = length(init_element)
        stack    = MatrixStack{T}(vec_size, start_size)
        push!(stack, init_element)
        return stack
    end
    
    function MatrixStack(::Type{T}, vec_size, start_size = min_stack_capacity) where {T}
        return MatrixStack{T}(vec_size, start_size)
    end
end




function allocate_matrixstack(::Type{T}, vec_size, capacity) where {T}
    capacity = convert(Int, capacity)
    data     = MatrixStackDataType{T}(undef, vec_size, capacity)
    return data
end




# ============================================================================ #
# Basics + Indexing
# ============================================================================ #


function Base.eltype(::MatrixStack{T}) where {T}
    return T
end

function Base.length(stack::MatrixStack)
    return stack.ptr
end

function Base.size(stack::MatrixStack)
    return (size(stack.data, 1), stack.ptr) # (length(stack), )
end

function capacity(stack::MatrixStack)
    return size(stack.data, 2)
end

function Base.isempty(stack::MatrixStack)
    return length(stack) <= 0
end


function Base.IndexStyle(::Type{MatrixStack{T}}) where {T}
    return IndexLinear()
end

function Base.IndexStyle(stack::MatrixStack{T}) where {T}
    return IndexLinear()
end

function Base.firstindex(stack::MatrixStack)
    return 1
end

function Base.lastindex(stack::MatrixStack)
    return stack.ptr
end

function Base.getindex(stack::MatrixStack{T}, index::I) where {T, I <: Integer}
    return stack.data[index]
end

# is this function really necessary?
function Base.getindex(stack::MatrixStack{T}, index::Vararg{I, N}) where {T, I <: Integer, N <: Integer}
    return stack.data[index]
end



# ============================================================================ #
# Reallocations
# ============================================================================ #

function grow_stack!(stack::MatrixStack{T}, policy = GrowthDouble) where {T}
    new_capa   = new_capacity(policy, capacity(stack))
    new_capa   = max(new_capa, min_stack_capacity)

    new_data   = similar(stack.data, size(stack.data,1), new_capa )
    copyto!(new_data, stack.data)

    stack.data = new_data
    return stack
end




# ============================================================================ #
# Push and Pop
# ============================================================================ #


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

function Base.getindex(stack::MatrixStack{T}, index::Int) where {T}
    return stack.data[index]
end

function Base.getindex(stack::MatrixStack{T}, index::Vararg{Int, N}) where {T, N}
    return stack.data[index]
end




# ============================================================================ #
# Copying out the underlying data
# ============================================================================ #




# ============================================================================ #
# Misc
# ============================================================================ #



function shrink_to_fit!(stack::MatrixStack{T}) where {T}
    mat = similar(stack.data, size(stack.data, 1), stack.ptr)
	copyto!( mat, 1, stack.data, 1, stack.ptr * size(stack.data, 1) )
	stack.data     = mat
	stack.capacity = stack.ptr
	return stack
end



# ============================================================================ #
# Visualization
# ============================================================================ #


# function Base.show(io::IO, stack::MatrixStack{T}) where {T}
# end



