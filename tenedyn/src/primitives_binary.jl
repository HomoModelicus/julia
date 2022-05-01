
# --------------------------------------------------------------------------- #
# Binary transformators
# --------------------------------------------------------------------------- #

function eval(block::B) where {B <: AbstractBinaryTransformer}
    error("not implemented yet")
end

function eval(block::B, time) where {B <: AbstractBinaryTransformer}
    return eval(block)
end

mutable struct Plus{T} <: AbstractBinaryTransformer
    x1::InputPin{T}
    x2::InputPin{T}
    y::OutputPin{T}

    function Plus{T}() where {T}
        x1 = InputPin{T}()
        x2 = InputPin{T}()
        y  = OutputPin{T}()

        obj = new()
        
        obj.x1 = x1
        obj.x2 = x2
        obj.y  = y

        x1.containing_object = obj
        x2.containing_object = obj
        y.containing_object  = obj
        
        return obj
    end
end
function Plus() where {T}
    return Plus{Float64}()
end

function eval(block::Plus)
    val = block.x1.value + block.x2.value
    block.y.value = val
    return val
end





mutable struct Minus{T} <: AbstractBinaryTransformer
    x1::InputPin{T}
    x2::InputPin{T}
    y::OutputPin{T}

    function Minus{T}() where {T}
        x1 = InputPin{T}()
        x2 = InputPin{T}()
        y  = OutputPin{T}()

        obj = new()
        
        obj.x1 = x1
        obj.x2 = x2
        obj.y  = y

        x1.containing_object = obj
        x2.containing_object = obj
        y.containing_object  = obj
        
        return obj
    end
end
function Minus() where {T}
    return Minus{Float64}()
end

function eval(block::Minus)
    val = block.x1.value - block.x2.value
    block.y.value = val
    return val
end



mutable struct Multiply{T} <: AbstractBinaryTransformer
    x1::InputPin{T}
    x2::InputPin{T}
    y::OutputPin{T}

    function Multiply{T}() where {T}
        x1 = InputPin{T}()
        x2 = InputPin{T}()
        y  = OutputPin{T}()

        obj = new()
        
        obj.x1 = x1
        obj.x2 = x2
        obj.y  = y

        x1.containing_object = obj
        x2.containing_object = obj
        y.containing_object  = obj
        
        return obj
    end
end
function Multiply() where {T}
    return Multiply{Float64}()
end

function eval(block::Multiply)
    val = block.x1.value * block.x2.value
    block.y.value = val
    return val
end


mutable struct Divide{T} <: AbstractBinaryTransformer
    x1::InputPin{T}
    x2::InputPin{T}
    y::OutputPin{T}

    function Divide{T}() where {T}
        x1 = InputPin{T}()
        x2 = InputPin{T}()
        y  = OutputPin{T}()

        obj = new()
        
        obj.x1 = x1
        obj.x2 = x2
        obj.y  = y

        x1.containing_object = obj
        x2.containing_object = obj
        y.containing_object  = obj
        
        return obj
    end
end
function Divide() where {T}
    return Divide{Float64}()
end

function eval(block::Divide)
    val = block.x1.value / block.x2.value
    block.y.value = val
    return val
end

