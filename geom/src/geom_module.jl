



include("../../__lib__/std/datastructs/src/datastructs_module.jl")
include("../../__lib__/std/util/src/util_module.jl")


module geom

using ..datastructs
using ..util
using LinearAlgebra
using Random
using PyPlot
PyPlot.pygui(true)


# =========================================================================== #
# Types
# =========================================================================== #
include("point.jl")
include("line.jl")
include("circle.jl")
include("quad.jl")
include("triangle.jl")
include("polygon.jl")


# =========================================================================== #
# Operations on types
# =========================================================================== #



# =========================================================================== #
# Mixed operations between types
# =========================================================================== #



# =========================================================================== #
# General, miscellenious types, operations
# =========================================================================== #
include("exterma.jl")
include("rotation_matrix.jl")
include("general.jl")



# =========================================================================== #
# Mesh generation
# =========================================================================== #
include("distance.jl")
include("convex_hull.jl")
include("delaunay.jl")
include("mesh_module.jl")




end # module
