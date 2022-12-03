



# --------------------------------------------------------------------------- #
# Unirected Matrix Graph
# --------------------------------------------------------------------------- #
#
# for a directed graph the full incidence_matrix or full adjacency_matrix is required
# adjacency_matrix:
# - contains only the out-edges
# - each row contains the from nodes, each col the to nodes
# 
# incidence_matrix: 
# - for leaving edge -1, for incoming edge +1
# - each row contains the nodes, each col the edges
# - each column contains only two nodes



export MatrixUndirectedGraph

struct MatrixUndirectedGraph{T} <: AbstractGraph
    adjacency_matrix::Matrix{T}

    function MatrixUndirectedGraph{T}(n_dim) where {T}
        adjacency_matrix = zeros(T, n_dim, n_dim)
        return new(adjacency_matrix)
    end

    function MatrixUndirectedGraph{T}(matrix::Matrix{T}) where {T}
        return new(matrix)
    end

    function MatrixUndirectedGraph(matrix::Matrix{T}) where {T}
        return MatrixUndirectedGraph{T}(matrix)
    end
end


function Base.eltype(ungraph::MatrixUndirectedGraph{T}) where {T}
    return T
end

function Base.length(ungraph::MatrixUndirectedGraph)
    return length(ungraph.adjacency_matrix)
end

function Base.size(ungraph::MatrixUndirectedGraph)
    return size(ungraph.adjacency_matrix)
end

function Base.size(ungraph::MatrixUndirectedGraph, dims)
    return size(ungraph.adjacency_matrix, dims)
end

function Base.IndexStyle(::Type{MatrixUndirectedGraph})
    return IndexCartesian()
end

function Base.IndexStyle(ungraph::MatrixUndirectedGraph)
    return IndexCartesian()
end


function Base.getindex(ungraph::MatrixUndirectedGraph{T}, row::Integer, col::Integer) where {T}
    return getindex(ungraph.adjacency_matrix, row, col)
end

function Base.setindex!(ungraph::MatrixUndirectedGraph{T}, x, row::Integer, col::Integer) where {T}
    setindex!(ungraph.adjacency_matrix, x, row, col)
    setindex!(ungraph.adjacency_matrix, x, col, row) # only for full matrix
    return ungraph
end

function Base.show(io::IO, mime::MIME"text/plain", ungraph::MatrixUndirectedGraph)
    display(ungraph.adjacency_matrix)
end


function n_nodes(ungraph::MatrixUndirectedGraph)
    return size(ungraph.adjacency_matrix, 1)
end

function n_edges(ungraph::MatrixUndirectedGraph{T}) where {T}
    n = count(x -> x != zero(T), ungraph.adjacency_matrix)
    return n
end

function add_edge!(ungraph::MatrixUndirectedGraph{T}, from_index::Int, to_index::Int) where {T}
    ungraph.adjacency_matrix[from_index, to_index] = one(T)
    return ungraph
end

function remove_edge!(ungraph::MatrixUndirectedGraph{T}, from_index::Int, to_index::Int) where {T}
    ungraph.adjacency_matrix[from_index, to_index] = zero(T)
    return ungraph
end





