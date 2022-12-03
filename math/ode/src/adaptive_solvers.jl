
include("abstract_solver_types.jl")

function order(::S) where {S <: AbstractOdeSolver}
    error("To be implemented")
end
function n_intermediates(::S) where {S <: AbstractOdeSolver}
    error("To be implemented")
end
function stepper!(ode_solver::S, ode_fcn, stepper_options, stepper_temp::StepperTemporaries) where {S <: AbstractOdeSolver}
    error("To be implemented")
end

# some errors with those: probably wrong formulas
# include("solver_heuneuler.jl")
# include("solver_ros34.jl")

include("solver_bsh23.jl")
include("solver_dp45.jl")
include("solver_ts45.jl")
include("solver_ros23.jl")

