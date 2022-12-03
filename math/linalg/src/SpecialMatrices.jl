



module SpecialMatrices

export UpperTriangularAntiSymmetric


function sum_to_n(n::I) where {I <: Integer}
    s = n * (n + 1)
    s = div(s, 2)
    return s
end


struct UpperTriangularAntiSymmetric{T} <: AbstractMatrix{T}
    n_dim::Int
    data::Vector{T}
    

    function UpperTriangularAntiSymmetric{T}(n_dim) where {T}
        n_elements = sum_to_n(n_dim-1)
        data       = zeros(n_elements)
        return new(n_dim, data)
    end    
end

function Base.length(matrix::UpperTriangularAntiSymmetric)
    return matrix.n_dim^2
end

function Base.size(matrix::UpperTriangularAntiSymmetric)
    return (matrix.n_dim, matrix.n_dim)
end

function Base.size(matrix::UpperTriangularAntiSymmetric, dims)
    return matrix.n_dim
end

function Base.eltype(matrix::UpperTriangularAntiSymmetric{T}) where {T}
    return T
end

function Base.IndexStyle(::Type{UpperTriangularAntiSymmetric})
    return IndexCartesian()
end

function Base.IndexStyle(matrix::UpperTriangularAntiSymmetric)
    return IndexCartesian()
end

function Base.getindex(matrix::UpperTriangularAntiSymmetric{T}, row::Integer, col::Integer) where {T}
    row == col && return zero(T) # no self loop
    row > col  && return -matrix[col, row]

    start_index = sum_to_n(col-2)
    abs_index   = start_index + row
    return matrix.data[abs_index]
end

function Base.setindex!(matrix::UpperTriangularAntiSymmetric{T}, x, row::Integer, col::Integer) where {T}
    # silently no set happens for the diagonal elements
    row == col && return matrix
    row > col  && return matrix[col, row] = -x

    start_index            = sum_to_n(col-2)
    abs_index              = start_index + row
    matrix.data[abs_index] = x

    return matrix
end


end # module


