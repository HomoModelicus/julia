

# common array utilities for stacks and queues


module ArrayUtils



# ============================================================================ #
# Error handling
# ============================================================================ #


# already contained in Core
# struct OverflowError <: Exception
#     msg::String
# end

struct UnderflowError <: Exception
    msg::String
end

function overflow_error(msg = "")
    throw( OverflowError(msg) )
end

function underflow_error(msg = "")
    throw( UnderflowError(msg) )
end





# ============================================================================ #
# Reallocations
# ============================================================================ #


export  AbstractGrowthPolicy,
        GrowthDouble,
        GrowthOneAndHalf,
        new_capacity
        

abstract type AbstractGrowthPolicy end

struct GrowthDouble <: AbstractGrowthPolicy
end

struct GrowthOneAndHalf <: AbstractGrowthPolicy
end


function new_capacity(::Type{AbstractGrowthPolicy}, old_capacity)
    error("to be implemented")
end

function new_capacity(::Type{GrowthDouble}, old_capacity)
    growth_factor   = 2
    new_capa        = convert(Int, ceil(old_capacity * growth_factor))
    return new_capa
end

function new_capacity(::Type{GrowthOneAndHalf}, old_capacity)
    growth_factor   = 1.5
    new_capa        = convert(Int, ceil(old_capacity * growth_factor))
    return new_capa
end



end

