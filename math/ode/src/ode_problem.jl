# =========================================================================== #
# Ode Problem
# =========================================================================== #

struct OdeProblem
    # add mass matrix
    # add event_fcn
    # add output_fcn
    ode_fcn
    time_interval::TimeInterval
    init_cond::Vector{Float64}
end

function n_dim(ode_problem::OdeProblem)
    return length(ode_problem.init_cond)
end
