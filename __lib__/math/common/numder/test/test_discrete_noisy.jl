

include("../../../opti/src/opti_module.jl")


module ntest
using ..opti

using ..noisydiff
using PyPlot
PyPlot.pygui(true)





function test()

    t = collect( 0:0.01:7 )
    y_theo = sin.(t) # abs.(t .- 3.5)# abs.(t .- 3.5)
    noise = 0.01 * sin.(100 .* t)
    y_noisy = y_theo .+ noise # 0.01 .* randn(size(y_theo))
    y_est = noisydiff.pt1_smooth(t, y_noisy; T = 0.1)



    # @time (x_sol, y_sol, iter, stopping_crit) = noisydiff.tvd(t, y_noisy, lamda = 1 * 0.2,
    #         tol_options = opti.ToleranceOptions(max_iter = 500, step_size_tol = 1e-20, f_abs_tol = 1e-15))
    # dy_tvd_fw = stat.x_sol
    # dy_tvd_fw = x_sol
    # show(stat)
    # y_tvd = y_noisy[1] .+ noisydiff.cumtrapezoidal(t, dy_tvd_fw)



    t_mids = 0.5 * (t[1:end-1] + t[2:end])
    dy_theo = cos.(t_mids)
    dy_straightfw = noisydiff.diff_fw(t, y_noisy)
    dy_pt1_fw = noisydiff.diff_fw(t, y_est)


    w1 = 50
    t_lsq_d1 = t[(w1+1):end]
    dy_lsq_d1 = noisydiff.diff_sliding_least_squares_d1(t, y_noisy, w = w1)

    w3 = w1# 3*w1
    t_lsq_d3 = t[(w3+1):end]
    dy_lsq_d3 = noisydiff.diff_sliding_least_squares_d3(t, y_noisy, w = w3)


    # dy_tvd_fw = noisydiff.diff_fw(t, y_tvd)




    # PyPlot.figure()
    # PyPlot.grid()
    # PyPlot.plot(t, y_noisy)
    # # PyPlot.plot(t, y_theo, linewidth = 2)
    # PyPlot.plot(t, y_est, linewidth = 2)
    # PyPlot.plot(t, y_tvd, linewidth = 2)



    # PyPlot.figure()

    # PyPlot.subplot(2,1,1)
    # PyPlot.grid()
    # PyPlot.plot(t, y_noisy)


    # PyPlot.subplot(2,1,2)
    # PyPlot.grid()
    # # PyPlot.plot(t_mids, dy_theo, linewidth = 2)
    # # PyPlot.plot(t_mids, dy_straightfw)
    # PyPlot.plot(t_mids, dy_pt1_fw, linewidth = 2)
    # PyPlot.plot(t, dy_tvd_fw, linewidth = 4)



    PyPlot.figure()
    PyPlot.grid()
    PyPlot.plot(t_mids, dy_pt1_fw, linewidth = 2)
    PyPlot.plot(t_lsq_d1, dy_lsq_d1, linewidth = 2)
    PyPlot.plot(t_lsq_d3, dy_lsq_d3, linewidth = 2)

end






end
