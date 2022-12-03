
# include("../../../../std/SimpleSearches./src/SimpleSearches._module.jl") # for binary search
# include("../../datastructs/src/datastructs_module.jl") # for stack

include("../../simplesearches/src/SimpleSearches.jl")


module numint
using ..SimpleSearches
# using ..datastructs

struct Interval
    x_lo::Float64
    x_hi::Float64
    function Interval(x_lo, x_hi)
        (x_lo, x_hi) = (x_lo < x_hi) ? (x_lo, x_hi) : (x_hi, x_lo)
        return new(x_lo, x_hi)
    end
end
function range(interval::Interval)
    return interval.x_hi - interval.x_lo
end



function trapezoidal(fcn, interval::Interval, N::Int)

    int_range = range(interval)
    dx = int_range / N
    I  = 0.0
    x1 = interval.x_lo
    f1 = fcn(x1)
    @inbounds for kk = 1:N
        x2 = x1 + dx
        f2 = fcn(x2)
        I += 0.5 * (f1 + f2) * dx
        x1 = x2
        f1 = f2
    end
    return I
end

function trapezoidal(fcn, interval::Interval, xs::Vector)
    I  = 0.0
    x1 = interval.x_lo
    f1 = fcn(x1)
    @inbounds for kk = 2:length(xs)
        x2 = xs[kk]
        dx = x2 - x1
        f2 = fcn(x2)
        I += 0.5 * (f1 + f2) * dx
        x1 = x2
        f1 = f2
    end
    return I
end



struct RombergOptions
    N::Int
    abs_tol::Float64
    rel_tol::Float64
end
function RombergOptions()
    return RombergOptions(128, 1e-8, 1e-8)
end
function RombergOptions(;N = 128, abs_tol = 1e-8, rel_tol = 1e-8)
    return RombergOptions(N, abs_tol, rel_tol)
end


@enum StoppingCrit begin
    max_iter_reached
    rel_tol
    abs_tol
    unknown
end

struct RombergResult
    integral::Float64
    n_fcn_eval::Int
    stopping_crit::StoppingCrit
    I::Vector{Float64}
end


function romberg(
    fcn,
    interval::Interval,
    options::RombergOptions = RombergOptions()
    )

    # allocations
    int_range   = range(interval)
    Nmax        = ceil(Int, log2(options.N)) + 1
    I           = zeros(Nmax)

    # N == 2
    # stat
    n_fcn_eval    = 2
    stopping_crit = unknown::StoppingCrit

    idxi    = 1
    fi_a    = fcn(interval.x_lo)
    fi_b    = fcn(interval.x_hi)
    I[idxi] = 0.5 * (fi_a + fi_b) * int_range
    
    # R = datastructs.Stack{Float64}()
    R    = zeros(Nmax)
    R[1] = I[1]

    # auxilary arrays
    r   = zeros(Nmax)
    tmp = zeros(Nmax)

    # main loop
    @inbounds for N = 2:Nmax
        
        # fill up the trapezoidal table first column
        hn = int_range / 2^(N-1)

        # evaluate the function or steal it from the previous iteration
        I_partial = 0.0
        @inbounds for kk = 1:2^(N-2)
            x = interval.x_lo + hn * (2 * kk - 1)
            n_fcn_eval += 1
            I_partial  += fcn(x)
        end
        R[N] = 0.5 * R[N-1] + hn * I_partial

        copyto!(r, R)
        @inbounds for jj = 2:N
            @inbounds for ii = jj:N
                R_n_m1  = r[ii]
                R_n1_m1 = r[ii-1]
                tmp[ii] = R_n_m1 + (R_n_m1 - R_n1_m1) / (4^(jj-1)-1)
            end
            # swap the arrays such that the previous array is always in r
            r, tmp = tmp, r
        end


        idxi    += 1
        I[idxi] = r[N]
        if idxi >= 2
            dI = abs(I[idxi-1] - I[idxi]) 
            if dI <= options.abs_tol
                stopping_crit = abs_tol::StoppingCrit
                break
            end
            if  dI / abs(I[idxi]) <= options.rel_tol
                stopping_crit = rel_tol::StoppingCrit
                break
            end
        end

    end

    if idxi == Nmax
        stopping_crit = max_iter_reached::StoppingCrit
    end

    stat = RombergResult(I[idxi], n_fcn_eval, stopping_crit, I)
    return stat
end








struct GaussKronrodOptions
    abs_tol::Float64
    rel_tol::Float64
    min_interval::Float64
end
function GaussKronrodOptions(;
    abs_tol = 1e-8,
    rel_tol = 1e-8,
    min_interval = 1e-10
    )
    return GaussKronrodOptions(abs_tol, rel_tol, min_interval)
end

struct GaussKronrodResult
    integral::Float64
    n_fcn_eval::Int
end


function gauss_kronrod(
    fcn,
    interval::Interval,
    options::GaussKronrodOptions = GaussKronrodOptions()
    )


    (gi_idx,
    kronrod_weights,
    kronrod_nodes,
    gauss_weights) = __gk_nodes_weights()

    n_fcn_eval = 0
    x_lo = interval.x_lo
    x_hi = interval.x_hi

    (K15, n_fcn_eval) = __rec_gk(
        fcn,
        x_lo,
        x_hi,
        options,
        gi_idx,
        kronrod_weights,
        kronrod_nodes,
        gauss_weights,
        n_fcn_eval)

    stat = GaussKronrodResult(K15, n_fcn_eval)
    return stat
end

function __rec_gk(
    fcn,
    x_lo,
    x_hi,
    options,
    gi_idx,
    kronrod_weights,
    kronrod_nodes,
    gauss_weights,
    n_fcn_eval)

    # constants
    Nk = 15
    Ng = 7


    int_range = x_hi - x_lo
    mid_point = (x_lo + x_hi) / 2

    if int_range < options.min_interval
        return (0.0, n_fcn_eval)
    end

    fi = zeros(Nk)
    @inbounds for ii = 1:Nk
        xi = int_range/2 * kronrod_nodes[ii] + mid_point
        fi[ii] = fcn(xi)
    end
    n_fcn_eval += 15

    gi = fi[gi_idx]

    K15 = 0.0
    @inbounds for ii = 1:Nk
        K15 += kronrod_weights[ii] * fi[ii]
    end
    K15 *= int_range/2

    G7 = 0.0
    @inbounds for ii = 1:Ng
        G7 += gauss_weights[ii] * gi[ii]
    end
    G7 *= int_range/2

    error_est = abs(G7 - K15)
    if error_est <= options.abs_tol
        return (K15, n_fcn_eval)
    end
    if error_est / abs(K15) <= options.rel_tol
        return (K15, n_fcn_eval)
    end
    
    # subdivide the interval
    x_mid = mid_point

    (K15_left, n_fcn_eval) = __rec_gk(
        fcn,
        x_lo,
        x_mid,
        options,
        gi_idx,
        kronrod_weights,
        kronrod_nodes,
        gauss_weights,
        n_fcn_eval)

    (K15_right, n_fcn_eval) = __rec_gk(
        fcn,
        x_mid,
        x_hi,
        options,
        gi_idx,
        kronrod_weights,
        kronrod_nodes,
        gauss_weights,
        n_fcn_eval)
    
    return (K15_left + K15_right, n_fcn_eval)
end


function __gk_nodes_weights()
# gauss_nodes = [
    # -0.949107912342759  # 1
    # -0.741531185599394  # 2
    # -0.405845151377397  # 3
    # 0.0                 # 4
    # +0.405845151377397
    # +0.741531185599394
    # +0.949107912342759
    # ]

    gauss_weights = [
        0.129484966168870
        0.279705391489277
        0.381830050505119

        0.417959183673469

        0.381830050505119
        0.279705391489277
        0.129484966168870
    ]
    
    kronrod_nodes = [
        -0.991455371120813
        -0.949107912342759  # 1
        -0.864864423359769
        -0.741531185599394  # 2
        -0.586087235467691
        -0.405845151377397  # 3
        -0.207784955007898

        0.0                 # 4

        0.207784955007898
        0.405845151377397
        0.586087235467691
        0.741531185599394
        0.864864423359769
        0.949107912342759
        0.991455371120813
    ]

    kronrod_weights = [
        0.022935322010529
        0.063092092629979
        0.104790010322250
        0.140653259715525
        0.169004726639267
        0.190350578064785
        0.204432940075298

        0.209482141084728

        0.204432940075298
        0.190350578064785
        0.169004726639267
        0.140653259715525
        0.104790010322250
        0.063092092629979
        0.022935322010529
    ]


    gi_idx = [  2, 4, 6, 
                8,
                10, 12, 14
            ]
    
    return (gi_idx, kronrod_weights, kronrod_nodes, gauss_weights)
end



end # module


