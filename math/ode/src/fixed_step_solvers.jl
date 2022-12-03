include("abstract_solver_types.jl")

abstract type AbstractFixedStepExplicitSolver <: AbstractOdeSolver
end

abstract type AbstractFixedStepImplicitSolver <: AbstractOdeSolver
end

struct ExplicitEulerSolver <: AbstractFixedStepExplicitSolver
end

struct ImplicitEulerSolver <: AbstractFixedStepImplicitSolver
end

struct FixedStepRungeKutta4Solver <: AbstractFixedStepExplicitSolver
end