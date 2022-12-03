# ============================================================================ #
# Point
# ============================================================================ #
abstract type AbstractPoint end

struct Point{T} <: AbstractPoint
    x::T
    y::T
    function Point{T}(x::T, y::T) where {T}
        new(x, y)
    end
end

Point(x::T, y::T) where {T} = Point{T}(x, y)
Point(x, y) = Point( promote(x, y)... )
Point{T}(x, y) where {T} = Point( promote( convert(T, x), convert(T, y))... )
Point(a::A) where {A<:AbstractArray} = Point(a[1], a[2])
Point() = Point(0.0, 0.0)

mutable struct MutablePoint{T} <: AbstractPoint
    x::T
    y::T
    function MutablePoint{T}(x::T, y::T) where {T}
        new(x, y)
    end
end

MutablePoint(x::T, y::T) where {T} = MutablePoint{T}(x, y)
MutablePoint(x, y) = MutablePoint( promote(x, y)... )
MutablePoint{T}(x, y) where {T} = MutablePoint( promote( convert(T, x), convert(T, y))... )
MutablePoint(a::A) where {A<:AbstractArray} = MutablePoint(a[1], a[2])
MutablePoint() = MutablePoint(0.0, 0.0)

# ---------------------------------------------------------------------------- #
# Methods
# ---------------------------------------------------------------------------- #

function Base.getindex(p::T, index::Int) where {T <: AbstractPoint}
    if index == 1
        return p.x
    elseif index == 2
        return p.y
    else
        return NaN
    end
end

function Base.size(p::T) where {T <: AbstractPoint}
    return (2,)
end

function Base.size(p::T, dim = 1) where {T <: AbstractPoint}
    if dim == 1
        return 2
    elseif dim == 2
        return 1
    else
        return 0
    end
end




Base.:(==)(p1::AbstractPoint, p2::AbstractPoint) = p1.x == p2.x && p1.y == p2.y

Base.:+(p1::AbstractPoint, p2::AbstractPoint) = [p1.x + p2.x, p1.y + p2.y]
Base.:-(p1::AbstractPoint, p2::AbstractPoint) = [p1.x - p2.x, p1.y - p2.y]

Base.:+(p1::AbstractPoint, p2::AbstractArray) = [p1.x + p2[1], p1.y + p2[2]]
Base.:-(p1::AbstractPoint, p2::AbstractArray) = [p1.x - p2[1], p1.y - p2[2]]

Base.:+(p1::AbstractArray, p2::AbstractPoint) = [p1[1] + p2.x, p1[2] + p2.y]
Base.:-(p1::AbstractArray, p2::AbstractPoint) = [p1[1] - p2.x, p1[2] - p2.y]


Base.:+(p1::AbstractArray, p2::T) where {T <: Number} = [p1[1] + p2, p1[2] + p2]
Base.:-(p1::AbstractArray, p2::T) where {T <: Number} = [p1[1] - p2, p1[2] - p2]

Base.:+(p1::AbstractPoint, p2::T) where {T <: Number} = [p1[1] + p2, p1[2] + p2]
Base.:-(p1::AbstractPoint, p2::T) where {T <: Number} = [p1[1] - p2, p1[2] - p2]

Base.:*(f::N, point::P) where {N <: Number, P <: AbstractPoint} = P(f * point.x, f * point.y)
Base.:*(point::P, f::N) where {N <: Number, P <: AbstractPoint} = f * point;


Base.:/(point::P, f::N) where {N <: Number, P <: AbstractPoint} =  P( point.x / f, point.y / f);


function shift(p::T, v) where {T <: AbstractPoint}
    return shift(p::T, v[1], v[2])
end

function shift(p::T, x::S, y::S) where {S, T <: AbstractPoint}
    return T(p.x + x, p.y + y)
end
function scale(p::T, factor) where {T <: AbstractPoint}
    return factor * p
end
function rotate(p::T, rot_mat) where {T <: AbstractPoint}
    x = rot_mat[1,1] * p.x + rot_mat[1,2] * p.y
    y = rot_mat[2,1] * p.x + rot_mat[2,2] * p.y
    return T(x, y)
end


function random_point(n::Int, t::Type{PointType})  where {PointType <: AbstractPoint}
    # point x, y in the range of [0,1) x [0,1)

    point_array = Vector{t}(undef, n)
    x = rand(n)
    y = rand(n)
    for kk = 1:n
        point_array[kk] = t(x[kk], y[kk])
    end
    return point_array
end

random_point(n::Int) = random_point(n, Point)


function discretize_for_plot(point::AbstractPoint)
    return (point.x, point.y)
end

function discretize_for_plot(array::Vector{<:AbstractPoint}, closed_curve::Bool = false)
    L = length(array)
    if L <= 0
        return ([],[])
    end
    Lc = closed_curve ? 1 : 0

    ElementType = typeof(array[1].x)
    x_ = Vector{ElementType}(undef, L + Lc)
    y_ = Vector{ElementType}(undef, L + Lc)
    for kk = 1:L
        x_[kk] = array[kk].x
        y_[kk] = array[kk].y
    end
    if closed_curve
        x_[end] = array[1].x
        y_[end] = array[1].y
    end
    return (x_, y_)
end


function x(array::Vector{<:AbstractPoint})
    return map(p->p.x, array)
end

function y(array::Vector{<:AbstractPoint})
    return map(p->p.y, array)
end


function point_array_to_matrix(point_array)

    L = length(point_array)
    mat = zeros(L,2)

    for kk = 1:L
        mat[kk, 1] = point_array[kk].x
        mat[kk, 2] = point_array[kk].y        
    end

    return mat
end

function matrix_to_point_array(mat)
    L = size(mat, 1)
    pa = Vector{MutablePoint}(undef, L)
    for kk = 1:L
        pa[kk] = MutablePoint(mat[kk,1], mat[kk,2])
    end
    return pa
end
