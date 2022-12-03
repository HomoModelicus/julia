
include("../../number_theo/src/NumberTheo.jl")


module QuasiRandoms
using LinearAlgebra
using ..NumberTheo


function halton(i; base = 2)
    # von der Corput sequence
    result = 0.0
    f = 1.0
    while i > 0
        f = f / base
        result += f * mod(i, base)
        i = floor(Int, i / base)
    end
    return result
end

function halton_filling_seq(n_points; base = 2)
    return [halton(i, base = base) for i = 1:n_points]
end

function halton_filling_seq(n_points, n_dim)
    upto = max(n_dim * (log(n_dim) + log(log(n_dim))), 6) |> ceil |> Int
    bases = NumberTheo.sieve_of_eratosthenes(upto)
    mat = zeros(n_points, n_dim)
    for dd = 1:n_dim
        mat[:,dd] = halton_filling_seq(n_points; base = bases[dd])
    end
    return mat
end



function pairwise_distances(X)
    # columns are the different dimensions
    # rows are the different points

    (N, n_dim)  = size(X)
    Nn          = div(N * (N-1), 2)
    n           = zeros(Nn)
    kk = 0
    @inbounds for ii = 1:(N-1)
        @inbounds for jj = (ii+1):N
            kk += 1
            v1 = view(X, ii, 1:n_dim)
            v2 = view(X, jj, 1:n_dim)
            n[kk] = norm(v1 - v2)
        end
    end
    return n
end

function morris_mitchell_criterion(X, q = 1.0)
    dists = pairwise_distances(X)
    s = sum( dists.^(-q) )^(1/q)
    return s
end



end

