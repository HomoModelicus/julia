
# =========================================================================== #
# Types
# =========================================================================== #

abstract type AbstractMap{T}
end

struct GriddedMap{T} <: AbstractMap{T}
    x::Vector{T}
    y::Vector{T}
    z::Matrix{T}
end
function GriddedMap(x::Vector{T}, y::Vector{T}, z::Matrix{T}) where {T}
     Lx = length(x)
     Ly = length(y)
     sz = size(z)
    
    if sz[1] != Lx
        error("Size mismatch at x")
    end
    if sz[2] != Ly
        error("Size mismatch at y")
    end

    map = GriddedMap{T}(x, y, z)
    return map
end


# =========================================================================== #
# Base functions
# =========================================================================== #

function Base.eltype(map::T) where {T <: AbstractMap}
    return eltype(map.x)
end


function Base.length(map::AbstractMap)
    return length(map.x) * length(map.y)
end

function Base.size(map::AbstractMap)
    return ( length(map.x), length(map.y) )
end

function Base.show(io::IO, map::T) where {T <: AbstractMap}
    sz = size(map)
    println("$(T) - gridded map with size: ($(sz[1]), $(sz[2])):")

    print("x: ")
    show(map.x)
    print("\n")

    print("y: ")
    show(map.y)
    print("\n")

    print("z: ")
    show(map.z)
    print("\n")

    return nothing
end

# =========================================================================== #
# Math functions
# =========================================================================== #


function add_x!(map::AbstractMap, factor)
    map.x .+= factor
    return map
end
function add_y!(map::AbstractMap, factor)
    map.y .+= factor
    return map
end
function add_z!(map::AbstractMap, factor)
    map.z .+= factor
    return map
end

function scale_x!(map::AbstractMap, factor)
    map.x .*= factor
    return map
end
function scale_y!(map::AbstractMap, factor)
    map.y .*= factor
    return map
end
function scale_z!(map::AbstractMap, factor)
    map.z .*= factor
    return map
end

function map_x!(map::AbstractMap, fcn, args...)
    for kk = 1:length(map)
        map.x[kk] = fcn(map.x[kk], args...)
    end
    return map
end
function map_y!(map::AbstractMap, fcn, args...)
    for kk = 1:length(map)
        map.y[kk] = fcn(map.y[kk], args...)
    end
    return map
end
function map_z!(map::AbstractMap, fcn, args...)
    for kk = 1:length(map)
        map.z[kk] = fcn(map.z[kk], args...)
    end
    return map
end

function map!(map::AbstractMap, fcn, args...)
    fcn(map, args...)
    return map
end



# =========================================================================== #
# Special creation functions
# =========================================================================== #

function Base.copy(map::T) where {T <: AbstractMap}
    new_map = T( copy(map.x), copy(map.y), copy(map.z) )
    return new_map
end

function peaks(
    x_vec = linspace(-3.0, 3, 49),
    y_vec = linspace(-3.0, 3, 49))

    # (X, Y) = util.mesh_grid(x_vec, y_vec)
	(X, Y) = mesh_grid(x_vec, y_vec)
    Z = (
        3 .* (1 .- X).^2 .* exp.(.-X.^2 .- (Y .+ 1).^2) .- 
        10.0 .* (X./5 .- X.^3 - Y.^5) .* exp.(.-X.^2 .- Y.^2) .-
        1 ./ 3 .* exp.(-(X .+ 1).^2 .- Y.^2)
        );
    
    map = GriddedMap(x_vec, y_vec, Z)
    
    return map
end

# =========================================================================== #
# Interpolations
# =========================================================================== #

function linear_search_interpolate(
    map::AbstractMap{T},
    xq::T,
    yq::T;
    x_init_index = 1,
    y_init_index = 1) where {T}

    # linear search
    # it is assumed that x is strictly monotonically increasing
    # only the first match is found
    #
    # constant extrapolation
    # linear interpolation

    (Lx, Ly) = size(map)

    # handle extrapolation
    if xq <= map.x[1]

        x_left_idx = 1
        crv = MutableCurve( map.y, map.z[1, :] )
        (zq, y_left_idx) = linear_search_interpolate(crv, yq)
        return (zq, x_left_idx, y_left_idx)

    elseif xq >= map.x[Lx]

        x_left_idx = Lx
        crv = MutableCurve( map.y, map.z[Lx, :] )
        (zq, y_left_idx) = linear_search_interpolate(crv, yq)
        return (zq, x_left_idx, y_left_idx)

    elseif yq <= map.y[1]

        y_left_idx = 1
        crv = MutableCurve( map.x, map.z[:, 1] )
        (zq, x_left_idx) = linear_search_interpolate(crv, xq)
        return (zq, x_left_idx, y_left_idx)

    elseif yq >= map.y[Ly]

        y_left_idx = Ly
        crv = MutableCurve( map.x, map.z[:, Ly] )
        (zq, x_left_idx) = linear_search_interpolate(crv, xq)
        return (zq, x_left_idx, y_left_idx)

    end


    # handle interpolation
    x_left_idx = 0
    ii = x_init_index
    while ii <= Lx
        if xq <= map.x[ii]
            x_left_idx = ii - 1
            break
        end
        ii += 1
    end


    y_left_idx = 0
    jj = y_init_index
    while jj <= Ly
        if yq <= map.y[jj]
            y_left_idx = jj - 1
            break
        end
        jj += 1
    end

    # interpolation
    x1 = map.x[x_left_idx]
    x2 = map.x[x_left_idx+1]
    y1 = map.y[y_left_idx]
    y2 = map.y[y_left_idx+1]
    
    z11 = map.z[x_left_idx,   y_left_idx]
    z12 = map.z[x_left_idx,   y_left_idx+1]
    z21 = map.z[x_left_idx+1, y_left_idx]
    z22 = map.z[x_left_idx+1, y_left_idx+1]
    

    dx = x2 - x1
    dy = y2 - y1
    zq =
        (xq - x2) * ( (yq - y2)*z11 - (yq - y1)*z12 ) + 
        (xq - x1) * ( (yq - y1)*z22 - (yq - y2)*z21 )
    zq = zq / (dx * dy)


    return (zq, x_left_idx, y_left_idx)

end




function binary_search_interpolate(
    map::AbstractMap{T},
    xq::T,
    yq::T;
    x_init_index = 1,
    y_init_index = 1) where {T}

    # binary search
    # it is assumed that x is strictly monotonically increasing
    # only the first match is found
    #
    # constant extrapolation
    # linear interpolation

    (Lx, Ly) = size(map)

    # handle extrapolation
    if xq <= map.x[1]

        x_left_idx = 1
        crv = MutableCurve( map.y, map.z[1, :] )
        (zq, y_left_idx) = binary_search_interpolate(crv, yq)
        return (zq, x_left_idx, y_left_idx)

    elseif xq >= map.x[Lx]

        x_left_idx = Lx
        crv = MutableCurve( map.y, map.z[Lx, :] )
        (zq, y_left_idx) = binary_search_interpolate(crv, yq)
        return (zq, x_left_idx, y_left_idx)

    elseif yq <= map.y[1]

        y_left_idx = 1
        crv = MutableCurve( map.x, map.z[:, 1] )
        (zq, x_left_idx) = binary_search_interpolate(crv, xq)
        return (zq, x_left_idx, y_left_idx)

    elseif yq >= map.y[Ly]

        y_left_idx = Ly
        crv = MutableCurve( map.x, map.z[:, Ly] )
        (zq, x_left_idx) = binary_search_interpolate(crv, xq)
        return (zq, x_left_idx, y_left_idx)

    end



	# handle interpolation
	x_left_idx  = x_init_index
	x_right_idx = Lx
	mid_idx_x   = div(x_right_idx + x_left_idx, 2)
	while true
		if xq <= map.x[mid_idx_x]
			x_right_idx = mid_idx_x
		else # xq > map.x[mid_idx_x]
			x_left_idx = mid_idx_x
		end
		mid_idx_x = div(x_right_idx + x_left_idx, 2)
		if mid_idx_x == x_left_idx
			break
		end
	end
	
	
	
	y_left_idx  = y_init_index
	y_right_idx = Ly
	mid_idx_y   = div(y_right_idx + y_left_idx, 2)
	while true
		if yq <= map.y[mid_idx_y]
			y_right_idx = mid_idx_y
		else # xq > map.y[mid_idx_y]
			y_left_idx = mid_idx_y
		end
		mid_idx_y = div(y_right_idx + y_left_idx, 2)
		if mid_idx_y == y_left_idx
			break
		end
	end


    # interpolation
    x1 = map.x[x_left_idx]
    x2 = map.x[x_left_idx+1]
    y1 = map.y[y_left_idx]
    y2 = map.y[y_left_idx+1]
    
    z11 = map.z[x_left_idx,   y_left_idx]
    z12 = map.z[x_left_idx,   y_left_idx+1]
    z21 = map.z[x_left_idx+1, y_left_idx]
    z22 = map.z[x_left_idx+1, y_left_idx+1]
    

    dx = x2 - x1
    dy = y2 - y1
    zq =
        (xq - x2) * ( (yq - y2)*z11 - (yq - y1)*z12 ) + 
        (xq - x1) * ( (yq - y1)*z22 - (yq - y2)*z21 )
    zq = zq / (dx * dy)


    return (zq, x_left_idx, y_left_idx)

end



