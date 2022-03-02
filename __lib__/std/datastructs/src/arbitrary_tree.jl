

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
