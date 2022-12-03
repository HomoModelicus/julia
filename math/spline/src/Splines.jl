



include("../../simplesearches/src/SimpleSearches.jl")
include("../../linalg/src/Linalg.jl")


module Splines
using ..Linalg
using ..SimpleSearches


struct NaturalSpline{T}
    x::Vector{T}
    y::Vector{T}
    c::Vector{T}
    function NaturalSpline{T}(x_::Vector{T}, y_::Vector{T}, c_::Vector{T}) where {T}
        return new( copy(x_), copy(y_), copy(c_) )
    end
end
function NaturalSpline(x::Vector{T}, y::Vector{T}, vec::Vector{T}) where {T}
    return NaturalSpline{T}(x, y, vec)
end

function Base.length(natural_spline::NaturalSpline)
    return length(natural_spline.x)
end

function fit_natural(x::Vector{T}, y::Vector{T}) where {T}
    n_points        = length(x)
    dx              = diff(x)
    dy              = diff(y)
    v1              = view(dx, 2:(n_points-1))
    v2              = view(dx, 1:(n_points-2))
    left_diag       = view(dx, 2:(n_points-2))
    main_diag       = 2 .* (v1 .+ v2)
    dydx            = dy ./ dx
    diff_dydx       = diff(dydx)
    rhs             = 6 * diff_dydx
    c               = linalg.linsolve_tridiagonal(left_diag, main_diag, left_diag, rhs)
    natural_spline  = NaturalSpline(x, y, [0.0; c; 0.0])
    return natural_spline
end

# function interpolate(natural_spline::NaturalSpline, xq::T; init_index::Int = 1) where {T <:Number}
function interpolate(spline_obj, xq::T; init_index::Int = 1) where {T <:Number}
    (x, a0, a1, a2, a3) = __find_interp_values(spline_obj, xq, init_index)
    return __poly_eval(x, a0, a1, a2, a3)
end

function __find_interp_values(spline_obj, xq, init_index)
 
    # search for the coeffs
    # use binary search for it
    left_idx = SimpleSearches.binary_search(
        spline_obj.x, 
        xq;
        left_init_index = init_index)

    n = length(spline_obj)
    
    if left_idx >= n
        return spline_obj.y[n]
    elseif left_idx < 1
        return spline_obj.y[1]
    end

    x1 = spline_obj.x[left_idx]
    x2 = spline_obj.x[left_idx+1]
    
    y1 = spline_obj.y[left_idx]
    y2 = spline_obj.y[left_idx+1]
    
    c1 = spline_obj.c[left_idx]
    c2 = spline_obj.c[left_idx+1]
    

    dx = x2 - x1
    dy = y2 - y1
    
    # def of the coeffs
    a0 = y1
    a1 = dy / dx - (c2 + 2 * c1) / 6 * dx
    a2 = c1 / 2
    a3 = (c2 - c1) / (6 * dx)

    # eval of the poly
    x = xq - x1

    return (x, a0, a1, a2, a3)
end

function __poly_eval(x, a0, a1, a2, a3)
    return ((a3 .* x .+ a2) .* x + a1) .* x .+ a0
end

function __diff_poly_eval(x, a0, a1, a2, a3)
    return (3 .* a3 .* x .+ 2 .* a2) .* x + a1
end

function __poly_eval(x, a0, a1, a2)
    return (a2 .* x .+ a1) .* x + a0
end

# function interpolate(natural_spline::NaturalSpline, xq::Vector{T}) where {T <:Number}
function interpolate(spline_obj, xq::Vector{T}) where {T <:Number}
    # todo: rewrite it in a more better way
    n  = length(xq)
    yq = zeros(n)
    for ii = 1:n
        yq[ii] = interpolate(spline_obj, xq[ii])
    end
    return yq
end

function diff_interpolate(spline_obj, xq::T; init_index::Int = 1) where {T <:Number}
    (x, a0, a1, a2, a3) = __find_interp_values(spline_obj, xq, init_index)
    return __diff_poly_eval(x, a0, a1, a2, a3)
end

function diff_interpolate(spline_obj, xq::Vector{T}) where {T <:Number}
    # todo: rewrite it in a more better way
    n  = length(xq)
    yq = zeros(n)
    for ii = 1:n
        yq[ii] = diff_interpolate(spline_obj, xq[ii])
    end
    return yq
end




struct ClampedSpline{T}
    x::Vector{T}
    y::Vector{T}
    c::Vector{T}
    function ClampedSpline{T}(x_, y_, c_) where {T}
        return new( copy(x_), copy(y_), copy(c_) )
    end
end
function ClampedSpline(x::Vector{T}, y::Vector{T}, vec::Vector{T}) where {T}
    return ClampedSpline{T}(x, y, vec)
end

function Base.length(clamped_spline::ClampedSpline)
    return length(clamped_spline.x)
end

function fit_clamped(x::Vector{T}, y::Vector{T}, g1, g2) where {T}
    n_points        = length(x)
    dx              = diff(x)
    dy              = diff(y)
    v1              = view(dx, 2:(n_points-1))
    v2              = view(dx, 1:(n_points-2))
    left_diag       = dx
    main_diag       = [2 * dx[1]; 2 .* (v1 .+ v2); 2 * dx[end]]
    dydx            = dy ./ dx
    diff_dydx       = diff(dydx)
    rhs             = 6 .* [-g1 + dydx[1]; diff_dydx; g2 - dydx[end]]
    c               = linalg.linsolve_tridiagonal(left_diag, main_diag, left_diag, rhs)
    natural_spline  = ClampedSpline(x, y, c)
    return natural_spline
end





mutable struct ModifiedAkimaSpline{T}
    x::Vector{T}
    y::Vector{T}
    function ModifiedAkimaSpline{T}(x_, y_) where {T}
        return new( copy(x_), copy(y_) )
    end
end
function ModifiedAkimaSpline(x::Vector{T}, y::Vector{T}) where {T}
    return ModifiedAkimaSpline{T}(x, y)
end

function Base.length(akima_spline::ModifiedAkimaSpline)
    return length(akima_spline.x)
end

function fit_modified_akima(x, y)
    return ModifiedAkimaSpline(x, y)
end


function interpolate(
    spline_obj::ModifiedAkimaSpline,
    xq::T;
    init_index::Int = 1
    ) where {T <:Number}
    
    (a0, a1, a2, a3, x3) = __mod_akima_interp(
        spline_obj,
        xq;
        init_index = init_index)


    return __poly_eval(xq - x3, a0, a1, a2, a3)
end


function diff_interpolate(
    spline_obj::ModifiedAkimaSpline,
    xq::T;
    init_index::Int = 1
    ) where {T <: Number}

    (a0, a1, a2, a3, x3) = __mod_akima_interp(
        spline_obj,
        xq;
        init_index = init_index)

    return __diff_poly_eval(xq - x3, a0, a1, a2, a3)
end



function __mod_akima_interp(
    spline_obj::ModifiedAkimaSpline,
    xq::T;
    init_index::Int = 1
    ) where {T <:Number}

    left_idx = SimpleSearches.binary_search(
        spline_obj.x, 
        xq;
        left_init_index = init_index)

    n = length(spline_obj)
    
    if left_idx >= n
        return spline_obj.y[n]
    elseif left_idx < 1
        return spline_obj.y[1]
    end

    # see https://blogs.mathworks.com/cleve/2019/04/29/makima-piecewise-cubic-interpolation/
    # first two segments
    # quadratic interpolation
    t1 = 0.0
    t2 = 0.0
    g3 = 0.0
    x3 = 0.0
    x4 = 0.0
    y3 = 0.0

    ii = left_idx
    if left_idx == 1

        x3 = spline_obj.x[ii]
        x4 = spline_obj.x[ii+1]
        x5 = spline_obj.x[ii+2]
        x6 = spline_obj.x[ii+3]
        
        y3 = spline_obj.y[ii]
        y4 = spline_obj.y[ii+1]
        y5 = spline_obj.y[ii+2]
        y6 = spline_obj.y[ii+3]


        g3 = (y4 - y3) / (x4 - x3)
        g4 = (y5 - y4) / (x5 - x4)
        g5 = (y6 - y5) / (x6 - x5)

        g2 = 2 * g3 - g4
        g1 = 2 * g2 - g3

    
    elseif left_idx == 2

        x2 = spline_obj.x[ii-1]
        x3 = spline_obj.x[ii]
        x4 = spline_obj.x[ii+1]
        x5 = spline_obj.x[ii+2]
        x6 = spline_obj.x[ii+3]
        
        y2 = spline_obj.y[ii-1]
        y3 = spline_obj.y[ii]
        y4 = spline_obj.y[ii+1]
        y5 = spline_obj.y[ii+2]
        y6 = spline_obj.y[ii+3]

        g2 = (y3 - y2) / (x3 - x2)
        g3 = (y4 - y3) / (x4 - x3)
        g4 = (y5 - y4) / (x5 - x4)
        g5 = (y6 - y5) / (x6 - x5)

        g1 = 2 * g2 - g3

    elseif left_idx == n-1

        x1 = spline_obj.x[ii-2]
        x2 = spline_obj.x[ii-1]
        x3 = spline_obj.x[ii]
        x4 = spline_obj.x[ii+1]
        

        y1 = spline_obj.y[ii-2]
        y2 = spline_obj.y[ii-1]
        y3 = spline_obj.y[ii]
        y4 = spline_obj.y[ii+1]


        g1 = (y2 - y1) / (x2 - x1)
        g2 = (y3 - y2) / (x3 - x2)
        g3 = (y4 - y3) / (x4 - x3)

        g4 = 2 * g3 - g2
        g5 = 2 * g4 - g3

    elseif left_idx == n-2

        x1 = spline_obj.x[ii-2]
        x2 = spline_obj.x[ii-1]
        x3 = spline_obj.x[ii]
        x4 = spline_obj.x[ii+1]
        x5 = spline_obj.x[ii+2]

        y1 = spline_obj.y[ii-2]
        y2 = spline_obj.y[ii-1]
        y3 = spline_obj.y[ii]
        y4 = spline_obj.y[ii+1]
        y5 = spline_obj.y[ii+2]


        g1 = (y2 - y1) / (x2 - x1)
        g2 = (y3 - y2) / (x3 - x2)
        g3 = (y4 - y3) / (x4 - x3)
        g4 = (y5 - y4) / (x5 - x4)

        g5 = 2 * g4 - g3

    else
        # bulk
        x1 = spline_obj.x[ii-2]
        x2 = spline_obj.x[ii-1]
        x3 = spline_obj.x[ii]
        x4 = spline_obj.x[ii+1]
        x5 = spline_obj.x[ii+2]
        x6 = spline_obj.x[ii+3]
        

        y1 = spline_obj.y[ii-2]
        y2 = spline_obj.y[ii-1]
        y3 = spline_obj.y[ii]
        y4 = spline_obj.y[ii+1]
        y5 = spline_obj.y[ii+2]
        y6 = spline_obj.y[ii+3]

        g1 = (y2 - y1) / (x2 - x1)
        g2 = (y3 - y2) / (x3 - x2)
        g3 = (y4 - y3) / (x4 - x3)
        g4 = (y5 - y4) / (x5 - x4)
        g5 = (y6 - y5) / (x6 - x5)


    end

    w1 = abs(g4 - g3) + 0.5 * abs(g4 + g3)
    w2 = abs(g2 - g1) + 0.5 * abs(g2 + g1)
    t1 = w1 / (w1 + w2) * g2 + w2 / (w1 + w2) * g3


    w1 = abs(g5 - g4) + 0.5 * abs(g5 + g4)
    w2 = abs(g3 - g2) + 0.5 * abs(g3 + g2)
    t2 = w1 / (w1 + w2) * g3 + w2 / (w1 + w2) * g4

    if isnan(t1)
        t1 = 0
    end
    if isnan(t2)
        t2 = 0
    end

    a0 = y3
    a1 = t1
    a2 = (3 * g3 - 2 * t1 - t2) / (x4 - x3)
    a3 = (t1 + t2 - 2 * g3) / (x4 - x3)^2

    return (a0, a1, a2, a3, x3)
end





struct AkimaSpline{T}
    x::Vector{T}
    y::Vector{T}
end
function AkimaSpline(x::Vector{T}, y::Vector{T}) where {T}
    return AkimaSpline{T}(x, y)
end

function Base.length(akima_spline::AkimaSpline)
    return length(akima_spline.x)
end

function fit_akima(x, y)
    return AkimaSpline(x, y)
end

function interpolate(spline_obj::AkimaSpline, xq::T; init_index::Int = 1) where {T <:Number}
    left_idx = SimpleSearches.binary_search(
        spline_obj.x, 
        xq;
        left_init_index = init_index)

    n = length(spline_obj)
    
    if left_idx >= n
        return spline_obj.y[n]
    elseif left_idx < 1
        return spline_obj.y[1]
    end


    # first two segments
    # quadratic interpolation
    if left_idx < 3
        return spline_obj.y[1]
    elseif left_idx > n-3
        return spline_obj.y[n-3]
    end

    
    # bulk
    ii = left_idx
    x1 = spline_obj.x[ii-2]
    x2 = spline_obj.x[ii-1]
    x3 = spline_obj.x[ii]
    x4 = spline_obj.x[ii+1]
    x5 = spline_obj.x[ii+2]
    x6 = spline_obj.x[ii+3]
    

    y1 = spline_obj.y[ii-2]
    y2 = spline_obj.y[ii-1]
    y3 = spline_obj.y[ii]
    y4 = spline_obj.y[ii+1]
    y5 = spline_obj.y[ii+2]
    y6 = spline_obj.y[ii+3]

    g1 = (y2 - y1) / (x2 - x1)
    g2 = (y3 - y2) / (x3 - x2)
    g3 = (y4 - y3) / (x4 - x3)
    g4 = (y5 - y4) / (x5 - x4)
    g5 = (y6 - y5) / (x6 - x5)


    t1 = abs(g4 - g3) * g2 + abs(g2 - g1) * g3
    t1 = t1 / ( abs(g4 - g3) + abs(g2 - g1) )

    t2 = abs(g5 - g4) * g3 + abs(g3 - g2) * g4
    t2 = t2 / ( abs(g5 - g4) + abs(g3 - g2))


    if isapprox(g1, g2)
        t1 = g2
    end
    if isapprox(g3, g4)
        t1 = g3
    end
    if isapprox(g1, g2) && isapprox(g3, g4) && !isapprox(g1, g3)
        t1 = 0.5 * (g1 + g3)
    end

    if isapprox(g2, g3)
        t2 = g3
    end
    if isapprox(g4, g5)
        t2 = g4
    end
    if isapprox(g2, g3) && isapprox(g4, g5) && !isapprox(g2, g4)
        t2 = 0.5 * (g2 + g4)
    end

    a0 = y3
    a1 = t1
    a2 = (3 * g3 - 2 * t1 - t2) / (x4 - x3)
    a3 = (t1 + t2 - 2 * g3) / (x4 - x3)^2

    return __poly_eval(xq - x3, a0, a1, a2, a3)
end


#=
struct HermiteSpline{T}
    # lazy version
    x::Vector{T}
    y::Vector{T}
    g::Vector{T}
end
function HermiteSpline(x::Vector{T}, y::Vector{T}, g1, g2) where {T}
    g = [g1; diff(y) ./ diff(x); g2]
    return HermiteSpline{T}(x, y, g)
end
function Base.length(hermite_spline::HermiteSpline)
    return length(hermite_spline.x)
end

function fit_hermite(
    x::Vector{T},
    y::Vector{T},
    g1 = (y[2] - y[1]) / (x[2] - x[1]),
    g2 = (y[end] - y[end-1]) / (x[end] - x[end-1])
    ) where {T}

    return HermiteSpline(x, y, g1, g2)

end

function interpolate(spline_obj::HermiteSpline, xq::T; init_index::Int = 1) where {T <:Number}
    left_idx = SimpleSearches.binary_search(
        spline_obj.x, 
        xq;
        left_init_index = init_index)

    n = length(spline_obj)
    
    if left_idx >= n
        return spline_obj.y[n]
    elseif left_idx < 1
        return spline_obj.y[1]
    end


    x1 = spline_obj.x[left_idx]
    x2 = spline_obj.x[left_idx+1]
    y1 = spline_obj.y[left_idx]
    y2 = spline_obj.y[left_idx+1]

    g1 = spline_obj.g[left_idx]
    g2 = spline_obj.g[left_idx+2]

    a0 = y1
    a1 = g1

    dx_ = x2 - x1
    dy_ = y2 - y1

    a3 = ((g2 - g1) / dx_ - (dy_ - g1 * dx_) / dx_^2) / dx_
    a2 = 0.5 * ((g2 - g1) / dx_ - 3 * a3 * dx_)

    return __poly_eval(xq - x1, a0, a1, a2, a3)
end
=#

#=
struct HermiteSpline{T}
    # eager version
    x::Vector{T}
    y::Vector{T}
    a0::Vector{T}
    a1::Vector{T}
    a2::Vector{T}
    a3::Vector{T}
end
function HermiteSpline(x::Vector{T}, y::Vector{T}, a0, a1, a2, a3) where {T}
    return HermiteSpline{T}(x, y, a0, a1, a2, a3)
end

function Base.length(hermite_spline::HermiteSpline)
    return length(hermite_spline.x)
end


function fit_hermite(
    x::Vector{T},
    y::Vector{T},
    g1 = (y[2] - y[1]) / (x[2] - x[1]),
    g2 = (y[end] - y[end-1]) / (x[end] - x[end-1])
    ) where {T}

    L = length(x)
    dx = diff(x) # L-1
    dy = diff(y) # L-1
    
    # vy1 = view(y, 1:L-2) # L-2
    # vy2 = view(y, 3:L) # L-2
    # vx1 = view(x, 1:L-2) # L-2
    # vx2 = view(x, 3:L) # L-2

    # g = [g1; (vy2 .- vy1) ./ (vx2 .- vx1); g2] # L - 2 + 2 = L
    
    g      = zeros(L)
    g[1]   = g1
    g[end] = g2
    for kk = 2:L-1
        m   = x[kk]   - x[kk-1]
        p   = x[kk+1] - x[kk]
        dym = y[kk]   - y[kk-1]
        dyp = y[kk+1] - y[kk]
        
        g[kk] = (dyp * m^2 + dym * p^2) / ( m*p * (m + p) )
    end


    a0 = copy(y)
    pop!(a0) # L-1

    a1 = g[1:end-1] # L - 1
    a2 = zeros(L-1)
    a3 = zeros(L-1)
    for kk = 1:L-1
        g1  = g[kk]
        g2  = g[kk+1]
        dx_ = dx[kk]
        dy_ = dy[kk]
        
        a2[kk] = - (2 * g2 + g1) / dx_ + 3 * dy_ / dx_^2
        a3[kk] = (g1 + g2) / dx_^2 - 2 * dy_ / dx_^3
    end

    return HermiteSpline(x, y, a0, a1, a2, a3)
end


function interpolate(spline_obj::HermiteSpline, xq::T; init_index::Int = 1) where {T <:Number}
    left_idx = SimpleSearches.binary_search(
        spline_obj.x, 
        xq;
        left_init_index = init_index)

    n = length(spline_obj)
    
    if left_idx >= n
        return spline_obj.y[n]
    elseif left_idx < 1
        return spline_obj.y[1]
    end

    a0 = spline_obj.a0[left_idx]
    a1 = spline_obj.a1[left_idx]
    a2 = 0 * spline_obj.a2[left_idx]
    a3 = 0 * spline_obj.a3[left_idx]


    return __poly_eval(xq - spline_obj.x[left_idx], a0, a1, a2, a3)
end
=#

end








