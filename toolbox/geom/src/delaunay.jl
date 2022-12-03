
# include(raw"D:\programming\src\julia\dev\utilities\utilities.jl")

mutable struct DelaunayMeshTriangle
    alive::Bool

    # indices into the vertex array
    index_1::Int
    index_2::Int
    index_3::Int

    # indices into the triangle array
    parent::Int
    child_1::Int
    child_2::Int
    child_3::Int

    neighbor_12::Int
    neighbor_23::Int
    neighbor_31::Int

    function DelaunayMeshTriangle()
        obj = new()
        obj.alive = false
        obj.index_1 = 0
        obj.index_2 = 0
        obj.index_3 = 0

        obj.parent = 0
        obj.child_1 = 0
        obj.child_2 = 0
        obj.child_3 = 0

        obj.neighbor_12 = 0
        obj.neighbor_23 = 0
        obj.neighbor_31 = 0

        return obj
    end
    function DelaunayMeshTriangle(
        alive,
        index_1,
        index_2,
        index_3,
        parent,
        child_1,
        child_2,
        child_3,
        neighbor_12,
        neighbor_23,
        neighbor_31)
    
        obj = new()
        obj.alive = alive
        obj.index_1 = index_1
        obj.index_2 = index_2
        obj.index_3 = index_3
    
        obj.parent = parent
        obj.child_1 = child_1
        obj.child_2 = child_2
        obj.child_3 = child_3
    
        obj.neighbor_12 = neighbor_12
        obj.neighbor_23 = neighbor_23
        obj.neighbor_31 = neighbor_31
    
        return obj
    end
end





function Base.show(io::IO, obj::DelaunayMeshTriangle)
    str = util.matlab_display(obj)
    print(io, str)
end


mutable struct DelaunayMesh
    vertex_array::Vector{<:AbstractPoint}
    triangle_array::datastructs.Stack{DelaunayMeshTriangle}
    triangle_index::Matrix{Int}
    # triangle_array::Vector{DelaunayMeshTriangle}

    function DelaunayMesh(va::Vector{<:AbstractPoint})
        obj = new()
        L = length(va)
        obj.vertex_array = Vector{eltype(va)}(undef, L + 3)
        copyto!(obj.vertex_array, 4, va, 1, L)
        # obj.triangle_array = datastructs.Stack{DelaunayMeshTriangle}(div(L,3)+1)
        obj.triangle_array = datastructs.Stack{DelaunayMeshTriangle}(L)
        return obj
    end
end

DelaunayMesh() = DelaunayMesh( Vector{MutablePoint}(undef, 0) )



function create_initial_triangle(dmesh::DelaunayMesh)
    PointType = eltype(dmesh.vertex_array)
    tan_a = 1.0 # alpha = 45 degrees
    scale_factor = 1.12 # 1.12
    scale_L = 0.1
    (min_x, max_x, min_y, max_y) = extrema(dmesh.vertex_array[4:length(dmesh.vertex_array)])
    Lx = max_x.x - min_x.x
    Ly = max_y.y - min_y.y
    if Lx > Ly
        b_y = min_y.y - Ly * scale_L # make the triangle 10% bigger than necessary
        b_x = min_x.x + Lx/2
        B = PointType(b_x, b_y)
        a = Lx/2 + Ly / tan_a
        h = Ly + Lx/2 * tan_a
        a = a * scale_factor
        h = h * scale_factor
        X = PointType(B.x - a, B.y)
        Y = PointType(B.x + a, B.y)
        Z = PointType(B.x, B.y + h)
    else
        b_y = min_y.y + Ly/2 # make the triangle 10% bigger than necessary
        b_x = min_x.x - Lx * scale_L
        B = PointType(b_x, b_y)
        a = Ly/2 + Lx * tan_a
        h = Lx + Ly/2 * 1 / tan_a
        a = a * scale_factor
        h = h * scale_factor
        X = PointType(B.x, B.y + a)
        Y = PointType(B.x, B.y - a)
        Z = PointType(B.x + h, B.y)
    end
    return (X, Y, Z)
end

function insert_first_point!(dmesh::DelaunayMesh)
    p_idx = 4

    tri_pxy = DelaunayMeshTriangle()
    tri_pyz = DelaunayMeshTriangle()
    tri_pzx = DelaunayMeshTriangle()

    push!(dmesh.triangle_array, tri_pxy)
    push!(dmesh.triangle_array, tri_pyz)
    push!(dmesh.triangle_array, tri_pzx)

    tri_parent_idx = 1
    tri_parent = dmesh.triangle_array.data[tri_parent_idx]
    tri_parent.alive = false

    tri_pxy_idx = 2
    tri_pyz_idx = 3
    tri_pzx_idx = 4

    tri_pxy.parent = tri_parent_idx
    tri_pxy.alive = true

    tri_pyz.parent = tri_parent_idx
    tri_pyz.alive = true

    tri_pzx.parent = tri_parent_idx
    tri_pzx.alive = true

    tri_parent.child_1 = tri_pxy_idx
    tri_parent.child_2 = tri_pyz_idx
    tri_parent.child_3 = tri_pzx_idx


    tri_pxy.index_1 = p_idx
    tri_pxy.index_2 = 1
    tri_pxy.index_3 = 2

    tri_pxy.neighbor_12 = tri_pzx_idx
    tri_pxy.neighbor_23 = 0
    tri_pxy.neighbor_31 = tri_pyz_idx


    tri_pyz.index_1 = p_idx
    tri_pyz.index_2 = 2
    tri_pyz.index_3 = 3

    tri_pyz.neighbor_12 = tri_pxy_idx
    tri_pyz.neighbor_23 = 0
    tri_pyz.neighbor_31 = tri_pzx_idx


    tri_pzx.index_1 = p_idx
    tri_pzx.index_2 = 3
    tri_pzx.index_3 = 1

    tri_pzx.neighbor_12 = tri_pyz_idx
    tri_pzx.neighbor_23 = 0
    tri_pzx.neighbor_31 = tri_pxy_idx

    return dmesh
end

function create_triangle(dmesh::DelaunayMesh, tri_idx::Int)
    tri = dmesh.triangle_array.data[tri_idx]

    p1 = dmesh.vertex_array[tri.index_1]
    p2 = dmesh.vertex_array[tri.index_2]
    p3 = dmesh.vertex_array[tri.index_3]

    return Triangle(p1, p2, p3)
end

function is_in_triangle(dmesh::DelaunayMesh, tri_idx::Int, p_idx::Int)::Bool
    # tri = create_triangle(dmesh, tri_idx)
    # return is_in_triangle(tri, dmesh.vertex_array[p_idx])
    query_point = dmesh.vertex_array[p_idx]

    tri = dmesh.triangle_array.data[tri_idx]
    p1 = dmesh.vertex_array[tri.index_1]
    p2 = dmesh.vertex_array[tri.index_2]
    p3 = dmesh.vertex_array[tri.index_3]
    return is_in_triangle(p1, p2, p3, query_point)
end

function find_containing_triange(dmesh::DelaunayMesh, p_idx::Int)
    tri_idx = 1
    tri = dmesh.triangle_array.data[tri_idx]
    succes = true
    while !tri.alive
        if tri.child_1 != 0 && is_in_triangle(dmesh, tri.child_1, p_idx)
            child_tri_idx = tri.child_1
            succes = true
        elseif tri.child_2 != 0 &&  is_in_triangle(dmesh, tri.child_2, p_idx)
            child_tri_idx = tri.child_2
            succes = true
        elseif tri.child_3 != 0 &&  is_in_triangle(dmesh, tri.child_3, p_idx)
            child_tri_idx = tri.child_3
            succes = true
        else
            succes = false
            # try to shuffle the query point a bit
            x_ = dmesh.vertex_array[p_idx].x
            y_ = dmesh.vertex_array[p_idx].y
            
            dmesh.vertex_array[p_idx].x += sqrt(eps(x_))
            dmesh.vertex_array[p_idx].y += sqrt(eps(y_))

            parent_p1 = dmesh.vertex_array[tri.index_1]
            parent_p2 = dmesh.vertex_array[tri.index_2]
            parent_p3 = dmesh.vertex_array[tri.index_3]

            println("The requested point: [$(dmesh.vertex_array[p_idx].x), $(dmesh.vertex_array[p_idx].y)]")

            println("The parent triangle P1: [$(parent_p1.x), $(parent_p1.y)]")
            println("The parent triangle P2: [$(parent_p2.x), $(parent_p2.y)]")
            println("The parent triangle P3: [$(parent_p3.x), $(parent_p3.y)]")

            println("The triangle child indices: ($(tri.child_1), $(tri.child_2), $(tri.child_3))")

            if tri.child_1 != 0
                tri_ch = dmesh.triangle_array[tri.child_1]
                p1 = dmesh.vertex_array[tri_ch.index_1]
                p2 = dmesh.vertex_array[tri_ch.index_2]
                p3 = dmesh.vertex_array[tri_ch.index_3]

                println("The child 1 triangle P1: [$(p1.x), $(p1.y)]")
                println("The child 1 triangle P1: [$(p2.x), $(p2.y)]")
                println("The child 1 triangle P1: [$(p3.x), $(p3.y)]")
            end

            if tri.child_2 != 0
                tri_ch = dmesh.triangle_array[tri.child_2]
                p1 = dmesh.vertex_array[tri_ch.index_1]
                p2 = dmesh.vertex_array[tri_ch.index_2]
                p3 = dmesh.vertex_array[tri_ch.index_3]

                println("The child 2 triangle P1: [$(p1.x), $(p1.y)]")
                println("The child 2 triangle P1: [$(p2.x), $(p2.y)]")
                println("The child 2 triangle P1: [$(p3.x), $(p3.y)]")
            end

            if tri.child_3 != 0
                tri_ch = dmesh.triangle_array[tri.child_3]
                p1 = dmesh.vertex_array[tri_ch.index_1]
                p2 = dmesh.vertex_array[tri_ch.index_2]
                p3 = dmesh.vertex_array[tri_ch.index_3]

                println("The child 3 triangle P1: [$(p1.x), $(p1.y)]")
                println("The child 3 triangle P1: [$(p2.x), $(p2.y)]")
                println("The child 3 triangle P1: [$(p3.x), $(p3.y)]")
            end

            # error("Something went wrong with the point location")
        end
        if succes
            tri_idx = child_tri_idx
            tri = dmesh.triangle_array.data[tri_idx]
        end
    end
    return (tri, tri_idx)
end

function point_vector_in_triangle(dmesh, tri)
    return [
            dmesh.vertex_array[tri.index_1],
            dmesh.vertex_array[tri.index_2],
            dmesh.vertex_array[tri.index_3] ]
end

function __create_triangles_in_containing!(dmesh::DelaunayMesh, tri::DelaunayMeshTriangle, tri_idx::Int, p_idx::Int)
    # create 3 triangles in the containtment triangle
    tri_pxy_idx = dmesh.triangle_array.ptr + 1
    tri_pyz_idx = tri_pxy_idx + 1
    tri_pzx_idx = tri_pyz_idx + 1

    tri.alive = false
    tri.child_1 = tri_pxy_idx
    tri.child_2 = tri_pyz_idx
    tri.child_3 = tri_pzx_idx


    tri_pxy = DelaunayMeshTriangle()
    tri_pyz = DelaunayMeshTriangle()
    tri_pzx = DelaunayMeshTriangle()

    push!(dmesh.triangle_array, tri_pxy)
    push!(dmesh.triangle_array, tri_pyz)
    push!(dmesh.triangle_array, tri_pzx)


    tri_pxy.parent = tri_idx
    tri_pyz.parent = tri_idx
    tri_pzx.parent = tri_idx

    tri_pxy.alive = true
    tri_pyz.alive = true
    tri_pzx.alive = true


    tri_pxy.index_1 = p_idx
    tri_pxy.index_2 = tri.index_1
    tri_pxy.index_3 = tri.index_2

    tri_pyz.index_1 = p_idx
    tri_pyz.index_2 = tri.index_2
    tri_pyz.index_3 = tri.index_3

    tri_pzx.index_1 = p_idx
    tri_pzx.index_2 = tri.index_3
    tri_pzx.index_3 = tri.index_1


    tri_pxy.neighbor_12 = tri_pzx_idx
    tri_pxy.neighbor_23 = tri.neighbor_12
    tri_pxy.neighbor_31 = tri_pyz_idx

    tri_pyz.neighbor_12 = tri_pxy_idx
    tri_pyz.neighbor_23 = tri.neighbor_23
    tri_pyz.neighbor_31 = tri_pzx_idx

    tri_pzx.neighbor_12 = tri_pyz_idx
    tri_pzx.neighbor_23 = tri.neighbor_31
    tri_pzx.neighbor_31 = tri_pxy_idx


    # update the neighborhood relationships

    # X = dmesh.triangle_array.data[tri.index_1]
    # Y = dmesh.triangle_array.data[tri.index_2]
    # Z = dmesh.triangle_array.data[tri.index_3]

    X = dmesh.vertex_array[tri.index_1]
    Y = dmesh.vertex_array[tri.index_2]
    Z = dmesh.vertex_array[tri.index_3]

    if tri.neighbor_12 != 0
        tri_ayx = dmesh.triangle_array.data[tri.neighbor_12]
        x_local_idx = find_point_local_index(dmesh, tri_ayx, X)
        if x_local_idx == 1
            tri_ayx.neighbor_31 = tri_pxy_idx
        elseif x_local_idx == 2
            tri_ayx.neighbor_12 = tri_pxy_idx
        elseif x_local_idx == 3
            tri_ayx.neighbor_23 = tri_pxy_idx
        else
            error("Something went wrong")
        end
    end

    if tri.neighbor_23 != 0
        tri_bzy = dmesh.triangle_array.data[tri.neighbor_23]
        y_local_idx = find_point_local_index(dmesh, tri_bzy, Y)
        if y_local_idx == 1
            tri_bzy.neighbor_31 = tri_pyz_idx
        elseif y_local_idx == 2
            tri_bzy.neighbor_12 = tri_pyz_idx
        elseif y_local_idx == 3
            tri_bzy.neighbor_23 = tri_pyz_idx
        else
            error("Something went wrong")
        end
    end

    if tri.neighbor_31 != 0
        tri_cxz = dmesh.triangle_array.data[tri.neighbor_31]
        z_local_idx = find_point_local_index(dmesh, tri_cxz, Z)
        if z_local_idx == 1
            tri_cxz.neighbor_31 = tri_pzx_idx
        elseif z_local_idx == 2
            tri_cxz.neighbor_12 = tri_pzx_idx
        elseif z_local_idx == 3
            tri_cxz.neighbor_23 = tri_pzx_idx
        else
            error("Something went wrong")
        end
    end

    return dmesh
end


function neighbor_triangle_index(dmesh::DelaunayMesh, tri::DelaunayMeshTriangle, not_edge_point)::Int
    A = dmesh.vertex_array[tri.index_1]
    B = dmesh.vertex_array[tri.index_2]
    C = dmesh.vertex_array[tri.index_3]

    neighbor_index = 0
    if A == not_edge_point
        # edge BC
        neighbor_index = tri.neighbor_23
    elseif B == not_edge_point
        # edge CA
        neighbor_index = tri.neighbor_31
    elseif C == not_edge_point
        # edge AB
        neighbor_index = tri.neighbor_12
    else
        println("Point is not one of the triangle vertices")
    end
    return neighbor_index
end

function find_point_local_index(dmesh, tri, point)
    A = dmesh.vertex_array[tri.index_1]
    B = dmesh.vertex_array[tri.index_2]
    C = dmesh.vertex_array[tri.index_3]

    local_index = 0
    if A == point
        # edge BC
        local_index = 1
    elseif B == point
        # edge CA
        local_index = 2
    elseif C == point
        # edge AB
        local_index = 3
    else
        println("Point is not one of the triangle vertices")
    end

    return local_index
end

function point_index_from_local_index(tri, local_index::Int)
    idx = 0
    if local_index == 1
        idx = tri.index_1
    elseif local_index == 2
        idx = tri.index_2
    elseif local_index == 3
        idx = tri.index_3
    else
        println("Index out of bound")
    end
    return idx
end

function insert_existing_point!(dmesh::DelaunayMesh, p_idx::Int)
    L = length(dmesh.vertex_array)
    if p_idx > L
        println("Requested index greater than the length")
        return
    end
    P = dmesh.vertex_array[p_idx]
    (tri_parent, tri_parent_idx) = find_containing_triange(dmesh, p_idx)
    __create_triangles_in_containing!(dmesh, tri_parent, tri_parent_idx, p_idx)

    # loop over the neighboring triangles for checking the delaunay criterion
    # tri_pab_idx = dmesh.triangle_array.ptr-2
    # tri_pbc_idx = tri_pab_idx + 1
    # tri_pca_idx = tri_pbc_idx + 1

    tri_pab_idx = tri_parent.child_1
    tri_pbc_idx = tri_parent.child_2
    tri_pca_idx = tri_parent.child_3

    tri_pab = dmesh.triangle_array.data[tri_pab_idx]
    tri_pbc = dmesh.triangle_array.data[tri_pbc_idx]
    tri_pca = dmesh.triangle_array.data[tri_pca_idx]


    tri_stack = datastructs.Stack{DelaunayMeshTriangle}(3)
    push!(tri_stack, tri_pca)
    push!(tri_stack, tri_pbc)
    push!(tri_stack, tri_pab)

    while !isempty(tri_stack)
        act_tri = pop!(tri_stack)
        neighbor_index = neighbor_triangle_index(dmesh, act_tri, P)
        if neighbor_index == 0
            continue
        end
        neighbor_tri = dmesh.triangle_array.data[neighbor_index]

        x_global_idx = act_tri.index_2
        y_global_idx = act_tri.index_3
        X = dmesh.vertex_array[x_global_idx]
        Y = dmesh.vertex_array[y_global_idx]

        local_idx_x = find_point_local_index(dmesh, neighbor_tri, X)
        local_idx_y = find_point_local_index(dmesh, neighbor_tri, Y)
        if local_idx_x == 0
            error("Local index X cannot be zero")
        end
        if local_idx_y == 0
            error("Local index Y cannot be zero")
        end

        if local_idx_x == 1 && local_idx_y == 3
            local_idx_z = 2
        elseif local_idx_x == 2 && local_idx_y == 1
            local_idx_z = 3
        elseif local_idx_x == 3 && local_idx_y == 2
            local_idx_z = 1

        elseif local_idx_x == 1 && local_idx_y == 2
            local_idx_z = 3
        elseif local_idx_x == 2 && local_idx_y == 3
            local_idx_z = 1
        elseif local_idx_x == 3 && local_idx_y == 1
            local_idx_z = 2

        else
            error("I dont think the triangle is in ccw order")
        end
        z_global_idx = point_index_from_local_index(neighbor_tri, local_idx_z)
        Z = dmesh.vertex_array[z_global_idx]

        det_mat = in_circle(X, Z, Y, P)
        if abs(det_mat) <= 1e-10
            # fuzz the point
            pm = rand(1)
            s = +1.0
            if pm[1] < 0.5
                s = -1.0
            end
            fuzz_value = s * eps(P.x) # s * sqrt( eps(P.x) )
            fuzz_value = -s * eps(P.y) # -s * sqrt( eps(P.y) )
            P.x = P.x + fuzz_value
            P.y = P.y + fuzz_value
        end
        if det_mat > 0
            # harder part:
            #   - make the current triagngle dead
            #   - create two new triangles
            #   - push them to the stack
            #   - set the act_tri and neighbor_tri children 1,2 to this new triangles

            #   - reproduce neighborhood indices

            neighbor_tri.alive = false
            act_tri.alive = false

            tri_pzy = DelaunayMeshTriangle()
            tri_pxz = DelaunayMeshTriangle()
            push!(tri_stack, tri_pzy)
            push!(tri_stack, tri_pxz)

            new_tri_pzy_idx = dmesh.triangle_array.ptr + 1
            new_tri_pxz_idx = dmesh.triangle_array.ptr + 2
            push!(dmesh.triangle_array, tri_pzy)
            push!(dmesh.triangle_array, tri_pxz)

            tri_pzy.alive = true
            tri_pxz.alive = true

            tri_pzy.parent = neighbor_index
            tri_pxz.parent = neighbor_index

            neighbor_tri.child_1 = new_tri_pzy_idx
            neighbor_tri.child_2 = new_tri_pxz_idx
            act_tri.child_1 = new_tri_pzy_idx
            act_tri.child_2 = new_tri_pxz_idx

            tri_pzy.index_1 = p_idx
            tri_pzy.index_2 = z_global_idx
            tri_pzy.index_3 = y_global_idx

            tri_pxz.index_1 = p_idx
            tri_pxz.index_2 = x_global_idx
            tri_pxz.index_3 = z_global_idx

            # update neighbor indices
            if local_idx_x == 1
                tri_pzy_neighbor_23 = neighbor_tri.neighbor_23
                tri_pxz_neighbor_23 = neighbor_tri.neighbor_12
            elseif local_idx_x == 2
                tri_pzy_neighbor_23 = neighbor_tri.neighbor_31
                tri_pxz_neighbor_23 = neighbor_tri.neighbor_23
            elseif local_idx_x == 3
                tri_pzy_neighbor_23 = neighbor_tri.neighbor_12
                tri_pxz_neighbor_23 = neighbor_tri.neighbor_31
            else
                error("Something went wrong, for debugging only")
            end

            tri_pxz.neighbor_12 = act_tri.neighbor_12 # new_tri_pyz_idx
            tri_pxz.neighbor_23 = tri_pxz_neighbor_23 # ok
            tri_pxz.neighbor_31 = new_tri_pzy_idx # tri_pbc_idx

            tri_pzy.neighbor_12 = new_tri_pxz_idx # tri_pab_idx
            tri_pzy.neighbor_23 = tri_pzy_neighbor_23 # ok
            tri_pzy.neighbor_31 = act_tri.neighbor_31 # new_tri_pzx_idx

            # get the neighbors if exist
            # find the local indices in the neighbors
            # update the common edge neighbor
            if tri_pxz.neighbor_12 != 0
                # neighbor exists
                nei_tri = dmesh.triangle_array.data[tri_pxz.neighbor_12]
                local_idx_p_in_px_neighbor = find_point_local_index(dmesh, nei_tri, P)
                if local_idx_p_in_px_neighbor == 1
                    nei_tri.neighbor_31 = new_tri_pxz_idx
                elseif local_idx_p_in_px_neighbor == 2
                    nei_tri.neighbor_12 = new_tri_pxz_idx
                elseif local_idx_p_in_px_neighbor == 3
                    nei_tri.neighbor_23 = new_tri_pxz_idx
                else
                    error("Something went wrong")
                end
            end

            if tri_pxz.neighbor_23 != 0
                # neighbor exists
                nei_tri = dmesh.triangle_array.data[tri_pxz.neighbor_23]
                local_idx_x_in_xz_neighbor = find_point_local_index(dmesh, nei_tri, X)
                if local_idx_x_in_xz_neighbor == 1
                    nei_tri.neighbor_31 = new_tri_pxz_idx
                elseif local_idx_x_in_xz_neighbor == 2
                    nei_tri.neighbor_12 = new_tri_pxz_idx
                elseif local_idx_x_in_xz_neighbor == 3
                    nei_tri.neighbor_23 = new_tri_pxz_idx
                else
                    error("Something went wrong")
                end
            end

            if tri_pzy.neighbor_23 != 0
                # neighbor exists
                nei_tri = dmesh.triangle_array.data[tri_pzy.neighbor_23]
                local_idx_z_in_zy_neighbor = find_point_local_index(dmesh, nei_tri, Z)
                if local_idx_z_in_zy_neighbor == 1
                    nei_tri.neighbor_31 = new_tri_pzy_idx
                elseif local_idx_z_in_zy_neighbor == 2
                    nei_tri.neighbor_12 = new_tri_pzy_idx
                elseif local_idx_z_in_zy_neighbor == 3
                    nei_tri.neighbor_23 = new_tri_pzy_idx
                else
                    error("Something went wrong")
                end
            end

            if tri_pzy.neighbor_31 != 0
                # neighbor exists
                nei_tri = dmesh.triangle_array.data[tri_pzy.neighbor_31]
                local_idx_y_in_yp_neighbor = find_point_local_index(dmesh, nei_tri, Y)
                if local_idx_y_in_yp_neighbor == 1
                    nei_tri.neighbor_31 = new_tri_pzy_idx
                elseif local_idx_y_in_yp_neighbor == 2
                    nei_tri.neighbor_12 = new_tri_pzy_idx
                elseif local_idx_y_in_yp_neighbor == 3
                    nei_tri.neighbor_23 = new_tri_pzy_idx
                else
                    error("Something went wrong")
                end
            end

        else
            # easy part: do nothing
        end
    end

    return dmesh
end


using LinearAlgebra
function is_in_circle(tri_A::P, tri_B::P, tri_C::P, D::P)::Bool where {P <: AbstractPoint}
    det_mat = in_circle(tri_A, tri_B, tri_C, D)
    return det_mat >= 0
end

function in_circle(tri_A::P, tri_B::P, tri_C::P, D::P) where {P <: AbstractPoint}
    # mat = [
    # tri_A.x     tri_A.y     tri_A.x^2 + tri_A.y^2   1;
    # tri_B.x     tri_B.y     tri_B.x^2 + tri_B.y^2   1;
    # tri_C.x     tri_C.y     tri_C.x^2 + tri_C.y^2   1;
    # D.x         D.y         D.x^2 + D.y^2           1
    # ]

    sa = (tri_A.x - D.x)^2 + (tri_A.y - D.y)^2
    sb = (tri_B.x - D.x)^2 + (tri_B.y - D.y)^2
    sc = (tri_C.x - D.x)^2 + (tri_C.y - D.y)^2

    dx_ad = tri_A.x - D.x
    dy_ad = tri_A.y - D.y
    dx_bd = tri_B.x - D.x
    dy_bd = tri_B.y - D.y
    dx_cd = tri_C.x - D.x
    dy_cd = tri_C.y - D.y

    det_a = dx_bd * dy_cd - dx_cd * dy_bd
    det_b = dx_ad * dy_cd - dx_cd * dy_ad
    det_c = dx_ad * dy_bd - dx_bd * dy_ad

    det_mat = sa * det_a - sb * det_b + sc * det_c

    # det_mat = det(mat)
    return det_mat
end


function build_delaunay_mesh!(point_array)
    L = length(point_array)
    if L <= 3
        dmesh = DelaunayMesh()
        for kk = 1:L
            dmesh.vertex_array[kk] = point_array[kk]
        end
        return dmesh
    end
    # sort the point_array -> do not sort them!
    # sort!(point_array, lt = (p1, p2) -> p1.x < p2.x)

    
    

    dmesh = DelaunayMesh(point_array)

    # make an initial reshuffling
    # reshuffling_indices = randperm(L)
    # dmesh.vertex_array = dmesh.vertex_array[reshuffling_indices]
    # shuffle!( view(dmesh.vertex_array, 4:L) )

    (X, Y, Z) = create_initial_triangle(dmesh)


    dmesh.vertex_array[1] = X
    dmesh.vertex_array[2] = Y
    dmesh.vertex_array[3] = Z

    root_triangle = DelaunayMeshTriangle()
    root_triangle.index_1 = 1
    root_triangle.index_2 = 2
    root_triangle.index_3 = 3

    push!(dmesh.triangle_array, root_triangle)
    insert_first_point!(dmesh)

    p_idx_min = 2
    p_idx_max = length(dmesh.vertex_array)-3

    for p_idx = p_idx_min:p_idx_max
        insert_existing_point!(dmesh, 3 + p_idx)
    end


    # shrink to fit
    # dmesh.triangle_array

    return dmesh
end



function triangle_vector_for_plot(dmesh; init_triangle = false)
    tri_stack = datastructs.Stack{Triangle}()
    for kk = 1:dmesh.triangle_array.ptr
        tri_kk = dmesh.triangle_array.data[kk]
        if tri_kk.alive

            if !init_triangle
                if  tri_kk.index_1 == 1 || tri_kk.index_1 == 2 || tri_kk.index_1 == 3 ||
                    tri_kk.index_2 == 1 || tri_kk.index_2 == 2 || tri_kk.index_2 == 3 ||
                    tri_kk.index_3 == 1 || tri_kk.index_3 == 2 || tri_kk.index_3 == 3
                    continue
                end
            end

            push!(tri_stack, Triangle(
                dmesh.vertex_array[tri_kk.index_1],
                dmesh.vertex_array[tri_kk.index_2],
                dmesh.vertex_array[tri_kk.index_3]))
        end
    end
    tri_vec = tri_stack.data[1:tri_stack.ptr]
    return tri_vec
end




function triangle_indices(delmesh::geom.DelaunayMesh; init_triangle = false)

    L = length(delmesh.triangle_array)
    triidx = zeros(Int64, L, 3)

    last_idx = 0
    for ii = 1:L
        
        if !delmesh.triangle_array.data[ii].alive
            continue
        end

        if init_triangle

            last_idx += 1
            triidx[last_idx, 1] = delmesh.triangle_array.data[ii].index_1
            triidx[last_idx, 2] = delmesh.triangle_array.data[ii].index_2
            triidx[last_idx, 3] = delmesh.triangle_array.data[ii].index_3

        else

            tri_kk = delmesh.triangle_array.data[ii]
            if  tri_kk.index_1 == 1 || tri_kk.index_1 == 2 || tri_kk.index_1 == 3 ||
                tri_kk.index_2 == 1 || tri_kk.index_2 == 2 || tri_kk.index_2 == 3 ||
                tri_kk.index_3 == 1 || tri_kk.index_3 == 2 || tri_kk.index_3 == 3
                continue
            end

            last_idx += 1
            triidx[last_idx, 1] = delmesh.triangle_array.data[ii].index_1 - 3
            triidx[last_idx, 2] = delmesh.triangle_array.data[ii].index_2 - 3
            triidx[last_idx, 3] = delmesh.triangle_array.data[ii].index_3 - 3
        end

    end

    triidx = triidx[1:last_idx, :]

    return triidx

end

function envelope_points(delmesh::DelaunayMesh)
    return delmesh.vertex_array[1:3]
end

function valid_points(delmesh::DelaunayMesh)
    return delmesh.vertex_array[4:end]
end





function plot_triangulation(delmesh::DelaunayMesh; init_triangle = false)
    
    px = x(delmesh.vertex_array[4:end])
    py = y(delmesh.vertex_array[4:end])

    # px = point_array[:,1]
    # py = point_array[:,2]

    if isdefined(delmesh, :triangle_index)
        triangle_index = delmesh.triangle_index
    else
        triangle_index = triangle_indices(delmesh)
    end
    

    PyPlot.grid()
    PyPlot.plot( px, py,
        marker = :., linestyle = :none, markersize = 10)

    for tt = 1:size(triangle_index, 1)
        t = triangle_index[tt,:]
        tx = px[ [t[1], t[2], t[3], t[1]]]
        ty = py[ [t[1], t[2], t[3], t[1]]]
        PyPlot.plot(tx, ty)
    end

    #=
    p_x = x(delmesh.vertex_array)
    p_y = y(delmesh.vertex_array)

    tri_vec = triangle_vector_for_plot(delmesh; init_triangle = init_triangle)

    PyPlot.plot(p_x, p_y,
        color = "k",
        alpha = 0.7,
        linestyle = "none",
        marker = ".",
        markersize = 10)

    if init_triangle
        (init_tri_x, init_tri_y) = discretize_for_plot(
            [delmesh.vertex_array[1], 
            delmesh.vertex_array[2],
            delmesh.vertex_array[3]], true)

        PyPlot.plot(init_tri_x, init_tri_y,
            marker = "o", linewidth = 2)
    end


    for kk = 1:length(tri_vec)
        (p_x, p_y) = discretize_for_plot(tri_vec[kk])
        PyPlot.plot(p_x, p_y,
        marker = "o",
        linewidth = 1,
        color = "r",
        alpha = 0.7,)
    end

    =#
end