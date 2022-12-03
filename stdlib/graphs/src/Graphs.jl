

# abstract type AbstractDirectedGraph <: AbstractGraph end
# abstract type AbstractUndirectedGraph <: AbstractGraph end
# abstract type AbstractDirectedMatrixGraph <: AbstractDirectedGraph end
# abstract type AbstractMatrixGraph         <: AbstractUndirectedGraph end

# export  AbstractGraph,
#         AbstractDirectedGraph,
#         AbstractUndirectedGraph,
#         AbstractEdge,
#         AbstractNode,
#         AbstractDirectedMatrixGraph,
#         AbstractMatrixGraph



# struct MatrixGraphTrait
# end

# struct DirectedGraphTrait
# end

# struct UndirectedGraphTrait
# end




include("../../stacks/src/Stacks.jl")
include("../../queues/src/Queues.jl")


module Graphs
using ..Stacks
using ..Queues







# --------------------------------------------------------------------------- #
# Abstract Types
# --------------------------------------------------------------------------- #

abstract type AbstractGraph end
abstract type AbstractEdge end
abstract type AbstractNode end



export  AbstractGraph,
        AbstractEdge,
        AbstractNode,
        #
        n_nodes,
        n_edges,
        add_edge!,
        remove_edge!,
        bfs,
        dfs


# --------------------------------------------------------------------------- #
# includes
# --------------------------------------------------------------------------- #


include("matrix_directed_graph.jl")
include("matrix_undirected_graph.jl")
include("matrix_bipartite_graph.jl")
include("search_utils.jl")


# --------------------------------------------------------------------------- #
# common utils
# --------------------------------------------------------------------------- #


function copy(graph::MatrixGraphType) where {MatrixGraphType <: AbstractGraph}
    new_graph = MatrixGraphType( Base.copy(graph.adjacency_matrix) )
    return new_graph
end



function random_integer_matrix(n_dim, q = 0.5, t::Type{T} = Int) where {T <: Integer}
    matrix = zeros(t, n_dim, n_dim)
    for ii = eachindex(matrix)
        if rand() <= q
            matrix[ii] = one(T)
        end
    end
    return matrix
end




function transposed_graph(digraph::MatrixDirectedGraph{T}) where {T}

    new_matrix = digraph.adjacency_matrix'

    n_dim = n_nodes(digraph)
    new_graph = MatrixDirectedGraph{T}(n_dim)

    for ii in eachindex(new_matrix)
        new_graph.adjacency_matrix[ii] = new_matrix[ii]
    end

    return new_graph
end



# assumption: 
# - square matrix is the input
function bipartite_to_max_flow_graph(graph::G) where {G <: AbstractGraph}
    N = n_nodes(graph)

    T = eltype(graph)
    Nnew = 2*N + 2 
    new_matrix = zeros(T, Nnew, Nnew)

    for jj = 1:N
        new_matrix[1, 1 + jj] = one(T)
    end

    for ii = 1:N
        new_matrix[1 + N + ii, 2*N + 2] = one(T)
    end

    for jj = 1:N
        for ii = 1:N
            new_matrix[1 + ii, 1 + N + jj] = graph[ii, jj]
        end
    end


    return new_matrix
end


# assumptions: 
# - square matrix from bipartite -> max_flow -> result is the input here
# - first block is the left block (equations)
function find_bipartite_matching(max_flow_matrix)
    N_ext   = size(max_flow_matrix, 1)
    N_nodes = div(N_ext, 2) - 1
    T       = eltype(max_flow_matrix)

    col_offset = N_nodes + 1
    row_offset = 1

    assignment = zeros(Int, N_nodes)

    for col = 1:N_nodes
        for row = 1:N_nodes
            # if there is a positive flow -> match found
            if max_flow_matrix[row + row_offset, col + col_offset] > zero(T)
                assignment[col] = row
                break
            end
        end
    end

    return assignment
end



function bipartite_dependency_graph(bipgraph, assignment)
    T       = eltype(bipgraph)
    N_nodes = n_nodes(bipgraph)
    digraph = MatrixDirectedGraph{Int}(N_nodes)

    # switched order for better cache-efficiency
    
    for jj = 1:N_nodes # columns -> variables
        for ii = 1:N_nodes # rows -> equations

            # skip for no connection
            if bipgraph[ii, jj] == zero(T)
                continue
            end

            # if the variable is assigned to that equation -> skip
            if assignment[jj] == ii
                continue
            end

            digraph[ assignment[jj], ii ] = one(T)
        end
    end

    return digraph
end

# --------------------------------------------------------------------------- #
# strongly_connected_components
# --------------------------------------------------------------------------- #


function strongly_connected_components(
    digraph::MatrixDirectedGraph;
    result = DFSResult(n_nodes(digraph)),
    stack  = Stack{Tuple{Int, Int}}(n_nodes(digraph))
    )


    # first depth first search
    time = 1
    for source = 1:n_nodes(digraph)
        if result.color[source] == white
            (result, time) = __dfs_matrix(
                                digraph,
                                source;
                                start_time = time,
                                result     = result,
                                stack      = stack,
                                on_pop     = do_nothing)
            time += 1
        end
    end


    # compute transposed 
    transp_digraph = transposed_graph(digraph)

    # permutation vector for decreasing finishing time
    perm_vec = sortperm(result.finishing_time; rev = true)


    # allocate the scc working arrays
    scc_sets      = Stack{ Vector{Int} }(4)
    working_stack = Stack{Int}(n_nodes(digraph))
    on_pop_push_scc(result, node) = push!(working_stack, node)

    transp_result = DFSResult(n_nodes(digraph))
    time = 1
    for index = 1:n_nodes(digraph)
        source = perm_vec[index]
        if transp_result.color[source] == white

            # reset the stack -> reuse the array
            Stacks.reinit!(working_stack) 

            (transp_result, time) = __dfs_matrix(
                transp_digraph,
                source;
                start_time = time,
                result     = transp_result,
                stack      = stack,
                on_pop     = on_pop_push_scc)

            time += 1

            # save the scc index array
            push!(scc_sets, valid_data(working_stack))
        end
    end

    return scc_sets
end


function strongly_connected_components_block_sizes(scc_sets)
    n   = Stacks.last_valid_index(scc_sets)
    vec = zeros(Int, n)
    for ii = 1:n
        vec[ii] = length(scc_sets[ii])
    end
    return vec
end


# --------------------------------------------------------------------------- #
# ford_fulkerson
# --------------------------------------------------------------------------- #


# assumtions:
# - first node is the source
# - last node is the target/sink
# - edge capacities are in the entries
# - for irrational numbers the algo might not terminate

function ford_fulkerson(digraph::MatrixDirectedGraph{T}) where {T}

    N_nodes          = n_nodes(digraph)
    flow_matrix      = zeros(T, N_nodes, N_nodes)
    adj_mat          = Base.copy(digraph.adjacency_matrix)
    residual_network = MatrixDirectedGraph(adj_mat)

    source = 1       # always, most likely can be relaxed
    target = N_nodes # always, most likely can be relaxed

    bfs_res = BFSResult(N_nodes)
    queue   = Queue{Int}(N_nodes)

    while true

        reinit!(bfs_res) # must be -> color info at least must be reset
        bfs_res = bfs(residual_network, source, bfs_res, queue)
        Queues.reinit!(queue) # reset for safety, should not be necessary

        # println("=== predecessor ===")
        # show(bfs_res.predecessor)
        # print("\n\n")

        # stopping criterion - target doesnt have a predecessor
        if bfs_res.predecessor[target] < one(T)
            break
        end

        # calculate the min capacity along the path in the residual_network
        min_cf = typemax(T)
        index  = target
        while index > one(Int)
            col    = index
            row    = bfs_res.predecessor[index]
            min_cf = min(min_cf, residual_network[row, col])
            index  = bfs_res.predecessor[index]
        end

        # update the flow matrix (and residual_network)

        # println("=== residual_network ===")
        # display( residual_network )

        # println("=== flow_matrix ===")
        # display( flow_matrix )

        index  = target
        while index > one(Int)
            col    = index
            row    = bfs_res.predecessor[index]

            flow_matrix[row, col] += min_cf
            flow_matrix[col, row] -= min_cf

            residual_network[row, col] -= min_cf
            residual_network[col, row] += min_cf

            index  = bfs_res.predecessor[index]
        end

        # println("=== residual_network ===")
        # display( residual_network )

        # println("=== flow_matrix ===")
        # display( flow_matrix )
    end

    return flow_matrix
end





function sort_bipartite_graph(bipgraph::MatrixBipartiteGraph{T}, scc_sets, assignment) where {T}
    N_nodes = n_nodes(bipgraph)
    adj_mat = Base.copy(bipgraph.adjacency_matrix)
    
    # sort by row/equation
    eq_perm = create_row_permutation_vector(bipgraph, scc_sets)
    adj_mat = adj_mat[eq_perm, :]

    # sort by column/variable
    reverse_assignment = sortperm(assignment) # reverse the assignment eq -> var now
    var_perm           = reverse_assignment[eq_perm] # column permutation
    adj_mat            = adj_mat[:, var_perm]


    sorted_bipgraph = MatrixBipartiteGraph(adj_mat)
    return (sorted_bipgraph, eq_perm, var_perm)
end





function create_row_permutation_vector(bipgraph::MatrixBipartiteGraph{T}, scc_sets) where {T}
    n_dim = n_nodes(bipgraph)

    pvec = zeros(T, n_dim)

    row_idx = 1
    for ii = 1:Stacks.last_valid_index(scc_sets)
        vec = scc_sets[ii]
        L   = length(vec)

        for jj = 1:L
            from_row = vec[jj]
            pvec[row_idx] = from_row
            row_idx += 1
        end
    end

    return pvec
end



end # module


