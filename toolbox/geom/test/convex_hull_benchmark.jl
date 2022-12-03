


include("../src/geom_module.jl")



module btest
using BenchmarkTools
using ..geom



function test_naive_graham_scan(point_array)
    b = @benchmark geom.naive_graham_scan!($point_array)

    println("=== test_naive_graham_scan ===")
    show(
        stdout,
        MIME("text/plain"),
        b )
    println("\n\n")

end


function test_graham_scan(point_array)
    b = @benchmark geom.graham_scan!($point_array)

    println("=== test_graham_scan ===")
    show(
        stdout,
        MIME("text/plain"),
        b )
    println("\n\n")

end

function test_jarvis_march(point_array)
    b = @benchmark geom.jarvis_march!($point_array)

    println("=== test_jarvis_march ===")
    show(
        stdout,
        MIME("text/plain"),
        b )
    println("\n\n")

end

function test_jarvis_march2(point_array)
    b = @benchmark geom.jarvis2!($point_array)

    println("=== test_jarvis_march2 ===")
    show(
        stdout,
        MIME("text/plain"),
        b )
    println("\n\n")

end
function test_jarvis_march3(point_array)
    b = @benchmark geom.jarvis3!($point_array)

    println("=== test_jarvis_march3 ===")
    show(
        stdout,
        MIME("text/plain"),
        b )
    println("\n\n")

end
function test_incremental_hull(point_array)
    b = @benchmark geom.incremental_hull!($point_array)

    println("=== test_incremental_hull ===")
    show(
        stdout,
        MIME("text/plain"),
        b )
    println("\n\n")

end





function benchmark_it()
    N_point = 2_000
    # global point_array = geom.random_point(N_point)

    test_graham_scan( geom.random_point(N_point) )
    test_naive_graham_scan( geom.random_point(N_point) )
    # test_jarvis_march( geom.random_point(N_point) )
    # test_jarvis_march2( geom.random_point(N_point) )
    test_jarvis_march3( geom.random_point(N_point) )
    test_incremental_hull(geom.random_point(N_point) )

end



# using Profile

function prof_naive_graham_scan()
    N_point = 200_000
    for kk = 1:1_0
        point_array = geom.random_point(N_point)
        ch = geom.naive_graham_scan!(point_array)
    end
end

function prof_graham_scan()
    N_point = 200_000
    for kk = 1:1_0
        point_array = geom.random_point(N_point)
        ch = geom.graham_scan!(point_array)
    end
end

end
