
# =========================================================================== #
# Types
# =========================================================================== #

abstract type DistributionType 
end

struct UniformDistribution{T} <: DistributionType
    a::T
    b::T
end
function UniformDistribution(a::T, b::T) where {T}
    a = min(a, b)
    b = max(a, b)
    UniformDistribution{T}(a, b)
end
function UniformDistribution() where {T}
    UniformDistribution{T}(0.0, 1.0)
end


struct NormalDistribution{T} <: DistributionType
    mu::T
    sigma::T
end
function NormalDistribution(mu::T, sigma::T) where {T}
    if sigma < 0
        error("sigma must be positive")
    end
    NormalDistribution{T}(mu, sigma)
end
function NormalDistribution(;mu = 0.0, sigma = 1.0) 
    NormalDistribution(mu, sigma)
end

struct CauchyDistribution{T} <: DistributionType
    mu::T
    c::T
end
function CauchyDistribution(mu::T, c::T) where {T}
    CauchyDistribution{T}(mu, c)
end
function CauchyDistribution(;mu = 0.0, c = 1.0)
    CauchyDistribution(mu, c)
end



struct MultiNormalDistribution{T} <: DistributionType
    mu::Vector{T}
    sigma::Matrix{T}
    L::LowerTriangular{T, Matrix{T}}
    inv_sigma::Matrix{T}
end
function MultiNormalDistribution(mu::Vector{T}, sigma::Matrix{T}) where {T}
    n_dim = length(mu)
    sz = size(sigma)
    if sz[1] != sz[2]
        error("Non-square sigma matrix")
    end
    if sz[1] != n_dim
        error("dimension mismatch between mu and sigma")
    end

    fact = cholesky(sigma)
    
    id = Matrix{T}( one(T) * I, n_dim, n_dim )
    inv_sigma = fact.L \ ( fact.U \ id )
    MultiNormalDistribution{T}(mu, sigma, fact.L, inv_sigma)
end
