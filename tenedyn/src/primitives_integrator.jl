
# --------------------------------------------------------------------------- #
# Integrator
# --------------------------------------------------------------------------- #

function eval(block::B) where {B <: AbstractIntegrator}
    error("not implemented yet")
end

function eval(block::B, time) where {B <: AbstractIntegrator}
    return eval(block)
end

mutable struct Integrator{T} <: AbstractIntegrator
    initial_value::T
    x::InputPin{T}  # der(state)
    y::OutputPin{T} # state

    function Integrator{T}(initial_value) where {T}
        x = InputPin{T}()
        y = OutputPin{T}()
        y.value = initial_value

        obj = new()
        
        obj.x = x
        obj.y = y
        obj.initial_value = initial_value

        x.containing_object = obj
        y.containing_object = obj
        
        return obj
    end
end

function Integrator(initial_value::T) where {T}
    return Integrator{T}(initial_value)
end


function eval(block::Integrator)
    val = block.y.value
    return val
end

function eval(block::Integrator, time::A) where {A <: Real}
    val = block.y.value
    return val
end


function eval(block::Integrator, state::A) where {A <: AbstractArray}
    block.y.value = state
    return state
end



