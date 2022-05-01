

include("../src/symbolics_module.jl")

module stest
using ..symbolics

symbolics.@variable v 1.0
symbolics.@variable z 0.2
symbolics.@variable x 0.5


sigma0 = 10

ex = v - z * sigma0 * abs(v)

str = symbolics.to_string(ex)

der = symbolics.derivative(ex, x)
str_der = symbolics.to_string(der)

sder = symbolics.simplify(der)
str_sder = symbolics.to_string(sder)




end

