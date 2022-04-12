
# include("datastructs_module.jl")


# module tr # to be removed
# using ..datastructs
# include("tree_search_helper.jl") # to be removed




# mutable struct PtrTreeNode{T}
#     parent::PtrTreeNode
#     child
# end

mutable struct TreeNode{T}
    parent::TreeNode
    left_child::TreeNode
    right_sibling::TreeNode
    data::T

    function TreeNode{T}(content::T) where {T}
        obj = new()
        obj.data = content
        return obj
    end
    function TreeNode{T}() where {T}
        obj = new()
        return obj
    end
end

TreeNode(content::T) where {T} = TreeNode{T}(content::T)
TreeNode() = TreeNode(undef)

Base.eltype( ::Type{ <: TreeNode{T}} ) where {T} = T
Base.isempty(node::TreeNode) = node.data == undef


function has_parent(node::TreeNode)
    return isdefined(node, :parent)
end

function has_child(node::TreeNode)
    return isdefined(node, :left_child)
end

function has_right_sibling(node::TreeNode)
    return isdefined(node, :right_sibling)
end


function is_root(node::TreeNode)
    return !has_parent(node)
end

function is_leaf(node::TreeNode)
    return !has_child(node)
end

function is_empty(node::TreeNode)
    return !isdefined(node, :data)
end

function set_data(node::TreeNode, data)
    node.data = data
end

function get_data(node::TreeNode)
    return node.data
end

function Base.show(io::IO, node::TreeNode{T}) where {T}
    println("TreeNode{$(T)}")

    print("\tparent: ")
    if has_parent(node)
        isdefined(node.parent, :data) ? show(node.parent.data) : print("<no_data>\n")
    else
        print("not_defined\n")
    end

    print("\tleft_child: ")
    if has_child(node)
        isdefined(node.left_child, :data) ? show(node.left_child.data) : print("<no_data>\n")
    else
        print("not_defined\n")
    end

    print("\right_sibling: ")
    if has_right_sibling(node)
        isdefined(node.right_sibling, :data) ? show(node.right_sibling.data) : print("<no_data>\n")
    else
        print("not_defined\n")
    end

    print("\tdata: ")
    if !is_empty(node)
        show(node.data)
    else
        print("not_defined\n")
    end
end

function clone(node::TreeNode{T}) where {T}
    new_node = TreeNode{T}()

    if has_parent(node)
        new_node.parent         = node.parent
    end
    if has_child(node)
        new_node.left_child     = node.left_child
    end
    if has_right_sibling(node)
        new_node.right_sibling  = node.right_sibling
    end
    if !is_empty(node)
        new_node.data           = node.data
    end
    
    
    return new_node
end

function children_vector(node::TreeNode{T}) where {T}

    vec = Vector{TreeNode{T}}(undef, 0)
    push!(vec, node)

    while has_right_sibling(node)
        right = node.right_sibling
        push!(vec, right)
    end
    
    return vec
end




mutable struct Tree{T}
    count::Int64
    node::TreeNode{T}

    function Tree{T}(content::T) where {T}
        count_ = 1
        node_ = TreeNode{T}(content)
        return new(count_, node_)
    end
    function Tree{T}() where {T}
        count_ = 1
        node_ = TreeNode{T}()
        return new(count_, node_)
    end
end
Tree(content::T) where {T} = Tree{T}(content::T)

function is_empty(tree::Tree)
    return tree.count == 0
end

function count(tree::Tree)
    return tree.count
end

function Base.show(io::IO, tree::Tree{T}) where {T}
    println("Tree{$(T)}")
    println("\tcount: $(tree.count)")
end

function insert_after!(tree::Tree, node::TreeNode, new_node::TreeNode)
    
    if is_leaf(node)
        node.left_child = new_node
    else
        # has some children, singly linked list
        left_child             = node.left_child
        node.left_child        = new_node
        new_node.right_sibling = left_child
    end

    new_node.parent = node
    tree.count     += 1

    return tree
end


function select(tree::Tree, index_vec)

    node = tree.node

    ii = 1
    L = length(index_vec)
    while ii <= L
        
        idx = index_vec[ii]
        if idx == 1
            node = node.left_child
        else
            aa = 1
            while has_right_sibling(node)
                aa += 1
                node = node.right_sibling
                if aa >= idx
                    break
                end
            end
            if aa < idx
                error("There is not as many siblings at level: $(ii), index: $(idx)")
            end

        end
        ii += 1
    end

    return node
end

function root(tree::Tree)
    return tree.node
end


function depth_first_search(tree::Tree;
    visited_fcn = do_nothing,
    push_fcn = do_nothing)

    n        = tree.count
    depths   = zeros(Int, n)
    NodeType = typeof(tree.node)
    # nodes    = Vector{NodeType}(undef, n)
    nodes    = Vector{Any}(undef, n)

    init_size    = div(n, 2)
    helper       = TreeSearchHelper(1, false)
    # node_stack   = Stack{NodeType}(init_size)
    node_stack   = Stack{Any}(init_size)
    
    helper_stack = Stack{TreeSearchHelper}(init_size)
    push!(node_stack,   tree.node)
    push!(helper_stack, helper)

    index = 0
    while !isempty(node_stack)

        node   = pop!(node_stack)
        helper = pop!(helper_stack)

        if helper.visited
            
            index        += 1
            nodes[index]  = node
            depths[index] = helper.depth

            # call the callback function
            visited_fcn(node, helper.depth, helper.visited)
        else

            # add the same node once again
            helper = TreeSearchHelper(helper.depth, true)
            push!(node_stack,   node)
            push!(helper_stack, helper)

            # add the children
            next_depth = helper.depth + 1
            visited    = false

            if !has_child(node)
                continue
            end

            node = node.left_child
            push!(node_stack,   node)
            push!(helper_stack, TreeSearchHelper(next_depth, visited))
            push_fcn(node, next_depth, visited)

            while has_right_sibling(node)
                node = node.right_sibling
                push!(node_stack,   node)
                push!(helper_stack, TreeSearchHelper(next_depth, visited))
                push_fcn(node, next_depth, visited)
            end

        end

    end


    return (nodes, depths)
end


function breadth_first_search(tree::Tree;
    visited_fcn = do_nothing,
    push_fcn = do_nothing)

    n        = tree.count
    depths   = zeros(Int, n)
    NodeType = typeof(tree.node)
    nodes    = Vector{NodeType}(undef, n)

    init_size    = div(n, 2)
    helper       = TreeSearchHelper(1, false)
    node_queue   = Queue{NodeType}(init_size)
    helper_queue = Queue{TreeSearchHelper}(init_size)
    push!(node_queue,   tree.node)
    push!(helper_queue, helper)

    index = 0
    while !isempty(node_queue)

        node   = pop!(node_queue)
        helper = pop!(helper_queue)

        # println("Popped: ")
        # show(node)

        if helper.visited
            index        += 1
            nodes[index]  = node
            depths[index] = helper.depth

            # call the callback function
            visited_fcn(node, helper.depth, helper.visited)
        else

            # add the same node once again
            helper = TreeSearchHelper(helper.depth, true)
            push!(node_queue,   node)
            push!(helper_queue, helper)

            # add the children
            next_depth = helper.depth + 1
            visited    = false

            if !has_child(node)
                continue
            end

            node = node.left_child
            push!(node_queue,   node)
            push!(helper_queue, TreeSearchHelper(next_depth, visited))
            push_fcn(node, next_depth, visited)
 
            while has_right_sibling(node)
                node = node.right_sibling
                push!(node_queue,   node)
                push!(helper_queue, TreeSearchHelper(next_depth, visited))
                push_fcn(node, next_depth, visited)
            end
        end

    end


    return (nodes, depths)
end


# function leaves(tree::Tree)
#     # needs e.g. dfs
# end

# function remove_node!(tree::Tree, node::TreeNode)
#     if is_root(node)
#         tree.count = 0
#         return tree
#     end

#     if is_leaf(node)
#         # easy case
#         parent = node.parent

#         
#     else
#         # hard case
#     end

#     tree.count -= 1
#     return tree
# end



# function merge!(tree1::TreeNode, tree2::TreeNode)
#     # basically a simultanous breadth first search
#     return tree1
# end




# Creation
# 
# clone - shallow copy -> is not implemented because it is dangerous
# split - not implemented yet
# sub tree - not implemented yet
# 
# State
# is_empty
# count
# show
# 
# Selection
# select == find_indices -> basically the path from the root
# leaves
# root
# 
# 
# Insertion
# insert_after
# insert_before - not implemented yet
# merge - not implemented yet
# 
# Deletion
# remove_node 
# 
# search from node - bfs, dfs -> apply functions include

 
# end


