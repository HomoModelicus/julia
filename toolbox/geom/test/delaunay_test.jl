


include("../src/geom_module.jl")


module dtest
using Random
using BenchmarkTools
using ..geom
using PyPlot
PyPlot.pygui(true)



# x_ = vec([0 1 0.3 1.5 1.7 -0.9 -1])
# y_ = vec([ 0 0.2 1 1.5 3 2.55 0.65])

N = 1000
R = 10.0
# # R_x = 30
# # R_y = 3
# #
# # phi = LinRange(0, 2*π, N)
# # x_ = R_x .* map(cos, phi)
# # y_ = R_y .* map(sin, phi)
#
r_ = R .* Random.rand(N)
phi_ = (2*π) .* Random.rand(N)
x_ = r_ .* cos.(phi_)
y_ = r_ .* sin.(phi_)




point_array = map(geom.MutablePoint, x_, y_)

dmesh = geom.build_delaunay_mesh!(point_array)

point_array2 = copy(point_array)
rnb_idx = Random.randperm(length(point_array2))



(p_x, p_y) = geom.discretize_for_plot(point_array)
(init_tri_x, init_tri_y) = geom.discretize_for_plot(
  [dmesh.vertex_array[1], dmesh.vertex_array[2], dmesh.vertex_array[3]], true)


tri_vec = geom.triangle_vector_for_plot(dmesh)



PyPlot.figure()
PyPlot.grid()
PyPlot.plot(p_x, p_y,
    color = "k",
    alpha = 0.7,
    linestyle = "none",
    marker = ".",
    markersize = 10)
PyPlot.plot(init_tri_x, init_tri_y,
  marker = "o", linewidth = 2)

for kk = 1:length(tri_vec)
    (p_x, p_y) = geom.discretize_for_plot(tri_vec[kk])
    PyPlot.plot(p_x, p_y,
      marker = "o",
      linewidth = 1,
      color = "r",
      alpha = 0.7,)
end



end # module dtest
