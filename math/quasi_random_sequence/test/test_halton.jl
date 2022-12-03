

include("../src/quasirandom_module.jl")

module qtest
using ..quasirandom
using PyPlot
PyPlot.pygui(true)

# h = low.halton(1; base = 2)
# h = low.halton(10; base = 2)

n_points = 21
n_dim = 2
hseq = quasirandom.halton_filling_seq(n_points, n_dim)

mmc = quasirandom.morris_mitchell_criterion(hseq)


PyPlot.figure()
PyPlot.grid()
PyPlot.plot(hseq[:,1], hseq[:,2], linestyle = :none, marker = :., markersize = 10)




end

