# ============================================================================ #
# General
# ============================================================================ #


orthogonal_vector(a::AbstractArray) = [-a[2], a[1]]



function point_projection(point::AbstractPoint, line::Line)
    e12 = normalize!( vector(line) )
    p = line.p1 + Point(e12 .* dot(point - line.p1, e12))
end




function cross2(a::AbstractArray, b::AbstractArray)
    if !(length(a) == length(b) == 2)
        throw(DimensionMismatch("cross2 is only defined for vectors of length 2"))
    end
    unsafe_cross2(a, b)
end

unsafe_cross2(a::AbstractArray, b::AbstractArray) = a[1] * b[2] - a[2] * b[1]

function cross2(a_x::T, a_y::T, b_x::T, b_y::T)::T where {T}
    return a_x * b_y - a_y * b_x
end

function dot2(a_x::T, a_y::T, b_x::T, b_y::T)::T where {T}
    return a_x * b_x + a_y * b_y
end


function is_left(line::Line, point::AbstractPoint)::Bool
    v12 = vector(line)
    v1p = point - line.p1
    c = cross2(v12, v1p)
    return c > 0
end



function is_left_on(line::Line, point::AbstractPoint)::Bool
    v12 = vector(line)
    v1p = point - line.p1
    c = cross2(v12, v1p)
    return c >= 0
end


function is_left_on(line_1::AbstractPoint, line_2::AbstractPoint, point::AbstractPoint)::Bool
    # v12 = vector(line)
    v12 = line_2 - line_1
    v1p = point - line_1
    c = cross2(v12, v1p)
    return c >= 0
end

function is_left(line_1::AbstractPoint, line_2::AbstractPoint, point::AbstractPoint)::Bool
    # v12 = vector(line)
    # v12 = line_2 - line_1
    # v1p = point - line_1
    # c = cross2(v12, v1p)

    v12_x = line_2.x - line_1.x
    v12_y = line_2.y - line_1.y
    v1p_x = point.x - line_1.x
    v1p_y = point.y - line_1.y

    c = cross2(v12_x, v12_y, v1p_x, v1p_y)

    return c > 0
end

function is_left_on_inlined(line::Line, point::AbstractPoint)::Bool
    v12_x = line.p2.x - line.p1.x
    v12_y = line.p2.y - line.p1.y
    v1p_x = point.x - line.p1.x
    v1p_y = point.y - line.p1.y

    c = cross2(v12_x, v12_y, v1p_x, v1p_y)
    return c >= 0
end

function is_left_on_inlined(p1::AbstractPoint, p2::AbstractPoint, point::AbstractPoint)::Bool
    v12_x = p2.x - p1.x
    v12_y = p2.y - p1.y
    v1p_x = point.x - p1.x
    v1p_y = point.y - p1.y

    c = cross2(v12_x, v12_y, v1p_x, v1p_y)
    return c >= 0
end


function is_on_line(line::Line, point::AbstractPoint, tol = 1e-10)::Bool
    d = distance(line, point)
    return d <= tol
end


function is_on_line(line_p1::AbstractPoint, line_p2::AbstractPoint, point::AbstractPoint, tol = 1e-10)::Bool
    d = distance(line_p1, line_p2, point)
    return d <= tol
end


