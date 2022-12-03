
# include("../../datastructs/src/datastructs_module.jl")
include("../src/geom_module.jl")



module dbench
using ..datastructs
using Random
using BenchmarkTools
using ..geom

function create_random_points_in_circle(N, R = 10.0)

    r_ = R .* Random.rand(N)
    phi_ = (2*π) .* Random.rand(N)
    x_ = r_ .* cos.(phi_)
    y_ = r_ .* sin.(phi_)
    point_array = map(geom.MutablePoint, x_, y_)

    return point_array
end

function test_random_in_circle(N)
    R = 10.0
    point_array = create_random_points_in_circle(N, R)

    b = @benchmark geom.build_delaunay_mesh!($point_array)

    println("=== test_random_in_circle ===")
    println("N = $(N)")
    show(
        stdout,
        MIME("text/plain"),
        b )
    println("\n\n")
end


function testraw_random_in_circle(N)
    R = 10.0
    point_array = create_random_points_in_circle(N, R)
    b = geom.build_delaunay_mesh!(point_array)
    return nothing
end



end
