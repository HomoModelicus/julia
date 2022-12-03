

# =========================================================================== #
# BasicOdeOptions
# =========================================================================== #

struct BasicOdeOptions{N} # where N is the problem dimension
    abs_tol::NTuple{N, Float64}
    rel_tol::NTuple{N, Float64}
    max_iter::Int
    max_rejection_streak::Int

    function BasicOdeOptions{N}(abs_tol, rel_tol, max_iter, max_rejection_streak) where {N}
        return new(tuple(abs_tol...), tuple(rel_tol...), max_iter, max_rejection_streak)
    end
end

function BasicOdeOptions(N::Int, abs_tol::T, rel_tol::T, max_iter, max_rejection_streak) where {T}
    return BasicOdeOptions{N}(abs_tol, rel_tol, max_iter, max_rejection_streak)
end

function BasicOdeOptions(N::Int, abs_tol::T, rel_tol::T, max_iter, max_rejection_streak) where {T <: Number}
    atol = ntuple(i -> abs_tol, N)
    rtol = ntuple(i -> rel_tol, N)
    return BasicOdeOptions{N}(atol, rtol, max_iter, max_rejection_streak)
end


function BasicOdeOptions(
    N::Int64;
    abs_tol = 1e-6,
    rel_tol = 1e-6,
    max_iter = 1_000_000,
    max_rejection_streak = 5000)

    return BasicOdeOptions(
        N,
        abs_tol,
        rel_tol,
        max_iter,
        max_rejection_streak)
end

function BasicOdeOptions(
    ode_problem::OdeProblem;
    abs_tol = 1e-6,
    rel_tol = 1e-6,
    max_iter = 1_000_000,
    max_rejection_streak = 5000)

    return BasicOdeOptions(
        n_dim(ode_problem),
        abs_tol,
        rel_tol,
        max_iter,
        max_rejection_streak)
end



