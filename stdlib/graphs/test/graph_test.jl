


include("../src/Graphs.jl")

# #=

module dtest
using ..Graphs





# definition of the fcn - var bipartite graph

n_dim = 6
bipgraph = MatrixBipartiteGraph{Int8}(n_dim)

bipgraph[1, 3] = 1
bipgraph[1, 4] = 1
bipgraph[1, 6] = 1
bipgraph[2, 1] = 1
bipgraph[2, 2] = 1
bipgraph[2, 5] = 1
bipgraph[2, 6] = 1
bipgraph[3, 2] = 1
bipgraph[3, 3] = 1
bipgraph[4, 1] = 1
bipgraph[4, 3] = 1
bipgraph[4, 5] = 1
bipgraph[5, 2] = 1
bipgraph[5, 6] = 1
bipgraph[6, 3] = 1
bipgraph[6, 6] = 1


# n_dim = 3
# bipgraph = MatrixBipartiteGraph{Int8}(n_dim)
# bipgraph[1, 3] = 1
# bipgraph[2, 1] = 1
# bipgraph[2, 2] = 1
# bipgraph[2, 3] = 1
# bipgraph[3, 2] = 1



# n_dim = 7
# bipgraph = MatrixBipartiteGraph{Int8}(n_dim)

# bipgraph[1, 3] = 1
# bipgraph[1, 6] = 1
# bipgraph[2, 1] = 1
# bipgraph[2, 2] = 1
# bipgraph[2, 5] = 1
# bipgraph[2, 6] = 1
# bipgraph[3, 4] = 1
# bipgraph[3, 5] = 1
# bipgraph[3, 6] = 1
# bipgraph[4, 2] = 1
# bipgraph[5, 3] = 1
# bipgraph[5, 5] = 1
# bipgraph[6, 2] = 1
# bipgraph[6, 6] = 1
# bipgraph[7, 2] = 1
# bipgraph[7, 3] = 1
# bipgraph[7, 7] = 1




# n_dim = 7
# bipgraph = MatrixBipartiteGraph{Int8}(n_dim)

# bipgraph[1, 3] = 1
# bipgraph[1, 4] = 1
# bipgraph[1, 6] = 1
# bipgraph[2, 1] = 1
# bipgraph[2, 2] = 1
# bipgraph[2, 5] = 1
# bipgraph[2, 6] = 1
# bipgraph[3, 4] = 1
# bipgraph[3, 5] = 1
# bipgraph[4, 2] = 1
# bipgraph[5, 1] = 1
# bipgraph[5, 3] = 1
# bipgraph[5, 5] = 1
# bipgraph[6, 2] = 1
# bipgraph[6, 6] = 1
# bipgraph[7, 3] = 1
# bipgraph[7, 7] = 1



# n_dim = 4
# bipgraph = MatrixBipartiteGraph{Int8}(n_dim)

# bipgraph[1, 2] = 1
# bipgraph[1, 3] = 1
# bipgraph[2, 1] = 1
# bipgraph[2, 3] = 1
# bipgraph[3, 1] = 1
# bipgraph[3, 4] = 1
# bipgraph[4, 2] = 1
# bipgraph[4, 4] = 1




n_dim = 4
bipgraph = MatrixBipartiteGraph{Int8}(n_dim)

bipgraph[1, 2] = 1
bipgraph[1, 3] = 1
bipgraph[2, 1] = 1
bipgraph[2, 3] = 1
bipgraph[3, 1] = 1
bipgraph[3, 2] = 1
bipgraph[3, 4] = 1
bipgraph[4, 2] = 1
bipgraph[4, 4] = 1


# workflow for equation-variable bipartite graph to causalised system


# convert to max flow graph
adj_matrix_flow = Graphs.bipartite_to_max_flow_graph(bipgraph)
flow_digraph    = MatrixDirectedGraph(adj_matrix_flow)

# solve the max flow problem
max_flow_matrix = Graphs.ford_fulkerson(flow_digraph)

# get the assignment from the max flow result
assignment = Graphs.find_bipartite_matching(max_flow_matrix)

# create equation dependency graph
depgraph = Graphs.bipartite_dependency_graph(bipgraph, assignment)

# for strongly connected components -> blocks are the equation blocks in order
scc_sets = Graphs.strongly_connected_components(depgraph)

# sort the rows and cols
(sorted_bipgraph, eq_perm, var_perm) = Graphs.sort_bipartite_graph(bipgraph, scc_sets, assignment)

# block sizes
block_sizes = Graphs.strongly_connected_components_block_sizes(scc_sets)



end # module

# =#



#=

n_dim = 8
ungraph = MatrixUndirectedGraph{Int}(n_dim)

ungraph[1, 2] = 1
ungraph[1, 5] = 1

ungraph[2, 6] = 1

ungraph[3, 4] = 1
ungraph[3, 6] = 1
ungraph[3, 7] = 1

ungraph[4, 7] = 1
ungraph[4, 8] = 1

ungraph[6, 7] = 1

ungraph[7, 8] = 1


bfs_result = bfs(ungraph, 1)

=#


#=
n_dim = 6
digraph = MatrixDirectedGraph{Int}(n_dim)


digraph[1, 2] = 1
digraph[1, 4] = 1

digraph[2, 5] = 1

digraph[3, 5] = 1
digraph[3, 6] = 1

digraph[4, 2] = 1

digraph[5, 4] = 1

# digraph[6, 6] = 1

=#



# n_dim = 5
# digraph = MatrixDirectedGraph{Int}(n_dim)

# digraph[1, 3] = 1
# digraph[1, 4] = 1

# digraph[2, 1] = 1

# digraph[3, 2] = 1

# digraph[4, 5] = 1



# using Random
# Random.seed!(1)

# n_dim   = 200
# mat     = Graphs.random_integer_matrix(n_dim, 0.01)
# digraph = MatrixDirectedGraph(mat)




#=
n_dim = 6
digraph = MatrixDirectedGraph{Int}(n_dim)

digraph[2, 4] = 1
digraph[3, 2] = 1
digraph[3, 5] = 1
digraph[4, 2] = 1
digraph[5, 1] = 1
digraph[5, 2] = 1
digraph[5, 6] = 1
digraph[6, 1] = 1
digraph[6, 3] = 1
digraph[6, 4] = 1
=#




# dfs_result = dfs(digraph, 1)
# dfs_result = dfs(digraph, 2)
# dfs_result_all = Graphs.dfs_all_sources(digraph)

# scc_sets = Graphs.strongly_connected_components(digraph)







