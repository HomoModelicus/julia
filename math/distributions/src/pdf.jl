
# =========================================================================== #
# pdf functions
# =========================================================================== #

function pdf(d::UniformDistribution, x)
    h = 1 / (d.b - d.a)
    if d.a <= x <= d.b
        y = h
    else
        y = 0.0
    end
    return y
end

function pdf(d::NormalDistribution, x)
    y = 1 ./ (sqrt(2*pi) .* d.sigma) .* exp.( -0.5 .* (x .- d.mu).^2 ./ d.sigma.^2 )
    return y
end

function pdf(d::CauchyDistribution, x)
    return 1 ./ ( (pi * d.c) .* (1 .+ ((x .- d.mu) ./ d.c).^2 ) )
end


function pdf(d::MultiNormalDistribution, x)
    n_dim       = length(d.mu)
    det_sigma   = prod( diag(d.L) )
    dx          = x .- d.mu
    arg         = -0.5 .* dot(dx, d.inv_sigma * dx )
    nom         = exp.(arg)
    den         = sqrt( (2*pi)^n_dim * det_sigma )
    return nom ./ den
end