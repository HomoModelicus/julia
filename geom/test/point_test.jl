
include("../src/geom_module.jl")


module pointtest
using ..geom
using PyPlot
PyPlot.pygui(true)


function test_rot_mat()

    phi = 0.0
    rot_mat = geom.RotationMatrix(phi)

    phi = pi
    rot_mat = geom.RotationMatrix(phi)

    phi = pi/2
    rot_mat = geom.RotationMatrix(phi)

    println(rot_mat)

end


function test_point()

    p1 = geom.Point{Float64}(0, 1)
    p2 = geom.Point{Float64}(1, 0)
    p3 = geom.Point{Float64}(1, 1)
    p4 = geom.Point{Float64}(0, 0)

    println("at first index: $(p1[1])" )
    println("at second index: $(p1[2])" )

    println("at first index: $(p1[1] == p1.x)" )
    println("at first index: $(p1[2] == p1.y)" )
    
end


function test_point2()

    p1 = geom.Point{Float64}(2.0, 1)
    p2 = geom.Point{Float64}(1, -1.0)

    p_sum = p1 + p2
    p_neg = p1 - p2
    p_prod = p1 * 10

    println(" p sum = $(p_sum) ")
    println(" p sum = $(p_sum - geom.Point(p1.x + p2.x, p1.y + p2.y) ) ")
    println(" p prod = $(p_prod) ")
    println(" p_neg = $(p_neg) ")


    rot_mat = geom.RotationMatrix(pi/2)

    p_rot = geom.rotate(p1, rot_mat)
    println(" p_rot = $(p_rot) ")


end


function test_point3()

    p1 = geom.Point(10., 3.)

    p_shift = geom.shift(p1, 10., 5.)
    p_scale = geom.scale(p1, 3)

    println(" p_shift = $(p_shift) ")
    println(" p_scale = $(p_scale) ")

end



end # module