

# struct LinearMemoryChunk{T}
#     data::Vector{T}
# end
# 
# this would be just a lightweight hull over two pointers
# struct AnotherStack{T}
#     # memory chunk must be changeable -> either the MemoryChunk is mutable or the container object is mutable
#     # ptr must be changeable as well
# end
# 
# rather do a mutable struct with as much inlined in that object as possible
# 







module Stacks
include("../../arrayutils/src/ArrayUtils.jl")


using .ArrayUtils


# ============================================================================ #
# Basic definitions
# ============================================================================ #

const min_stack_capacity = 2

abstract type AbstractStack end

# ============================================================================ #
# Common utility functions
# ============================================================================ #

function next_index(stack::T, index::I) where {T <: AbstractStack, I <: Integer}
    n = index + 1
    next = ifelse(
        n > capacity(stack),
        1,
        n)
    return next
end

function prev_index(stack::T, index::I) where {T <: AbstractStack, I <: Integer}
    n = index - 1
    prev = ifelse(
        n < 1,
        capacity(stack),
        n)
    return prev
end

function is_capacity_reached(stack::T, index = length(stack)) where {T <: AbstractStack}
    return capacity(stack) == 0 || capacity(stack) < index
end

function last_valid_index(stack::S) where {S <: AbstractStack}
    return stack.ptr
end


# ============================================================================ #
# Includes - special implementations
# ============================================================================ #


include("stack.jl")
    
include("matrix_stack.jl")


export 	AbstractStack,
		Stack,
        MatrixStack,
        #
		capacity,
        next_index,
        prev_index,
		#
        # reinit!, # dont export it, due to ambiguity
		shrink_to_fit!,
        #
		valid_data,
        valid_view 


end # module












