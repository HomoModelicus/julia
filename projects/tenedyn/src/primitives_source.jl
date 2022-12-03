
# --------------------------------------------------------------------------- #
# Sources
# --------------------------------------------------------------------------- #

function eval(source::S, time) where {S <: AbstractSource}
    error("not implemented yet")
end


mutable struct Constant{T} <: AbstractSource
    value::T
    y::OutputPin{T}

    function Constant{T}(val::T) where {T}
        y = OutputPin{T}()

        obj   = new()
        obj.y = y

        y.containing_object = obj
        
        return obj
    end
end
function Constant(val::T) where {T}
    return Constant{T}(val)
end

function eval(source::Constant, time)
    val = source.value
    source.y.value = val
    return val
end



mutable struct SinGenerator{T} <: AbstractSource
    amplitude::T
    frequency::T
    phase::T
    y::OutputPin{T}

    function SinGenerator{T}(a::T, f::T, p::T) where {T}
        y = OutputPin{T}()
        return new(a, f, p, y)


        y = OutputPin{T}()

        obj   = new()
        obj.y = y

        obj.amplitude = a
        obj.frequency = f
        obj.phase     = p

        y.containing_object = obj
        
        return obj
    end
end
function SinGenerator(a::T = one(Float64), f = one(T), p = zero(T)) where {T}
    return SinGenerator{T}(a, convert(T, f), convert(T, p))
end

function eval(source::SinGenerator, time)
    val = source.amplitude * sin(time * source.frequency + source.phase)
    source.y.value = val
    return val
end


mutable struct Step{T} <: AbstractSource
    amplitude::T
    time_delay::T
    y::OutputPin{T}

    function Step{T}(a::T, t::T) where {T}
        y = OutputPin{T}()

        obj   = new()
        obj.y = y
        obj.amplitude  = a
        obj.time_delay = t

        y.containing_object = obj
        
        return obj
    end
end
function Step(a::T, t) where {T}
    return Step{T}(a, convert(T, t))
end

function eval(source::Step{T}, time) where {T}
    val = time >= source.time_delay ? source.amplitude : zero(T)
    source.y.value = val
    return val
end




mutable struct Curve{T} <: AbstractSource
    curve::gridded.StaticCurve{T}
    y::OutputPin{T}

    function Curve{T}(curve_x, curve_y) where {T}
        y = OutputPin{T}()

        curve = gridded.StaticCurve{T}(curve_x, curve_y)
        obj   = new()
        obj.y = y
        obj.curve = curve

        y.containing_object = obj
        
        return obj
    end
end
function Curve(x, y)
    return Curve{Float64}(x, y)
end


function eval(source::Curve{T}, time) where {T}
    (yq, left_idx) = gridded.binary_search_interpolate(source.curve, time)
    source.y.value = yq
    return yq
end


