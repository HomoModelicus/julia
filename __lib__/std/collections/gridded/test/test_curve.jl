
include("../src/gridded_module.jl")


module gtest
using BenchmarkTools
using ..gridded
using ..util
using PyPlot
PyPlot.pygui(true)

function test_static_curve()

    x = [0.0,  1.0, 2.0, 3.0, 4.0]
    y = [10.0, 20,  30,  40,  50]

    z = 2 * copy(x)


    sc = gridded.StaticCurve(x, y)
    # sc.x = [10] # fails to bind a new curve to that -> good
    sc.x[1] = 10 # still, elements can still be changed

    mc = gridded.MutableCurve(x, y) # the vectors itself can be changed to other vectors == the pointers
    # mc.x[1] = 20
    mc.x = z;

    println( length(mc) )

    PyPlot.figure()
    PyPlot.plot(sc.x, sc.y)


    PyPlot.figure()
    PyPlot.plot(mc.x, mc.y)

end

function test_push()

    x = [0.0,  1.0, 2.0, 3.0, 4.0]
    y = [10.0, 20,  30,  40,  50]

    x_new = 10
    y_new = 50

    sc = gridded.StaticCurve(x, y)
    mc = gridded.MutableCurve(x, y)

    show(sc)
    push!(sc, x_new, y_new)
    show(sc)


    show(mc)
    push!(mc, x_new, y_new)
    show(mc)


end

function test_inv()
    x = [0.0,  1.0, 2.0, 3.0, 4.0]
    y = [10.0, 20,  30,  40,  50]


    mc = gridded.MutableCurve(x, y)

    mc_inv = gridded.inverse(mc)
    show(mc_inv)

end

function test_linear_interpolation()

    crv = gridded.ramp_curve(gridded.MutableCurve{Float64}, 0.0, 0.1, 5.0)
    gridded.map_y!(crv, sin)

    xq = pi/2 # -1.0 # 6.0 # 3.14
    # (yq, right_idx) = gridded.linear_search_interpolate(crv, xq)
    
    (yq, right_idx) = gridded.binary_search_interpolate(crv, xq)



    println(yq)
    println(right_idx)

    PyPlot.figure()
    PyPlot.grid()
    PyPlot.plot(crv.x, crv.y, marker = :.)
    PyPlot.plot(xq, yq, marker = :o)

end


function benchmark_fcn_linear_interpolation(crv, x_vec)
    # x_query = x_vec
    x_query = sort(x_vec)
    left_idx = 1
    for kk = 1:length(x_query)
        xq = x_query[kk]
        (yq, left_idx) = gridded.linear_search_interpolate(crv, xq, init_index = left_idx)
    end
end

function benchmark_fcn_binary_interpolation(crv, x_vec)
    # x_query = x_vec
    x_query = sort(x_vec)
    left_idx = 1
    for kk = 1:length(x_query)
        xq = x_query[kk]
        (yq, left_idx) = gridded.binary_search_interpolate(crv, xq, left_init_index = left_idx)
    end
end


function benchmark_linear_interpolation(crv, x_vec)
    b = @benchmark benchmark_fcn_linear_interpolation($crv, $x_vec)

    println("=== benchmark_linear_interpolation ===")
    show(
            stdout,
            MIME("text/plain"),
            b )
    println("\n\n")
end

function benchmark_binary_interpolation(crv, x_vec)
    b = @benchmark benchmark_fcn_binary_interpolation($crv, $x_vec)

    println("=== benchmark_binary_interpolation ===")
    show(
            stdout,
            MIME("text/plain"),
            b )
    println("\n\n")
end


function benchmark_all_interpolations()

    crv = gridded.ramp_curve(gridded.MutableCurve{Float64}, 0.0, 0.001, 5.0)
    crv.y = gridded.map_y(crv, sin)

    n_vec = [50, 500, 5_000, 50_000]
    for n in n_vec
        # n = 5_0
        a = -1.0
        b = 6.0
        x_vec = (b - a) .* rand(n) .+ a # gridded.ramp(-1.0, 0.003, 6.0)

        println(" ========================================== ")
        println("N: $(n)")
        println(" ========================================== ")
        benchmark_linear_interpolation(crv, x_vec)
        benchmark_binary_interpolation(crv, x_vec)
    end


end



# =========================================================================== #
# Map
# =========================================================================== #


function test_map()

    x = [10.0, 20, 30, 40, 50]
    y = [100.0, 200, 300]
    z = [
        1.0 2   3;
        4   5   6;
        7   8   9;
        10  11  12;
        13  14  15;
        ]

    map = gridded.GriddedMap(x, y, z)
    show(map)

    gridded.map_z!(map, q -> q^2)
    show(map)

    (X, Y) = util.mesh_grid(map.x, map.y)

    PyPlot.figure()
    PyPlot.surf(X, Y, map.z)

end

function test_map_interp()
    x = [10.0, 20, 30, 40, 50]
    y = [100.0, 200, 300]
    z = [
        1.0 2   3;
        4   5   6;
        7   8   9;
        10  11  12;
        13  14  15;
        ]


    map = gridded.GriddedMap(x, y, z)

    xq = 15.0
    yq = 250.0
    (zq, x_idx, y_idx) = gridded.linear_search_interpolate(map, xq, yq)

    println(zq)

    (X, Y) = util.mesh_grid(map.x, map.y)

    PyPlot.figure()
    PyPlot.surf(X, Y, map.z, alpha = 0.5)
    PyPlot.plot3D(xq, yq, zq, marker = :., markersize = 20, color = :k)


end

function test_peaks()

    x_vec = gridded.linspace(-3.0, 3, 10)
    y_vec = gridded.linspace(-3.0, 3, 10)
    map = gridded.peaks(x_vec, y_vec)

    xq = 1.1
    yq = 2.1
    # (zq, x_idx, y_idx) = gridded.linear_search_interpolate(map, xq, yq)
    (zq, x_idx, y_idx) = gridded.binary_search_interpolate(map, xq, yq)

    println(zq)
    println(x_idx)
    println(y_idx)

    (X, Y) = util.mesh_grid(map.x, map.y)

    PyPlot.figure()
    PyPlot.surf(X, Y, map.z, alpha = 0.9)
    PyPlot.plot3D(xq, yq, zq, marker = :., markersize = 20, color = :k)


end




end # gtest



