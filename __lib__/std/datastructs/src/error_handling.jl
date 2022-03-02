

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



