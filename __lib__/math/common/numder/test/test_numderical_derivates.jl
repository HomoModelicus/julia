
include("../src/numder_module.jl")
include("../../../../std/util/src/util_module.jl")


# =========================================================================== #
# Test
# =========================================================================== #
module numdertest
using ..numder
using ..util
using LinearAlgebra

using PyPlot
PyPlot.pygui(true)

function test_step_size()
    x0 = [0.0, 1e-15, 1e-16, 1, 2, 10]
    h = map( numder.step_size, x0 )
end

function numdiff_fwbw()

    f = sin
    x0 = collect( -pi:0.1:pi )
    g_theo = cos.(x0)

    g_fw = map(x -> numder.numdiff_fw(f, x), x0)
    g_bw = map(x -> numder.numdiff_bw(f, x), x0)

    g_error_fw = g_fw .- g_theo
    g_error_bw = g_bw .- g_theo


    PyPlot.figure()
    PyPlot.grid()
    PyPlot.plot(x0, g_fw, marker=:o)
    PyPlot.plot(x0, g_theo, marker=:*)

    PyPlot.figure()
    PyPlot.grid()
    PyPlot.plot(x0, g_error_fw, marker=:o)
    PyPlot.plot(x0, g_error_bw, marker=:o)

end


function numdiff_central()

    f = sin
    x0 = collect( -pi:0.1:pi )
    g_theo = cos.(x0)

    g_c = map(x -> numder.numdiff_central(f, x), x0)

    g_error_c = g_c .- g_theo

    PyPlot.figure()
    PyPlot.grid()
    PyPlot.plot(x0, g_c, marker=:o)
    PyPlot.plot(x0, g_theo, marker=:*)

    PyPlot.figure()
    PyPlot.grid()
    PyPlot.plot(x0, g_error_c, marker=:o)

end


function gradient_fw()

    f(x) = x[1].^2 + x[2].^3

    x_vec = collect( -pi:0.1:pi )
    y_vec = collect( -pi:0.1:pi )
    
    (x_mat, y_mat) = util.meshgrid( x_vec, y_vec )
    x0 = [x_mat[:] y_mat[:]]
    g_theo_fcn(x) = [2 * x[1], 3 * x[2].^2]

    g_theo = mapslices( g_theo_fcn, x0, dims = 2)
    g_fw = mapslices( x -> numder.gradient_fw(f, x), x0, dims = 2)

    g_error = mapslices( norm, g_fw - g_theo, dims = 2 )
    g_error_mat = reshape(g_error, (length(x_vec), length(y_vec)) )

    PyPlot.figure()
    PyPlot.grid()
    PyPlot.plot_surface(x_vec, y_vec, g_error_mat)
    # PyPlot.plot(g_error)

end


function jacobian_fw()

    # f(x) = [x[1].^2  x[2].^3]
    f(x) = [cos(x[1])  x[1].^2 + x[2].^2   sin(x[2])] # R^2 -> R^3

    x_vec = collect( -pi:0.1:pi )
    y_vec = collect( -pi:0.1:pi )
    (x_mat, y_mat) = util.meshgrid( x_vec, y_vec )
    x0 = [x_mat[:] y_mat[:]]

    idx = 2
    #=
    g_theo_fcn(x) = 
        [
        2 * x[1]    0.0;
        0.0         3 * x[2].^2
        ]
    =#
    g_theo_fcn(x) = 
        [
            -sin(x[1])      0.0
            2 * x[1]        2 * x[2]
            0.0             cos(x[2])
        ]
    g_theo = g_theo_fcn( x0[idx, :] )
    g_fw = numder.jacobian_fw(f, x0[idx, :] )
    g_error = g_fw - g_theo

end


function test_directional_diff_fw()

    f(x) = x[1]^2 + x[2]^2

    x0 = [1.0, 2]
    d = [3.0, 6]
    d = d ./ norm(d)

    dfdd = numder.directional_diff_fw(f, x0, d)

    g = numder.gradient_fw(f, x0)
    df_theo = sum(g .* d)

    println(dfdd)

    println(df_theo)

end




end # numdertest


