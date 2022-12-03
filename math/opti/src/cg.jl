
module cg

using BenchmarkTools
using LinearAlgebra

function conjgrad(A, b, x_init; max_iter = Int(ceil(length(b)*5)), residual_tol = 1e-20 )

    n_dim = length(b)
    
    x0  = copy(x_init)
    r0  = A * x0 - b
    p0  = -r0
    rtr = dot(r0, r0)
    iter = 0
    
    Ap = similar(x0)
    for outer iter = 1:max_iter
        if rtr <= residual_tol
            break
        end
        # Ap      = A * p0
        mul!(Ap, A, p0)
        alpha   = rtr / dot(p0, Ap)
        @inbounds @simd for ii = 1:n_dim
            x0[ii] += alpha * p0[ii]
            r0[ii] += alpha * Ap[ii]
        end
        # x1      = x0 + alpha * p0
        # r1      = r0 + alpha * Ap
        rtr1    = dot(r0, r0)
        beta    = rtr1 / rtr
        # p1      = - r1 + beta * p0

        @inbounds  @simd  for ii = 1:n_dim
            p0[ii] = p0[ii] * beta - r0[ii]
        end

        # p0  = p1
        rtr = rtr1
        # x0  = x1
        # r0  = r1
    end
    return (x0, iter)
end


function test()
    
    # n_dim = 3000
    # 0.193567 seconds (6 allocations: 68.711 MiB, 28.44% gc time)
    # 35.281426 seconds (10 allocations: 117.578 KiB)

    n_dim = 5
    A = rand(n_dim, n_dim)
    A = A' * A
    b = rand(n_dim)

    x0 = rand(n_dim)

    # b = @benchmark x_theo = $A \ $b
    # b = @benchmark (x_cg, iter) = conjgrad($A, $b, $x0)

    b1 = @benchmark $A \ $b
    b2 = @benchmark conjgrad($A, $b, $x0)

    return (b1, b2)

    # println("dx: $(x_theo - x_cg)")
    # println("norm dx: $(norm(x_theo - x_cg))")

end

end


