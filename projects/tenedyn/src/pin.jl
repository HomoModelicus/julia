
# =========================================================================== #
## General
# =========================================================================== #


abstract type AbstractPin end
abstract type AbstractInputPin <: AbstractPin end
abstract type AbstractOutputPin <: AbstractPin end


mutable struct InputPin{T} <: AbstractInputPin
    value::T
    containing_object

    function InputPin{T}(val::T) where {T}
        obj       = new()
        obj.value = val
        return obj
    end
end
function InputPin{T}() where {T}
    return InputPin{T}(zero(T))
end
function InputPin()
    T = Float64
    return InputPin{T}()
end

mutable struct OutputPin{T} <: AbstractOutputPin
    value::T
    # name::String
    protocol::Bool
    containing_object
    left_child_signal

    function OutputPin{T}(val::T, protocol) where {T}
        obj          = new()
        obj.value    = val
        obj.protocol = protocol
        return obj
    end
end
function OutputPin{T}() where {T}
    return OutputPin{T}(zero(T), false)
end
function OutputPin()
    T = Float64
    return OutputPin{T}()
end

function has_child(pin::OutputPin)
    return isdefined(pin, :left_child_signal)
end
