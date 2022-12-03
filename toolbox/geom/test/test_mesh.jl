

include("../src/geom_module.jl")



module meshtest
using PyPlot
PyPlot.pygui(true)
using ..geom



rectangle = geom.Rectangle(-1.0, -1.0, 1.0, 1.0)
circle = geom.Circle(0.0, 0.0, 0.4)


distance_fcn = p -> geom.difference_signed_distance_function( 
    geom.signed_distance_function(rectangle, p),
    geom.signed_distance_function(circle, p) )


src_point     = [0.0 0]
h_0           = 0.15
h_inf         = 0.5
spread_factor = 1.0
node_spacing_fcn(p) = geom.point_source_node_spacing(p, src_point, h_0, h_inf, spread_factor)
# node_spacing_fcn(p) = geom.uniform_node_spacing(p)

initial_spacing 	= 0.1
bounding_box 		= geom.Rectangle(-1.0, -1.0, 1.0, 1.0)
fixed_points 		= [
    -1.0 -1.0;
    +1.0 -1.0;
    +1.0 +1.0;
    -1.0 +1.0] # zeros(0,2)
max_iteration 		= 20


options = geom.MeshGenerationOptions(
    distance_fcn,
	node_spacing_fcn,
	initial_spacing,
	bounding_box,
	fixed_points;
	max_iteration = max_iteration)


(point_array, triangle_index, delmesh) = geom.create_mesh(options);

n_points = size(point_array, 1)



px = point_array[:,1]
py = point_array[:,2]
Lt = size(triangle_index,1)


PyPlot.figure()
PyPlot.grid()

PyPlot.plot( px, py,
    marker = :., linestyle = :none, markersize = 10)

for tt = 1:size(triangle_index,1)
    t = triangle_index[tt,:]
    tx = px[ [t[1], t[2], t[3], t[1]]]
    ty = py[ [t[1], t[2], t[3], t[1]]]
    PyPlot.plot(tx, ty)
end


end
