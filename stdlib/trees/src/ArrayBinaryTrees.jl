

include("../../stacks/src/Stacks.jl")
include("../../queues/src/Queues.jl")
include("TreeUtils.jl")




module ArrayBinaryTrees
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
        add_right_child!,
        root

export  inorder_tree_walk,
        preorder_tree_walk,
        postorder_tree_walk,
        TreeSearchHelper,
        dfs,
        bfs



const default_index::Int = 0


struct BinaryTreeNode{T}
    index::Int
    parent::Int
    left::Int
    right::Int

    data::T
    

    function BinaryTreeNode{T}(
        data::T,
        index::Int,
        parent::Int = default_index,
        left::Int   = default_index,
        right::Int  = default_index) where {T}

        return new(index, parent, left, right, data)
    end
    
    function BinaryTreeNode(
        data::T,
        index::Int,
        parent::Int = default_index,
        left::Int   = default_index,
        right::Int  = default_index) where {T}

        return BinaryTreeNode{T}(data, index, parent, left, right)
    end

    function BinaryTreeNode(data::T) where {T}
        index  = default_index
        parent = default_index
        left   = default_index
        right  = default_index
        return BinaryTreeNode{T}(data, index, parent, left, right)
    end

    function BinaryTreeNode(
        node::BinaryTreeNode{T};
        index  = default_index,
        parent = default_index,
        left   = default_index,
        right  = default_index) where {T}

        i = index  > default_index ? index  : node.index
        p = parent > default_index ? parent : node.parent
        l = left   > default_index ? left   : node.left
        r = right  > default_index ? right  : node.right

        data = node.data
        return BinaryTreeNode{T}(data, i, p, l, r)
    end

end


function has_parent(node::BinaryTreeNode)
    return node.parent > default_index
end

function is_root(node::BinaryTreeNode)
    return !has_parent(node)
end

function has_left_child(node::BinaryTreeNode)
    return node.left > default_index
end

function has_right_child(node::BinaryTreeNode)
    return node.right > default_index
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



const n_stack_init_size = 32

# data must have the same type
struct BinaryTree{T}
    stack::Stack{ BinaryTreeNode{T} }

    function BinaryTree{T}(data::T) where {T}
        stack    = Stack{BinaryTreeNode{T}}(n_stack_init_size)
        new_node = BinaryTreeNode(data, 1)
        push!(stack, new_node)
        return new(stack)
    end

    function BinaryTree(data::T) where {T}
        return BinaryTree{T}(data)
    end
end

function root(tree::BinaryTree{T}) where {T}
    return tree[1]
end

function Base.getindex(tree::BinaryTree{T}, index::Int) where {T}
    return tree.stack[index]
end

function Base.setindex!(tree::BinaryTree{T}, new_node::BinaryTreeNode{T}, index::Int) where {T}
    return tree.stack.data[index] = new_node
end

function Base.push!(tree::BinaryTree{T}, new_node::BinaryTreeNode{T}) where {T}
    # new_index = next_index(tree)
    # new_node = BinaryTreeNode(new_)
    return push!(tree.stack, new_node)
end

function Base.peek(tree::BinaryTree{T}) where {T}
    return peek(tree.stack)
end

function Base.length(tree::BinaryTree)
    return length(tree.stack)
end

function Base.size(tree::BinaryTree)
    return (length(tree), )
end

function Base.firstindex(tree::BinaryTree)
    return 1
end

function Base.lastindex(tree::BinaryTree)
    return tree.stack.ptr
end

function next_index(tree::BinaryTree)
    return tree.stack.ptr + 1
end




function add_left_child!(tree::BinaryTree{T}, parent_node::BinaryTreeNode{T}, new_node::BinaryTreeNode{T}) where {T}

    parent_index = parent_node.index
    parent_node  = tree[parent_index]
    new_index    = next_index(tree)

    if has_left_child(parent_node)
        left_child             = tree[parent_node.left]
        new_left_child         = BinaryTreeNode(left_child; parent = new_index)
        tree[parent_node.left] = new_left_child
    end

    new_parent_node = BinaryTreeNode(parent_node; left = new_index)
    new_node        = BinaryTreeNode(new_node; index = new_index, parent = parent_index)

    tree[parent_index] = new_parent_node
    push!(tree, new_node)

    return new_node
end

function add_left_child!(tree::BinaryTree, parent_index::Int, new_node::BinaryTreeNode{T}) where {T}
    parent_node = tree[parent_index]
    return add_left_child!(tree, parent_node, new_node)
end

function add_left_child!(tree::BinaryTree, parent_index::Int, new_data::T) where {T}
    parent_node = tree[parent_index]
    new_node    = BinaryTreeNode(new_data)
    return add_left_child!(tree, parent_node, new_node)
end


function add_right_child!(tree::BinaryTree{T}, parent_node::BinaryTreeNode{T}, new_node::BinaryTreeNode{T}) where {T}

    parent_index = parent_node.index
    parent_node  = tree[parent_index] # reindexing needed, because the parent node might be already updated
    new_index    = next_index(tree)

    if has_right_child(parent_node)
        right_child             = tree[parent_node.right]
        new_right_child         = BinaryTreeNode(right_child; parent = new_index)
        tree[parent_node.right] = new_right_child
    end

    new_parent_node = BinaryTreeNode(parent_node; right = new_index)
    new_node        = BinaryTreeNode(new_node; index = new_index, parent = parent_index)

    tree[parent_index] = new_parent_node
    push!(tree, new_node)

    return new_node
end

function add_right_child!(tree::BinaryTree, parent_index::Int, new_node::BinaryTreeNode{T}) where {T}
    parent_node = tree[parent_index]
    return add_right_child!(tree, parent_node, new_node)
end

function add_right_child!(tree::BinaryTree, parent_index::Int, new_data::T) where {T}
    parent_node = tree[parent_index]
    new_node    = BinaryTreeNode(new_data)
    return add_right_child!(tree, parent_node, new_node)
end




function get_left_node(tree::BinaryTree{T}, parent_node::BinaryTreeNode{T}) where {T}
    return tree[parent_node.left]
end

function get_right_node(tree::BinaryTree{T}, parent_node::BinaryTreeNode{T}) where {T}
    return tree[parent_node.right]
end


function inorder_tree_walk(tree::BinaryTree, fcn::F) where {F <: Function}
    node = root(tree)
    return __rec_inorder_tree_walk(tree, node, fcn, 1)
end

function __rec_inorder_tree_walk(tree::BinaryTree, node::BinaryTreeNode, fcn::F, depth) where {F <: Function}
    if has_left_child(node)
        __rec_inorder_tree_walk(tree, get_left_node(tree, node), fcn, depth + 1)
    end

    fcn(node, depth)

    if has_right_child(node)
        __rec_inorder_tree_walk(tree, get_right_node(tree, node), fcn, depth + 1)
    end
end



function preorder_tree_walk(tree::BinaryTree, fcn::F) where {F <: Function}
    node = root(tree)
    return __rec_preorder_tree_walk(tree, node, fcn, 1)
end

function __rec_preorder_tree_walk(tree::BinaryTree, node::BinaryTreeNode, fcn::F, depth) where {F <: Function}
    
    fcn(node, depth)
    
    if has_left_child(node)
        __rec_preorder_tree_walk(tree, get_left_node(tree, node), fcn, depth + 1)
    end

    if has_right_child(node)
        __rec_preorder_tree_walk(tree, get_right_node(tree, node), fcn, depth + 1)
    end
end




function postorder_tree_walk(tree::BinaryTree, fcn::F) where {F <: Function}
    node = root(tree)
    return __rec_postorder_tree_walk(tree, node, fcn, 1)
end

function __rec_postorder_tree_walk(tree::BinaryTree, node::BinaryTreeNode, fcn::F, depth) where {F <: Function}
    if has_left_child(node)
        __rec_postorder_tree_walk(tree, get_left_node(tree, node), fcn, depth + 1)
    end

    if has_right_child(node)
        __rec_postorder_tree_walk(tree, get_right_node(tree, node), fcn, depth + 1)
    end

    fcn(node, depth)
end

















struct BinaryTreeSearchHelper
    node::BinaryTreeNode
    visited::Bool
    depth::Int
end


function dfs(
    tree::BinaryTree;
    on_push_fcn::Fp = do_nothing,
    on_visited_fcn::Fv = do_nothing
    ) where {Fp <: Function, Fv <: Function}

    n_init = div(length(tree), 2)
    stack = Stack{BinaryTreeSearchHelper}(n_init)

    push!(stack, BinaryTreeSearchHelper(root(tree), false, 1))

    while !isempty(stack)
        
        cont = pop!(stack)

        if cont.visited
            on_visited_fcn(cont)
        else
            new_cont = BinaryTreeSearchHelper(cont.node, true, cont.depth)
            push!(stack, new_cont)
            on_push_fcn(new_cont)

            node = cont.node
            if has_right_child(node)
                right_child_cont = BinaryTreeSearchHelper(get_right_node(tree, node), false, cont.depth + 1)
                push!(stack, right_child_cont)
                on_push_fcn(right_child_cont)
            end

            if has_left_child(node)
                left_child_cont = BinaryTreeSearchHelper(get_left_node(tree, node), false, cont.depth + 1)
                push!(stack, left_child_cont)
                on_push_fcn(left_child_cont)
            end
        end

    end
end


end # module


