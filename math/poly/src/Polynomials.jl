


module Polynomials
using LinearAlgebra

# Base.+ OK
# Base.- OK
# Base.* OK
# degree OK
# pow to a positive integer OK
# eval OK
# derivative OK
# integrate OK
# roots OK
# create polynomial from roots OK


struct Polynomial{N, T} # monomial basis
    coeff::NTuple{N, T} # coeff[1] is the constant

    function Polynomial{N, T}(coeff::NTuple{N, T}) where {N, T}
        return new(coeff)
    end

    function Polynomial(coeff::AbstractArray{T}) where {T}
        N = length(coeff)
        t = tuple(coeff...)
        return Polynomial{N, T}(t)
    end

    function Polynomial(coeff::Tuple)
        t = promote(coeff...)
        N = length(coeff)
        T = eltype(t)
        return Polynomial{N,T}(t)
    end
    function Polynomial(coeff::T) where {T <: Number}
        return Polynomial((coeff,))
    end

    function Polynomial(coeff::Vararg{N, T}) where {N, T}
        return Polynomial(coeff)
    end

end

function Base.eltype(p::Polynomial)
    return eltype(p.coeff)
end

function degree(p::Polynomial)
    return length(p.coeff)-1
end

function vector(p::Polynomial)
    N = degree(p)+1
    v = Vector{eltype(p)}(undef, N)
    for ii = 1:N
        v[ii] = p.coeff[ii]
    end
    return v
end

function Base.:+(p1::Polynomial, p2::Polynomial)
    N1 = degree(p1) + 1
    N2 = degree(p2) + 1
    N3 = max(N1, N2)
    T1 = eltype(p1)
    T2 = eltype(p2)
    T3 = promote_type(T1, T2)
    
    coeff = zeros(T3, N3)
    for ii = 1:N1
        coeff[ii] += p1.coeff[ii]
    end
    for ii = 1:N2
        coeff[ii] += p2.coeff[ii]
    end
    
    p3 = Polynomial(coeff)
    return p3
end

function Base.:-(p1::Polynomial, p2::Polynomial)
    N1 = degree(p1) + 1
    N2 = degree(p2) + 1
    N3 = max(N1, N2)
    T1 = eltype(p1)
    T2 = eltype(p2)
    T3 = promote_type(T1, T2)
    
    coeff = zeros(T3, N3)
    for ii = 1:N1
        coeff[ii] += p1.coeff[ii]
    end
    for ii = 1:N2
        coeff[ii] -= p2.coeff[ii]
    end
    
    p3 = Polynomial(coeff)
    return p3
end

function Base.:*(p1::Polynomial, p2::Polynomial)

    d1 = degree(p1)
    d2 = degree(p2)
    N1 = d1 + 1
    N2 = d2 + 1
    T1 = eltype(p1)
    T2 = eltype(p2)
    T = promote_type(T1, T2)
    N = d1 + d2 + 1
    v = Vector{T}(undef, N)
    
    if N1 <= N2
        v1 = p1.coeff
        v2 = p2.coeff
    else
        v1 = p2.coeff
        v2 = p1.coeff
        N1, N2 = N2, N1
    end
     

    for ii = 1:d1
        sum = 0.0
        for jj = 1:ii
            sum += v1[ii - jj + 1] * v2[jj]
        end
        v[ii] = sum
    end

    for ii = N1:-1:2
        sum = 0.0
        for jj = ii:N1
            sum += v1[jj] * v2[ii - jj + N2]
        end
        v[ii - N1 + N] = sum
    end

    for ii = N1:N2
        sum = 0.0
        for jj = 1:N1
            sum += v1[N1 - jj + 1] * v2[jj + ii - N1]
        end
        v[ii] = sum
    end

    q = Polynomial(v)
    return q
end

function Base.:^(p::Polynomial, n::Int)
    if n < 0
        error("This is not a polynomial any more")
    end
    if n == 0
        q = Polynomial(1.0)
        return q
    end

    q = p
    for ii = 1:(n-1)
        q = q * p
    end
    return q
end

function integrate(p::Polynomial, C = 0.0)
    # int x^m = x^(m+1) / (m+1)

    v = [C, vector(p)...]

    for ii = 2:length(v)
        v[ii] /= ii - 1
    end

    q = Polynomial(v)
    return q
end

function derivative(p::Polynomial)
    # der x^m = m * x^(m-1)

    v = vector(p)
    v = v[2:end]
    
    for ii = eachindex(v)
        v[ii] *= ii
    end

    q = Polynomial(v)
    return q
end

function highest_nonzero_degree(p::Polynomial; abs_tol = 0.0, rel_tol = eps(1.0))
    d = degree(p)
    max_degree = 0
    for ii = (d+1):-1:1
        if !isapprox(p.coeff[ii], zero(eltype(p)), atol = abs_tol, rtol = rel_tol)
            max_degree = ii - 1
            break
        end
    end

    return max_degree
end

function companion_matrix(p::Polynomial)
    hd = highest_nonzero_degree(p)
    m = zeros(hd, hd)
    for ii = 1:(hd-1)
        m[ii+1, ii] = 1.0
    end
    for ii = 1:hd
        m[1, ii] = - p.coeff[hd + 1 - ii] / p.coeff[hd+1]
    end

    return m
end

function roots(p::Polynomial)
    m = companion_matrix(p)
    F = eigen(m)
    z = F.values
    return z
end

function poly_from_roots(roots::AbstractArray; make_real::Bool = true)
    t = tuple(roots...)
    return poly_from_roots(t; make_real = make_real)
end

function poly_from_roots(roots::Tuple; make_real::Bool = true)
    L = length(roots)
    q = Polynomial(1.0)
    for ii = 1:L
        p = Polynomial( (-roots[ii], one(eltype(roots[1]))) )
        q = p * q
    end
    if make_real
        q_real_or_imag = Polynomial( map(real, q.coeff) )
    else
        q_real_or_imag = q
    end
    return q_real_or_imag
end

function poly_eval(p::Polynomial, x)
    return poly_eval(x, p.coeff)
end

function (p::Polynomial)(x)
    return poly_eval(p, x)
end

function poly_eval(x, a0, a1, a2, a3)
    return ((a3 .* x .+ a2) .* x + a1) .* x .+ a0
end

function poly_eval(x, a0, a1, a2)
    return (a2 .* x .+ a1) .* x + a0
end

function poly_eval(x, a0, a1)
    return a1 .* x .+ a0
end

function poly_eval(x::AbstractArray, p)
    # p array polynomial coeffiecents
    # p[1] + p[2] * x + p[3] * x^2 + ...
    y  = zeros( length(x) )
    np = length(p)
    if np == 0
        return y
    end
    if np == 1
        return p[1] .* ones(np)
    end

    y .= p[np]
    for ii = np:-1:2
        y .= y .* x .+ p[ii-1]
    end

    return y
end

function poly_eval(x::T, p) where {T <: Number}
    y = zero(T)
    np = length(p)
    if np == 0
        return y
    end
    if np == 1
        return p[1]
    end

    y = p[np] 
    for ii = np:-1:2
        y = y * x + p[ii-1]
    end

    return y
end




struct NevilleAitkenPolynomial{T}
    x::Vector{T}
    y::Vector{T}
    tmp::Vector{T}
    
    function NevilleAitkenPolynomial{T}(x::Vector{T}, y::Vector{T}) where {T}
        tmp = zeros(T, length(x)-1)
        return new(x, y, tmp)
    end

    function NevilleAitkenPolynomial(x::Vector{T}, y::Vector{T}) where {T}
        return NevilleAitkenPolynomial{T}(x, y)
    end
end

function (p::NevilleAitkenPolynomial)(x::T) where {T <: Number}
    n_row = length(p.x)

    y = zero(T)

    # first column in the divided differences
    for ii = 2:n_row
        scale       = (x - p.x[ii-1]) / (p.x[ii] - p.x[ii-1])
        p.tmp[ii-1] = p.y[ii-1] + scale * (p.y[ii] - p.y[ii-1])
    end

    for jj = 2:n_row
        kk = 0
        for ii = (jj+1):n_row
            kk += 1
            scale     = (x - p.x[ii-jj]) / (p.x[ii] - p.x[ii-jj])
            p.tmp[kk] = p.tmp[kk] + scale * (p.tmp[kk+1] - p.tmp[kk])
        end
    end

    y = p.tmp[1]

    return y
end


struct NewtonPolynomial{T}
    x::Vector{T}
    y::Vector{T}
    d::Vector{T} # diagonal in the divided differences

    function NewtonPolynomial{T}(x::Vector{T}, y::Vector{T}) where {T}
        d = zeros(length(y) + 1)
        prepare_divided_differences!(x, y, d)
        return new(x, y, d)
    end

    function NewtonPolynomial(x::Vector{T}, y::Vector{T}) where {T}
        return NewtonPolynomial{T}(x, y)
    end
end

function prepare_divided_differences!(x, y, d)
    
    n = length(y)

    d[1] = y[1]
    for ii = 2:n
        d[ii] = (y[ii] - y[ii-1]) / (x[ii] - x[ii-1])
    end

    for jj = 3:n
        for ii = jj:n
            d[ii] = (d[ii] - d[ii-1]) / (x[ii] - x[ii-jj+1])
        end
    end

    return nothing
end


function (p::NewtonPolynomial)(x::T) where {T <: Number}
    # x  = x - p.x[1]
    nd = length(p.d)
    y  = p.d[nd]
    for ii = (nd-1):-1:1
        y = (x - p.x[ii]) * y + p.d[ii]
    end

    return y
end



end # module





