

# ============================================================================ #
# Typedefs
# ============================================================================ #


const QueueDataType = Vector

mutable struct Queue{T} <: AbstractQueue
    head_ptr::Int64 # points to the last valid element
    tail_ptr::Int64 # points to the last valid element
    data::QueueDataType{T}

    function Queue{T}(start_size) where {T}
        
        head_ptr   = 0
        tail_ptr   = 0

        start_size = convert(Int, start_size)
        capacity   = max(min_queue_capacity, start_size)

        data       = allocate_queue(T, capacity)

        return new(head_ptr, tail_ptr, data)
    end

    function Queue{T}() where {T}
        start_size = min_queue_capacity
        return Queue{T}(start_size)
    end

    function Queue(init_element::T, start_size = min_queue_capacity) where {T}
        queue = Queue{T}(start_size)
        push!(queue, init_element)
        return queue
    end

    function Queue(::Type{T}, start_size = min_queue_capacity) where {T}
        return Queue{T}(start_size)
    end
end


function allocate_queue(::Type{T}, capacity) where {T}
    capacity = convert(Int, capacity)
    data     = QueueDataType{T}(undef, capacity)
    return data
end


# ============================================================================ #
# Basics + Indexing
# ============================================================================ #


function Base.eltype(::Queue{T}) where {T}
    return T
end

function Base.length(queue::Queue{T}) where {T}
    queue.head_ptr == 0              && return 0
    queue.head_ptr == queue.tail_ptr && return 1

    h = queue.head_ptr
    t = queue.tail_ptr
    N = capacity(queue)
    return t - h + 1 + ifelse(t <= h, N, 0)
end

function Base.size(queue::Queue{T}) where {T}
    return (length(queue),)
end

function Base.isempty(queue::Queue{T}) where {T}
    return length(queue) <= 0
end

function capacity(queue::Queue{T}) where {T}
    return length(queue.data)
end

function Base.IndexStyle(::Type{Queue{T}}) where {T}
    return IndexLinear()
end

function Base.IndexStyle(queue::Queue{T}) where {T}
    return IndexLinear()
end

function Base.getindex(queue::Queue{T}, index::I) where {T, I <: Integer}
    ptr = queue.head_ptr + index - 1
    ptr = ifelse(
        ptr > capacity(queue),
        ptr - capacity(queue),
        ptr)

    return queue.data[ptr]
end

# no setindex! -> not supported by the public interface


# ============================================================================ #
# Reallocations
# ============================================================================ #


function grow_queue!(queue::Queue{T}, policy = GrowthDouble) where {T}
    new_capa = new_capacity(policy, capacity(queue))
    new_capa = max(new_capa, min_queue_capacity)

    new_data = similar(queue.data, T, new_capa)
    L        = capacity(queue)

    if queue.head_ptr >= queue.tail_ptr
        # two copies
        copyto!(new_data, 1,                      queue.data, queue.head_ptr, L - queue.head_ptr + 1)
        copyto!(new_data, L - queue.head_ptr + 2, queue.data, 1,              queue.tail_ptr)
    else
        # one copy
        copyto!(new_data, queue.data)
    end

    queue.head_ptr = 1
    queue.tail_ptr = L
    queue.data     = new_data;

    return queue
end




# ============================================================================ #
# Push and Pop
# ============================================================================ #


function Base.push!(queue::Queue{T}, new_element::T) where {T}
    # this might point to over the last element
    # temporarly increase the index for the correct length check
    queue.tail_ptr += 1 
    if is_capacity_reached(queue)
        grow_queue!(queue) # tail pointer is corrected here
    else
        queue.tail_ptr -= 1 # set back the temporary increase
    end
    queue.tail_ptr = next_index(queue, queue.tail_ptr) # correct index calculation

    queue.data[queue.tail_ptr] = new_element

    # first push
    if queue.head_ptr == 0 && queue.tail_ptr != 0
        queue.head_ptr = queue.tail_ptr
    end
    
    return queue
end

function Base.pop!(queue::Queue{T}) where {T}
    L = length(queue)
    if L <= 0
        underflow_error("empty queue")
    end

    elem   = queue.data[queue.head_ptr]

    if L == 1
        # reset queue
        queue.head_ptr = 0
        queue.tail_ptr = 0
    else
        queue.head_ptr = next_index(queue, queue.head_ptr)
    end

    return elem
end

function Base.peek(queue::Queue{T}) where {T}
    return queue.data[queue.head_ptr]
end


# ============================================================================ #
# Copying out the underlying data
# ============================================================================ #

# ============================================================================ #
# Misc
# ============================================================================ #

function reinit!(queue::Q) where {Q <: AbstractQueue}
	queue.head_ptr  = 0
    queue.tail_ptr  = 0
	return queue
end

function copy(queue::Queue{T}) where {T}
    new_queue           = Queue{T}()
    new_queue.data      = copy(queue.data)
    new_queue.capacity  = queue.capacity
    new_queue.head_ptr  = queue.head_ptr
    new_queue.tail_ptr  = queue.tail_ptr
    
    return new_queue
end


# ============================================================================ #
# Visualization
# ============================================================================ #

function Base.show(io::IO, mime::MIME"text/plain", queue::Queue{T}) where {T}
    println("Queue{$(T)} with properties:")
    println("   capacity: $(capacity(queue))")
    println("   head_ptr: $(queue.head_ptr)")
    println("   tail_ptr: $(queue.tail_ptr)")
    print("\n\n")
end

function showall(queue::Queue{T}) where {T}
    println("Queue{$(T)} with properties:")
    println("   capacity: $(capacity(queue))")
    println("   head_ptr: $(queue.head_ptr)")
    println("   tail_ptr: $(queue.tail_ptr)")
    # display(queue.data)

    if queue.head_ptr > queue.tail_ptr
        display( view(queue.data, queue.head_ptr:queue.capacity) )
        display( view(queue.data, 1:queue.tail_ptr) )
    else
        if queue.head_ptr == 0 || queue.tail_ptr == 0
        else
            display( view(queue.data, queue.head_ptr:queue.tail_ptr) )
        end
    end
end



#= 
# old stuff


# ============================================================================ #
# Queue
# ============================================================================ #



# ============================================================================ #
# Typedefs
# ============================================================================ #




mutable struct Queue{T} <:AbstractQueue
    head_ptr::Int64
    tail_ptr::Int64
    capacity::Int64
    data::Vector{T}

    function Queue{T}(start_size::Int) where {T}
        head_ptr  = 0
        tail_ptr  = 0
        min_size  = min_queue_size
        capacity  = start_size < 0 ? min_size : max(min_size, start_size)
        data      = Vector{T}(undef, capacity)
        new(head_ptr, tail_ptr, capacity, data)
    end

    function Queue{T}() where {T}
        min_size = min_queue_size
        return Queue{T}(min_size)
    end

end



# ============================================================================ #
# Basics + Indexing
# ============================================================================ #


function Base.eltype(::Queue{T}) where {T}
    return T
end


function Base.length(queue::Queue{T}; head = queue.head_ptr, tail = queue.tail_ptr) where {T}
    if head == 0 || tail == 0
        return 0
    else
        h = head
        t = tail
        L = queue.capacity
        return t - h + 1 + ((t < h) * L)
    end
end

function Base.size(queue::Queue{T}) where {T}
    return (length(queue),)
end

function Base.isempty(queue::Queue{T}) where {T}
    return length(queue) <= 0
end

function capacity(queue::Queue{T}) where {T}
    return queue.capacity
end


function Base.getindex(queue::Queue{T}, idx::Int) where {T}
    return queue.data[idx]
end

function Base.getindex(queue::Queue{T}, I::Vararg{Int, N}) where {T, N}
    return queue.data[I]
end



function next_index(queue::Queue{T}, index::Int) where {T}
    n = index + 1
    if n > queue.capacity
        n = 1
    end
    return n
end

function prev_index(queue::Queue{T}, index::Int) where {T}
    n = index - 1
    if n < 1
        n = queue.capacity
    end
    return n
end











# ============================================================================ #
# Reallocations
# ============================================================================ #




function is_capacity_reached(queue::Queue{T}, add_one::Bool = false) where {T}
    zero_capa                   = queue.capacity == 0
    L = length(queue)
    exceeding_length_actual     = L >= queue.capacity
    exceeding_length_pretending = L + (1 * add_one) > queue.capacity

    return zero_capa || exceeding_length_actual || exceeding_length_pretending
end

function grow_queue!(queue::Queue{T}) where {T}
    growth_factor   = 2
    L               = queue.capacity
    new_capa        = convert(Int, ceil(queue.capacity * growth_factor))
    queue.capacity  = queue.capacity == 0 ? 1 : new_capa
    new_data        = similar( queue.data, T, queue.capacity )

    if queue.head_ptr >= queue.tail_ptr
        # two copies
        copyto!(new_data, 1,                      queue.data, queue.head_ptr, L - queue.head_ptr + 1)
        copyto!(new_data, L - queue.head_ptr + 2, queue.data, 1,              queue.tail_ptr)
        queue.head_ptr = 1
        queue.tail_ptr = L
    else
        # one copy
        copyto!(new_data, queue.data)
        queue.head_ptr = 1
        queue.tail_ptr = L
    end

    queue.data = new_data;

    return queue
end



# ============================================================================ #
# Push and Pop
# ============================================================================ #


function Base.push!(queue::Queue{T}, new_element::T) where {T}

    t_next = next_index(queue, queue.tail_ptr)

    if is_capacity_reached(queue, true)
        grow_queue!(queue)
        queue.tail_ptr += 1
    else
        queue.tail_ptr = t_next
    end

    queue.data[queue.tail_ptr] = new_element

    # first push
    if queue.head_ptr == 0 && queue.tail_ptr != 0
        queue.head_ptr = queue.tail_ptr
    end

    return queue
end

function Base.pop!(queue::Queue{T}) where {T}
    L = length(queue)
    if L <= 0
        underflow_error("empty queue")
    end

    elem   = queue.data[queue.head_ptr]

    if L == 1
        # reset queue
        queue.head_ptr = 0
        queue.tail_ptr = 0
    else
        queue.head_ptr = next_index(queue, queue.head_ptr)
    end

    return elem
end

function Base.peek(queue::Queue{T}) where {T}
    return queue.data[queue.head_ptr]
end


# function Base.peek(queue::Queue{T}, n::Int = 0)::T where {T}
#     idx = queue.head_ptr + n
#     if idx > queue.capacity
#         over = idx - queue.capacity
#         idx = over
#     end
#     return queue.data[idx]
# end





# ============================================================================ #
# Copying out the underlying data
# ============================================================================ #







# ============================================================================ #
# Misc
# ============================================================================ #

function reinit!(queue::Q) where {Q <: AbstractQueue}
	queue.head_ptr  = 0
    queue.tail_ptr  = 0
	return queue
end



function copy(queue::Queue{T}) where {T}
    new_queue           = Queue{T}()
    new_queue.data      = copy(queue.data)
    new_queue.capacity  = queue.capacity
    new_queue.head_ptr  = queue.head_ptr
    new_queue.tail_ptr  = queue.tail_ptr
    
    return new_queue
end




# ============================================================================ #
# Visualization
# ============================================================================ #


function Base.show(io::IO, queue::Queue{T}) where {T}
    println("Queue{$(T)} with properties:")
    println("\tcapacity:\t$(queue.capacity)")
    println("\thead_ptr:\t$(queue.head_ptr)")
    println("\ttail_ptr:\t$(queue.tail_ptr)")
    
    print("\tdata:\t\tVector{$(T)}")

    if queue.head_ptr > queue.tail_ptr
        print( view(queue.data, queue.head_ptr:queue.capacity) )
        print( view(queue.data, 1:queue.tail_ptr) )
    else
        if queue.head_ptr == 0 || queue.tail_ptr == 0
        else
            print( view(queue.data, queue.head_ptr:queue.tail_ptr) )
        end
    end
    
    print("\n\n")
end


# not implemented for now
# function shrink_to_fit!(stack::Stack{T}) where {T}
# end
# function merge!(stack::Stack{T}, vec::AbstractArray{T})
# end



=#