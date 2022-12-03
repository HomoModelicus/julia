





module Queues
include("../../arrayutils/src/ArrayUtils.jl")

using .ArrayUtils

# ============================================================================ #
# Basic definitions
# ============================================================================ #

const min_queue_capacity = 2

abstract type AbstractQueue end

# ============================================================================ #
# Common utility functions
# ============================================================================ #

function next_index(queue::T, index::I) where {T <: AbstractQueue, I <: Integer}
    n = index + 1
    next = ifelse(
        n > capacity(queue),
        1,
        n)
    return next
end

function prev_index(queue::T, index::I) where {T <: AbstractQueue, I <: Integer}
    n = index - 1
    prev = ifelse(
        n < 1,
        capacity(queue),
        n)
    return prev
end

function is_capacity_reached(queue::T, index = length(queue)) where {T <: AbstractQueue}
    return capacity(queue) == 0 || capacity(queue) < index
end



# ============================================================================ #
# Includes - special implementations
# ============================================================================ #

include("queue.jl")

export 	AbstractQueue,
        Queue,
        #
		capacity,
        next_index,
        prev_index
		#
        # reinit! # dont export it, due to ambiguity
		# shrink_to_fit!,
        #
		# valid_data,
        # valid_view




end # module




