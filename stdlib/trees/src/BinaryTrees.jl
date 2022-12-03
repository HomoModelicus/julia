

include("../../stacks/src/Stacks.jl")
include("../../queues/src/Queues.jl")
include("TreeUtils.jl")




module BinaryTrees
using ..Stacks
using ..Queues
using ..TreeUtils


export  BinaryTreeNode,
        has_parent,
        is_root,
        has_left_child,
        has_right_child,
        is_leaf,
        has_right_sibling,
        has_child

export  BinaryTree,
        add_left_child!,
        add_right_child!

export  inorder_tree_walk,
        preorder_tree_walk,
        postorder_tree_walk,
        TreeSearchHelper,
        dfs,
        bfs

        


mutable struct BinaryTreeNode{T}
    parent::BinaryTreeNode
    left::BinaryTreeNode
    right::BinaryTreeNode
    
    data::T

    function BinaryTreeNode{T}(data::T) where {T}
        obj      = new()
        obj.data = data
        return obj
    end

    function BinaryTreeNode(data::T) where {T}
        return BinaryTreeNode{T}(data)
    end
end

function Base.show(io::IO, ::MIME{Symbol("text/plain")}, node::BinaryTreeNode{T}) where {T}
    if get(io, :compact, false)
        print("BinaryTreeNode{$T}($(node.data))")
    else
        println("BinaryTreeNode{$T}")
        println(" has parent: $(has_parent(node))")
        println("   has left: $(has_left_child(node))")
        println("  has right: $(has_right_child(node))")
        println("       data: $(node.data)")
    end
end

function is_root(node::BinaryTreeNode)
    return !isdefined(node, :parent)
end

function has_parent(node::BinaryTreeNode)
    return !is_root(node)
end

function has_left_child(node::BinaryTreeNode)
    return isdefined(node, :left)
end

function has_right_child(node::BinaryTreeNode)
    return isdefined(node, :right)
end

function is_leaf(node::BinaryTreeNode)
    return !has_left_child(node) && !has_right_child(node)
end

function has_right_sibling(node::BinaryTreeNode)
    if has_parent(node)
        parent = node.parent
        if parent.right == node
            return false
        else
            return true
        end
    else
        return false
    end
end

function has_child(node::BinaryTreeNode)
    return has_left_child(node) || has_right_child(node)
end


mutable struct BinaryTree{T}
    count::Int
    root::BinaryTreeNode{T}

    function BinaryTree{T}(data::T) where {T}
        obj       = new()
        obj.count = 1
        obj.root  = BinaryTreeNode(data)
        return obj
    end

    function BinaryTree(data::T) where {T}
        return BinaryTree{T}(data)
    end
end

function Base.show(io::IO, ::MIME{Symbol("text/plain")}, tree::BinaryTree{T}) where {T}
    if get(io, :compact, false)
        print("BinaryTree{$T}(count: $(tree.count))")
    else
        println("BinaryTree{$T}")
        println(" count: $(tree.count)")
    end
end


function Base.length(tree::BinaryTree)
    return length(tree.count)
end

function Base.size(tree::BinaryTree)
    return (length(tree), )
end

function root(tree::BinaryTree)
    return tree.root
end


function add_left_child!(
    tree::BinaryTree,
    parent_node::BinaryTreeNode,
    new_node::BinaryTreeNode)

    if has_left_child(parent_node)
        left_child        = parent_node.left
        left_child.parent = new_node
    end

    new_node.parent  = parent_node
    parent_node.left = new_node

    tree.count += 1
    return tree
end

function add_right_child!(
    tree::BinaryTree,
    parent_node::BinaryTreeNode,
    new_node::BinaryTreeNode)

    if has_right_child(parent_node)
        right_child        = parent_node.right
        right_child.parent = new_node
    end

    new_node.parent  = parent_node
    parent_node.right = new_node

    tree.count += 1
    return tree
end



function inorder_tree_walk(tree::BinaryTree, fcn::F) where {F <: Function}
    node = tree.root
    return __rec_inorder_tree_walk(node, fcn, 1)
end

function __rec_inorder_tree_walk(node::BinaryTreeNode, fcn::F, depth) where {F <: Function}
    if has_left_child(node)
        __rec_inorder_tree_walk(node.left, fcn, depth + 1)
    end

    fcn(node, depth)

    if has_right_child(node)
        __rec_inorder_tree_walk(node.right, fcn, depth + 1)
    end
end




function preorder_tree_walk(tree::BinaryTree, fcn::F) where {F <: Function}
    node = tree.root
    return __rec_preorder_tree_walk(node, fcn, 1)
end

function __rec_preorder_tree_walk(node::BinaryTreeNode, fcn::F, depth) where {F <: Function}
    
    fcn(node, depth)

    if has_left_child(node)
        __rec_preorder_tree_walk(node.left, fcn, depth + 1)
    end

    if has_right_child(node)
        __rec_preorder_tree_walk(node.right, fcn, depth + 1)
    end
end



function postorder_tree_walk(tree::BinaryTree, fcn::F) where {F <: Function}
    node = tree.root
    return __rec_postorder_tree_walk(node, fcn, 1)
end

function __rec_postorder_tree_walk(node::BinaryTreeNode, fcn::F, depth) where {F <: Function}

    if has_left_child(node)
        __rec_postorder_tree_walk(node.left, fcn, depth + 1)
    end

    if has_right_child(node)
        __rec_postorder_tree_walk(node.right, fcn, depth + 1)
    end

    fcn(node, depth)
end





struct BinaryTreeSearchHelper
    node::BinaryTreeNode
    visited::Bool
    depth::Int
end



function bfs(
    root::BinaryTreeNode;
    on_push_fcn::Fp    = do_nothing,
    on_visited_fcn::Fv = do_nothing,
    n_init             = 128
    ) where {Fp <: Function, Fv <: Function}

    
    queue = Queue{BinaryTreeSearchHelper}(n_init)
    push!(queue, BinaryTreeSearchHelper(root, false, 1))

    while !isempty(queue)
        
        cont = pop!(queue)

        if cont.visited
            on_visited_fcn(cont)
        else
            new_cont = BinaryTreeSearchHelper(cont.node, true, cont.depth)
            push!(queue, new_cont)
            on_push_fcn(new_cont)

            if has_right_child(cont.node)
                right_child_cont = BinaryTreeSearchHelper(cont.node.right, false, cont.depth + 1)
                push!(queue, right_child_cont)
                on_push_fcn(right_child_cont)
            end

            if has_left_child(cont.node)
                left_child_cont = BinaryTreeSearchHelper(cont.node.left, false, cont.depth + 1)
                push!(queue, left_child_cont)
                on_push_fcn(left_child_cont)
            end
        end

    end

end

function dfs(
    root::BinaryTreeNode;
    on_push_fcn::Fp    = do_nothing,
    on_visited_fcn::Fv = do_nothing,
    n_init             = 128
    ) where {Fp <: Function, Fv <: Function}
    
    stack = Stack{BinaryTreeSearchHelper}(n_init)
    push!(stack, BinaryTreeSearchHelper(root, false, 1))

    while !isempty(stack)
        
        cont = pop!(stack)

        if cont.visited
            on_visited_fcn(cont)
        else
            new_cont = BinaryTreeSearchHelper(cont.node, true, cont.depth)
            push!(stack, new_cont)
            on_push_fcn(new_cont)

            if has_right_child(cont.node)
                right_child_cont = BinaryTreeSearchHelper(cont.node.right, false, cont.depth + 1)
                push!(stack, right_child_cont)
                on_push_fcn(right_child_cont)
            end

            if has_left_child(cont.node)
                left_child_cont = BinaryTreeSearchHelper(cont.node.left, false, cont.depth + 1)
                push!(stack, left_child_cont)
                on_push_fcn(left_child_cont)
            end
        end

    end
end

function dfs(
    tree::BinaryTree;
    on_push_fcn::Fp    = do_nothing,
    on_visited_fcn::Fv = do_nothing,
    n_init             = div(tree.count, 2)
    ) where {Fp <: Function, Fv <: Function}
    
    return dfs(
        tree.root;
        on_push_fcn    = on_push_fcn,
        on_visited_fcn = on_visited_fcn,
        n_init         = n_init)
end

function bfs(
    tree::BinaryTree;
    on_push_fcn::Fp    = do_nothing,
    on_visited_fcn::Fv = do_nothing,
    n_init             = div(tree.count, 2)
    ) where {Fp <: Function, Fv <: Function}

    return bfs(
        tree.root;
        on_push_fcn    = on_push_fcn,
        on_visited_fcn = on_visited_fcn,
        n_init         = n_init)

end



end # module


