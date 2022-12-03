# ============================================================================ #
# Circle
# ============================================================================ #

abstract type AbstractCircle end

struct Circle{T <: Real, PointType <: AbstractPoint} <: AbstractCircle
    center::PointType
    r::T
end

Circle(r::T) where {T} = Circle(Point(0, 0), r)
Circle(a::AbstractArray, r::T) where {T} = Circle(Point(a[1], a[2]), r)
Circle(x0::T, y0::T, r::S) where {T, S} = Circle(Point(x0, y0), r)

# ---------------------------------------------------------------------------- #
# Methods
# ---------------------------------------------------------------------------- #

Base.:(==)(c1::Circle, c2::Circle) = c1.center == c2.center && c1.r == c2.r

function shift(circle::AbstractCircle, v)
    return Circle( circle.x + v[1], circle.y + v[2], circle.r )
end

function shift(circle::T, v) where {T <: AbstractCircle}
    return T( circle.x + v[1], circle.y + v[2], circle.r )
end
function scale(c::T, factor) where {T <: AbstractCircle}
    return T( circle.x, circle.y, circle.r * factor )
end
function rotate(c::T, rot_mat) where {T <: AbstractCircle}
    return c
end


diameter(circle::Circle) = circle.r * 2
circumference(circle::Circle) = 2 * circle.r * π
area(circle::Circle) = circle.r^2 * π
is_in_circle(c::Circle, p::AbstractPoint) = distance( c.center, p ) <= c.r

function discretize_for_plot(c::Circle, n::Int = 100)
    phi = LinRange(0, 2*pi, n)
    x = c.center.x .+ c.r .* cos.(phi)
    y = c.center.y .+ c.r .* sin.(phi)
    return (x, y)
end



function mid_point(circle::T) where {T <: AbstractCircle}
    return circle.center
end

