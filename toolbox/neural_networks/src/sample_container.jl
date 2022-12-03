
# =========================================================================== #
# Sample Container
# =========================================================================== #

abstract type AbstractSampleContainer
end

struct MatrixVectorSampleContainer{T} <: AbstractSampleContainer
    # each column is a new sample
    x::Matrix{T}
    y::Vector{T}
    function MatrixVectorSampleContainer{T}(x::Matrix{T}, y::Vector{T}) where {T}
        n_col = size(x, 2)
        L     = length(y)
        if n_col != L
            error("Invalid dimensions")
        end

        return new(x, y)
    end 
end

function MatrixVectorSampleContainer(x::Matrix{T}, y::Vector{T}) where {T}
    return MatrixVectorSampleContainer{T}(x, y)
end

function Base.length(sample_cont::MatrixVectorSampleContainer)
    return size(sample_cont.x, 2)
end

function n_samples(sample_cont::MatrixVectorSampleContainer)
    return size(sample_cont.x, 2)
end

function n_dim(sample_cont::MatrixVectorSampleContainer)
    return size(sample_cont.x, 1)
end

function get_sample(sample_cont::MatrixVectorSampleContainer, idx::Int)
    nd = n_dim(sample_cont)
    x  = view(sample_cont.x, 1:nd, idx)
    y  = sample_cont.y[idx]

    return (x, y)
end

function split(sample_cont::MatrixVectorSampleContainer, idx::Int)

    ns = n_samples(sample_cont)

    x1  = sample_cont.x[:, 1:idx]
    y1  = sample_cont.y[1:idx]
    sc1 = MatrixVectorSampleContainer(x1, y1)

    x2  = sample_cont.x[:, (idx+1):ns]
    y2  = sample_cont.y[(idx+1):ns]
    sc2 = MatrixVectorSampleContainer(x2, y2)

    return (sc1, sc2)
end

function Random.shuffle!(sample_cont::MatrixVectorSampleContainer)
    N = length(sample_cont)
    xx = copy(sample_cont.x)
    yy = copy(sample_cont.y)
    idx = randperm(N)
    for ii = 1:N
        sample_cont.x[:,ii] = xx[:,idx[ii]]
        sample_cont.y[ii]   = yy[idx[ii]]
    end
end







struct MatrixMatrixSampleContainer{T} <: AbstractSampleContainer
    # each column is a new sample
    x::Matrix{T}
    y::Matrix{T}
    function MatrixMatrixSampleContainer{T}(x::Matrix{T}, y::Matrix{T}) where {T}
        n_col = size(x, 2)
        L     = size(y, 2)
        if n_col != L
            error("Invalid dimensions")
        end

        return new(x, y)
    end 
end

function MatrixMatrixSampleContainer(x::Matrix{T}, y::Matrix{T}) where {T}
    return MatrixMatrixSampleContainer{T}(x, y)
end


function Base.length(sample_cont::MatrixMatrixSampleContainer)
    return size(sample_cont.x, 2)
end

function n_samples(sample_cont::MatrixMatrixSampleContainer)
    return size(sample_cont.x, 2)
end

function n_dim_x(sample_cont::MatrixMatrixSampleContainer)
    return size(sample_cont.x, 1)
end

function n_dim_y(sample_cont::MatrixMatrixSampleContainer)
    return size(sample_cont.y, 1)
end

function get_sample(sample_cont::MatrixMatrixSampleContainer, idx::Int)
    ndx = n_dim_x(sample_cont)
    ndy = n_dim_y(sample_cont)

    x  = view(sample_cont.x, 1:ndx, idx)
    y  = view(sample_cont.y, 1:ndy, idx)

    return (x, y)
end

function split(sample_cont::MatrixMatrixSampleContainer, idx::Int)
    ns = n_samples(sample_cont)

    x1  = sample_cont.x[:, 1:idx]
    y1  = sample_cont.y[:, 1:idx]
    sc1 = MatrixMatrixSampleContainer(x1, y1)

    x2  = sample_cont.x[:, (idx+1):ns]
    y2  = sample_cont.y[:, (idx+1):ns]
    sc2 = MatrixMatrixSampleContainer(x2, y2)

    return (sc1, sc2)
end


function Random.shuffle!(sample_cont::MatrixMatrixSampleContainer)
    N = length(sample_cont)
    xx = copy(sample_cont.x)
    yy = copy(sample_cont.y)
    idx = randperm(N)
    for ii = 1:N
        sample_cont.x[:, ii] = xx[:, idx[ii]]
        sample_cont.y[:, ii] = yy[:, idx[ii]]
    end
end

