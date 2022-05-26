

include("../../__lib__/std/datastructs/src/datastructs_module.jl")

# dependencies:
# - datastructs

module autodiff
using ..datastructs
using LinearAlgebra


abstract type AbstractMode end

struct ForwardMode <: AbstractMode
end

struct ReverseMode <: AbstractMode
end


include("forward_mode.jl")
include("reverse_mode.jl")


end
