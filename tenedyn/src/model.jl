
# =========================================================================== #
## Model
# =========================================================================== #

abstract type AbstractModel end
abstract type AbstractSubModel <: AbstractModel end

mutable struct Model <: AbstractModel
    # add submodel vector
    nodes::Vector{AbstractBlock}
    names::Vector{String}
    signals::Vector{Signal}
    map_node_to_index::Dict{AbstractBlock, Int}
    graph::datastructs.MatrixGraph
    # incidence_matrix::Matrix{Int}

    function Model()
        nodes   = Vector{AbstractBlock}(undef, 0)
        names   = Vector{String}(undef, 0)
        signals = Vector{Signal}(undef, 0)
        
        map_node_to_index = Dict{AbstractBlock, Int}()

        return new(nodes, names, signals, map_node_to_index)
    end
end

function Base.show(io::IO, model::Model)
    println("Model with properties:")
    println("\t   n nodes: $(length(model.nodes))")
    println("\t   n names: $(length(model.names))")
    println("\t n signals: $(length(model.signals))")
    
end

function Base.push!(model::Model, node::N, name::S) where {N <: AbstractBlock, S <: AbstractString}

    last_idx = length(model.nodes)
    new_idx  = last_idx + 1
    model.map_node_to_index[node] = new_idx

    push!(model.nodes, node)
    push!(model.names, name)

    return model
end

# =========================================================================== #
## Connection
# =========================================================================== #

function connect!(model::Model, from_pin::OutType, to_pin::InType) where {OutType <: AbstractOutputPin, InType <: AbstractInputPin}
# tenedyn.connect!(model, sensor.y, ctrl_minus.x2)

    signal = Signal(from_pin, to_pin)
    push!(model.signals, signal)

    if has_child(from_pin)
        child_signal = from_pin.left_child_signal
        
        while has_right_sibling(child_signal)
            child_signal = child_signal.right_sibling_signal
        end
        child_signal.right_sibling_signal = signal
    else
        from_pin.left_child_signal = signal
    end

    return model
end
    

function find_integrators(model::Model)
    L       = length(model.nodes)
    n_init  = ceil(Int, L/5)
    indices = Vector{Int}(undef, n_init)
    jj      = 1

    for ii = 1:length(model.nodes)
            t = typeof( model.nodes[ii] )
            if t <: tenedyn.AbstractIntegrator
                indices[jj] = ii
                jj += 1
            end
    end

    indices = indices[1:jj-1]
    return indices
end
    
function compile(model::Model)
    
        # validation
        validate_model(model)
    
        # recompute the connection graph
        create_graph!(model)
    
        # initialize the forest
        integrator_indices  = find_integrators(model)
        n_states = length(integrator_indices)
        forest   = initialize_forest(n_states)
    
        tree_node_vecvec           = Vector{Vector{Any}}(undef, n_states)
        evalulation_indices_vecvec = Vector{Vector{Int}}(undef, n_states)
    
        # build the trees
        for ii = 1:n_states
            tree = build_tree(model, integrator_indices[ii])
            forest[ii] = tree
    
            (tree_nodes, tree_depths, tree_leaf, evaluation_indices) =
                tenedyn.extended_depth_first_search(model, tree)
    
            tree_node_vecvec[ii]           = tree_nodes
            evalulation_indices_vecvec[ii] = evaluation_indices
        end
    
    
        return (forest, integrator_indices, tree_node_vecvec, evalulation_indices_vecvec)
end

function validate_model(model::Model)
        # do nothing yet
end

function create_graph!(model::Model)
        # create incidence matrix
    
        n_nodes = length(model.nodes)
        n_edges = length(model.signals)
        inc_mat = zeros(Int, n_nodes, n_nodes)
        
    
        for ii = 1:n_edges
            edge = model.signals[ii]
            start_node = edge.start_pin.containing_object
            end_node   = edge.end_pin.containing_object
            
            si = find_block_index(model, start_node)
            ei = find_block_index(model, end_node)
            
            inc_mat[si, ei] = -1
            inc_mat[ei, si] = +1
        end
    
        model.graph = datastructs.MatrixGraph(inc_mat)
        
        return model
end

function find_block_index(model::Model, node)
        return model.map_node_to_index[node]
end

function initialize_forest(n_states::Int)
        forest = Vector{datastructs.Tree}(undef, n_states)
        return forest
end


struct TreeSearchHelper
        depth::Int
        visited::Bool
        last_tree_node::datastructs.TreeNode
end

function build_tree(model::Model, node_index::Int)
    
        # basically bfs/dfs search
        node = model.nodes[node_index]
    
        tree = datastructs.Tree(node)
    
        NodeType     = AbstractBlock
        init_size    = div( length(model.nodes), 2)
        helper       = TreeSearchHelper(1, false, tree.node)
        node_queue   = datastructs.Queue{NodeType}(init_size)
        helper_queue = datastructs.Queue{TreeSearchHelper}(init_size)
        push!(node_queue,   node)
        push!(helper_queue, helper)
    
        is_first = true
        while !isempty(node_queue)
    
            node   = pop!(node_queue)
            helper = pop!(helper_queue)
    
            if helper.visited
                # do nothing ?
            else
    
                # add the same node once again
                # helper = TreeSearchHelper(helper.depth, true, helper.last_tree_node)
                # push!(node_queue,   node)  # probably not necessary
                # push!(helper_queue, helper) # probably not necessary
    
                # stop search if:
                #   - the node has no input pin
                #   - input pin is not defined == nil
                #   => all of these can be expressed by the incidence matrix
                #   - OR the child node is an integrator
    
                # add the children to the queue
                if !is_first && is_integrator(node)
                    continue
                end
                is_first = false
                
                next_depth = helper.depth + 1
                visited    = false
    
                node_index  = model.map_node_to_index[node]
                adj_indices = datastructs.find_incoming_nodes(model.graph, node_index)
    
                for ii = 1:length(adj_indices)
                    child_node = model.nodes[ adj_indices[ii] ]
                    tree_node  = datastructs.TreeNode(child_node)
                    datastructs.insert_after!(tree, helper.last_tree_node, tree_node)
    
                    push!(node_queue,   child_node)
                    push!(helper_queue, TreeSearchHelper(next_depth, visited, tree_node))
                end
    
                
            end
        end
    
        return tree
end

function extended_depth_first_search(model::Model, tree::datastructs.Tree)
    
        n        = tree.count
        depths   = zeros(Int, n)
        nodes    = Vector{Any}(undef, n)
        is_leaf  = falses(n)
        evaluation_indices = zeros(Int, n)
    
        init_size    = div(n, 2)
        helper       = datastructs.TreeSearchHelper(1, false)
        node_stack   = datastructs.Stack{Any}(init_size)
        
        helper_stack = datastructs.Stack{datastructs.TreeSearchHelper}(init_size)
        push!(node_stack,   tree.node)
        push!(helper_stack, helper)
    
        index = 0
        while !isempty(node_stack)
    
            node   = pop!(node_stack)
            helper = pop!(helper_stack)
    
            if helper.visited
                
                index         += 1
                nodes[index]   = node
                depths[index]  = helper.depth
                is_leaf[index] = datastructs.is_leaf(node)
                evaluation_indices[index] = model.map_node_to_index[node.data]
            else
    
                # add the same node once again
                helper = datastructs.TreeSearchHelper(helper.depth, true)
                push!(node_stack,   node)
                push!(helper_stack, helper)
    
                # add the children
                next_depth = helper.depth + 1
                visited    = false
    
                if !datastructs.has_child(node)
                    continue
                end
    
                node = node.left_child
                push!(node_stack,   node)
                push!(helper_stack, datastructs.TreeSearchHelper(next_depth, visited))
    
                while datastructs.has_right_sibling(node)
                    node = node.right_sibling
                    push!(node_stack,   node)
                    push!(helper_stack, datastructs.TreeSearchHelper(next_depth, visited))
                end
    
            end
    
        end
    
    
        return (nodes, depths, is_leaf, evaluation_indices)
end

function eval_tree(
        model::Model,
        tree::datastructs.Tree,
        tree_nodes, # vector of any -> any treenode
        evaluation_indices::Vector{Int},
        time::Float64)
    
        value = tree.node.data.y.value
        L     = length(evaluation_indices)
        
        for ii = 1:L
            
            node_idx  = evaluation_indices[ii]
            node      = model.nodes[node_idx]
            tree_node = tree_nodes[ii]
    
            # eval node
            eval(node, time)
            # at the end of this eval the output of the node is updated
            # the output can be up propagated to its parent
            
            if !datastructs.is_root(tree_node)
                parent_tree_node = tree_node.parent
                parent_node      = parent_tree_node.data
                # parent_node.x?   = node.y.value
    
                # maybe a hash table for n1.outputpin - n2.inputpin -> int into edges
    
    
                # I could ask:
                symbol_list = get_output_pin_names(node)
                for sym in symbol_list
                    out_pin = getfield(node, sym)
                    
                    # search in the outgoing edges for the parent node
                    signal = out_pin.left_child_signal
                    found = false
                    while true
                        potentially_the_parent = signal.end_pin.containing_object  
                        if potentially_the_parent == parent_node
                            # propagate up the tree
                            signal.end_pin.value = out_pin.value
                            found = true
                            break
                        else
                            if has_right_sibling(signal)
                                signal = signal.right_sibling_signal
                            else
                                break
                            end
                        end
                    end
                    if !found
                        error("parent node has not been found")
                    end
                    value = signal.end_pin.value
                end
                
            end # if
    
            
        end # for
    
        return value
end

function get_output_pin_names(node)
        symbol_list = propertynames(node)
        bool        = map( sym -> isa(getfield(node, sym), OutputPin), symbol_list )
        idx         = findall(bool)
        symbol_list = symbol_list[idx]
        
        return symbol_list
end

function get_input_pin_names(node)
    symbol_list = propertynames(node)
    bool        = map( sym -> isa(getfield(node, sym), InputPin), symbol_list )
    idx         = findall(bool)
    symbol_list = symbol_list[idx]
    
    return symbol_list
end


function create_ode_function(
        model::Model,
        forest,
        integrator_indices,
        tree_node_vecvec,
        evalulation_indices_vecvec)
    
        
        # eval_tree(
        # model::Model,
        # tree::datastructs.Tree,
        # tree_nodes, # vector of any -> any treenode
        # evaluation_indices::Vector{Int},
        # time::Float64)
    
        n_states = length(integrator_indices)
    
        ode_fcn(der_q, time, q) = begin
    
            # update integrators
            for ii = 1:n_states
                model.nodes[ integrator_indices[ii] ].y.value = q[ii]
            end
    
            # evaluate the trees
            for ii = 1:n_states
                
                tree               = forest[ii]
                tree_nodes         = tree_node_vecvec[ii]
                evaluation_indices = evalulation_indices_vecvec[ii]
    
                value = eval_tree(
                    model,
                    tree,
                    tree_nodes,
                    evaluation_indices,
                    time)
    
                der_q[ii] = value
            end
    
            return der_q
        end
        
        return ode_fcn
end
    