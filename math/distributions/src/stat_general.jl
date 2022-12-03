
function mean(x::Vector{T}) where {T}
    m = sum(x) / length(x)
    return m
end

function std(x::Vector{T}) where {T}
    m = mean(x)
    z = x .- m
    m = sqrt( sum(z.^2) / (length(x) - 1) )
    return m
end

function center(x::Vector)
    m = mean(x)
    y = copy(x)
    y .-= m
    return y
end

function cov(x::Vector{T}) where {T}
    return std(x)
end

function cov(x::Vector{T}, y::Vector{T}) where {T}
    mx = mean(x)
    my = mean(y)
    L = length(x)

    return 1 / (L - 1) * dot(x .- mx, y .- my)
end

function cov(x::Matrix{T}) where {T}
    # covariance in column way
    L = size(x,1)
    return 1/(L-1) * (x' * x)
end
