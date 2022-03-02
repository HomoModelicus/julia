

include("../../__lib__/std/datastructs/src/datastructs_module.jl")

# dependencies:
# - datastructs

module autodiff
using ..datastructs

include("forward_mode.jl")
include("reverse_mode.jl")

end
