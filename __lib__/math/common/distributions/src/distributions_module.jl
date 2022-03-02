
# include("../../util/src/util_module.jl")
include("../../../../std/util/src/util_module.jl")

# dependencies:
# - util

module distributions
using LinearAlgebra
using ..util


include("stat_general.jl")
include("histogram.jl")
include("distr_types.jl")
include("pdf.jl")
include("sampling.jl")


end # distr



