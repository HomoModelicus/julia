
include("../src/ArrayViews.jl")

# #=
module ttest
using ..ArrayViews


vec = [10, 20, 30, 40, 50, 60]

vi = ArrayView(vec, 2, 5)

sa = view(vec, 2:5)


end
# =#
