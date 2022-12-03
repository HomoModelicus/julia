
mutable struct SparseMatrixCOO{T}
    # simple coordinate form
    # maybe to do for later: try to implement a compressed column scheme
    data::Vector{T}
    row_index::Vector{<:Integer}
    col_index::Vector{<:Integer}
    function SparseMatrixCOO{T}(data, row_index, col_index) where {T}
        # last index must specify the length of the full array
        Ld = length(data)
        Lci = length(col_index)
        Lri = length(row_index)
        if Lci != Lri
            error("The two index arrays must have the same length")
        end
        
        if (Ld + 1) != Lci
            error(
                "Data array must have one element less then index array,
                last index must contain the number of elements in the full array")
        end
        if Lci[end] * Lri[end] < Ld
            error("The last index element must contain the col and row dimensions")
        end
        vec = new(data, row_index, col_index);
    end
end

function SparseMatrixCOO(data::Vector{T}, col_index, row_index) where {T}
    vec = SparseMatrixCOO{T}(data, col_index, row_index);
end


function Base.length(spmat::SparseMatrixCOO{T}) where {T}
    return length(spmat.data)
end

function n_nonzero(spmat::SparseMatrixCOO{T}) where {T}
    return length(spmat)
end

function sparse_length(spmat::SparseMatrixCOO{T}) where {T}
    return length(spmat)
end

function full_length(spmat::SparseMatrixCOO{T}) where {T}
    return spmat.col_index[end] * spmat.row_index[end]
end

function Base.size(spmat::SparseMatrixCOO{T}) where {T}
    return ( spmat.row_index[end], spmat.col_index[end] )
end

function Base.size(spmat::SparseMatrixCOO{T}, dim) where {T}
    if dim == 1
        return spmat.row_index[end]
    elseif dim == 2
        return spmat.col_index[end]
    else
        return 1
    end
end


function Base.show(io::IO, spmat::SparseMatrixCOO{T}) where {T}
    n = length(spmat)
    (n_row_full, n_col_full) = size(spmat)
    println("$(n)-sparse element (full size: $(n_row_full)x$(n_col_full)) SparseMatrixCOO{$(T)}:")
    println("\tindex\tdata")
    for kk = 1:n
        ii = spmat.row_index[kk]
        jj = spmat.col_index[kk]
        dd = spmat.data[kk]
        println("\t($(ii), $(jj))\t$(dd)")
    end
end


function create_full(spmat::SparseMatrixCOO{T}) where {T}
    (n_row_full, n_col_full) = size(spmat)
    Ls = sparse_length(spmat)
    mat = zeros(T, n_row_full, n_col_full)
    for ii = 1:Ls
        mat[ spmat.row_index[ii], spmat.col_index[ii] ] = spmat.data[ii]
    end
    return mat
end

function create_sparse_coo(data::Matrix, tolerance = 1e-10)
    # for now: create a temporary array with the size of data
    L = length(data)
    tmp_data = similar(data)
    tmp_col_index = Vector{Int64}(undef, L+1)
    tmp_row_index = Vector{Int64}(undef, L+1)

    (n_row, n_col) = size(data)

    kk = 0
    for jj = 1:n_col
        for ii = 1:n_row
            if abs(data[ii, jj]) >= tolerance
                kk += 1
                tmp_data[kk] = data[ii, jj]
                tmp_col_index[kk] = jj
                tmp_row_index[kk] = ii
            end
        end
    end
    
    data = tmp_data[1:kk]

    kk += 1
    tmp_col_index[kk] = n_col
    tmp_row_index[kk] = n_row
    
    col_index = tmp_col_index[1:kk]
    row_index = tmp_row_index[1:kk]
    

    spmat = SparseMatrixCOO(data, row_index, col_index)
    return spmat
end









function sort_indicies_with_data!(data, row_idx, col_idx)
    # radix sort algo

    i1 = sortperm(row_idx; alg = MergeSort)
    row_idx = row_idx[i1]
    col_idx = col_idx[i1]


    i2 = sortperm(col_idx; alg = MergeSort)
    row_idx = row_idx[i2]
    col_idx = col_idx[i2]


    data = data[i1]
    data = data[i2]
    
    return (data, row_idx, col_idx)
end


struct SparseMatrixCSC{T}
    n_row::Int
    n_col::Int
    data::Vector{T}
    row_index::Vector{Int} # has the same length as data
    col_begins_index::Vector{Int} # same length as number of columns
    
    function SparseMatrixCSC(n_row::Int, n_col::Int, data_in::Vector, row_idx_in::Vector, col_idx_in::Vector)
        data    = copy(data_in)
        row_idx = copy(row_idx_in)
        col_idx = copy(col_idx_in)

        (data, row_idx, col_idx) = sort_indicies_with_data!(data, row_idx, col_idx)

        L = length(data)
        col_begins = zeros(Int, n_col+1)

        kk = 1
        for cc = 1:n_col

            # if the data only at later columns comes , then move the column index to this
            if col_idx[kk] > cc
                continue
            end

            # if 
            while true
                if kk <= L && col_idx[kk] < cc
                    kk += 1
                else
                    break
                end
            end
            if kk > L
                 break
            end
            if col_idx[kk] == cc
                col_begins[cc] = kk
            end
        end
        # ii = n_col
        # while col_begins[ii] == 0
        #     col_begins[ii] = -1
        #     ii -= 1
        # end
        col_begins[n_col+1] = length(data)+1

        T = eltype(data)
        obj = new{T}(n_row, n_col, data, row_idx, col_begins)
        return obj
    end
end



function create_sparse_csc(data::Matrix, tolerance = 1e-10)
    # for now: create a temporary array with the size of data
    L = length(data)
    tmp_data = similar(data)
    tmp_col_index = Vector{Int64}(undef, L+1)
    tmp_row_index = Vector{Int64}(undef, L+1)

    (n_row, n_col) = size(data)

    kk = 0
    for jj = 1:n_col
        for ii = 1:n_row
            if abs(data[ii, jj]) >= tolerance
                kk += 1
                tmp_data[kk] = data[ii, jj]
                tmp_col_index[kk] = jj
                tmp_row_index[kk] = ii
            end
        end
    end
    
    data = tmp_data[1:kk]
    col_index = tmp_col_index[1:kk]
    row_index = tmp_row_index[1:kk]

    spmat = SparseMatrixCSC(n_row, n_col, data, row_index, col_index)
    return spmat
end


function create_full(spmat::SparseMatrixCSC)
    A = zeros(eltype(spmat.data), spmat.n_row, spmat.n_col)
    L = length(spmat)

    for cc = 1:spmat.n_col
        
        idx_start = spmat.col_begins_index[cc]
        if idx_start <= 0
            continue
        end
        (idx_end, flag_end_reached) = find_next_nonempty_col_begin(spmat, cc)

        for rr = idx_start:(idx_end-1)
            if rr < 0
                println("")
            end
            a_ij = spmat.data[rr]
            ii = spmat.row_index[rr]
            jj = cc
            A[ii, jj] = a_ij
        end

    end

    return A
end

# function Base.show(io::IO, spmat::SparseMatrixCSC)

#     n = length(spmat)
#     (n_row_full, n_col_full) = size(spmat)
#     T = eltype(spmat.data)
#     println("$(n)-sparse element (full size: $(n_row_full)x$(n_col_full)) SparseMatrixCSC{$(T)}:")
#     println("\tindex\tdata")

#     for cc = 1:n_col_full
        
#     end

#     for kk = 1:n
#         ii = spmat.row_index[kk]
#         jj = spmat.col_index[kk]
#         dd = spmat.data[kk]
#         println("\t($(ii), $(jj))\t$(dd)")
#     end

# end






function Base.length(spmat::SparseMatrixCSC)
    return length(spmat.data)
end

function n_nonzero(spmat::SparseMatrixCSC)
    return length(spmat)
end

function sparse_length(spmat::SparseMatrixCSC)
    return length(spmat)
end

function full_length(spmat::SparseMatrixCSC)
    return spmat.n_row * spmat.n_col
end

function Base.size(spmat::SparseMatrixCSC)
    return ( spmat.n_row, spmat.n_col )
end

function Base.size(spmat::SparseMatrixCSC, dim)
    if dim == 1
        return spmat.n_row
    elseif dim == 2
        return spmat.n_col
    else
        return 1
    end
end


function find_next_nonempty_col_begin(spmat::SparseMatrixCSC, col::Int)
    kk::Int = 1
    idx_end::Int = 0
    while true
        idx_end = spmat.col_begins_index[col + kk]
        if idx_end <= 0
            kk += 1
        else
            break
        end
    end
    flag_end_reached = idx_end == spmat.col_begins_index[end]
    return (idx_end, flag_end_reached)
end


function Base.getindex(spmat::SparseMatrixCSC, idx::Int)

    n_row = spmat.n_row
    n_col = spmat.n_col
    dims = (n_row, n_col)
    ci = CartesianIndices(dims)
    (rr, cc) = ci[idx].I

    col_begin = spmat.col_begins_index[cc]
    if col_begin <= 0
        return zero(eltype(spmat.data))
    end

    (col_end, flag_end_reached) = find_next_nonempty_col_begin(spmat, cc)
    if flag_end_reached
        return zero(eltype(spmat.data))
    end

    for ii = col_begin:(col_end-1)
        if spmat.row_index[ii] == rr
            return spmat.data[ii]
        end
    end

    return zero(eltype(spmat.data))
end

function Base.getindex(spmat::SparseMatrixCSC, I...)

    rr = I[1]
    cc = I[2]

    col_begin = spmat.col_begins_index[cc]
    if col_begin == 0
        return zero(eltype(spmat.data))
    end

    (col_end, flag_end_reached) = find_next_nonempty_col_begin(spmat, cc)

    if flag_end_reached
        return zero(eltype(spmat.data))
    end

    for ii = col_begin:(col_end-1)
        if spmat.row_index[ii] == rr
            return spmat.data[ii]
        end
    end

    return zero(eltype(spmat.data))


end


function matrix_split(spmat::SparseMatrixCSC)

    n_row = spmat.n_row
    n_col = spmat.n_col
    
    L = length(spmat)

    n_square = min(n_row, n_col)
    T = eltype(spmat.data)
    d = zeros(T, n_square)


    # for now: every newly created temporary array will have the same length as the original
    L_data      = zeros(T, L)
    L_row_idx   = zeros(Int, L)
    L_col_idx   = zeros(Int, L)
    
    U_data      = zeros(T, L)
    U_row_idx   = zeros(Int, L)
    U_col_idx   = zeros(Int, L)

    # main loop
    lastidx_l = 0
    lastidx_u = 0
    lastidx_d = 0

    for cc = 1:n_col
        
        col_begin = spmat.col_begins_index[cc]
        if col_begin <= 0
            continue
        end
        (col_end, flag_end_reached) = find_next_nonempty_col_begin(spmat, cc)
        
        for ii = col_begin:(col_end-1)

            dd = spmat.data[ii]
            rr = spmat.row_index[ii]

            if rr > cc # rr < cc # upper half

                lastidx_l += 1
                L_data[lastidx_l] = dd
                L_row_idx[lastidx_l] = rr
                L_col_idx[lastidx_l] = cc

            elseif rr == cc # diagonal

                lastidx_d += 1
                d[lastidx_d] = dd
                
            else # rr > cc # lower half

                lastidx_u += 1
                U_data[lastidx_u] = dd
                U_row_idx[lastidx_u] = rr
                U_col_idx[lastidx_u] = cc

            end

        end

    end

    # selection
    L_data      = L_data[1:lastidx_l]
    L_row_idx   = L_row_idx[1:lastidx_l]
    L_col_idx   = L_col_idx[1:lastidx_l]
    U_data      = U_data[1:lastidx_u]
    U_row_idx   = U_row_idx[1:lastidx_u]
    U_col_idx   = U_col_idx[1:lastidx_u]
    

    L = SparseMatrixCSC(n_row, n_col, L_data, L_row_idx, L_col_idx)
    U = SparseMatrixCSC(n_row, n_col, U_data, U_row_idx, U_col_idx)

    return (L, d, U)
end



