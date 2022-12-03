



module DualNumbers


export  AbstractDualNumber,
        DualNumber

abstract type AbstractDualNumber <: Number
end

const BuiltinNumberSubtypes = Union{Real, ComplexF16, ComplexF32, ComplexF64}

struct DualNumber{T} <: AbstractDualNumber
    x::T
    v::T

    function DualNumber{T}(x::T, v::T) where {T}
        return new(x, v)
    end

    function DualNumber(x::T, v::T) where {T}
        return DualNumber{T}(x, v)
    end

    function DualNumber(x::T, v::U) where {T <: BuiltinNumberSubtypes, U <: BuiltinNumberSubtypes}
        R = promote_type(T, U)
        return DualNumber{R}( promote(x, v)... )
    end

    function DualNumber{T}(x::DualNumber{T}) where {T}
        return DualNumber{T}(x.x, x.v)
    end

    function DualNumber(x::DualNumber{T}) where {T}
        return DualNumber{T}(x.x, x.v)
    end

    function DualNumber{U}(x::T) where {U, T <: BuiltinNumberSubtypes} # 
        xc = convert(U, x)
        return DualNumber{U}(xc, zero(U))
    end

    function DualNumber(x::T) where {T <: BuiltinNumberSubtypes}
        return DualNumber{T}(x)
    end
end



function Base.eltype(d::DualNumber{T}) where {T}
    return T
end

function Base.zero(::Type{DualNumber{T}}) where {T}
    return DualNumber(zero(T), zero(T))
end

function Base.one(::Type{DualNumber{T}}) where {T}
    return DualNumber(one(T), zero(T))
end

function Base.zero(x::DualNumber{T}) where {T}
    return zero(DualNumber{T})
end

function Base.one(x::DualNumber{T}) where {T}
    return one(DualNumber{T})
end


function Base.promote_rule(
    ::Type{DualNumber{T1}},
    ::Type{DualNumber{T2}}) where {T1, T2}
    return DualNumber{ promote_type(T1, T2) }
end

function Base.promote_rule(
    ::Type{DualNumber{T1}},
    ::Type{T2}) where {T1, T2}
    return DualNumber{ promote_type(T1, T2) }
end

# function Base.promote_rule(
#     ::Type{T1},
#     ::Type{DualNumber{T2}}) where {T1, T2}
#     return DualNumber{ promote_rule(T1, T2) }
# end



function Base.convert(::Type{DualNumber{T}}, x::DualNumber{T}) where {T}
    return x
end


function Base.convert(::Type{DualNumber{T}}, x::DualNumber{U}) where {T, U}
    R = promote_type(T, U)
    return DualNumber{R}( convert(R, x.x), convert(R, x.v) )
end



function Base.:(==)(d1::DualNumber, d2::DualNumber)
    return d1.x == d2.x && d1.v == d1.v
end

function Base.:(<)(d1::DualNumber, d2::DualNumber)
    return d1.x < d2.x
end

function Base.isless(d1::DualNumber, d2::DualNumber)
    return isless(d1.x, d2.x)
end














function value!(vec::AbstractArray{DualNumber{T}, N}, out::AbstractArray{T, N}) where {T, N}
    for kk = eachindex(vec)
        out[kk] = vec[kk].x
    end
    return out
end

function value(vec::AbstractArray{DualNumber{T}, N}) where {T, N}
    out = similar(vec, T)
    return value!(vec, out)
end

function derivative!(vec::AbstractArray{DualNumber{T}, N}, out::AbstractArray{T, N}) where {T, N}
    for kk = eachindex(vec)
        out[kk] = vec[kk].v
    end
    return out
end

function derivative(vec::Vector{DualNumber{T}}) where {T}
    out = similar(vec, T)
    return derivative!(vec, out)
end









function derivative(fcn::F, x0::T) where {F <: Function, T <: AbstractDualNumber}
    # f R -> R
    y = fcn(x0)
    return y.v
end

function derivative(fcn::F, x0::T) where {F <: Function, T <: Number}
    d = DualNumber(x0, one(T))
    return derivative(fcn, d)
end


function __gradient!(fcn::F, x0::AbstractArray{T,1}, g, ds) where {F <: Function, T <: Number}
    L = length(x0)
    for ii = 1:L
        ds[ii] = DualNumber(x0[ii], one(T))
        y      = fcn(ds)
        g[ii]  = y.v
        ds[ii] = DualNumber(x0[ii], zero(T))
    end

    return g
end

function gradient!(fcn::F, x0::AbstractArray{T,1}, g) where {F <: Function, T <: Number}
    ds = zeros(DualNumber{T}, length(x0))
    return __gradient!(fcn, x0, g, ds)
end


function gradient(fcn::F, x0::Vector{T}) where {F <: Function, T <: Number}
    g = zeros(T, length(x0))
    g = gradient!(fcn, x0, g)
    return g
end


function gradient(fcn, d0::Vector{T}) where {T <: AbstractDualNumber}
    x0 = value(d0)
    return gradient(fcn, x0)
end


function __jacobian!(fcn, x0::Vector{T}, ds, jac) where {T <: Number}
    
    f1     = fcn(ds)
    # jac    = zeros(T, length(f1), length(x0)) # m-by-n

    jac[:, 1] .= derivative(f1)
    for ii = 2:L
        ds[ii-1]   = DualNumber(x0[ii-1], zero(T))
        ds[ii]     = DualNumber(x0[ii], one(T))
        f1         = fcn(ds)
        jac[:, ii] = derivative(f1)
    end

    return jac
end

function jacobian!(fcn, x0::Vector{T}, jac) where {T <: Number}

    L      = length(x0)
    e_i    = zeros(T, L)
    e_i[1] = one(T)
    ds     = map(DualNumber, x0, e_i)

    return __jacobian!(fcn, x0, ds, jac)
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


function __norm(x::AbstractArray{T, 1}) where {T}
    n = zero(T)
    for ii in eachindex(x)
        n += x[ii]^2
    end
    return n
end

function directional_derivative(fcn, x, s)
    # naive implementation
    # g  = gradient(fcn, x)
    # dg = dot(g, s)
    
    # a bit better version, take the gradient of
    sn = __norm(s) # normalize(s)
    # df(t) = begin
    #     z = map(a -> t * a, sn)
    #     y = x + z
    #     return fcn(y)
    # end # fcn(x + t .* s)
    df(d) = fcn(x .+ d/sn .* s)
    dg    = derivative(df, 0.0)
    return dg 
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
    v_ = x_ * (d2.v * log(abs(d2.x)) + d2.x * d1.v / d1.x)
    return DualNumber(x_, v_)
end
# function Base.:^(d1::T, d2::D) where {D <: AbstractDualNumber, T <: Number}
#     x_ = d1 ^ d2.x
#     v_ = x_ * log(d1)
#     return DualNumber(x_, v_)
# end
# function Base.:^(d1::D, d2::T) where {D <: AbstractDualNumber, T <: Real}
#     x_ = d1.x ^ d2
#     v_ = d1.v * d2 * d1.x ^ (d2 - 1)
#     return DualNumber(x_, v_)
# end
function Base.:^(d1::D, d2::T) where {D <: AbstractDualNumber, T <: BuiltinNumberSubtypes}
    (d1, d2) = promote(d1, d2)
    return d1^d2
end

function Base.:^(d1::D, d2::T) where {D <: AbstractDualNumber, T <: Integer}
    (d1, d2) = promote(d1, d2)
    return d1^d2
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



end # module 



