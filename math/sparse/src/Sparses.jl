
# dependencies:
# - none

module Sparses
include("sparse_vector.jl")
include("sparse_matrix.jl")

export  SparseMatrixCOO,
        SparseMatrixCSC


# =========================================================================== #
# Math functions
# =========================================================================== #

function Base.:*(mat::SparseMatrixCOO{T}, vec::Vector{S}) where {T, S}
    return matrix_vector_prod(mat, vec)
end

function Base.:*(mat::SparseMatrixCOO{T}, vec::SparseVector{S}) where {T, S}
    return matrix_vector_prod(mat, vec)
end

function Base.:*(mat::SparseMatrixCSC{T}, vec::Vector{S}) where {T, S}
    return matrix_vector_prod(mat, vec)
end



function matrix_vector_prod(mat::SparseMatrixCOO{T}, vec::Vector{S}) where {T, S}
    # sparse matrix * dense vector

    res = zeros(eltype(vec), mat.row_index[end])

    for kk = 1:length(mat)
        ii       = mat.row_index[kk]
        jj       = mat.col_index[kk]
        a_ij     = mat.data[kk]
        x_j      = vec[jj]
        res[ii] += a_ij * x_j
    end
    
    return res
end

function matrix_vector_prod(mat::SparseMatrixCOO{T}, vec::SparseVector{S}) where {T, S}

    # sparse matrix * sparse vector
    # same algo but overridden operator[]

    res = zeros(eltype(vec), mat.row_index[end])

    for kk = 1:length(mat)
        ii       = mat.col_index[kk]
        jj       = mat.row_index[kk]
        a_ij     = mat.data[kk]
        x_j      = vec[jj] 
        res[ii] += a_ij * x_j
    end
    
    return res

end



function matrix_vector_prod(spmat::SparseMatrixCSC, vec::Vector)

    res = zeros(eltype(vec), spmat.n_row)
    L::Int = length(spmat)

    for cc = 1:spmat.n_col
        
        idx_start = spmat.col_begins_index[cc]
        if idx_start == 0
            continue
        end

        (idx_end, flag_end_reached) = find_next_nonempty_col_begin(spmat, cc)
        
        for rr = idx_start:(idx_end-1)
            a_ij = spmat.data[rr]
            ii = spmat.row_index[rr]
            v_j = vec[cc]
            res[ii] += a_ij * v_j
        end

    end


    return res
end



end # sparse



