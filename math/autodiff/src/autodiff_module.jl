


include("../../../stdlib/stacks/src/Stacks.jl")




module autodiff
using ..Stacks
using LinearAlgebra


abstract type AbstractMode end

struct ForwardMode <: AbstractMode
end

struct ReverseMode <: AbstractMode
end



# include("forward_mode.jl")
include("reverse_mode.jl")


end
