# ============================================================================ #
# Triangle
# ============================================================================ #
abstract type AbstractTriangle end

struct Triangle{PointType <: AbstractPoint} <: AbstractTriangle
    p1::PointType
    p2::PointType
    p3::PointType
end

Triangle(x::A, y::A) where {A<:AbstractArray} = Triangle( Point(x[1], y[1]), Point(x[2], y[2]),  Point(x[3], y[3]) )
Triangle(p1::A, p2::A, p3::A) where {A<:AbstractArray} = Triangle( Point(p1[1], p1[2]), Point(p2[1], p2[2]),  Point(p3[1], p3[2]) )


mutable struct MutableTriangle{T} <: AbstractTriangle
    p1::MutablePoint{T}
    p2::MutablePoint{T}
    p3::MutablePoint{T}
end



# ---------------------------------------------------------------------------- #
# Methods
# ---------------------------------------------------------------------------- #

Base.:(==)(t1::AbstractTriangle, t2::AbstractTriangle) = t1.p1 == t2.p1 && t1.p2 == t2.p2  && t1.p3 == t2.p3

function Base.getindex(triangle::AbstractTriangle, index::Int)
    if index == 1
        return triangle.p1
    elseif index == 2
        return triangle.p2
    elseif index == 3
        return triangle.p3
    else
        return NaN
    end
end


function shift(triangle::T, v) where {T <: AbstractTriangle}
    return T( triangle.p1 + v, triangle.p2 + v, triangle.p3 + v )
end
function scale(line::T, factor) where {T <: AbstractTriangle}
    mid = mid_point(triangle)

    vm1 = triangle.p1 - mid
    vm2 = triangle.p2 - mid
    vm3 = triangle.p3 - mid

    return T( vm1, vm2, vm3 )
end


function circumference(triangle::AbstractTriangle)
    v12 = triangle.p2 - triangle.p1
    v23 = triangle.p3 - triangle.p2
    v31 = triangle.p1 - triangle.p3
    return norm(v12) + norm(v23) + norm(v31)
end

function area(triangle::AbstractTriangle)
    v12 = triangle.p2 - triangle.p1
    v13 = triangle.p3 - triangle.p1
    return cross2(v12, v13)/2
end

function centroid(triangle::AbstractTriangle)
    return (triangle.p1 + triangle.p2 + triangle.p3)./3
end
function mid_point(triangle)
    return centroid(triangle)
end


function is_in_triangle(triangle::AbstractTriangle, point::AbstractPoint)::Bool
    line_12 = Line(triangle.p1, triangle.p2)
    line_23 = Line(triangle.p2, triangle.p3)
    line_31 = Line(triangle.p3, triangle.p1)


    # b12 = is_left_on(line_12, point)
    b12 = is_left_on_inlined(line_12, point)
    if !b12
        return false
    end

    # b23 = is_left_on(line_23, point)
    b23 = is_left_on_inlined(line_23, point)
    if !b23
        return false
    end

    # b31 = is_left_on(line_31, point)
    b31 = is_left_on_inlined(line_31, point)
    return b31
end

function is_in_triangle(p1, p2, p3, query_point)::Bool

    # b12 = is_left(p1, p2, query_point)
    b12 = is_left_on_inlined(p1, p2, query_point)
    if !b12
        return false
    end

    
    # b23 = is_left(p2, p3, query_point)
    b23 = is_left_on_inlined(p2, p3, query_point)
    if !b23
        return false
    end

    # b31 = is_left(p3, p1, query_point)
    b31 = is_left_on_inlined(p3, p1, query_point)
    return b31
end

function side_lengths(triangle::AbstractTriangle)
    v12 = triangle.p2 - triangle.p1
    v23 = triangle.p3 - triangle.p2
    v31 = triangle.p1 - triangle.p3
    a = norm(v12)
    b = norm(v23)
    c = norm(v31)

    return (a, b, c)
end

function in_circle(triangle::AbstractTriangle)

    (a, b, c) = side_lengths(triangle)
    s = 0.5 * (a + b + c)
    r = sqrt( (s-a) * (s-b) * (s-c) / s )

    A = triangle.p3
    B = triangle.p1
    C = triangle.p2

    center = (a * A + b * B + c * C) / (a + b + c)

    return Circle(center, r)
end



function out_circle(triangle::AbstractTriangle)
    (a, b, c) = side_lengths(triangle)
    Area = heron_formula(a, b, c)
    R = a * b * c / (4 * Area)
    asq = a * a
    bsq = b * b
    csq = c * c

    w_a = asq * (bsq + csq - asq)
    w_b = bsq * (asq + csq - bsq)
    w_c = csq * (asq + bsq - csq)

    A = triangle.p3
    B = triangle.p1
    C = triangle.p2

    center = (w_a * A + w_b * B + w_c * C ) / (16 * Area * Area)

    return Circle(center, R)
end

function out_circle_radius(triangle::AbstractTriangle)
    (a, b, c) = side_lengths(triangle)
    A = heron_formula(a, b, c)
    R = a * b * c / (4 * A)
end

function heron_formula(a::T, b::T, c::T) where {T <: Real}
    s = 0.5 * (a + b + c)
    A = sqrt( s * (s-a) * (s-b) * (s-c) )
    return A
end
heron_formula(a, b, c) = heron_formula( promote(a, b, c)... )


function discretize_for_plot(t::AbstractTriangle)
    x = [t.p1.x, t.p2.x, t.p3.x, t.p1.x]
    y = [t.p1.y, t.p2.y, t.p3.y, t.p1.y]
    return (x, y)
end
