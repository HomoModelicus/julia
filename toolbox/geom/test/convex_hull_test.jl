


include("../src/geom_module.jl")


module gtest
using BenchmarkTools
using ..geom
using PyPlot
PyPlot.pygui(true)


function test_for_concrete_points()

    x_ = [ 0.5715937461408043
    0.8916206497257309
    0.8203136478441682
    0.25164289137427875
    0.4403285873605831
    0.43681263870560505
    0.2217704001238916
    0.20004462640858622
    0.5542972315770416
    0.9659375830665178
    0.1
    1]
   
    y_ = [ 0.712953799846491
    0.8172755930467877
    0.8094867906788563
    0.5920712401620924
    0.7383511283992972
    0.4897454560982253
    0.34283329277824315
    0.39353333699051496
    0.7313215009997691
    0.19999430363560622
    0.3
    0.3]


    point_array = map(geom.Point, x_, y_)
    (p_x, p_y) = geom.discretize_for_plot(point_array)

    ch_graham   = geom.graham_scan!(point_array)
    ch_jarvis   = geom.jarvis_march!(point_array)
    ch_jarvis2  = geom.jarvis2!(point_array)
    ch_jarvis3  = geom.jarvis3!(point_array)
    ch_incr     = geom.incremental_hull!(point_array)

    (ch_graham_x, ch_graham_y)      = geom.discretize_for_plot(ch_graham, true)
    (ch_jarvis_x, ch_jarvis_y)      = geom.discretize_for_plot(ch_jarvis, true)
    (ch_jarvis2_x, ch_jarvis2_y)    = geom.discretize_for_plot(ch_jarvis2, true)
    (ch_jarvis3_x, ch_jarvis3_y)    = geom.discretize_for_plot(ch_jarvis3, true)
    (ch_incr_x, ch_incr_y)          = geom.discretize_for_plot(ch_incr, true)
    
    
    

    PyPlot.figure()
    PyPlot.grid()
    
    PyPlot.plot(p_x, p_y,
        color = "k",
        alpha = 0.7,
        linestyle = "none",
        marker = ".",
        markersize = 10)

    PyPlot.plot(ch_graham_x, ch_graham_y,
        linewidth = 2,
        marker = "o")


    PyPlot.figure()
    PyPlot.grid()
    
    PyPlot.plot(p_x, p_y,
        color = "k",
        alpha = 0.7,
        linestyle = "none",
        marker = ".",
        markersize = 10)

    PyPlot.plot(ch_jarvis_x, ch_jarvis_y,
        linewidth = 2,
        marker = "o")

        


    PyPlot.figure()
    PyPlot.grid()
    
    PyPlot.plot(p_x, p_y,
        color = "k",
        alpha = 0.7,
        linestyle = "none",
        marker = ".",
        markersize = 10)

    PyPlot.plot(ch_incr_x, ch_incr_y,
        linewidth = 2,
        marker = "o")
end


function test_random_test()


    for kk = 1:3# 100
        N_point = 10
        point_array = geom.random_point(N_point)
    
        point_array = map(p -> geom.Point(p.x + p.y, p.x - p.y), point_array)
    
        ch_graham = geom.graham_scan!(point_array)
        # ch = geom.jarvis_march!(point_array)
        # ch = geom.jarvis2!(point_array)
        # ch = geom.jarvis3!(point_array)
        ch = geom.incremental_hull!(point_array)
        reduced_point_array = geom.reduce_array_for_convex_hull!(point_array)
    
        # println("The graham length $(length(ch_graham))")
        # @show length(ch)
        # @show all( ch_graham .== ch )
    
        L_incr = length(ch)
        L_graham = length(ch_graham)
        if L_incr == L_graham
            b = all(ch_graham .== ch)
            if b == false
                # they are not identical because of the permutation of the points
                println("stop here")
    
                (p_x, p_y) = geom.discretize_for_plot(point_array)
                (ch_graham_x, ch_graham_y) = geom.discretize_for_plot(ch_graham, true)
                (ch_x, ch_y) = geom.discretize_for_plot(ch, true)
    
    
                PyPlot.figure()
                PyPlot.grid()
                PyPlot.plot(p_x, p_y,
                    color = "k",
                    alpha = 0.7,
                    linestyle = "none",
                    marker = ".",
                    markersize = 10)
                PyPlot.plot(ch_x, ch_y,
                    linewidth = 2,
                    marker = "o")
                PyPlot.plot(ch_graham_x, ch_graham_y,
                    linewidth = 2,
                    marker = "*")
    
    
            end
            println( b )
    
    
        else
            if L_incr < L_graham
                println("graham is longer  Lincr $(L_incr), Lgr $(L_graham)")
            else
                println("incr is longer Lincr $(L_incr), Lgr $(L_graham)")
            end
        end
    end
    
end

test_random_test()







function test_graham_scan()

    N_point = 2000
    point_array = geom.random_point(N_point)

    ch = geom.naive_graham_scan!(point_array)

    (ch_x, ch_y) = geom.discretize_for_plot(ch, true)
    (xs, ys) = geom.discretize_for_plot(point_array)

    PyPlot.figure()
    PyPlot.grid()
    PyPlot.plot(xs, ys, linestyle = :none, marker=:., markersize = 10)
    
    PyPlot.plot(ch_x, ch_y, linewidth=2)


    # n_new = geom.reduce_array_for_convex_hull(point_array)

end





end
