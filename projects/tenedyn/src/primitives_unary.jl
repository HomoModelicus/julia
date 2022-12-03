
# --------------------------------------------------------------------------- #
# Unary transformators
# --------------------------------------------------------------------------- #

function eval(block::B) where {B <: AbstractUnaryTransformer}
    error("not implemented yet")
end

function eval(block::B, time) where {B <: AbstractUnaryTransformer}
    return eval(block)
end

mutable struct Identity{T} <: AbstractUnaryTransformer
    x::InputPin{T}
    y::OutputPin{T}

    function Identity{T}() where {T}
        x = InputPin{T}()
        y = OutputPin{T}()

        obj = new()
        
        obj.x = x
        obj.y = y

        x.containing_object = obj
        y.containing_object = obj
        
        return obj
    end
end
function Identity()
    T = Float64
    return Identity{T}()
end


function eval(block::Identity)
    val = block.x.value
    block.y.value = val
    return val
end




mutable struct Gain{T} <: AbstractUnaryTransformer
    g::T
    x::InputPin{T}
    y::OutputPin{T}

    function Gain{T}(g::T) where {T}
        x = InputPin{T}()
        y = OutputPin{T}()

        obj = new()
        
        obj.x = x
        obj.y = y
        obj.g = g

        x.containing_object = obj
        y.containing_object = obj
        
        return obj
    end
end
function Gain(g::T) where {T}
    return Gain{T}(g)
end
function Gain(g = one(Float64))
    return Gain{Float64}(g)
end

function eval(block::Gain)
    val = block.x.value * block.g
    block.y.value = val
    return val
end



mutable struct Sin{T} <: AbstractUnaryTransformer
    x::InputPin{T}
    y::OutputPin{T}

    function Sin{T}() where {T}
        x = InputPin{T}()
        y = OutputPin{T}()

        obj = new()
        
        obj.x = x
        obj.y = y

        x.containing_object = obj
        y.containing_object = obj
        
        return obj
    end
end
function Sin()
    return Sin{Float64}()
end

function eval(block::Sin)
    val = sin(block.x.value)
    block.y.value = val
    return val
end



mutable struct UserDefinedUnaryFunction{T} <: AbstractUnaryTransformer
    fcn
    x::InputPin{T}
    y::OutputPin{T}

    function UserDefinedUnaryFunction{T}(fcn) where {T}
        x = InputPin{T}()
        y = OutputPin{T}()

        obj = new()
        
        obj.x = x
        obj.y = y
        obj.fcn = fcn

        x.containing_object = obj
        y.containing_object = obj
        
        return obj
    end
end
function UserDefinedUnaryFunction(fcn) where {T}
    return UserDefinedUnaryFunction{Float64}(fcn)
end

function eval(block::UserDefinedUnaryFunction)
    val = block.fcn(block.x.value)
    block.y.value = val
    return val
end
