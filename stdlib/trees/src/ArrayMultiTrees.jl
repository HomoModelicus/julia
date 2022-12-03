

include("../../stacks/src/Stacks.jl")
include("../../queues/src/Queues.jl")
include("TreeUtils.jl")




module ArrayMultiTrees
using ..Stacks
using ..Queues
using ..TreeUtils


const default_index::Int = 0


struct TreeArrayNode{T}
    parent::Int
    left_child::Int
    right_sibling::Int

    data::T

    function TreeArrayNode{T}(
        data::T,
        parent        = default_index,
        left_child    = default_index,
        right_sibling = default_index) where {T}

        obj               = new()
        obj.data          = data
        obj.parent        = parent
        obj.left_child    = left_child
        obj.right_sibling = right_sibling
            
        return obj
    end

    function TreeArrayNode(
        data::T,
        parent        = default_index,
        left_child    = default_index,
        right_sibling = default_index) where {T}

        return TreeArrayNode{T}(data, parent, left_child, right_sibling)
    end

    function TreeArrayNode(
        node::TreeArrayNode{T};
        parent        = default_index,
        left_child    = default_index,
        right_sibling = default_index) where {T}

        p = node.parent         >= parent ?         node.parent         : parent
        l = node.left_child     >= left_child ?     node.left_child     : left_child
        r = node.right_sibling  >= right_sibling ?  node.right_sibling  : right_sibling
        
        return TreeArrayNode{T}(node.data, p, l, r)
    end

end




struct TreeArray{T}
    stack::Stack{TreeArrayNode{T}}

    function TreeArray{T}(n_init::Int) where {T}
        stack = Stack{TreeArrayNode{T}}(n_init)
        return new(stack)
    end
end


function has_child(node::TreeArrayNode)
    return node.left_child > default_index
end

function has_parent(node::TreeArrayNode)
    return node.parent > default_index
end

function has_right_sibling(node::TreeArrayNode)
    return node.right_sibling > default_index
end

function is_root(node::TreeArrayNode)
    return !has_parent(node)
end

function is_leaf(node::TreeArrayNode)
    return !has_child(node)
end


function add_child!(tree::TreeArray, parent_index::Int, new_node::TreeArrayNode)

    new_index   = tree.stack.ptr + 1
    parent_node = tree.stack[parent_index]
    

    if has_child(parent_node)

    else
        
    end
    
    
    new_parent  = TreeArrayNode(orig_parent; left_child = new_index)



end



function add_child!(parent_node::TreeNode, new_node::TreeNode)
    if has_child(parent_node)
        left_child             = parent_node.left_child
        new_node.right_sibling = left_child
        parent_node.left_child = new_node
        new_node.parent        = parent_node
    else
        parent_node.left_child = new_node
        new_node.parent        = parent_node
    end
end

# function add_sibling!(left_sibling::TreeNode, new_node::TreeNode)
#     if has_parent(left_sibling)

#         parent          = left_sibling.parent
#         new_node.parent = parent

#         if has_right_sibling(left_sibling)
#             right_sibling               = left_sibling.right_sibling
#             left_sibling.right_sibling  = new_node
#             new_node.right_sibling      = right_sibling
#         else
#             left_sibling.right_sibling  = new_node
#         end

#     else
#         error("Root cannot have a sibling")
#     end
# end





end # module