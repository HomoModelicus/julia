

include("../src/spline_module.jl")

module stest
using ..spline
using PyPlot
PyPlot.pygui(true)



function test_discrete()
    x = [1.0, 1.5, 2.1, 3., 3.1, 3.4, 4.,  5.5, 6, 7, 8]
    y = [10.0, 10.2, 11,  8,  5,   9,   13,  12,  10, 10, 10]




    natural_spline = spline.fit_natural(x, y)

    xq = collect( range(x[1], x[end], 10000) )
    yq = spline.interpolate(natural_spline, xq)




    PyPlot.figure()
    PyPlot.grid()
    PyPlot.plot(x, y, marker = :o)
    PyPlot.plot(xq, yq)
end

function test_sin()

    x = collect( range(0, 2*pi, 15) )
    y = sin.(x)

    

    natural_spline = spline.fit_natural(x, y)

    xq = collect( range(x[1], x[end], 1000) )
    yq = spline.interpolate(natural_spline, xq)


    PyPlot.figure()
    PyPlot.grid()
    PyPlot.plot(x, y, marker = :o)
    PyPlot.plot(xq, yq)
end



function test_lim_sin()

    x = collect( range(0, 2*pi, 15) )
    y = sin.(x)
    y[y .<= 0] .= 0.0
    

    natural_spline = spline.fit_natural(x, y)

    xq = collect( range(x[1], x[end], 1000) )
    yq = spline.interpolate(natural_spline, xq)


    PyPlot.figure()
    PyPlot.grid()
    PyPlot.plot(x, y, marker = :o)
    PyPlot.plot(xq, yq)
end


function test_clamped()
    x = [1.0, 1.5, 2.1, 3., 3.1, 3.4, 4.,  5.5, 6]
    y = [10.0, 10.2, 11,  8,  5,   9,   13,  12,  10]
    g1 = -10
    g2 = +20
    clamped_spline = spline.fit_clamped(x, y, g1, g2)

    xq = collect( range(x[1], x[end], 1000) )
    yq = spline.interpolate(clamped_spline, xq)
    dyq = spline.diff_interpolate(clamped_spline, xq)



    PyPlot.figure()

    PyPlot.subplot(2,1,1)
    PyPlot.grid()
    PyPlot.plot(x, y, marker = :o)
    PyPlot.plot(xq, yq)

    PyPlot.subplot(2,1,2)
    PyPlot.grid()
    PyPlot.plot(xq, dyq)
end



x = collect( range(0, 2*2*pi, 15) )
y = sin.(x)
# y[y .>= 0.5]  .= 0.5
# y[y .<= -0.5] .= -0.5




akima_spline = spline.fit_modified_akima(x, y)
xq = collect( range(x[1], x[end], 100) )
yq = spline.interpolate(akima_spline, xq)
dyq = spline.diff_interpolate(akima_spline, xq)


PyPlot.figure()
PyPlot.grid()
PyPlot.plot(x, y, marker = :o)
PyPlot.plot(xq, yq)

PyPlot.figure()
PyPlot.grid()
PyPlot.plot(xq, dyq)



end


