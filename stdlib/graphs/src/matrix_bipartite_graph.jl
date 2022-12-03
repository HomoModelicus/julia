



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



export MatrixBipartiteGraph

struct MatrixBipartiteGraph{T} <: AbstractGraph
    adjacency_matrix::Matrix{T}

    function MatrixBipartiteGraph{T}(n_dim) where {T}
        adjacency_matrix = zeros(T, n_dim, n_dim)
        return new(adjacency_matrix)
    end

    function MatrixBipartiteGraph{T}(matrix::Matrix{T}) where {T}
        return new(matrix)
    end

    function MatrixBipartiteGraph(matrix::Matrix{T}) where {T}
        return MatrixBipartiteGraph{T}(matrix)
    end
end

function Base.eltype(bipgraph::MatrixBipartiteGraph{T}) where {T}
    return T
end

function Base.length(bipgraph::MatrixBipartiteGraph)
    return length(bipgraph.adjacency_matrix)
end

function Base.size(bipgraph::MatrixBipartiteGraph)
    return size(bipgraph.adjacency_matrix)
end

function Base.size(bipgraph::MatrixBipartiteGraph, dims)
    return size(bipgraph.adjacency_matrix, dims)
end

function Base.IndexStyle(::Type{MatrixBipartiteGraph})
    return IndexCartesian()
end

function Base.IndexStyle(bipgraph::MatrixBipartiteGraph)
    return IndexCartesian()
end


function Base.getindex(bipgraph::MatrixBipartiteGraph{T}, row::Integer, col::Integer) where {T}
    return getindex(bipgraph.adjacency_matrix, row, col)
end

function Base.setindex!(bipgraph::MatrixBipartiteGraph{T}, x, row::Integer, col::Integer) where {T}
    setindex!(bipgraph.adjacency_matrix, x, row, col)
    return bipgraph
end

function Base.show(io::IO, mime::MIME"text/plain", bipgraph::MatrixBipartiteGraph)
    display(bipgraph.adjacency_matrix)
end


function n_nodes(bipgraph::MatrixBipartiteGraph)
    return size(bipgraph.adjacency_matrix, 1)
end

function n_edges(bipgraph::MatrixBipartiteGraph{T}) where {T}
    n = count(x -> x != zero(T), bipgraph.adjacency_matrix)
    return n
end

function add_edge!(bipgraph::MatrixBipartiteGraph{T}, from_index::Int, to_index::Int) where {T}
    bipgraph.adjacency_matrix[from_index, to_index] = one(T)
    return bipgraph
end

function remove_edge!(bipgraph::MatrixBipartiteGraph{T}, from_index::Int, to_index::Int) where {T}
    bipgraph.adjacency_matrix[from_index, to_index] = zero(T)
    return bipgraph
end





