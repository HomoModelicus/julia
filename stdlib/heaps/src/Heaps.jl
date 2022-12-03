

module Heaps

function parent_index(index::I) where {I <: Integer}
    return div(index, 2)
end

function left_child_index(index::I) where {I <: Integer}
    return 2 * index
end

function right_child_index(index::I) where {I <: Integer}
    return 2 * index + 1
end

function element_in_level(level::I) where {I <: Integer}
    return 2^(level-1)
end

function elements_up_to_level(level::I) where {I <: Integer}
    return 2^level - 1
end




abstract type AbstractHeapPolicy end

struct MaxHeapPolicy <: AbstractHeapPolicy
end

struct MinHeapPolicy <: AbstractHeapPolicy
end




abstract type AbstractHeap end

mutable struct MinHeap{C} <: AbstractHeap
    container::C
    heap_size::Int

    function MinHeap{C}(container::C, heap_size = length(container)) where {C}
        return new(container, heap_size)
    end
end
function MinHeap(container::C) where {C}
    return MinHeap{C}(container)
end


mutable struct MaxHeap{C} <: AbstractHeap
    container::C
    heap_size::Int

    function MaxHeap{C}(container::C, heap_size = length(container)) where {C}
        return new(container, heap_size)
    end
end
function MaxHeap(container::C) where {C}
    return MaxHeap{C}(container)
end



function Base.length(heap::H) where {H <: AbstractHeap}
    return length(heap.container)
end

function Base.getindex(heap::H, I) where {H <: AbstractHeap}
    return heap.container[I]
end

function Base.isempty(heap::H) where {H <: AbstractHeap}
    return Base.isempty(heap.container)
end

function swap!(heap::H, index1, index2) where {H <: AbstractHeap}
    heap.container[index2], heap.container[index1] = heap.container[index1], heap.container[index2]
    return heap
end

function peek(heap::H) where {H <: AbstractHeap}
    return heap.container[1]
end

function increase_heap_size!(heap::H) where {H <: AbstractHeap}
    heap.heap_size += 1
    return heap
end

function decrease_heap_size!(heap::H) where {H <: AbstractHeap}
    heap.heap_size -= 1
    return heap
end

function Base.push!(heap::H, new_key) where {H <: AbstractHeap}
    push!(heap.container, new_key)
    increase_heap_size!(heap)
    sift_up!(heap, heap.heap_size)
    return heap
end

function Base.insert!(heap::H, new_key) where {H <: AbstractHeap}
    return push!(heap, new_key)
end

function Base.pop!(heap::H) where {H <: AbstractHeap}
    # extract_maximum / extract minimum
    elem = heap.container[1]
    swap!(heap, 1, heap.heap_size)
    decrease_heap_size!(heap)
    heapify!(heap, 1)
    return elem
end


function sift_up!(heap::MaxHeap, index::I) where {I <: Integer}
    return __sift_up_template!(heap, index, Base.:(<))
end

function sift_up!(heap::MinHeap, index::I) where {I <: Integer}
    return __sift_up_template!(heap, index, Base.:(>))
end

function __sift_up_template!(heap::H, index::I, op) where {H <: AbstractHeap, I <: Integer}

    parent = parent_index(index)

    while index > 1 && op(heap[parent], heap[index])
        swap!(heap, parent, index)
        index  = parent
        parent = parent_index(index)
    end

    return heap

end




function sift_down!(heap::MaxHeap, index::I) where {I <: Integer}
    return __sift_down_template!(heap, index, Base.:(>))
end

function sift_down!(heap::MinHeap, index::I) where {I <: Integer}
    return __sift_down_template!(heap, index, Base.:(<))
end

function __sift_down_template!(heap::H, index::I, op) where {H <: AbstractHeap, I <: Integer}

    N = heap.heap_size
    
    while true

        left    = left_child_index(index)
        right   = right_child_index(index)
        largest = index

        if left <= N && op(heap[left], heap[largest])
            largest = left
        end

        if right <= N && op(heap[right], heap[largest])
            largest = right
        end

        if largest == index
            break
        else
            swap!(heap, largest, index)
            index = largest
        end
    end
    

    return heap

end


function heapify!(heap::MaxHeap, index::I) where {I <: Integer}
    return sift_down!(heap, index)
end

function heapify!(heap::MinHeap, index::I) where {I <: Integer}
    return sift_down!(heap, index)
end


function maximum(heap::MaxHeap)
    return heap.container[1]
end

function minimum(heap::MinHeap)
    return heap.container[1]
end


function __create_cmp_op(::MaxHeapPolicy)
    return Base.:(<)
end

function __create_cmp_op(::MinHeapPolicy)
    return Base.:(>)
end



function is_heap(array::A, policy = MaxHeapPolicy()) where {A <: AbstractArray}
    N = length(array)
    return is_heap_until(array, N, policy)
end

function is_heap_until(
    array::A,
    until_parent_index::I,
    policy = MaxHeapPolicy()
    ) where {A <: Union{AbstractArray, AbstractHeap}, I <: Integer}

    op = __create_cmp_op(policy)
    return __is_heap_until_template(array, until_parent_index, op)
end

function __is_heap_until_template(
    array::A,
    until_parent_index::I,
    op
    ) where {A <: Union{AbstractArray, AbstractHeap}, I <: Integer}

    N    = length(array)
    bool = true
    ii   = 0
    for outer ii = 1:until_parent_index

        left  = left_child_index(ii)
        right = right_child_index(ii)

        if (left  <= N && op(array[ii], array[left]) ) ||
           (right <= N && op(array[ii], array[right]) )

           return false
        end

    end

    if ii < until_parent_index
        bool = false
    end

    return bool
end


function __create_heap(array::A, N, policy::MaxHeapPolicy) where {A <: AbstractArray}
    return MaxHeap(array, N)
end

function __create_heap(array::A, N, policy::MinHeapPolicy) where {A <: AbstractArray}
    return MinHeap(array, N)
end

function __create_heap(heap::H, N, policy) where {H <: AbstractHeap} 
    return heap
end

function make_heap(array::A, policy = MaxHeapPolicy()) where {A <: Union{AbstractArray, AbstractHeap}}
    
    N    = length(array)
    heap = __create_heap(array, N, policy) # MaxHeap(array, N)

    for ii = div(N, 2):-1:1
        heapify!(heap, ii)
    end

    return heap
end


function make_heap(heap::MaxHeap)
    return make_heap(heap, MaxHeapPolicy())
end

function make_heap(heap::MinHeap)
    return make_heap(heap, MinHeapPolicy())
end

function Base.sort!(heap::H) where {H <: AbstractHeap}

    heap = make_heap(heap)
    N    = length(heap)

    for ii = N:-1:2
        swap!(heap, 1, ii)
        decrease_heap_size!(heap)
        heapify!(heap, 1)
    end

    heap.heap_size = N
    return heap
end



# function increase_key!(heap::MaxHeap, index::I, new_key) where {I <: Integer}
# end

# function decrease_key!(heap::MinHeap, index::I, new_key) where {I <: Integer}
# end


end # module

