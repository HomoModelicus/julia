




# --------------------------------------------------------------------------- #
# Directed Matrix Graph
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



export MatrixDirectedGraph

struct MatrixDirectedGraph{T} <: AbstractGraph
    adjacency_matrix::Matrix{T}

    function MatrixDirectedGraph{T}(n_dim) where {T}
        adjacency_matrix = zeros(T, n_dim, n_dim)
        return new(adjacency_matrix)
    end

    function MatrixDirectedGraph{T}(matrix::Matrix{T}) where {T}
        return new(matrix)
    end

    function MatrixDirectedGraph(matrix::Matrix{T}) where {T}
        return MatrixDirectedGraph{T}(matrix)
    end
end

function Base.eltype(digraph::MatrixDirectedGraph{T}) where {T}
    return T
end

function Base.length(digraph::MatrixDirectedGraph)
    return length(digraph.adjacency_matrix)
end

function Base.size(digraph::MatrixDirectedGraph)
    return size(digraph.adjacency_matrix)
end

function Base.size(digraph::MatrixDirectedGraph, dims)
    return size(digraph.adjacency_matrix, dims)
end

function Base.IndexStyle(::Type{MatrixDirectedGraph})
    return IndexCartesian()
end

function Base.IndexStyle(digraph::MatrixDirectedGraph)
    return IndexCartesian()
end

function Base.getindex(digraph::MatrixDirectedGraph{T}, row::Integer, col::Integer) where {T}
    return getindex(digraph.adjacency_matrix, row, col)
end

function Base.setindex!(digraph::MatrixDirectedGraph{T}, x, row::Integer, col::Integer) where {T}
    setindex!(digraph.adjacency_matrix, x, row, col)
    return digraph
end

function Base.show(io::IO, mime::MIME"text/plain", digraph::MatrixDirectedGraph)
    display(digraph.adjacency_matrix)
end



function n_nodes(digraph::MatrixDirectedGraph)
    return size(digraph.adjacency_matrix, 1)
end

function n_edges(digraph::MatrixDirectedGraph{T}) where {T}
    n = count(x -> x != zero(T), digraph.adjacency_matrix)
    return n
end

function add_edge!(graph::MatrixDirectedGraph{T}, from_index::Int, to_index::Int) where {T}
    graph.adjacency_matrix[from_index, to_index] = one(T)
    return graph
end

function remove_edge!(graph::MatrixDirectedGraph{T}, from_index::Int, to_index::Int) where {T}
    graph.adjacency_matrix[from_index, to_index] = zero(T)
    return graph
end



