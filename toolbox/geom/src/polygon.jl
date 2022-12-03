

struct Polygon{PointType <: AbstractPoint}
    point_array::Vector{PointType} # ccw order is assumed, first point != last point
end

function area(polygon)
    L = length(polygon.point_array)
    if L <= 2
        return 0.0
    end
    v1 = polygon.point_array[1]
    a = zero(typeof(v1.x))
    for kk = 1:L
        ii = kk
        jj = util.next_index(ii)

        v1 = polygon.point_array[ii]
        v2 = polygon.point_array[jj]
        a_12 = cross2(v1.x, v1.y, v2.x, v2.y)
        a = a + a_12
    end
    return a * 0.5
end



function create_polygon(x, y)
    # ccw order is assumed
    point_array = map(Point, x, y)
    return Polygon(point_array)
end

function create_polygon(::Type{PointType}, x, y) where {PointType <: AbstractPoint}
    # ccw order is assumed
    point_array = map(PointType, x, y)
    return Polygon(point_array)
end

function n_line_segments(poly)
    # closed polygon is assumed
    return length(poly.point_array)
end

# function resample_line_segments(poly, N_intermediate_points)
#
# end


function discretize_for_plot(poly::Polygon, closed_curve::Bool = true)
    return discretize_for_plot(poly.point_array, closed_curve)
end


function is_diagonal_helper(polygon, a_idx, b_idx)
    L = length(polygon.point_array)
    a = polygon.point_array[a_idx]
    b = polygon.point_array[b_idx]
    for kk = 1:L
        ii = kk
        jj = util.next_index(ii, L)

        v1 = polygon.point_array[ii]
        v2 = polygon.point_array[jj]

        if (a_idx != ii) && (a_idx != jj) &&
            (b_idx != ii) && (b_idx != jj) &&
            segment_intersection(a, b, v1, v2)
            return false
        end
    end
    return true
end

function is_in_cone(polygon, a_idx::Int, b_idx::Int)::Bool
    # a is the base point
    # b is the other point
    L = length(polygon.point_array)
    a_1_idx = util.prev_index(a_idx, L)
    a_3_idx = util.next_index(a_idx, L)

    b = polygon.point_array[b_idx]
    a = polygon.point_array[a_idx]
    a_1 = polygon.point_array[a_1_idx]
    a_3 = polygon.point_array[a_3_idx]

    if is_left_on(a, a_3, a_1)
        return is_left_on(a, b, a_1) && is_left_on(b, a, a_3)
    else
        return !( is_left_on(a, b, a_3) && is_left_on(b, a, a_1) )
    end
end


function is_diagonal(polygon, a_idx, b_idx)
    return  is_in_cone(polygon, a_idx, b_idx) &&
            is_in_cone(polygon, b_idx, a_idx) &&
            is_diagonal_helper(polygon, a_idx, b_idx)
end

function __init_ear(polygon)
    L = length(polygon.point_array)
    bool = falses(L)
    for kk = 1:L
        aa = util.prev_index(kk, L)
        bb = kk
        cc = util.next_index(kk, L)
        bool[kk] = is_diagonal(polygon, aa, cc)
    end
    return bool
end


mutable struct PolygonTriangle
    index_1::Int
    index_2::Int
    index_3::Int
end

function triangulate(polygon)
    L = length(polygon.point_array)
    if L <= 3
        return [PolygonTriangle(1, 2, 3)]
    end
    ears = __init_ear(polygon)
    if L == 4
        if all(ears)
            t1 = PolygonTriangle(1, 2, 3)
            t2 = PolygonTriangle(3, 4, 1)
            return [t1, t2]
        else
            # concave case
            i1 = 0
            i2 = 0
            for kk = 1:4
                if ears[kk] == false && i1 == 0
                    i1 = kk
                elseif ears[kk] == false && i2 == 0
                    i2 = kk
                end
            end
            if i2 != i1 + 2
                error("Something went wrong")
            end
            k1 = i1
            k2 = util.next_index(k1, 4)
            k3 = util.next_index(k2, 4)
            k4 = util.next_index(k3, 4)
            t1 = PolygonTriangle(k1, k2, k3)
            t2 = PolygonTriangle(k3, k4, k1)
            return [t1, t2]
        end

    end # L 4

    poly_list = datastructs.array_to_linked_list(polygon.point_array)
    ears_list = datastructs.array_to_linked_list(Vector(ears))
    idx_list = datastructs.array_to_linked_list(collect(1:length(ears)))
    poly_tri_array = Vector{PolygonTriangle}(undef, L-2)
    ptr = 1
    n = L
    kk = 1
    first_node = poly_list.node
    while n > 3
        v2 = poly_list.node
        v2next = v2.next
        ear_node  = ears_list.node
        idx_node = idx_list.node
        while true
            if ear_node.data
                v1 = v2.prev
                v3 = v2.next
                v0 = v1.prev
                v4 = v2.next

                # v1 - v3 is a diagonal
                t = PolygonTriangle(
                    idx_node.prev.data,
                    idx_node.data,
                    idx_node.next.data)
                poly_tri_array[ptr] = t
                ptr = ptr + 1

                datastructs.remove_element!(idx_list, idx_node)
                datastructs.remove_element!(ears_list, ear_node)
                datastructs.remove_element!(poly_list, v2)
                n -= 1
                first_node = v3
                break
            end
            v2 = v2next
            if first_node == v2
                break
            end
        end
        return poly_tri_array
    end

end
