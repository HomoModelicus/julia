

# write the triangular elements into arrays rather into objects


include("../../__lib__/std/datastructs/src/datastructs_module.jl")
include("../../__lib__/std/io/json/src/json_module.jl")
include("../src/geom_module.jl")





module meshserial
using ..geom
using ..json
using ..datastructs
# using Threads

function read_mesh(url)
    # file io
    # read the file
    # create a dictionary from it
    # deserialize it

    iostr = open(url, "r");
    iobuff = read(iostr, String);
    close(iostr);

    # dict = json.parse_json(iobuff) 
    dict = json.parse(iobuff) 
    delmesh = deserialize_mesh(dict)

    return delmesh
end

function write_mesh(delmesh, url)
    # serialize julia object
    # write into file
    
    serialized_content = ""
    serialized_content = serialize_mesh(delmesh)

    iostr = open(url, "w");
    write(iostr, serialized_content);
    close(iostr);

    return nothing
end


function serialize_mesh(delmesh) # ::DelaunayMesh
    # julia object -> json format

    # mutable struct DelaunayMesh
    #     vertex_array::Vector{<:AbstractPoint}
    #     triangle_array::datastructs.Stack{DelaunayMeshTriangle}

    # "vertex_array": {
    #     "type": Float64,
    #     "length": n,
    #     "x": [],
    #     "y": []
    # },

    # "triangle_array": {
    #     "type": DelaunayMeshTriangle,
    #     "ptr": triangle_array.ptr,
    #     "data": [tri1, tri2,...]
    # }

    # triangle:
    # alive::Bool
    # index_1::Int
    # index_2::Int
    # index_3::Int
    # parent::Int
    # child_1::Int
    # child_2::Int
    # child_3::Int
    # neighbor_12::Int
    # neighbor_23::Int
    # neighbor_31::Int

    str_v = serialize_vertex_array(delmesh)
    str_t = serialize_triangle_array(delmesh)
    str_triidx = serialize_triangle_index(delmesh)

    serialized_content = """
    {
        $(str_v),

        $(str_t),

        $(str_triidx)
    }
    """

    return serialized_content
end

function serialize_triangle_index(delmesh)

    L = size(delmesh.triangle_index,1)

    str_vec_1 = Vector{String}(undef, L)
    str_vec_2 = Vector{String}(undef, L)
    str_vec_3 = Vector{String}(undef, L)
    

    for kk = 1:L-1
        str_vec_1[kk] = string(delmesh.triangle_index[kk,1]) * ","
        str_vec_2[kk] = string(delmesh.triangle_index[kk,2]) * ","
        str_vec_3[kk] = string(delmesh.triangle_index[kk,3]) * ","
    end

    str_vec_1[L] = string(delmesh.triangle_index[L,1])
    str_vec_2[L] = string(delmesh.triangle_index[L,2])
    str_vec_3[L] = string(delmesh.triangle_index[L,3])

    str_idx1 = reduce(*, str_vec_1)
    str_idx2 = reduce(*, str_vec_2)
    str_idx3 = reduce(*, str_vec_3)
    

    str = """
    "triangle_index": {
        "length": $(L),
        "idx1": [$(str_idx1)],
        "idx2": [$(str_idx2)],
        "idx3": [$(str_idx3)]
    }
    """
    return str
end

function serialize_vertex_array(delmesh)
    
    Lp = length(delmesh.vertex_array)
    
    x_str_vec = Vector{String}(undef, Lp)
    y_str_vec = Vector{String}(undef, Lp)
    
    delim = ","

    for kk = 1:Lp-1
        v = delmesh.vertex_array[kk]
        x_str_vec[kk] = string(v.x) * delim
        y_str_vec[kk] = string(v.y) * delim
    end
    v = delmesh.vertex_array[Lp]
    x_str_vec[Lp] = string(v.x)
    y_str_vec[Lp] = string(v.y)

    x_str = reduce(*, x_str_vec)
    y_str = reduce(*, y_str_vec)

    str = """
        "vertex_array": {
            "type": "Float64",
            "length": $(length(delmesh.vertex_array)),
            "x": [$(x_str)],
            "y": [$(y_str)]
        }
    """
    return str
end

function serialize_triangle_array(delmesh)
    # "triangle_array": {
    #     "type": DelaunayMeshTriangle,
    #     "ptr": triangle_array.ptr,
    #     "data": [tri1, tri2,...]
    # }

    Lt = length(delmesh.triangle_array)

    alive       = Vector{String}(undef, Lt)
    index_1     = Vector{String}(undef, Lt)
    index_2     = Vector{String}(undef, Lt)
    index_3     = Vector{String}(undef, Lt)
    parent      = Vector{String}(undef, Lt)
    child_1     = Vector{String}(undef, Lt)
    child_2     = Vector{String}(undef, Lt)
    child_3     = Vector{String}(undef, Lt)
    neighbor_12 = Vector{String}(undef, Lt)
    neighbor_23 = Vector{String}(undef, Lt)
    neighbor_31 = Vector{String}(undef, Lt)

    delim = ","
    for kk = 1:(Lt-1)
        tri = delmesh.triangle_array.data[kk]

        alive[kk]       = "$(tri.alive)" * delim
        index_1[kk]     = "$(tri.index_1)" * delim
        index_2[kk]     = "$(tri.index_2)" * delim
        index_3[kk]     = "$(tri.index_3)" * delim
        parent[kk]      = "$(tri.parent)" * delim
        child_1[kk]     = "$(tri.child_1)" * delim
        child_2[kk]     = "$(tri.child_2)" * delim
        child_3[kk]     = "$(tri.child_3)" * delim
        neighbor_12[kk] = "$(tri.neighbor_12)" * delim
        neighbor_23[kk] = "$(tri.neighbor_23)" * delim
        neighbor_31[kk] = "$(tri.neighbor_31)" * delim

    end

    tri = delmesh.triangle_array.data[Lt]

    alive[Lt]       = "$(tri.alive)"
    index_1[Lt]     = "$(tri.index_1)" 
    index_2[Lt]     = "$(tri.index_2)"
    index_3[Lt]     = "$(tri.index_3)"
    parent[Lt]      = "$(tri.parent)"
    child_1[Lt]     = "$(tri.child_1)"
    child_2[Lt]     = "$(tri.child_2)"
    child_3[Lt]     = "$(tri.child_3)"
    neighbor_12[Lt] = "$(tri.neighbor_12)"
    neighbor_23[Lt] = "$(tri.neighbor_23)"
    neighbor_31[Lt] = "$(tri.neighbor_31)"

    s_alive       = reduce(*, alive)
    s_index_1     = reduce(*, index_1)
    s_index_2     = reduce(*, index_2)
    s_index_3     = reduce(*, index_3)
    s_parent      = reduce(*, parent)
    s_child_1     = reduce(*, child_1)
    s_child_2     = reduce(*, child_2)
    s_child_3     = reduce(*, child_3)
    s_neighbor_12 = reduce(*, neighbor_12)
    s_neighbor_23 = reduce(*, neighbor_23)
    s_neighbor_31 = reduce(*, neighbor_31)

    str = """
    "triangle_array": 
    {
        "type": "DelaunayMeshTriangle",
        "ptr": $(delmesh.triangle_array.ptr),
        "serialized_data": {
            "alive": [$(s_alive)],
            "index_1": [$(s_index_1)],
            "index_2": [$(s_index_2)],
            "index_3": [$(s_index_3)],
            "parent": [$(s_parent)],
            "child_1": [$(s_child_1)],
            "child_2": [$(s_child_2)],
            "child_3": [$(s_child_3)],
            "neighbor_12": [$(s_neighbor_12)],
            "neighbor_23": [$(s_neighbor_23)],
            "neighbor_31": [$(s_neighbor_31)]
        }
    }
    """
    return str
end


#=
function serialize_triangle(tri)
    str = """
    {
        "alive": $(tri.alive),
        "index_1": $(tri.index_1),
        "index_2": $(tri.index_2),
        "index_3": $(tri.index_3),
        "parent": $(tri.parent),
        "child_1": $(tri.child_1),
        "child_2": $(tri.child_2),
        "child_3": $(tri.child_3),
        "neighbor_12": $(tri.neighbor_12),
        "neighbor_23": $(tri.neighbor_23),
        "neighbor_31": $(tri.neighbor_31)
    }
    """
    return str
end
=#

function deserialize_mesh(dict)
    # json dictionary -> julia object

    
    # "vertex_array": {
    #     "type": Float64,
    #     "length": n,
    #     "x": [],
    #     "y": []
    # },

    # "triangle_array": {
    #     "type": DelaunayMeshTriangle,
    #     "ptr": triangle_array.ptr,
    #     "data": [tri1, tri2,...]
    # }

    # triangle:
    # alive::Bool
    # index_1::Int
    # index_2::Int
    # index_3::Int
    # parent::Int
    # child_1::Int
    # child_2::Int
    # child_3::Int
    # neighbor_12::Int
    # neighbor_23::Int
    # neighbor_31::Int

    point_array    = deserialize_vertex_array(dict)
    triangle_array = deserialize_triangle_array(dict)

    triangle_index = deserialize_triangle_index(dict)

    delmesh                = geom.DelaunayMesh()
    delmesh.vertex_array   = point_array
    delmesh.triangle_array = triangle_array
    delmesh.triangle_index = triangle_index


    return delmesh
end

function deserialize_triangle_array(dict)
    subdict = dict["triangle_array"]
    Lt = Int64(subdict["ptr"])

    data = Vector{geom.DelaunayMeshTriangle}(undef, Lt)
    dict_for_tri_array = subdict["serialized_data"]


    alive       = Vector{Bool}(dict_for_tri_array["alive"])
    index_1     = Vector{Int64}(dict_for_tri_array["index_1"])
    index_2     = Vector{Int64}(dict_for_tri_array["index_2"])
    index_3     = Vector{Int64}(dict_for_tri_array["index_3"])
    parent      = Vector{Int64}(dict_for_tri_array["parent"])
    child_1     = Vector{Int64}(dict_for_tri_array["child_1"])
    child_2     = Vector{Int64}(dict_for_tri_array["child_2"])
    child_3     = Vector{Int64}(dict_for_tri_array["child_3"])
    neighbor_12 = Vector{Int64}(dict_for_tri_array["neighbor_12"])
    neighbor_23 = Vector{Int64}(dict_for_tri_array["neighbor_23"])
    neighbor_31 = Vector{Int64}(dict_for_tri_array["neighbor_31"])

    for kk = 1:Lt
        
        data[kk] = geom.DelaunayMeshTriangle(
            alive[kk],
            index_1[kk],
            index_2[kk],
            index_3[kk],
            parent[kk],
            child_1[kk],
            child_2[kk],
            child_3[kk],
            neighbor_12[kk],
            neighbor_23[kk],
            neighbor_31[kk])

    end


    triangle_array = datastructs.Stack{geom.DelaunayMeshTriangle}(Lt)
    triangle_array.ptr = Lt
    triangle_array.data = data

    return triangle_array
end

 #=
function deserialize_triangle_element(tri)

   
    elem = geom.DelaunayMeshTriangle()

    elem.alive = tri["alive"]
    elem.index_1 = tri["index_1"]
    elem.index_2 = tri["index_2"]
    elem.index_3 = tri["index_3"]
    elem.parent = tri["parent"]
    elem.child_1 = tri["child_1"]
    elem.child_2 = tri["child_2"]
    elem.child_3 = tri["child_3"]
    elem.neighbor_12 = tri["neighbor_12"]
    elem.neighbor_23 = tri["neighbor_23"]
    elem.neighbor_31 = tri["neighbor_31"]
    
    return elem
    
end
=#

function deserialize_vertex_array(dict)

    subdict = dict["vertex_array"]
    Lp = subdict["length"]
    xs = subdict["x"]
    ys = subdict["y"]
    
    x = Vector{Float64}(xs)
    y = Vector{Float64}(ys)
    
    point_array = map( (x, y) -> geom.MutablePoint(x, y), x, y )

    return point_array
end

function deserialize_triangle_index(dict)
    subdict = dict["triangle_index"]
    
    Lp = subdict["length"]
    
    i1 = subdict["idx1"]
    i2 = subdict["idx2"]
    i3 = subdict["idx3"]

    idx1 = Vector{Int}(i1)
    idx2 = Vector{Int}(i2)
    idx3 = Vector{Int}(i3)
    
    triangle_index = [idx1 idx2 idx3]

    return triangle_index
end





end



module stest
using PyPlot
PyPlot.pygui(true)
using ..geom
using ..meshserial

# iostr = open("bla.txt", "w")
# write(iostr, "this is the first line\n")
# write(iostr, "this is the second line\n")
# close(iostr)

# iostr = open("bla.txt", "r")
# iobuff = read(iostr, String)
# close(iostr)


# x_ = [0.0, 1, 2, 3, 2, 1, 0]
# y_ = [0.0, 0, 1, 1, 3, 1, 1]

# point_array = map( (x, y) -> geom.MutablePoint(x, y), x_, y_ )
# delmesh = geom.build_delaunay_mesh!(point_array)


function test_serialize()
    rectangle = geom.Rectangle(-1.0, -1.0, 1.0, 1.0)
    circle = geom.Circle(0.0, 0.0, 0.4)


    distance_fcn = p -> geom.difference_signed_distance_function( 
        geom.signed_distance_function(rectangle, p),
        geom.signed_distance_function(circle, p) )

    node_spacing_fcn 	= geom.uniform_node_spacing
    initial_spacing 	= 0.01
    bounding_box 		= geom.Rectangle(-1.0, -1.0, 1.0, 1.0)
    fixed_points 		= zeros(0,2)
    max_iteration 		= 20


    options = geom.MeshGenerationOptions(
        distance_fcn,
        node_spacing_fcn,
        initial_spacing,
        bounding_box,
        fixed_points;
        max_iteration = max_iteration,
        retriangulation_threshold = 0.05)

    @time (point_array, triangle_index, delmesh) = geom.create_mesh(options; visualize = false);




    url = "saved_mesh.txt"

    @time meshserial.write_mesh(delmesh, url)
    # des = meshserial.read_mesh(url)

    # PyPlot.figure()
    # PyPlot.grid()
    # geom.plot_triangulation(delmesh)



    # return nothing
end

function test_read()

    url = "saved_mesh.txt"

    # meshserial.write_mesh(delmesh, url)
    @time des = meshserial.read_mesh(url) # @time 

    # PyPlot.figure()
    # PyPlot.grid()
    # geom.plot_triangulation(des)


    return des
end


end


