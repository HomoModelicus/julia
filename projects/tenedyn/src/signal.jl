
# =========================================================================== #
## Signal
# =========================================================================== #

abstract type AbstractSignal end

mutable struct Signal{OutType, InType} <: AbstractSignal
    start_pin::OutType
    end_pin::InType
    right_sibling_signal::Signal
    
    function Signal{OutType, InType}(start_pin::OutType, end_pin::InType) where {InType <: AbstractInputPin, OutType <: AbstractOutputPin}
        return new(start_pin, end_pin)
    end
end

function Signal(start_pin::OutType, end_pin::InType) where {InType <: AbstractInputPin, OutType <: AbstractOutputPin}
    return Signal{OutType, InType}(start_pin, end_pin)
end


function has_right_sibling(signal::S) where {S <: AbstractSignal}
    return isdefined(signal, :right_sibling_signal)
end

