
# =========================================================================== #
# Sampling
# =========================================================================== #

function random(d::UniformDistribution, n::Int)
    return rand(n) .* (d.b - d.a) .+ d.a
end

function random(d::NormalDistribution, n::Int)
    z = randn(n)
    return d.sigma .* z .+ d.mu
end

function random(d::CauchyDistribution, n::Int)
    return d.c .* tan.( pi.*( rand(n) .- 0.5) ) .+ d.mu
end


function random(d::MultiNormalDistribution, n::Int)
    n_dim = length(d.mu)
    z = randn(n_dim, n)
    return d.L' * z .+ d.mu
end


function rejection_sampling_1d(pdf_fcn, x_min, x_max, n_rand)

    # select a majorizing constant
    n_for_y_max = max( 100, convert(Int, ceil(sqrt(n_rand)) ) )
    xs          = collect( range(x_min, x_max, n_for_y_max) )
    pdf_s       = pdf_fcn.(xs)
    max_pdf     = maximum(pdf_s)
    

    # coordinate distribution
    x_distr     = UniformDistribution(x_min, x_max)
    
    n_batch     = div(n_rand, 10)
    x_rnb_total = zeros(n_rand)
    left_idx    = 1
    right_idx   = 0

    while right_idx < n_rand

        # check if the sampled point is below the curve
        x_rnb       = random( x_distr, n_batch )
        pdf_rnb     = max_pdf * rand(n_batch)
        pdf_values  = pdf_fcn.(x_rnb)
        bool        = pdf_rnb .<= pdf_values

        # select the coordinates
        x_rnb = x_rnb[bool]

        # push back
        L = length(x_rnb)
        right_idx += L
        if right_idx > n_rand
            valid_idx = L - (right_idx - n_rand)
            right_idx = n_rand
            x_rnb_total[ left_idx:right_idx ] = x_rnb[1:valid_idx]
        else
            x_rnb_total[ left_idx:right_idx ] = x_rnb
        end
        left_idx = right_idx + 1
    end

    return x_rnb_total

end


function rejection_sampling_2d(pdf_fcn, x_min, x_max, y_min, y_max, n_rand)

    # select a majorizing constant
    n_for_y_max = max( 50, convert(Int, ceil(sqrt(n_rand)) ) )
    xs          = collect( range(x_min, x_max, n_for_y_max) )
    ys          = collect( range(y_min, y_max, n_for_y_max) )

    pdf_s = zeros(n_for_y_max, n_for_y_max)
    for ii = 1:n_for_y_max
        x_ = xs[ii]
        for jj = 1:n_for_y_max
            y_ = ys[jj]
            pdf_s[ii, jj] = pdf_fcn( (x_, y_) )
        end
    end
    max_pdf     = maximum(pdf_s)
    

    # coordinate distribution
    x_distr     = UniformDistribution(x_min, x_max)
    y_distr     = UniformDistribution(y_min, y_max)
    
    n_batch     = div(n_rand, 10)

    x_rnb_total = zeros(n_rand)
    y_rnb_total = zeros(n_rand)

    left_idx    = 1
    right_idx   = 0

    while right_idx < n_rand

        # check if the sampled point is below the curve
        x_rnb       = random( x_distr, n_batch )
        y_rnb       = random( y_distr, n_batch )

        pdf_rnb     = max_pdf * rand(n_batch)

        pdf_values = zeros(n_batch)
        for ii = 1:n_batch
            pdf_values[ii] = pdf_fcn( (x_rnb[ii], y_rnb[ii]) )
        end

        bool = pdf_rnb .<= pdf_values

        # select the coordinates
        x_rnb = x_rnb[bool]
        y_rnb = y_rnb[bool]

        # push back
        L = length(x_rnb)
        right_idx += L
        if right_idx > n_rand
            valid_idx = L - (right_idx - n_rand)
            right_idx = n_rand
            x_rnb_total[ left_idx:right_idx ] = x_rnb[1:valid_idx]
            y_rnb_total[ left_idx:right_idx ] = y_rnb[1:valid_idx]
        else
            x_rnb_total[ left_idx:right_idx ] = x_rnb
            y_rnb_total[ left_idx:right_idx ] = y_rnb
        end
        left_idx = right_idx + 1
    end

    return (x_rnb_total, y_rnb_total)

end
