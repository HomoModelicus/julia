

include("../src/geom_module.jl")

module ptest

using Random
using BenchmarkTools
using ..geom
using PyPlot
PyPlot.pygui(true)



# poly_tri = geom.create_polygon([0., 10., 5.], [0., 0., 5])
poly_L_shape = geom.create_polygon(
    geom.MutablePoint,
    [0., 10, 10, 5, 5, 0],
    [0., 0, 5, 5, 15, 15])

poly_3 = geom.create_polygon(
    geom.MutablePoint,
    [0., 1, 0],
    [0., 1, 2])

poly_4_convex = geom.create_polygon(
    geom.MutablePoint,
    [0., 1, 0, -1],
    [0., 1, 2, 1])

poly_4_concave = geom.create_polygon(
    geom.MutablePoint,
    [-1, 0., 1, 0],
    [1, 0., 1, 0.7])

poly_5_convex = geom.create_polygon(
    geom.MutablePoint,
    [0., 1, 1.71, 0.5, -0.2],
    [0., 0, 0.5, 1.21, 0.5])

poly_5_concave = geom.create_polygon(
    geom.MutablePoint,
    [0., 1, 0.21, 0.5, -0.2],
    [0., 0, 0.5, 1.21, 0.5])

# PyPlot.figure()
# PyPlot.grid()
# PyPlot.plot(
#     geom.x(poly_5_concave.point_array),
#     geom.y(poly_5_concave.point_array),
#     linewidth = 2,
#     marker = "o")
#
PyPlot.figure()
PyPlot.grid()
PyPlot.plot(
    geom.x(poly_5_convex.point_array),
    geom.y(poly_5_convex.point_array),
    linewidth = 2,
    marker = "o")

tri_array = geom.triangulate(poly_5_convex)


# L = length(poly_L_shape.point_array)
# b = falses(L, L)
#
# for ii = 1:L
#     for jj = 1:L
#         b[ii, jj] = geom.is_diagonal_helper(ptest.poly_L_shape, ii, jj)
#     end
# end

# geom.is_diagonal_helper(ptest.poly_L_shape, 2, 5)
# geom.is_diagonal_helper(ptest.poly_L_shape, 2, 6)
# geom.is_diagonal_helper(ptest.poly_L_shape, 3, 6)




#=
dmesh = geom.build_delaunay_mesh!(poly_L_shape.point_array)


# (ptri_x, ptri_y) = geom.discretize_for_plot(poly_tri)
(pL_x, pL_y) = geom.discretize_for_plot(poly_L_shape)


tri_vec = geom.triangle_vector_for_plot(dmesh)
(init_tri_x, init_tri_y) = geom.discretize_for_plot(
  [dmesh.vertex_array[1], dmesh.vertex_array[2], dmesh.vertex_array[3]], true)

# r = geom.rotation_matrix( deg2rad(30.0) )
#
# v_xy = r * [ptest.pL_x ptest.pL_y]'
# pL_x = v_xy[1, :]
# pL_y = v_xy[2, :]



PyPlot.figure()
PyPlot.grid()
PyPlot.plot(pL_x, pL_y, color = "k", alpha = 0.7, marker = ".", markersize = 25, linewidth = 3)
PyPlot.plot(init_tri_x, init_tri_y, marker = "o", linewidth = 2)

for kk = 1:length(tri_vec)
    (p_x, p_y) = geom.discretize_for_plot(tri_vec[kk])
    PyPlot.plot(p_x, p_y, marker = "o", linewidth = 1, color = "r", alpha = 0.7)
end

=#

end
