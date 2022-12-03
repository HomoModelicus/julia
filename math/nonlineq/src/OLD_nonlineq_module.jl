
#=


include("../../common/numder/src/numder_module.jl")

module nonlineq
using LinearAlgebra
using ..numder

include("../../opti/src/line_search.jl")


struct ToleranceOptions
    max_iter::Int
    step_size_tol::Float64
end

function ToleranceOptions(;max_iter = 100, step_size_tol = 1e-15)
    ToleranceOptions(max_iter, step_size_tol)
end


function broyden(
    fcn,
    x0::Vector{T};
    tol_options::ToleranceOptions = ToleranceOptions(),
    B0 = nothing,
    damping = 1.0) where {T}

    n_dim = length(x0)

    if isnothing(B0)
        B = Matrix( one(T) * I, n_dim, n_dim )
        B = numder.jacobian_fw(fcn, x0)
    else
        B = B0
    end
    
    x = x0
    f = fcn(x)

    x_sol = x

    # merit_fcn(x) = norm( fcn(x) )
    iter = 0
    for outer iter = 1:tol_options.max_iter
        
        p = -(B \ f)
        # line search? -> damping
        s = damping * p

        if norm(s) <= tol_options.step_size_tol
            x_sol = x
            break
        end

        x = x + s
        f1 = fcn(x)
        y = f1 - f
        f = f1
        B = B + (y - B * s) * (s ./ dot(s, s))'

    end
    if iter == tol_options.max_iter
        x_sol = x
    end
    return (x_sol, iter)

end





end # nonlineq




=#


