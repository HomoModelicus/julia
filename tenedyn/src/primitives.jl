
# =========================================================================== #
## Block - Primitives
# =========================================================================== #

abstract type AbstractBlock end
abstract type AbstractSource <: AbstractBlock end
abstract type AbstractSink <: AbstractBlock end

abstract type AbstractUnaryTransformer <: AbstractBlock end
abstract type AbstractBinaryTransformer <: AbstractBlock end

abstract type AbstractIntegrator <: AbstractBlock end



include("primitives_source.jl")
include("primitives_unary.jl")
include("primitives_binary.jl")
include("primitives_integrator.jl")

function Base.show(io::IO, block::T) where {T <: AbstractBlock}
    println(T)
    fnames = fieldnames(T)
    for fn in fnames
        print("\t")
        print(fn)
        print(": ")
        print("$(getfield(block, fn))")
        print("\n")
    end
end

function Base.show(io::IO, block::T) where {T <: AbstractInputPin}
    println(T)
    println("\tvalue: $(block.value)")
    # containing_object
end
function Base.show(io::IO, block::T) where {T <: AbstractOutputPin}
    println(T)
    println("\tvalue: $(block.value)")
    println("\tprotocol: $(block.protocol)")
    
    # containing_object
end


function is_integrator(block::T) where {T <: AbstractBlock}
    return false
end

function is_integrator(block::Integrator)
    return true
end


function has_input_pin(block::T) where {T <: AbstractBlock}
    return true
end

function has_input_pin(block::T) where {T <: AbstractSource}
    return false
end

