

function distance(p1::AbstractPoint, p2::AbstractPoint)
    return sqrt( (p2.x -p1.x)^2 + (p2.y -p1.y)^2 )
    # return norm(p2 - p1)
end


function distance(line::Line, point::AbstractPoint)
    e12 = normalize!( vector(line) )
    v1p = point - line.p1
    val = dot(v1p, v1p) - dot(e12, v1p)^2
    if val < zero(Float64)
        val = zero(Float64)
    end
    return sqrt( val )
end

function  distance(line_p1::AbstractPoint, line_p2::AbstractPoint, point::AbstractPoint)
    e12 = normalize!( line_p2 - line_p1 )
    v1p = point - line_p1
    val = dot(v1p, v1p) - dot(e12, v1p)^2
    if val < zero(Float64)
        val = zero(Float64)
    end
    return sqrt( val )
end






# ---------------------------------------------------------------------------- #
# Methods for mesh generation
# ---------------------------------------------------------------------------- #


function signed_distance_function(circle::T, p) where {T <: AbstractCircle}
    d = sqrt( (p[1] - circle.center.x)^2 + (p[2] - circle.center.y)^2 ) - circle.r
    return d
end

function signed_distance_function(rectangle::T, p) where {T <: AbstractRectangle}
    px = p[1]
    py = p[2]

    t1 = min(
        -px + rectangle.p2.x,
        px - rectangle.p1.x
    )

    t2 = min(
        -py + rectangle.p2.y,
        py - rectangle.p1.y
    )

    d = -min(t1, t2)
    return d
end


function union_signed_distance_function(d1, d2)
    d = min.(d1, d2)
    return d
end
function intersection_signed_distance_function(d1, d2)
    d = max.(d1, d2)
    return d
end
function difference_signed_distance_function(d1, d2)
    d = max.( d1, -d2 )
    return d
end





# --------------------------------------------------------------------------- #

function point_source_node_spacing(p, src_point, h_0, h_inf, spread_factor = 1)
	
	dx = p[1] - src_point[1];
	dy = p[2] - src_point[2];

	norm_dp_sq 	= dx.^2 + dy.^2;
	arg 		= .- spread_factor .* norm_dp_sq;
	h 			= (h_0 .- h_inf) .* exp.(arg) .+ h_inf;

    return h
end

function uniform_node_spacing(p)
	# Uniform h(x,y) distribution
	h = 1.0
    return h
end


function left_to_right_node_spacing(p)
	# 1 + x
	# 1 + x of p
	h = 1.0 + max(p[1], 0.0);
    return h
end


function bottom_to_top_node_spacing(p)
	# 1 + y
	# 1 + y of p
	h = 1.0 + max(p[2], 0);
    return h
end