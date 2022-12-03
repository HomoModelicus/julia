




# =========================================================================== #
# Types
# =========================================================================== #

abstract type AbstractCurve{T}
end


struct StaticCurve{T} <: AbstractCurve{T}
    x::Vector{T}
    y::Vector{T}
end
function StaticCurve(x::Vector{T}, y::Vector{T}) where {T}
    return StaticCurve{T}(copy(x), copy(y))
end



mutable struct MutableCurve{T} <: AbstractCurve{T}
    x::Vector{T}
    y::Vector{T}
end
function MutableCurve(x::Vector{T}, y::Vector{T}) where {T}
    return MutableCurve{T}(x, y)
end


# =========================================================================== #
# Base functions
# =========================================================================== #


function Base.eltype(curve::T) where {T <: AbstractCurve}
    return eltype(curve.x)
end

function Base.length(curve::AbstractCurve)
    return length(curve.x)
end

function Base.size(curve::AbstractCurve)
    return (length(curve.x), 2)
end

function Base.show(io::IO, curve::T) where {T <: AbstractCurve}
    println("$(T) - curve with $(length(curve)) elements:")
    println("\tx\ty")
    for kk = 1:length(curve)
        println("\t$(curve.x[kk])\t$(curve.y[kk])")
    end
    return nothing
end



function Base.push!(curve::AbstractCurve, x, y)
    push!(curve.x, x)
    push!(curve.y, y)
    return curve
end

# =========================================================================== #
# Math functions
# =========================================================================== #

function add_x!(curve::AbstractCurve, factor)
    curve.x .+= factor
    return curve
end
function add_y!(curve::AbstractCurve, factor)
    curve.y .+= factor
    return curve
end

function scale_x!(curve::AbstractCurve, factor)
    curve.x .*= factor
    return curve
end
function scale_y!(curve::AbstractCurve, factor)
    curve.y .*= factor
    return curve
end

function map_x!(curve::AbstractCurve, fcn, args...)
    for kk = 1:length(curve)
        curve.x[kk] = fcn(curve.x[kk], args...)
    end
    return curve
end

function map_y!(curve::AbstractCurve, fcn, args...)
    for kk = 1:length(curve)
        curve.y[kk] = fcn(curve.y[kk], args...)
    end
    return curve
end

function map!(curve::AbstractCurve, fcn, args...)
    fcn(curve, args...)
    return curve
end


# =========================================================================== #
# Special creation functions
# =========================================================================== #

function ramp_curve(T, x_start, x_delta, x_end)
    x = ramp(x_start, x_delta, x_end)
    y = copy(x)
    return T(x, y)
end

function linspace_curve(T, x_start, x_end, x_length)
    x = linspace( x_start, x_end, x_length )
    y = copy(x)
    return T(x, y)
end

function rand_curve(T, x_length)
    x = collect(1:x_length)
    y = rand(x_length)
    return T(x, y)
end

function Base.copy(curve::T) where {T <: AbstractCurve}
    new_curve = T( copy(curve.x), copy(curve.y) )
    return new_curve
end

function inverse(curve::T) where {T <: AbstractCurve}
    new_curve = T(curve.y, curve.x)
    return new_curve
end


## some issue with the implementation
# function initialize(::Type{T}, n::Int) where {T <: AbstractCurve}
#     return T( Vector{Float64}(undef, n), Vector{Float64}(undef, n) )
# end

# function Base.similar(curve::T) where {T <: AbstractCurve}
#     new_curve = T( copy(curve.x), copy(curve.y) )
# end


# =========================================================================== #
# Interpolations
# =========================================================================== #


function linear_search_interpolate(curve::AbstractCurve{T}, xq::T; init_index::Int = 2) where {T}
    # linear search
    # it is assumed that x is strictly monotonically increasing
    # only the first match is found
    #
    # constant extrapolation
    # linear interpolation

    L = length(curve)

    # handle extrapolation
    if xq <= curve.x[1]
        return (curve.y[1], 1)
    elseif xq >= curve.x[L]
        return (curve.y[L], L)
    end

    # handle interpolation
    ii = init_index
    yq = NaN
    left_idx = 0
    while ii <= L
        if xq <= curve.x[ii]
            left_idx = ii-1
            break
        end
        ii += 1
    end

    # interpolation
    yq = (curve.y[ii] - curve.y[ii-1]) / (curve.x[ii] - curve.x[ii-1]) * (xq - curve.x[ii-1]) + curve.y[ii-1]

    return (yq, left_idx)

end


function binary_search_interpolate(curve::AbstractCurve, xq; left_init_index = 1, right_init_index = length(curve), linear_search_crit_index = 0 )
    # binary search
    # it is assumed that x is strictly monotonically increasing
    #
    # constant extrapolation
    # linear interpolation

    L = length(curve)

    # handle extrapolation
    if xq <= curve.x[1]
        return (curve.y[1], 1)
    elseif xq >= curve.x[L]
        return (curve.y[L], L)
    end


    # handle interpolation
    left_idx  = left_init_index
    right_idx = right_init_index
    mid_idx   = div(right_idx + left_idx, 2)

    ii = 0
    yq = NaN
    while true

        if xq <= curve.x[mid_idx]
            right_idx = mid_idx
        else # xq > curve.x[mid_idx]
            left_idx = mid_idx
        end
        d_idx = right_idx - left_idx

        if d_idx <= linear_search_crit_index
            (yq, right_idx) = linear_search_interpolate(curve, xq; init_index = left_idx)
            break
        end

        mid_idx = div(right_idx + left_idx, 2)
        if mid_idx == left_idx
            # right_idx = left_idx + 1
            ii = left_idx + 1
            break
        end
    end

    # interpolation
    yq = (curve.y[ii] - curve.y[ii-1]) / (curve.x[ii] - curve.x[ii-1]) * (xq - curve.x[ii-1]) + curve.y[ii-1]

    return (yq, left_idx)

end



function vector_linear_search_interpolate(crv::AbstractCurve{T}, x_vec::Vector{T}; init_idx::Int = 2) where {T}
    x_query = sort(x_vec)
    left_idx = init_idx
    y_vec = similar(x_vec)
    for kk = 1:length(x_query)
        xq = x_query[kk]
        (y_vec[kk], left_idx) = linear_search_interpolate(crv, xq, init_index = left_idx)
    end
    return y_vec
end

function vector_binary_search_interpolate(crv::AbstractCurve{T}, x_vec::Vector{T}; init_idx::Int = 1) where {T}
    x_query = sort(x_vec)
    left_idx = init_idx
    y_vec = similar(x_vec)
    for kk = 1:length(x_query)
        xq = x_query[kk]
        (y_vec[kk], left_idx) = binary_search_interpolate(crv, xq, left_init_index = left_idx)
    end
    return y_vec
end






