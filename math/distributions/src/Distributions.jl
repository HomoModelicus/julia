
# include("../../util/src/util_module.jl")
# include("../../../../std/util/src/util_module.jl")

# dependencies:
# - util

include("../../simplesearches/src/SimpleSearches.jl")

module Distributions
using LinearAlgebra
using ..SimpleSearches


include("stat_general.jl")
include("histogram.jl")
include("distr_types.jl")
include("pdf.jl")
include("sampling.jl")


end # distr



