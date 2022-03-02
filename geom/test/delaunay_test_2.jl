
include("../src/geom_module.jl")



module dtest
using ..geom
using PyPlot
PyPlot.pygui(true)



# x_ = vec([0 1 0.3 1.5 1.7 -0.9 -1])
# y_ = vec([ 0 0.2 1 1.5 3 2.55 0.65])

x_ = [0.0, 1, 2, 3, 2, 1, 0]
y_ = [0.0, 0, 1, 1, 3, 1, 1]

point_array = map( (x, y) -> geom.MutablePoint(x, y), x_, y_ )

delmesh = geom.build_delaunay_mesh!(point_array)



triidx = geom.triangle_indices(delmesh)


PyPlot.figure()
PyPlot.grid()
geom.plot_triangulation(delmesh; init_triangle = false)








end


