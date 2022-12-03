
# ============================================================================ #
# Dequeue
# ============================================================================ #
# mutable struct Dequeue{T}
#     data::Vector{T}
#     ptr_head::Int64
#     ptr_tail::Int64
#     capacity::Int64

#     function Dequeue{T}(start_size::Int64 = 0) where {T}
#         ptr = 0
#         capacity = start_size < 0 ? 0 : start_size
#         data = Vector{T}(undef, capacity)
#         new(ptr, capacity, data)
#     end
# end


# function Base.push!(stack::Dequeue{T}, new_element::T)::Dequeue{T} where {T}
# end

# # Base.isempty(stack::Dequeue{T}) where {T} =
# # Base.length(stack::Dequeue{T}) where {T} =
# # Base.size(stack::Dequeue{T}) where {T} =
# Base.eltype(::Dequeue{T}) where {T} = T;
