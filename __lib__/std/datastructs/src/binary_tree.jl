
# include("datastructs_module.jl")

# module btr # to be removed
# using ..datastructs # to be removed


abstract type AbstractTree
end

abstract type AbstractTreeNode
end

abstract type AbstractBinaryTree <: AbstractTree
end

abstract type AbstractBinaryTreeNode <: AbstractTreeNode
end


mutable struct BinaryTreeNode{T} <: AbstractBinaryTreeNode
    parent::BinaryTreeNode
    left::BinaryTreeNode
    right::BinaryTreeNode
    data::T

    function BinaryTreeNode{T}(content::T) where {T}
        obj = new()
        # obj.left = undef;
        # obj.right = undef;
        obj.data = content
        return obj
    end
    function BinaryTreeNode{T}() where {T}
        obj = new()
        return obj
    end
end

function BinaryTreeNode(content::T) where {T}
    return BinaryTreeNode{T}(content::T)
end

function BinaryTreeNode()
    return BinaryTreeNode(undef)
end

function has_left_child(node::BinaryTreeNode)
    return isdefined(node, :left)
end

function has_right_child(node::BinaryTreeNode)
    return isdefined(node, :right)
end


function Base.eltype( ::Type{ <: BinaryTreeNode{T}} ) where {T}
    return T
end

function Base.isempty(node::BinaryTreeNode)
    return node.data == undef
end

function Base.show(io::IO, node::BinaryTreeNode{T}) where {T}
    println("BinaryTreeNode{$(T)}")
    print("data: ")
    show(node.data)
    print("\n")
    
    print("\t  left:")
    if isdefined(node, :left)
        show(node.left.data)
    else
        print(" not_defined\n")
    end
    print("\n")

    print("\t  right:")
    if isdefined(node, :right)
        show(node.right.data)
    else
        print(" not_defined\n")
    end

    
end


# function is_root(node::BinaryTreeNode)
#     return !isdefined(node, :parent)
# end

function is_root(tree::T, node::N) where {T <: AbstractBinaryTree, N <: AbstractBinaryTreeNode}
    # this doesnt work for red black tree
    # return !isdefined(node, :parent)
    return tree.node == node
end

mutable struct BinaryTree{T} <: AbstractBinaryTree
    count::Int64
    node::BinaryTreeNode{T}

    function BinaryTree{T}(content::T) where {T}
        count_ = 1
        node_ = BinaryTreeNode{T}(content)
        return new(count_, node_)
    end
    function BinaryTree{T}() where {T}
        count_ = 1
        node_ = BinaryTreeNode{T}()
        return new(count_, node_)
    end
end

function BinaryTree(content::T) where {T}
    return BinaryTree{T}(content::T)
end

# function is_nil(tree, node.left)
# end

function search(tree::T, key) where {T <: AbstractBinaryTree}
    node = tree.node
    while node.data != key
        if node.data < key
            if isdefined(node, :left)
                next_node = node.left
            else
                break
            end
        else
            if isdefined(node, :right)
                next_node = node.right
            else
                break
            end
        end
        node = next_node
    end
    return node
end

function inorder_tree_walk(tree::T, fcn = show) where {T <: AbstractBinaryTree}
    node = tree.node
    return inorder_tree_walk(node, fcn, 1)
end

function inorder_tree_walk(tree::T, node::N, fcn = show, depth = 1) where {T <: AbstractBinaryTree, N <: AbstractBinaryTreeNode}
    if isdefined(node, :left) # && !is_nil(tree, node.left)
        child = node.left
        inorder_tree_walk(tree, child, fcn, depth+1)
    end
    fcn(node, depth)
    if isdefined(node, :right) # && !is_nil(tree, node.right)
        child = node.right
        inorder_tree_walk(tree, child, fcn, depth+1)
    end
end

function preorder_tree_walk(tree::T, fcn = show) where {T <: AbstractBinaryTree}
    node = tree.node
    return preorder_tree_walk(node, fcn, 1)
end

function preorder_tree_walk(tree::T, node::N, fcn = show, depth = 1) where {T <: AbstractBinaryTree, N <: AbstractBinaryTreeNode}
    
    fcn(node, depth)
    if isdefined(node, :left) # && !is_nil(tree, node.left)
        child = node.left
        preorder_tree_walk(tree, child, fcn, depth+1)
    end
    if isdefined(node, :right) # && !is_nil(tree, node.right)
        child = node.right
        preorder_tree_walk(tree, child, fcn, depth+1)
    end
end

function tree_minimum(tree::T) where {T <: AbstractBinaryTree}
    node = tree.node
    return tree_minimum(node)
end

function tree_minimum(node::N) where {N <: AbstractBinaryTreeNode}
    while isdefined(node, :left)
        node = node.left
    end
    return node
end

function tree_maximum(tree::N) where {N <: AbstractBinaryTree}
    node = tree.node
    return tree_maximum(node)
end

function tree_maximum(node::N) where {N <: AbstractBinaryTreeNode}
    while isdefined(node, :right)
        node = node.right
    end
    return node
end

function successor(node::N) where {N <: AbstractBinaryTreeNode}
    if isdefined(node, :right)
        return tree_minimum(node.right)
    end
    orig_node = node
    while true
        if isdefined(node, :parent)
            parent = node.parent
            if node == parent.left
                node = parent
                break
            end
            node = parent;
        else
            # the node is the greatest element in that array
            node = orig_node
            break
        end
    end
    return node
end

function predecessor(node::N) where {N <: AbstractBinaryTreeNode}

    if isdefined(node, :left)
        return tree_maximum(node.left)
    end
    orig_node = node
    while true
        if isdefined(node, :parent)
            parent = node.parent
            if node == parent.right
                node = parent
                break
            end
            node = parent;
        else
            # the node is the greatest element in that array
            node = orig_node
            break
        end
    end
    return node

end



function Base.insert!(tree::T, new_node::N) where {T <: BinaryTree, N <: BinaryTreeNode}
    # data must have < operation
    node   = tree.node
    parent = node

    to_left  = false
    to_right = false

    while true
        if new_node.data < node.data
            if isdefined(node, :left)
                child = node.left
            else
                parent = node
                to_left = true
                break
            end
        else
            if isdefined(node, :right)
                child = node.right
            else
                parent = node
                to_right = true
                break
            end
        end
        parent = node
        node   = child
    end

    new_node.parent = parent
    if to_left
        parent.left = new_node
    end
    if to_right
        parent.right = new_node
    end
    
    tree.count += 1

    return tree
end

function transplant!(tree::T, old_node::N, new_node::N) where {T <: BinaryTree, N <: BinaryTreeNode}
    if isdefined(old_node, :parent)
        parent = old_node.parent
        if old_node == parent.left
            parent.left = new_node
        else
            parent.right = new_node
        end
        new_node.parent = parent
    else
        tree.node = new_node
    end
    
    return tree
end

function remove!(tree::T, node::N) where {T <: BinaryTree, N <: BinaryTreeNode}
    
    if !isdefined(node, :left) && !isdefined(node, :right)
        if isdefined(node, :parent)
            parent = node.parent
            if node == parent.left
                parent.left = undef
            else
                parent.right = undef
            end
        end
    end

    if !isdefined(node, :left)
    
        transplant!(tree, node, node.right)
    
    elseif !isdefined(node, :right)
    
        transplant!(tree, node, node.left)
    
    else
    
        y = tree_minimum(node.right)
        if y.parent != node
            transplant!(tree, node, y)
            y.right = node.right
            y.right.parent = isdefined(node, :parent) ? node.parent : undef
        end

        transplant!(tree, node, y)
        y.left = node.left
        y.left.parent = isdefined(node, :parent) ? node.parent : undef

    end

    tree.count -= 1

    return tree
end

function Base.show(io::IO, tree::BinaryTree{T}) where {T}
    println("BinaryTree{$(T)} with properties")
    println(" \t count: $(tree.count)")
    print(" \t node: ")
    show(tree.node)
    print("\n\n")
end

function tree_view(tree::TreeType) where { TreeType <: AbstractBinaryTree}
    println("$(TreeType)} with properties")
    println(" \t count: $(tree.count)")
    preorder_tree_walk(tree, tree.node, tree_node_show, 1)
    println("\n")
end

function show_node(node::BinaryTreeNode)
    show(node.data)
end

function tree_node_show(node::T, depth = 1, show_fcn = show_node) where {T <: AbstractTreeNode}
    ws = "    "^(depth-1)
    print(ws, "Node: ")
    show_fcn(node)
    print("\n")
end




function depth_first_search(tree::TreeType;
    visited_fcn = do_nothing,
    push_fcn = do_nothing) where {TreeType <: AbstractBinaryTree}

    n        = tree.count
    depths   = zeros(Int, n)
    NodeType = typeof(tree.node)
    nodes    = Vector{NodeType}(undef, n)

    init_size    = div(n, 2)
    helper       = TreeSearchHelper(1, false)
    node_stack   = Stack{NodeType}(init_size)
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

            if has_left_child(node)
                push!(node_stack,   node.left)
                push!(helper_stack, TreeSearchHelper(next_depth, visited))

                push_fcn(node.left, next_depth, visited)
            end

            if has_right_child(node)
                push!(node_stack,   node.right)
                push!(helper_stack, TreeSearchHelper(next_depth, visited))

                push_fcn(node.right, next_depth, visited)
            end
        end

    end


    return (nodes, depths)
end



function breadth_first_search(tree::TreeType;
    visited_fcn = do_nothing,
    push_fcn = do_nothing) where {TreeType <: AbstractBinaryTree}

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

            if has_left_child(node)
                push!(node_queue,   node.left)
                push!(helper_queue, TreeSearchHelper(next_depth, visited))

                push_fcn(node.left, next_depth, visited)
            end

            if has_right_child(node)
                push!(node_queue,   node.right)
                push!(helper_queue, TreeSearchHelper(next_depth, visited))

                push_fcn(node.left, next_depth, visited)
            end
        end

    end


    return (nodes, depths)
end


# end # to be removed

