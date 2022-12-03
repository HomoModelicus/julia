


# --------------------------------------------------------------------------- #
# matrix search utils
# --------------------------------------------------------------------------- #



function find_next_outgoing_edge(matrix_graph::MatrixDirectedGraph, node_index, start_index, reverse = false)
    return __find_next_outgoing_edge_matrix(matrix_graph, node_index, start_index, reverse)
end

function find_next_outgoing_edge(matrix_graph::MatrixUndirectedGraph, node_index, start_index, reverse = false)
    return __find_next_outgoing_edge_matrix(matrix_graph, node_index, start_index, reverse)
end


function __find_next_outgoing_edge_matrix(matrix_graph, node_index, start_index, reverse)
    T          = eltype(matrix_graph)
    N          = n_nodes(matrix_graph)
    next_index = -1

    if reverse
        range = start_index:-1:1
    else
        range = start_index:1:N
    end
    for jj in range
        if matrix_graph.adjacency_matrix[node_index, jj] != zero(T)
            next_index = jj
            break
        end
    end
    return next_index
end

function do_nothing(result, node)
    return nothing
end











# --------------------------------------------------------------------------- #
# search results
# --------------------------------------------------------------------------- #




const ColorType = Int8

const white = ColorType(0)
const gray  = ColorType(1)
const black = ColorType(2)

const no_predecessor_value   = Int(-1)
const start_depth_value      = Int(1)
const start_discorvery_value = Int(0)


struct BFSResult
    color::Vector{ColorType}
    depth::Vector{Int}
    predecessor::Vector{Int}

    function BFSResult(n_nodes::I) where {I <: Integer}
        color       = zeros(ColorType, n_nodes)
        depth       = zeros(Int,       n_nodes)
        predecessor = zeros(Int,       n_nodes)

        return new(color, depth, predecessor)
    end
end

function reinit!(bfs_res::BFSResult)
    N = length(bfs_res.color)
    for ii = 1:N
        bfs_res.color[ii]       = white
        bfs_res.depth[ii]       = 0
        bfs_res.predecessor[ii] = 0
    end
end




struct DFSResult
    color::Vector{ColorType}
    discovery_time::Vector{Int}
    finishing_time::Vector{Int}

    function DFSResult(n_nodes::I) where {I <: Integer}
        color          = zeros(ColorType, n_nodes)
        discovery_time = zeros(Int,       n_nodes)
        finishing_time = zeros(Int,       n_nodes)

        return new(color, discovery_time, finishing_time)
    end
end

function reinit!(dfs_res::DFSResult)
    N = length(dfs_res.color)
    for ii = 1:N
        dfs_res.color[ii]          = white
        dfs_res.discovery_time[ii] = 0
        dfs_res.finishing_time[ii] = 0
    end
end




# --------------------------------------------------------------------------- #
# bfs
# --------------------------------------------------------------------------- #



function __bfs_matrix(
    digraph::T,
    source::Int;
    result = BFSResult(n_nodes(digraph)),
    queue = Queue{Int}(n_nodes(digraph))
    ) where {T <: AbstractGraph}

    # initialization
    result.color[source]       = gray
    result.predecessor[source] = no_predecessor_value
    result.depth[source]       = start_depth_value

    push!(queue, source)

    while !isempty(queue)
        
        node = pop!(queue)

        next_edge = 0
        while true

            next_node = find_next_outgoing_edge(digraph, node, next_edge + 1)
            if next_node < 0
                break
            end

            next_edge = next_node
            if result.color[next_node] == white
                push!(queue, next_node)

                result.color[next_node]       = gray
                result.predecessor[next_node] = node
                result.depth[next_node]       = result.depth[node] + 1
            end

        end

        result.color[node] = black
    end

    return result
end



# function bfs(
#     digraph::MatrixDirectedGraph,
#     source::Int,
#     result = BFSResult(n_nodes(digraph)),
#     queue = Queue{Int}(n_nodes(digraph))
#     )

#     return __bfs_matrix(
#         ungraph,
#         source;
#         result = result,
#         queue  = queue)
# end

function bfs(
    graph,
    source::Int,
    result = BFSResult(n_nodes(graph)),
    queue = Queue{Int}(n_nodes(graph))
    )

    return __bfs_matrix(
        graph,
        source;
        result = result,
        queue  = queue)
end








# --------------------------------------------------------------------------- #
# dfs
# --------------------------------------------------------------------------- #


function __dfs_matrix(
    digraph::T,
    source::Int;
    start_time = 1,
    result = DFSResult(n_nodes(digraph)),
    stack  = Stack{Tuple{Int, Int}}(n_nodes(digraph)),
    on_pop = do_nothing
    ) where {T <: AbstractGraph}

    # initialization
    default_start_next_node       = 0
    time                          = start_time
    result.discovery_time[source] = time
    result.color[source]          = gray

    push!(stack, (source, default_start_next_node))

    while !isempty(stack)
        
        (node, start_next_node) = peek(stack)
        next_node = find_next_outgoing_edge(digraph, node, start_next_node + 1, false)

        if next_node > 0

            if result.color[next_node] == white
                time                            += 1
                result.discovery_time[next_node] = time
                result.color[next_node]          = gray

                push!(stack, (next_node, default_start_next_node))
            else
                # look for an other node which might be white
                pop!(stack)
                push!(stack, (node, start_next_node + 1)) 
            end

        else
            time                       += 1
            result.finishing_time[node] = time
            result.color[node]          = black
            pop!(stack)

            # gather the node indices at this place for scc
            # useful functionality for hook-in
            on_pop(result, node)
        end

    end

    return (result, time)
end



# function dfs(
#     digraph::MatrixDirectedGraph,
#     source::Int;
#     result = DFSResult(n_nodes(digraph)),
#     stack  = Stack{Tuple{Int, Int}}(n_nodes(digraph)),
#     on_pop = do_nothing
#     )

#     start_time = 1
#     (result, time) = __dfs_matrix(
#         digraph,
#         source;
#         start_time = start_time,
#         result     = result,
#         stack      = stack,
#         on_pop     = on_pop)

#     return result
# end

function dfs(
    graph,
    source::Int;
    result = DFSResult(n_nodes(graph)),
    stack  = Stack{Tuple{Int, Int}}(n_nodes(graph)),
    on_pop = do_nothing
    )

    start_time = 1
    (result, time) = __dfs_matrix(
        graph,
        source;
        start_time = start_time,
        result     = result,
        stack      = stack,
        on_pop     = on_pop)

    return result
end



function dfs_all_sources(
    digraph;
    result = DFSResult(n_nodes(digraph)),
    stack  = Stack{Tuple{Int, Int}}(n_nodes(digraph)),
    on_pop = do_nothing
    )

    time = 1
    for source = 1:n_nodes(digraph)
        if result.color[source] == white
            (result, time) = __dfs_matrix(
                                digraph,
                                source;
                                start_time = start_time,
                                result     = result,
                                stack      = stack,
                                on_pop     = on_pop)
            time += 1
        end
    end

    return result
end





