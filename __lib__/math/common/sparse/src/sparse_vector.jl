


mutable struct SparseVector{T}
    data::Vector{T}
    index::Vector{<:Integer}
    function SparseVector{T}(data::Vector{T}, index::Vector{<:Integer}) where {T}
        # last index must specify the length of the full array
        Ld = length(data)
        Li = length(index)
        if (Ld + 1) != Li
            error(
                "Data array must have one element less then index array,
                 last index must contain the number of elements in the full array")
        end
        if Li[end] < Ld
            error("The last index element must contain the length of the full array")
        end
        vec = new(data, index);
    end
end

function SparseVector{T}(data::Vector{T}, index) where {T}
    vec = SparseVector{T}(data, index);
end

function SparseVector(data::Vector{T}, index) where {T}
    vec = SparseVector{T}(data, index);
end

function create_sparse(data::Vector, tolerance = 1e-10)
    # for now: create a temporary array with the size of data
    L = length(data)
    tmp_data = similar(data)
    tmp_index = Vector{Int64}(undef, L+1)

    jj = 1
    for ii = 1:L
        if abs( data[ii] ) >= tolerance
            tmp_data[jj] = data[ii]
            tmp_index[jj] = ii
            jj += 1
        end
    end
    tmp_index[jj] = L
    vec = SparseVector(tmp_data[1:jj-1], tmp_index[1:jj])
    return vec
end

function create_full(spvec::SparseVector{T}) where {T}
    L = spvec.index[end]
    Ls = sparse_length(spvec)
    vec = zeros(T, L)
    for ii = 1:Ls
        vec[ spvec.index[ii] ] = spvec.data[ii]
    end
    return vec
end

function Base.length(spvec::SparseVector{T}) where {T}
    return length(spvec.data)
end

function Base.size(spvec::SparseVector{T}) where {T}
    return (length(spvec),)
end

function n_nonzero(spvec::SparseVector{T}) where {T}
    return length(spvec)
end

function sparse_length(spvec::SparseVector{T}) where {T}
    return length(spvec)
end

function full_length(spvec::SparseVector{T}) where {T}
    return spvec.index[end]
end


function Base.show(io::IO, spvec::SparseVector{T}) where {T}
    n = sparse_length(spvec)
    L = full_length(spvec)
    println("$(n)-sparse element (full length: $(L)) SparseVector{$(T)}:")
    println("\tindex\tdata")
    for kk = 1:n
        ii = spvec.index[kk]
        dd = spvec.data[kk]
        println("\t$(ii)\t$(dd)")
    end
end

function Base.getindex(spvec::SparseVector{T}, idx::Int) where {T}
    # error handling
    1 <= idx <= spvec.index[end] || throw(BoundsError(spvec, idx))

    # use linear search for finding the array index
    data = zero(T)

    for ii = 1:length(spvec)
        if spvec.index[ii] == idx
            data = spvec.data[ii]
        end
    end

    return data
end


# =========================================================================== #
# Math functions
# =========================================================================== #

# sparse + sparse
# sparse .* sparse

function Base.:+(x::SparseVector{T}, y::SparseVector{T}) where {T}
    return plus(x, y)
end

function Base.:-(x::SparseVector{T}, y::SparseVector{T}) where {T}
    return minus(x, y)
end

function Base.:*(x::SparseVector{T}, s::S) where {T, S}
    return scalar_multiply(x,  convert(promote_type(T, S), s) ) 
end
function Base.:*(s::S, x::SparseVector{T}) where {T, S}
    return x * s
end


function plus(x::SparseVector{T}, y::SparseVector{T}) where {T}
    # z = x + y

    Lfullx = full_length(x)
    Lfully = full_length(y)
    if Lfullx != Lfully
        error("Full size mismatch")
    end

    # already contains the last index length of the full array
    new_index = [copy(x.index); copy(y.index)] 
    new_index = sort!(new_index)
    new_index = unique!( new_index )
    
    new_data = zeros(eltype(x.data), length(new_index)-1)

    idx_x = 1;
    idx_y = 1;
    
    for ii = 1:(length(new_index)-1)
        if new_index[ii] == x.index[idx_x]
            new_data[ii] += x.data[idx_x]
            idx_x += 1
        end
        if new_index[ii] == y.index[idx_y]
            new_data[ii] += y.data[idx_y]
            idx_y += 1
        end
    end

    return SparseVector(new_data, new_index)
end

function minus(x::SparseVector{T}, y::SparseVector{T}) where {T}
    # z = x - y


    Lfullx = full_length(x)
    Lfully = full_length(y)
    if Lfullx != Lfully
        error("Full size mismatch")
    end

    # already contains the last index length of the full array
    new_index = [copy(x.index); copy(y.index)] 
    new_index = sort!(new_index)
    new_index = unique!( new_index )
    
    new_data = zeros(eltype(x.data), length(new_index)-1)

    idx_x = 1;
    idx_y = 1;
    
    for ii = 1:(length(new_index)-1)
        if new_index[ii] == x.index[idx_x]
            new_data[ii] += x.data[idx_x]
            idx_x += 1
        end
        if new_index[ii] == y.index[idx_y]
            new_data[ii] -= y.data[idx_y]
            idx_y += 1
        end
    end

    return SparseVector(new_data, new_index)
end


function scalar_multiply(x::SparseVector{T}, s::T) where {T}
    new_data = similar(x.data)
    for ii = 1:length(x)
        new_data[ii] = x.data[ii] * s
    end
    return SparseVector(new_data, copy(x.index))
end













