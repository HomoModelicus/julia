

# include("datastructs_module.jl")

# module gr # to be removed
# using ..datastructs  # to be removed


# --------------------------------------------------------------------------- #
# Abstract Types
# --------------------------------------------------------------------------- #

abstract type AbstractEdge end
abstract type AbstractNode end
abstract type AbstractGraph end
abstract type AbstractDirectedGraph end
abstract type AbstractUndirectedGraph end




# =========================================================================== #
## Edge manipulation
# =========================================================================== #

# --------------------------------------------------------------------------- #
# Directed Edge
# --------------------------------------------------------------------------- #


struct SentinelEdge <: AbstractEdge
end

mutable struct DirectedEdge{NodeType} <: AbstractEdge
    start_node::NodeType
    end_node::NodeType
    
    function DirectedEdge{NodeType}(start_node::NodeType, end_node::NodeType) where {NodeType <: AbstractNode}
        obj = new{NodeType}()

        if !is_sentinel(start_node)
            push_to_output!(start_node, obj)
        end

        if !is_sentinel(end_node)
            push_to_input!(end_node, obj)
        end


        obj.start_node = start_node
        obj.end_node   = end_node
        
        return obj
    end
end
function DirectedEdge(start_node::T, end_node::T) where {T <: AbstractNode}
    return DirectedEdge{T}(start_node, end_node)
end
function DirectedEdge()
    s = SentinelNode()
    return DirectedEdge(s, s)
end






# --------------------------------------------------------------------------- #
# Undirected Edge
# --------------------------------------------------------------------------- #

mutable struct UndirectedEdge{NodeType} <: AbstractEdge
    start_node::NodeType
    end_node::NodeType
    
    function UndirectedEdge{NodeType}(start_node::NodeType, end_node::NodeType) where {NodeType <: AbstractNode}
        obj = new{NodeType}()

        if !is_sentinel(start_node)
            push!(start_node, obj)
        end

        if !is_sentinel(end_node)
            push!(end_node, obj)
        end


        obj.start_node = start_node
        obj.end_node   = end_node
        
        return obj
    end
end
function UndirectedEdge(start_node::T, end_node::T) where {T <: AbstractNode}
    return UndirectedEdge{T}(start_node, end_node)
end
function UndirectedEdge()
    s = SentinelNode()
    return UndirectedEdge(s, s)
end


# =========================================================================== #
## Node manipulation
# =========================================================================== #

# --------------------------------------------------------------------------- #
# Sentinel Node
# --------------------------------------------------------------------------- #

struct SentinelNode <: AbstractNode
end

function is_sentinel(node::T) where {T <: AbstractNode}
    return false
end

function is_sentinel(node::SentinelNode)
    return true
end


# --------------------------------------------------------------------------- #
# Directed Node
# --------------------------------------------------------------------------- #


mutable struct DirectedNode{EdgeType} <: AbstractNode
    input_edges::Vector{EdgeType}
    output_edges::Vector{EdgeType}
    index::Int
    data

    function DirectedNode{EdgeType}(input_edges, output_edges) where {EdgeType <: AbstractEdge}
        return new(input_edges, output_edges)
    end
end

function DirectedNode{EdgeType}(input_edge::EdgeType, output_edge::EdgeType) where {EdgeType <: AbstractEdge}
    input_edges     = Vector{EdgeType}(undef, 1)
    input_edges[1]  = input_edge
    
    output_edges    = Vector{EdgeType}(undef, 1)
    output_edges[1] = output_edge

    return DirectedNode{EdgeType}(input_edges, output_edges)
end
function DirectedNode{EdgeType}() where {EdgeType <: AbstractEdge}
    input_edges  = Vector{EdgeType}(undef, 0)
    output_edges = Vector{EdgeType}(undef, 0)
    return DirectedNode{EdgeType}(input_edges, output_edges)
end

function Base.show(io::IO, node::DirectedNode{EdgeType}) where {EdgeType <: AbstractEdge}
    println("DirectedNode{$(EdgeType)} with properties: ")
    println("   n input_edges: $(length(node.input_edges))")
    println("  n output_edges: $(length(node.output_edges))")
    println("           index: $(node.index)")
    if isdefined(node, :data)
        show(node.data)
    end
end


function push_to_output!(start_node::NT, edge::ET) where {NT <: AbstractNode, ET <: AbstractEdge}
    push!(start_node.output_edges, edge)
end

function push_to_input!(end_node::NT, edge::ET) where {NT <: AbstractNode, ET <: AbstractEdge}
    push!(end_node.input_edges, edge)
end



# --------------------------------------------------------------------------- #
# Undirected Node
# --------------------------------------------------------------------------- #

mutable struct UndirectedNode{EdgeType} <: AbstractNode
    edges::Vector{EdgeType}
    index::Int
    data

    function UndirectedNode{EdgeType}(edges) where {EdgeType <: AbstractEdge}
        return new(edges)
    end
end

function UndirectedNode{EdgeType}(edges::EdgeType) where {EdgeType <: AbstractEdge}
    edges     = Vector{EdgeType}(undef, 1)
    edges[1]  = edges

    return UndirectedNode{EdgeType}(edges)
end
function UndirectedNode{EdgeType}() where {EdgeType <: AbstractEdge}
    edges  = Vector{EdgeType}(undef, 0)
    return UndirectedNode{EdgeType}(edges)
end

function Base.show(io::IO, node::UndirectedNode{EdgeType}) where {EdgeType <: AbstractEdge}
    println("UndirectedNode{$(EdgeType)} with properties: ")
    println("  n edges: $(length(node.edges))")
    println("    index: $(node.index)")
    if isdefined(node, :data)
        show(node.data)
    end
end

function Base.push!(end_node::NT, edge::ET) where {NT <: AbstractNode, ET <: AbstractEdge}
    push!(end_node.edges, edge)
end

# =========================================================================== #
## Graph manipulation
# =========================================================================== #

# --------------------------------------------------------------------------- #
# Directed Graph
# --------------------------------------------------------------------------- #

struct DirectedGraph{NodeType, EdgeType} <: AbstractDirectedGraph
    nodes::Vector{NodeType}
    edges::Vector{EdgeType}

    function DirectedGraph{NodeType, EdgeType}() where {NodeType <: AbstractNode, EdgeType <: AbstractEdge}
        nodes = Vector{NodeType}(undef, 0)
        edges = Vector{EdgeType}(undef, 0)
        return new(nodes, edges)
    end
end

function Base.show(io::IO, graph::DirectedGraph{NodeType, EdgeType}) where {NodeType <: AbstractNode, EdgeType <: AbstractEdge}
    println("DirectedGraph{$(NodeType), $(EdgeType)} with properties: ")
    println("  nodes: $(n_nodes(graph))")
    println("  edges: $(n_edges(graph))")
end

function n_nodes(graph::DirectedGraph)
    return length(graph.nodes)
end

function n_edges(graph::DirectedGraph)
    return length(graph.edges)
end

function add_edge!(graph::DirectedGraph{NodeType, EdgeType}, edge::EdgeType) where {NodeType <: AbstractNode, EdgeType <: AbstractEdge}
    push!(graph.edges, edge)
end

function add_edge!(graph::DirectedGraph{NodeType, EdgeType}, start_node::NodeType, end_node::NodeType) where {NodeType <: AbstractNode, EdgeType <: AbstractEdge}
    new_edge = EdgeType(start_node, end_node)
    push!(graph.edges, new_edge)
end

function remove_edge!(graph::DirectedGraph, idx::Int)
    edge       = graph.edges[idx]
    start_node = edge.start_node
    end_node   = edge.end_node
    
    for ii = 1:length(start_node.output_edges)
        if edge == start_node.output_edges[ii]
            popat!(start_node.output_edges, ii)
            break
        end
    end

    for ii = 1:length(end_node.input_edges)
        if edge == end_node.input_edges[ii]
            popat!(end_node.input_edges, ii)
            break
        end
    end

end

function find_edge(graph::DirectedGraph{NodeType, EdgeType}, start_node::NodeType, end_node::NodeType) where {NodeType <: AbstractNode, EdgeType <: AbstractEdge}
    Lout = length(start_node.output_edges)
    Lin  = length(start_node.input_edges)
    

    edge  = SentinelEdge()
    found = false
    if Lin < Lout
        for ii = 1:Lin
            if start_node.output_edges[ii] == end_node
                found = true
                edge  = start_node.output_edges[ii]
                break
            end
        end
    else
        for ii = 1:Lout
            if end_node.input_edges[ii] == start_node
                found = true
                edge  = end_node.output_edges[ii]
                break
            end
        end
    end

    return (edge, found)
end

function add_node!(graph::DirectedGraph{NodeType, EdgeType}, node::NodeType) where {NodeType <: AbstractNode, EdgeType <: AbstractEdge}
    L  = length(graph.nodes)
    L += 1
    node.index = L
    push!(graph.nodes, node)
end

function remove_node!(graph::DirectedGraph, idx::Int)

    node = graph.nodes[idx]

    for ii = 1:length(node.input_edges)
        edge_idx = findfirst(this.edges == node.input_edges[ii])
        remove_edge!(graph, edge_idx)
    end

    for ii = 1:length(node.output_edges)
        edge_idx = findfirst(this.edges == node.output_edges[ii])
        remove_edge!(graph, edge_idx)
    end

end


function adjacency_matrix(graph::DirectedGraph)
    N_nodes = n_nodes(graph)
    adj_mat = zeros(Int, N_nodes, N_nodes)

    for ii = 1:N_nodes
        
        node = graph.nodes[ii]
        for aa = 1:length(node.input_edges)
            jj = node.input_edges[aa].start_node.index
            adj_mat[ii, jj] = +1
        end

        for aa = 1:length(node.output_edges)
            jj = node.output_edges[aa].end_node.index
            adj_mat[ii, jj] = +1
        end

    end

    return adj_mat
end

function incidence_matrix(graph::DirectedGraph)
    N_nodes = n_nodes(graph)
    adj_mat = zeros(Int, N_nodes, N_nodes)

    for ii = 1:N_nodes
        
        node = graph.nodes[ii]
        for aa = 1:length(node.input_edges)
            jj = node.input_edges[aa].start_node.index
            adj_mat[ii, jj] = +1
        end

        for aa = 1:length(node.output_edges)
            jj = node.output_edges[aa].end_node.index
            adj_mat[ii, jj] = -1
        end

    end

    return adj_mat
end

function sparse_incidence_matrix(graph::DirectedGraph)
    N_edges = 2 * n_edges(graph)
    
    row_idx = zeros(Int, N_edges)
    col_idx = zeros(Int, N_edges)
    val     = zeros(Int, N_edges)
    
    idx_start = 1
    idx_end   = 1

    for ii = 1:n_nodes(graph)

        node = graph.nodes[ii]
        Lin  = length(node.input_edges)
        Lout = length(node.output_edges)
        idx_end = idx_start - 1 + Lin + Lout

        for kk = idx_start:idx_end
            row_idx[kk] = ii
        end
        for kk = 1:Lin
            edge         = node.input_edges[kk]
            idx          = idx_start - 1 + kk
            col_idx[idx] = edge.start_node.index
            val[idx]     = +1
        end
        for kk = 1:Lout
            edge         = node.output_edges[kk]
            idx          = idx_start - 1 + Lin + kk
            col_idx[idx] = edge.end_node.index
            val[idx]     = -1
        end

        idx_start = idx_end + 1
    end

    return (row_idx, col_idx, val)
end

function create_directed_from_incidence_matrix(row_idx, col_idx, val)
    n_edges = length(row_idx)

    L = div(n_edges,2) 
    edges = Vector{DirectedEdge}(undef, L)


    un_row  = unique([row_idx; col_idx])
    n_nodes = length(un_row)
    nodes   = Vector{DirectedNode}(undef, n_nodes)

    for ii = 1:n_nodes
        dummy_node = DirectedNode{DirectedEdge}()
        nodes[ii]  = dummy_node
    end

    edge_idx = 1
    for ii = 1:n_edges

        if val[ii] == -1

            start_node_idx = row_idx[ii]
            end_node_idx   = col_idx[ii]

            start_node = nodes[start_node_idx]
            end_node   = nodes[end_node_idx]

            edge            = DirectedEdge(start_node, end_node)
            edges[edge_idx] = edge
            edge_idx        += 1
        end

    end

    graph = DirectedGraph{DirectedNode, DirectedEdge}()

    for ii = 1:n_nodes
        nodes[ii].index = ii
        add_node!(graph, nodes[ii])
    end
    for ii = 1:L
        add_edge!(graph, edges[ii])
    end


    return graph
end

# function create_from_incidence_matrix(inc_mat)
#     N_nodes = size(inc_mat,1)

#     nodes = Vector{DirectedNode}(undef, N_nodes)

#     for ii = 1:N_nodes
#         for jj = 1:N_nodes
#             if inc_mat[ii, jj] == -1
#                 # add edge
#             end
#         end
#         node = DirectedNode()
#     end

#     for ii = 1:N_nodes
#         add_node!(graph, nodes[ii])
#     end
#     for ii = 1:N_edges
#         add_edge!(graph, edges[ii])
#     end

#     return graph
# end





## Searches

function do_nothig()
end


## Searches

function breadth_first_search(graph::DirectedGraph;
    visited_fcn = do_nothing,
    push_fcn = do_nothing) where {TreeType <: AbstractBinaryTree}

end

function depth_first_search(graph::DirectedGraph;
    visited_fcn = do_nothing,
    push_fcn = do_nothing) where {TreeType <: AbstractBinaryTree}

end


# --------------------------------------------------------------------------- #
# Undirected Graph
# --------------------------------------------------------------------------- #

struct UndirectedGraph{NodeType, EdgeType} <: AbstractUndirectedGraph
    nodes::Vector{NodeType}
    edges::Vector{EdgeType}

    function UndirectedGraph{NodeType, EdgeType}() where {NodeType <: AbstractNode, EdgeType <: AbstractEdge}
        nodes = Vector{NodeType}(undef, 0)
        edges = Vector{EdgeType}(undef, 0)
        return new(nodes, edges)
    end
end

function Base.show(io::IO, graph::UndirectedGraph{NodeType, EdgeType}) where {NodeType <: AbstractNode, EdgeType <: AbstractEdge}
    println("UndirectedGraph{$(NodeType), $(EdgeType)} with properties: ")
    println("  nodes: $(n_nodes(graph))")
    println("  edges: $(n_edges(graph))")
end

function n_nodes(graph::UndirectedGraph)
    return length(graph.nodes)
end

function n_edges(graph::UndirectedGraph)
    return length(graph.edges)
end

function add_edge!(graph::UndirectedGraph{NodeType, EdgeType}, edge::EdgeType) where {NodeType <: AbstractNode, EdgeType <: AbstractEdge}
    push!(graph.edges, edge)
end

function add_edge!(graph::UndirectedGraph{NodeType, EdgeType}, start_node::NodeType, end_node::NodeType) where {NodeType <: AbstractNode, EdgeType <: AbstractEdge}
    new_edge = EdgeType(start_node, end_node)
    push!(graph.edges, new_edge)
end

function remove_edge!(graph::UndirectedGraph, idx::Int)
    edge       = graph.edges[idx]
    start_node = edge.start_node
    end_node   = edge.end_node
    
    for ii = 1:length(start_node.edges)
        if edge == start_node.edges[ii]
            popat!(start_node.edges, ii)
            break
        end
    end

    for ii = 1:length(end_node.edges)
        if edge == end_node.edges[ii]
            popat!(end_node.edges, ii)
            break
        end
    end
end

function find_edge(graph::UndirectedGraph{NodeType, EdgeType}, start_node::NodeType, end_node::NodeType) where {NodeType <: AbstractNode, EdgeType <: AbstractEdge}

    L = length(start_node.edges)
    
    edge  = SentinelEdge()
    found = false

    for ii = 1:L
        if start_node.edges[ii] == end_node
            found = true
            edge  = start_node.output_edges[ii]
            break
        end
    end
    
    return (edge, found)

end

function add_node!(graph::UndirectedGraph{NodeType, EdgeType}, node::NodeType) where {NodeType <: AbstractNode, EdgeType <: AbstractEdge}
    L  = length(graph.nodes)
    L += 1
    node.index = L
    push!(graph.nodes, node)
end

function remove_node!(graph::UndirectedGraph, idx::Int)

    node = graph.nodes[idx]

    for ii = 1:length(node.edges)
        edge_idx = findfirst(this.edges == node.input_edges[ii])
        remove_edge!(graph, edge_idx)
    end

end



function adjacency_matrix(graph::UndirectedGraph) # check for symmetry
    N_nodes = n_nodes(graph)
    adj_mat = zeros(Int, N_nodes, N_nodes)

    for ii = 1:N_nodes
        
        node = graph.nodes[ii]
        for aa = 1:length(node.edges)
            current_edge = node.edges[aa]

            jj = current_edge.start_node.index
            adj_mat[ii, jj] = +1

            jj = current_edge.end_node.index
            adj_mat[ii, jj] = +1
        end

        adj_mat[ii, ii] = 0

    end

    return adj_mat
end

function incidence_matrix(graph::UndirectedGraph)
    adj_mat = adjacency_matrix(graph)
    return adj_mat
end

function sparse_incidence_matrix(graph::UndirectedGraph)
    N_edges = 2 * n_edges(graph)
    
    row_idx = zeros(Int, N_edges)
    col_idx = zeros(Int, N_edges)
    val     = zeros(Int, N_edges)
    
    idx_start = 1
    idx_end   = 1

    for ii = 1:n_nodes(graph)

        node    = graph.nodes[ii]
        L       = length(node.edges)
        idx_end = idx_start - 1 + L

        for kk = idx_start:idx_end
            row_idx[kk] = ii
        end
        for kk = 1:L
            edge         = node.edges[kk]
            idx          = idx_start - 1 + kk
            col_idx[idx] = edge.start_node.index
            col_idx[idx] = edge.end_node.index
            val[idx]     = +1
        end

        idx_start = idx_end + 1
    end

    bool = trues(N_edges)
    for ii = 1:N_edges
        if row_idx[ii] == col_idx[ii]
            bool[ii] = false
        end
    end
    row_idx = row_idx[bool]
    col_idx = col_idx[bool]
    val     = val[bool]


    return (row_idx, col_idx, val)
end

function create_undirected_from_incidence_matrix(row_idx, col_idx, val)

    n_edges = length(row_idx)

    L = n_edges # div(n_edges,2) 
    edges = Vector{UndirectedEdge}(undef, L)


    un_row  = unique([row_idx; col_idx])
    n_nodes = length(un_row)
    nodes   = Vector{UndirectedNode}(undef, n_nodes)

    for ii = 1:n_nodes
        dummy_node = UndirectedNode{UndirectedEdge}()
        nodes[ii]  = dummy_node
    end

    edge_idx = 1
    for ii = 1:n_edges

        start_node_idx = row_idx[ii]
        end_node_idx   = col_idx[ii]

        start_node = nodes[start_node_idx]
        end_node   = nodes[end_node_idx]

        edge            = UndirectedEdge(start_node, end_node)
        edges[edge_idx] = edge
        edge_idx        += 1

    end

    graph = UndirectedGraph{UndirectedNode, UndirectedEdge}()

    for ii = 1:n_nodes
        nodes[ii].index = ii
        add_node!(graph, nodes[ii])
    end
    for ii = 1:L
        add_edge!(graph, edges[ii])
    end


    return graph

end


# --------------------------------------------------------------------------- #
# Matrix Undirected Graph
# --------------------------------------------------------------------------- #
# to be implemented

# --------------------------------------------------------------------------- #
# Matrix Directed Graph
# --------------------------------------------------------------------------- #
# to be implemented


## Searches

function breadth_first_search(
    graph::UndirectedGraph,
    start_node = graph.nodes[1])

    N_nodes = n_nodes(graph)
    queue = datastructs.Queue{DirectedNode}(N_nodes)

    push!(queue, start_node)

    while true

    end
    
end



# end

#=
module gtest
using ..gr

function test_digraph()
    digraph = gr.DirectedGraph{gr.DirectedNode, gr.DirectedEdge}()

    node_1 = gr.DirectedNode{gr.DirectedEdge}()
    node_2 = gr.DirectedNode{gr.DirectedEdge}()
    node_3 = gr.DirectedNode{gr.DirectedEdge}()
    node_4 = gr.DirectedNode{gr.DirectedEdge}()
    node_5 = gr.DirectedNode{gr.DirectedEdge}()
    node_6 = gr.DirectedNode{gr.DirectedEdge}()


    edge_12 = gr.DirectedEdge(node_1, node_2)
    edge_14 = gr.DirectedEdge(node_1, node_4)
    edge_25 = gr.DirectedEdge(node_2, node_5)
    edge_35 = gr.DirectedEdge(node_3, node_5)
    edge_36 = gr.DirectedEdge(node_3, node_6)
    edge_42 = gr.DirectedEdge(node_4, node_2)
    edge_54 = gr.DirectedEdge(node_5, node_4)
    # edge_66 = gr.DirectedEdge(node_6, node_6)


    gr.add_node!(digraph, node_1)
    gr.add_node!(digraph, node_2)
    gr.add_node!(digraph, node_3)
    gr.add_node!(digraph, node_4)
    gr.add_node!(digraph, node_5)
    gr.add_node!(digraph, node_6)

    gr.add_edge!(digraph, edge_12)
    gr.add_edge!(digraph, edge_14)
    gr.add_edge!(digraph, edge_25)
    gr.add_edge!(digraph, edge_35)
    gr.add_edge!(digraph, edge_36)
    gr.add_edge!(digraph, edge_42)
    gr.add_edge!(digraph, edge_54)
    # gr.add_edge!(graph, edge_66)


    adj_mat = gr.adjacency_matrix(digraph)
    inc_mat = gr.incidence_matrix(digraph)
    (row_idx, col_idx, val) = gr.sparse_incidence_matrix(digraph)

    # cdigraph = gr.create_directed_from_incidence_matrix(row_idx, col_idx, val)
    # (crow_idx, ccol_idx, cval) = gr.sparse_incidence_matrix(cdigraph)

    return digraph
end

function ungraph_test()

    ungraph = gr.UndirectedGraph{gr.UndirectedNode, gr.UndirectedEdge}()

    node_1 = gr.UndirectedNode{gr.UndirectedEdge}()
    node_2 = gr.UndirectedNode{gr.UndirectedEdge}()
    node_3 = gr.UndirectedNode{gr.UndirectedEdge}()
    node_4 = gr.UndirectedNode{gr.UndirectedEdge}()
    node_5 = gr.UndirectedNode{gr.UndirectedEdge}()
    node_6 = gr.UndirectedNode{gr.UndirectedEdge}()

    edge_12 = gr.UndirectedEdge(node_1, node_2)
    edge_14 = gr.UndirectedEdge(node_1, node_4)
    edge_25 = gr.UndirectedEdge(node_2, node_5)
    edge_35 = gr.UndirectedEdge(node_3, node_5)
    edge_36 = gr.UndirectedEdge(node_3, node_6)
    edge_42 = gr.UndirectedEdge(node_4, node_2)
    edge_54 = gr.UndirectedEdge(node_5, node_4)


    gr.add_node!(ungraph, node_1)
    gr.add_node!(ungraph, node_2)
    gr.add_node!(ungraph, node_3)
    gr.add_node!(ungraph, node_4)
    gr.add_node!(ungraph, node_5)
    gr.add_node!(ungraph, node_6)

    gr.add_edge!(ungraph, edge_12)
    gr.add_edge!(ungraph, edge_14)
    gr.add_edge!(ungraph, edge_25)
    gr.add_edge!(ungraph, edge_35)
    gr.add_edge!(ungraph, edge_36)
    gr.add_edge!(ungraph, edge_42)
    gr.add_edge!(ungraph, edge_54)


    adj_mat = gr.adjacency_matrix(ungraph)
    inc_mat = gr.incidence_matrix(ungraph)
    (row_idx, col_idx, val) = gr.sparse_incidence_matrix(ungraph)


    ungraph = ungraph_test()
    (row_idx, col_idx, val) = gr.sparse_incidence_matrix(ungraph)
    cungraph = gr.create_undirected_from_incidence_matrix(row_idx, col_idx, val)
    (crow_idx, ccol_idx, cval) = gr.sparse_incidence_matrix(cungraph)

    return ungraph
end



end

=#



struct MatrixGraph
    incidence_matrix::Matrix{Int}

    function MatrixGraph(n::N) where {N <: Integer}
        mat = zeros(Int, n, n)
        return new(mat)
    end
    function MatrixGraph(matrix::T) where {T <: Matrix}
        return new(matrix)
    end
end


function Base.show(io::IO, graph::MatrixGraph)
    println("MatrixGraph with properties")
    println("\t n nodes: $(n_nodes(graph))")
end

function n_nodes(graph::MatrixGraph)
    return size(graph.incidence_matrix, 1)
end

function n_edges(graph::MatrixGraph)
    n = mapreduce(abs, +, graph.incidence_matrix)
    n = div(n, 2)
    return n
end

function add_edge!(graph::MatrixGraph, from_index::Int, to_index::Int)
    graph.incidence_matrix[from_index, to_index] = -1
    graph.incidence_matrix[to_index, from_index] = +1
    
    return graph
end

# function remove_edge!(graph::MatrixGraph, from_index::Int, to_index::Int)
# end

function find_edge(graph::MatrixGraph, from_index::Int, to_index::Int)
    return graph.incidence_matrix[from_index, to_index]
end

function find_adjacent_nodes(graph::MatrixGraph, from_index::Int)
    op_fcn(index) = index != 0
    return __find_adjacent_nodes(graph::MatrixGraph, from_index::Int, op_fcn)
end

function find_incoming_nodes(graph::MatrixGraph, from_index::Int)
    op_fcn(index) = index == 1
    return __find_adjacent_nodes(graph::MatrixGraph, from_index::Int, op_fcn)
end

function find_outgoing_nodes(graph::MatrixGraph, from_index::Int)
    op_fcn(index) = index == -1
    return __find_adjacent_nodes(graph::MatrixGraph, from_index::Int, op_fcn)
end

function __find_adjacent_nodes(graph::MatrixGraph, from_index::Int, op_fcn)
    n = n_nodes(graph)
    
    row = view( graph.incidence_matrix, from_index, 1:n)
    
    L = mapreduce(op_fcn, +, row)
    out_indices = zeros(eltype(graph.incidence_matrix), L)
    
    jj = 1
    for ii = 1:n
        if op_fcn(row[ii]) # row[ii] != 0
            out_indices[jj] = ii
            jj += 1
        end
    end

    return out_indices
end

function incoming_edge_index()::Int
    return +1
end

function outgoing_edge_index()::Int
    return -1
end

function is_incoming_edge(index::Int)
    return index == 1
end

function is_outgoing_edge(index::Int)
    return index == -1
end


