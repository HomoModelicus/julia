# ============================================================================ #
# Line
# ============================================================================ #
abstract type AbstractLine{T} end

struct Line{PointType <: AbstractPoint} # <: AbstractLine
    p1::PointType
    p2::PointType
end

Line(a::A, b::A) where {A <: AbstractArray} = Line( Point(a[1], a[2]), Point(b[1], b[2]) )

# ---------------------------------------------------------------------------- #
# Methods
# ---------------------------------------------------------------------------- #

Base.:(==)(line1::Line, line2::Line) = line1.p1 == line2.p1 && line1.p2 == line2.p2

function shift(line::T, v) where {T <: AbstractLine}
    return T( line.p1 + v, line.p2 + v )
end
function scale(line::T, factor) where {T <: AbstractLine}
    return T( line.p1 * factor, line.p2 * factor )
end

function Base.getindex(line::AbstractLine, index::Int)
    if index == 1
        return line.p1
    elseif index == 2
        return line.p2
    else
        return NaN
    end
end


function vector(line::Line)
    line.p2 - line.p1
end

function line_intersection(line1::Line, line2::Line, abs_tol::Real=0, rel_tol::Real=abs_tol>0 ? 0 : sqrt(eps))
    rhs = line1.p1 - line1.p2
    n1 = orthogonal_vector( vector(line1) )
    n2 = orthogonal_vector( vector(line2) )
    lamdas = n1 ./ n2
    if isapprox(lamdas[1], lamdas[2], atol = abs_tol, rtol = rel_tol)   # lamdas[1] == lamdas[2]
        return Point(v)
    end
    A = [n1, n2]
    t12 = A \ rhs
    v = t12[1] > t12[2] ? n1 .* t12[1] : n2 .* t12[2]
    return Point(v)
end



function segment_intersection(line1_a::P, line1_b::P, line2_a::P, line2_b::P) where {P <: AbstractPoint}

    d1 = point_orientation(line1_a, line1_b, line2_a)
    d2 = point_orientation(line1_a, line1_b, line2_b)
    d3 = point_orientation(line2_a, line2_b, line1_a)
    d4 = point_orientation(line2_a, line2_b, line1_b)

    b12 = (d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)
    b34 = (d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0)

    if b12 && b34
        return true

    elseif d1 == 0 && on_segment_paralell(line2_a, line2_b, line1_a)
        return true

    elseif d2 == 0 && on_segment_paralell(line2_a, line2_b, line1_b)
        return true

    elseif d3 == 0 && on_segment_paralell(line1_a, line1_b, line2_a)
        return true

    elseif d4 == 0 && on_segment_paralell(line1_a, line1_b, line2_b)
        return true

    else
        return false
    end

end

function segment_intersection(line1::Line, line2::Line)
    return segment_intersection(line1.p1, line1.p2, line2.p1, line2.p2)
end


function on_segment_paralell(line::Line, point::AbstractPoint)
# a point which lies on the line but not known whether on the segment
    return  (min(line.p1.x, line.p2.x) <= point.x <= max(line.p1.x, line.p2.x)) &&
            (min(line.p1.y, line.p2.y) <= point.y <= max(line.p1.y, line.p2.y))
end

function on_segment_paralell(line_a, line_b, point::AbstractPoint)
# a point which lies on the line but not known whether on the segment
    return  (min(line_a.x, line_b.x) <= point.x <= max(line_a.x, line_b.x)) &&
            (min(line_a.y, line_b.y) <= point.y <= max(line_a.y, line_b.y))
end


function point_orientation(p_base::P, p2::P, p3::P) where {P <: AbstractPoint}
    return cross2(p3 - p_base, p2 - p_base)
end

function discretize_for_plot(line::Line)
    x = [line.p1.x, line.p2.x]
    y = [line.p1.y, line.p2.y]
    return (x, y)
end
