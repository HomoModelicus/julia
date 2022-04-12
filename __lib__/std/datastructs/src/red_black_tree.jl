
# @ToDo:
# implement delete operation

# abstract type AbstractBinaryTree end # to be removed
# abstract type AbstractBinaryTreeNode end # to be removed


mutable struct RedBlackTreeNode{T} <: AbstractBinaryTreeNode
    color::Bool # 0 black, 1 red
    parent::RedBlackTreeNode
    left::RedBlackTreeNode
    right::RedBlackTreeNode
    data::T

    function RedBlackTreeNode{T}(content::T) where {T}
        obj = new()
        obj.data = content
        obj.color = true
        return obj
    end
    function RedBlackTreeNode{T}() where {T}
        obj = new()
        obj.color = true
        return obj
    end
end


function RedBlackTreeNode(content::T) where {T}
    return RedBlackTreeNode{T}(content::T)
end

function RedBlackTreeNode()
    return RedBlackTreeNode(undef)
end

function Base.eltype( ::Type{ <: RedBlackTreeNode{T}} ) where {T}
    return T
end

function Base.isempty(node::RedBlackTreeNode) 
    return node.data == undef
end

function is_red(node::RedBlackTreeNode)
    return node.color # == true
end
function is_black(node::RedBlackTreeNode)
    return !node.color # == false
end

function set_red!(node::RedBlackTreeNode)
    node.color = true
    return node
end
function set_black!(node::RedBlackTreeNode)
    node.color = false
    return node
end

function is_nil(tree::T, node::N) where {T <: AbstractBinaryTree, N <: AbstractBinaryTreeNode}
    return tree.nil == node
end

mutable struct RedBlackTree{T} <: AbstractBinaryTree
    count::Int64
    node::RedBlackTreeNode{T}
    nil::RedBlackTreeNode{Int}

    function RedBlackTree{T}(content::T) where {T}
        count_       = 1
        node_        = RedBlackTreeNode{T}(content)
        nil_         = RedBlackTreeNode{Int}(-1)
        node_.parent = nil_
        node_.left   = nil_
        node_.right  = nil_
        set_black!(nil_)
        set_black!(node_)
        return new(count_, node_, nil_)
    end
    function RedBlackTree{T}() where {T}
        count_       = 1
        node_        = RedBlackTreeNode{T}()
        nil_         = RedBlackTreeNode{Int}(-1)
        node_.parent = nil_
        node_.left   = nil_
        node_.right  = nil_
        set_black!(nil_)
        set_black!(node_)
        return new(count_, node_, nil_)
    end
end

function RedBlackTree(content::T) where {T}
    return RedBlackTree{T}(content::T)
end


function right_rotate!(tree::T, x::N) where {T <: AbstractBinaryTree, N <: AbstractBinaryTreeNode}
    
    if isdefined(x, :left)
        alpha = x.left
        
        if isdefined(x, :parent)
            p = x.parent
            alpha.parent = p
            if isdefined(p, :left) && x == p.left
                p.left = alpha
            elseif isdefined(p, :right) 
                p.right = alpha
            end
        end
        if isdefined(alpha, :right)
            x.left             = alpha.right
            alpha.right.parent = x
        end

        alpha.right = x
        x.parent    = alpha

        if is_root(tree, x)
            tree.node = alpha
        end
    end

    return tree
end

function left_rotate!(tree::T, x::N) where {T <: AbstractBinaryTree, N <: AbstractBinaryTreeNode}

    if isdefined(x, :right)
        beta = x.right
        
        if isdefined(x, :parent)
            p = x.parent
            beta.parent = p
            if isdefined(p, :left) && x == p.left
                p.left = beta
            elseif isdefined(p, :right) 
                p.right = beta
            end
        end
        if isdefined(beta, :left)
            x.right          = beta.left
            beta.left.parent = x
        end

        beta.left = x
        x.parent  = beta
        
        if is_root(tree, x)
            tree.node = beta
        end
    end

    return tree
end


function Base.insert!(tree::T, new_node::N) where {T <: RedBlackTree, N <: RedBlackTreeNode}
    node     = tree.node 
    parent   = node
    to_left  = false
    to_right = false

    while true
        if new_node.data < node.data
            if isdefined(node, :left) && !is_nil(tree, node.left)
                child = node.left
            else
                parent  = node
                to_left = true
                break
            end
        else
            if isdefined(node, :right) && !is_nil(tree, node.right)
                child = node.right
            else
                parent   = node
                to_right = true
                break
            end
        end
        parent = node
        node = child
    end

    new_node.parent = parent
    if to_left
        parent.left = new_node
    end
    if to_right
        parent.right = new_node
    end

    new_node.left  = tree.nil
    new_node.right = tree.nil
    

    set_red!(new_node)
    red_black_insert_fixup!(tree, new_node)

    tree.count += 1
    return tree
end


function red_black_insert_fixup!(tree::T, node::N) where {T <: RedBlackTree, N <: RedBlackTreeNode}
    while is_red(node.parent)

        # parent  = node.parent
        # grandpa = node.parent.parent
        # isdefined(grandpa, :left) &&
        if node.parent == node.parent.parent.left

            y = node.parent.parent.right     # uncle
            if is_red(y)
                set_black!(node.parent)      # parent is black
                set_black!(y)                # uncle is black
                set_red!(node.parent.parent) # grandparent is red
                node = node.parent.parent    # move 2 levels up the hierarchy
            else
                if node == node.parent.right
                    node = node.parent
                    left_rotate!(tree, node)
                end
                set_black!(node.parent)
                set_red!(node.parent.parent)
                right_rotate!(tree, node.parent.parent)
            end
            
        else
            # same with left and right exchanged
        
            y = node.parent.parent.left
            if is_red(y)
                set_black!(node.parent)
                set_black!(y)
                set_red!(node.parent.parent)
                node = node.parent.parent
            else
                if node == node.parent.left
                    node = node.parent
                    right_rotate!(tree, node)
                end
                set_black!(node.parent)
                set_red!(node.parent.parent)
                left_rotate!(tree, node.parent.parent)
            end
            
        end
    end

    set_black!(tree.node)
    set_black!(tree.nil)
    
    return tree
end



function transplant!(tree::T, old_node::N, new_node::N) where {T <: RedBlackTree, N <: RedBlackTreeNode}

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

function remove!(tree::T, node::N) where {T <: RedBlackTree, N <: RedBlackTreeNode}

    return tree
end





function Base.show(io::IO, tree::RedBlackTree{T}) where {T}
    println("RedBlackTree{$(T)} with properties")
    println(" \t count: $(tree.count)")
    print(" \t node: {")
    show_node(tree.node)
    print("}\n\n")
end



function show_node(node::RedBlackTreeNode)
    print(" color: ")
    if is_red(node)
        print("red, ")
    else
        print("black, ")
    end
    show(node.data)
end
