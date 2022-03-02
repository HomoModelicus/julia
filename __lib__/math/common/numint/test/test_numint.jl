
include("../src/numint_module.jl")


module ntest
using ..numint
using BenchmarkTools


# fcn(x) = x^3
# fcn(x) = x^4 * log(x + sqrt(x^2 + 1))
fcn(x) = exp(-3*x) - cos(5*pi*x)


interval = numint.Interval(0.0, 8.0)


N = 10000
# I = numint.trapezoidal(fcn, interval, N)
bt = @benchmark I = numint.trapezoidal(fcn, interval, N)
show(stdout, MIME("text/plain"), bt)



integration_options = numint.RombergOptions(abs_tol = 1e-8, rel_tol = 1e-8, N = 250)
br = @benchmark stat_romb = numint.romberg($fcn, $interval, $integration_options)
show(stdout, MIME("text/plain"), br)

bgk = @benchmark stat_gk = numint.gauss_kronrod($fcn, $interval)
show(stdout, MIME("text/plain"), bgk)


end




