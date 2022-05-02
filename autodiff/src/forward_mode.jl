
abstract type AbstractDualNumber
end

struct DualNumber{T} <: AbstractDualNumber
    x::T
    v::T
    function DualNumber{T}(x::T, v::T) where {T}
        return new(x, v)
    end
end
function DualNumber(x::T, v::T) where {T}
    return DualNumber{T}(x, v)
end
function DualNumber(x, v)
    return DualNumber( promote(x, v)... )
end
function DualNumber(x::T) where {T}
    return DualNumber{T}(x, one(T))
end

function eltype(d::DualNumber)
    return typeof(d.x)
end

function value(vec::Vector{D}) where {D <: AbstractDualNumber}
    T = eltype(vec[1])
    L = length(vec)
    v = Vector{T}(undef, L)
    for kk = 1:L
        v[kk] = vec[kk].x
    end
    return v
end
function derivative(vec::Vector{D}) where {D <: AbstractDualNumber}
    T = eltype(vec[1])
    L = length(vec)
    v = Vector{T}(undef, L)
    for kk = 1:L
        v[kk] = vec[kk].v
    end
    return v
end


function derivative(fcn, x0::T) where {T <: Number}
    d = DualNumber(x0)
    y = fcn(d)
    return y.v
end 

function derivative(fcn, x0::T) where {T <: AbstractDualNumber}
    y = fcn(x0)
    return y.v
end 

function gradient(fcn, x0::Vector{T}) where {T <: Number}
    
    L      = length(x0)
    e_i    = zeros(T, L)
    ds     = map(DualNumber, x0, e_i)
    g      = zeros(T, L)
    
    for ii = 1:L
        ds[ii] = DualNumber(x0[ii], one(T))
        y      = fcn(ds)
        g[ii]  = y.v
        ds[ii] = DualNumber(x0[ii], zero(T))
    end

    return g
end 

function gradient(fcn, d0::Vector{T}) where {T <: AbstractDualNumber}
    x0 = value(d0)
    return gradient(fcn, x0)
end

function jacobian(fcn, x0::Vector{T}) where {T <: Number}
    # f: R^n -> R^m
    # g_ij = df_i / dx_j

    L      = length(x0)
    e_i    = zeros(T, L)
    e_i[1] = one(T)
    ds     = map(DualNumber, x0, e_i)
    f1     = fcn(ds)
    jac    = zeros(T, length(f1), length(x0)) # m-by-n

    jac[:, 1] = derivative(f1)
    for ii = 2:L
        ds[ii-1]   = DualNumber(x0[ii-1], zero(T))
        ds[ii]     = DualNumber(x0[ii], one(T))
        f1         = fcn(ds)
        jac[:, ii] = derivative(f1)
    end

    return jac
end





function Base.:(==)(d1::DualNumber, d2::DualNumber)
    return d1.x == d2.x && d1.v == d1.v
end

function Base.:(!=)(d1::DualNumber, d2::DualNumber)
    return !(d1 == d2)
end


function Base.:+(d1::D, d2::D) where {D <: AbstractDualNumber}
    x_ = d1.x + d2.x
    v_ = d1.v + d2.v
    return DualNumber(x_, v_)
end
function Base.:+(d1::D, d2::T) where {D <: AbstractDualNumber, T <: Number}
    x_ = d1.x + d2
    v_ = d1.v
    return DualNumber(x_, v_)
end
function Base.:+(d1::T, d2::D) where {D <: AbstractDualNumber, T <: Number}
    return d2 + d1
end


function Base.:-(d1::DualNumber)
    return DualNumber(-d1.x, -d1.v)
end
function Base.:-(d1::D, d2::D) where {D <: AbstractDualNumber}
    x_ = d1.x - d2.x
    v_ = d1.v - d2.v
    return DualNumber(x_, v_)
end
function Base.:-(d1::D, d2::T) where {D <: AbstractDualNumber, T <: Number}
    x_ = d1.x - d2
    v_ = d1.v
    return DualNumber(x_, v_)
end
function Base.:-(d2::T, d1::D) where {D <: AbstractDualNumber, T <: Number}
    x_ = d2 - d1.x
    v_ = -d1.v
    return DualNumber(x_, v_)
end


function Base.:*(d1::D, d2::D) where {D <: AbstractDualNumber}
    x_ = d1.x * d2.x
    v_ = d1.v * d2.x + d1.x * d2.v
    return DualNumber(x_, v_)
end
function Base.:*(d1::D, d2::T) where {D <: AbstractDualNumber, T <: Number}
    x_ = d1.x * d2
    v_ = d1.v * d2
    return DualNumber(x_, v_)
end
function Base.:*(d1::T, d2::D) where {D <: AbstractDualNumber, T <: Number}
    return d2 * d1
end


function Base.:/(d1::D, d2::D) where {D <: AbstractDualNumber}
    x_ = d1.x / d2.x
    v_ = (d1.v * d2.x - d1.x * d2.v) / d2.x^2
    return DualNumber(x_, v_)
end
function Base.:/(d1::D, d2::T) where {D <: AbstractDualNumber, T <: Number}
    x_ = d1.x / d2
    v_ = d1.v / d2
    return DualNumber(x_, v_)
end
function Base.:/(d1::T, d2::D) where {D <: AbstractDualNumber, T <: Number}
    x_ = d1 / d2.x
    v_ = (- d1 * d2.v) / d2.x^2
    return DualNumber(x_, v_)
end

function Base.:^(d1::D, d2::D) where {D <: AbstractDualNumber}
    x_ = d1.x ^ d2.x
    v_ = x_ * (d2.v * log(d2.x) + d2.x * d1.v / d1.x)
    return DualNumber(x_, v_)
end
function Base.:^(d1::T, d2::D) where {D <: AbstractDualNumber, T <: Number}
    x_ = d1 ^ d2.x
    v_ = x_ * log(d1)
    return DualNumber(x_, v_)
end
function Base.:^(d1::D, d2::T) where {D <: AbstractDualNumber, T <: Number}
    x_ = d1.x ^ d2
    v_ = d2 * d1.x ^ (d2 - 1)
    return DualNumber(x_, v_)
end




function Base.abs(d::D) where {D <: AbstractDualNumber}
    x_ = abs(d.x)
    v_ = sign(d.v)
    return DualNumber(x_, v_)
end

function Base.max(d1::D, d2::D) where {D <: AbstractDualNumber}
    x_ = max(d1.x, d2.x)
    v_ = (d1.x < d2.x) * d2.v + !(d1.x < d2.x) * d1.v
    return DualNumber(x_, v_)
end
function Base.max(d1::D, d2::T) where {D <: AbstractDualNumber, T <: Number}
    x_ = max(d1.x, d2)
    v_ = (d1.x < d2) * 0.0 + !(d1.x < d2) * d1.v
    return DualNumber(x_, v_)
end
function Base.max(d1::T, d2::D) where {D <: AbstractDualNumber, T <: Number}
    return max(d2, d1)
end


function Base.min(d1::D, d2::D) where {D <: AbstractDualNumber}
    x_ = min(d1.x, d2.x)
    v_ = (d1.x > d2.x) * d2.v + !(d1.x > d2.x) * d1.v
    return DualNumber(x_, v_)
end
function Base.min(d1::D, d2::T) where {D <: AbstractDualNumber, T <: Number}
    x_ = min(d1.x, d2)
    v_ = (d1.x > d2) * 0.0 + !(d1.x > d2) * d1.v
    return DualNumber(x_, v_)
end
function Base.min(d1::T, d2::D) where {D <: AbstractDualNumber, T <: Number}
    return min(d2, d1)
end



function Base.sin(d::D) where {D <: AbstractDualNumber}
    x_ = sin(d.x)
    v_ = d.v * cos(d.x)
    return DualNumber(x_, v_)
end
function Base.cos(d::D) where {D <: AbstractDualNumber}
    x_ = cos(d.x)
    v_ = - d.v * sin(d.x)
    return DualNumber(x_, v_)
end
function Base.tan(d::D) where {D <: AbstractDualNumber}
    x_ = tan(d.x)
    v_ = d.v * (1/cos(d.x))^2
    return DualNumber(x_, v_)
end


function Base.sinh(d::D) where {D <: AbstractDualNumber}
    x_ = sinh(d.x)
    v_ = d.v * cosh(d.x)
    return DualNumber(x_, v_)
end
function Base.cosh(d::D) where {D <: AbstractDualNumber}
    x_ = cosh(d.x)
    v_ = d.v * sinh(d.x)
    return DualNumber(x_, v_)
end
function Base.tanh(d::D) where {D <: AbstractDualNumber}
    x_ = tanh(d.x)
    v_ = d.v * (1/cosh(d.x))^2
    return DualNumber(x_, v_)
end



function Base.exp(d::D) where {D <: AbstractDualNumber}
    x_ = exp(d.x)
    v_ = d.v * exp(d.x)
    return DualNumber(x_, v_)
end
function Base.log(d::D) where {D <: AbstractDualNumber}
    x_ = log(d.x)
    v_ = d.v / d.x
    return DualNumber(x_, v_)
end
function Base.sqrt(d::D) where {D <: AbstractDualNumber}
    x_ = sqrt(d.x)
    v_ = d.v / sqrt(d.x)
    return DualNumber(x_, v_)
end

# I think they are implemented by map -> no extra implementation is needed
# sum
# prod

