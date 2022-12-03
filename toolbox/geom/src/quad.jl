
# ============================================================================ #
# Rectangle
# ============================================================================ #


abstract type AbstractRectangle end

struct Rectangle{PointType} <: AbstractRectangle
    p1::PointType # lower_left
    p2::PointType # upper_right
end
function Rectangle(p1::T, p2::T) where {T <: AbstractPoint}
    return Rectangle{T}(p1, p2)
end
function Rectangle(x1::T, y1::T, x2::T, y2::T) where {T <: Number}
    return Rectangle( Point(x1, y1), Point(x2, y2) )
end


mutable struct MutableRectangle{PointType} <: AbstractRectangle
    p1::PointType
    p2::PointType
end


mutable struct BoundingBox{PointType}
    rectangle::MutableRectangle{PointType}
    midpoint::PointType
end


# ---------------------------------------------------------------------------- #
# Methods
# ---------------------------------------------------------------------------- #
Base.:(==)(r1::AbstractRectangle, r2::AbstractRectangle) = r1.p1 == r2.p1 && r1.p2 == r2.p2


function Base.:+(r::T, p::AbstractArray) where {T <: AbstractRectangle}
    q1 = r.p1 + p
    q2 = r.p2 + p
    return T(q1, q2)
end
function Base.:-(r::T, p::AbstractArray) where {T <: AbstractRectangle}
    q1 = r.p1 - p
    q2 = r.p2 - p
    return T(q1, q2)
end
function Base.:+(r::T) where {T <: AbstractRectangle}
    return r
end
function Base.:-(r::T) where {T <: AbstractRectangle}
    return T(-r.p1, -r.p2)
end
function Base.:+(p::AbstractArray, r::T) where {T <: AbstractRectangle}
    return r + p
end
function Base.:-(p::AbstractArray, r::T) where {T <: AbstractRectangle}
    return -(r - p)
end

function Base.:*(f::N, r::T) where {N <: Number, T <: AbstractRectangle}
    return T(f * r.p1, f * r.p2)
end
Base.:*(point::P, f::N) where {N <: Number, P <: AbstractPoint} = f * point;


function shift(rectangle::T, v) where {T <: AbstractRectangle}
    return T( rectangle.p1 + v, rectangle.p2 + v )
end
function scale(rectangle::T, factor) where {T <: AbstractRectangle}
    width  = factor * x_spread(rectangle)
    height = factor * y_spread(rectangle)
    mid    = mid_point(rectangle)

    PointType = typeof(rectangle.p1)
    p1 = PointType( mid.x - width/2, mid.y - height/2 )
    p2 = PointType( mid.x + width/2, mid.y + height/2 )
    
    return T(p1, p2)
end
function rotate(rectangle::T, rot_mat) where {T <: AbstractRectangle}
    mid = mid_point(rectangle)
    
    vm2 = rectangle.p2 - mid
    r

    x = rot_mat[1,1] * p.x + rot_mat[1,2] * p.y
    y = rot_mat[2,1] * p.x + rot_mat[2,2] * p.y
    return T(x, y)
end


function Base.getindex(r::T, index::Int) where {T <: AbstractRectangle}
    if index == 1
        return r.p1
    elseif index == 2
        return r.p2
    else
        return NaN
    end
end



function area(rectangle::AbstractRectangle)
    dx = rectangle.p2.x - rectangle.p1.x
    dy = rectangle.p2.y - rectangle.p1.y
    return dx * dy
end

function is_in_rectangle(rectangle::AbstractRectangle, point::AbstractPoint)
    bx = rectangle.p1.x <= point.x <= rectangle.p2.x
    if bx
        by = rectangle.p1.y <= point.y <= rectangle.p2.y
        return by
    else
        return false
    end
end

function centroid(rectangle::AbstractRectangle)
    return (rectangle.p1 + rectangle.p2)./2
end


function mid_point(rectangle::T) where {T <: AbstractRectangle}
    mid_x = 0.5 * (rectangle.p1.x + rectangle.p2.x)
    mid_y = 0.5 * (rectangle.p1.y + rectangle.p2.y)

    return Point(mid_x, mid_y)
end


function x_spread(rectangle::T) where {T <: AbstractRectangle}
    return rectangle.upper_right.x - rectangle.lower_left.x
end

function y_spread(rectangle::T) where {T <: AbstractRectangle}
    return rectangle.upper_right.y - rectangle.lower_left.y
end



function in_circle(rectangle::AbstractRectangle)
    mx = 0.5 * (rectangle.p1.x + rectangle.p2.x)
    my = 0.5 * (rectangle.p1.y + rectangle.p2.y)
    dx = rectangle.p2.x - rectangle.p1.x
    dy = rectangle.p2.y - rectangle.p1.y
    r = 0.5 * min(dx, dy)
    return Circle(Point(mx, my), r)
end

function out_circle(rectangle::AbstractRectangle)
    mx = 0.5 * (rectangle.p1.x + rectangle.p2.x)
    my = 0.5 * (rectangle.p1.y + rectangle.p2.y)
    dx = rectangle.p2.x - rectangle.p1.x
    dy = rectangle.p2.y - rectangle.p1.y
    R = sqrt(dx^2 + dy^2)
    return Circle(Point(mx, my), R)
end
