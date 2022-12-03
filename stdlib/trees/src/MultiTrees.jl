

include("../../stacks/src/Stacks.jl")
include("../../queues/src/Queues.jl")
include("TreeUtils.jl")




module MultiTrees
using ..Stacks
using ..Queues
using ..TreeUtils




export  MultiTreeNode,
        has_parent,
        is_root,
        has_left_child,
        has_right_child,
        is_leaf,
        has_right_sibling,
        has_child

export  Tree,
        add_child!,
        add_sibling!

export  TreeSearchHelper,
        dfs,
        bfs


mutable struct MultiTreeNode{T}
    parent::MultiTreeNode
    left_child::MultiTreeNode
    right_sibling::MultiTreeNode

    data::T

    function MultiTreeNode{T}(data::T) where {T}
        obj = new()
        obj.data = data
            
        return obj
    end

    function MultiTreeNode(data::T) where {T}
        return MultiTreeNode{T}(data)
    end
end

function Base.show(io::IO, ::MIME{Symbol("text/plain")}, node::MultiTreeNode{T}) where {T}
    if get(io, :compact, false)
        print("MultiTreeNode{$(T)}(data = $(node.data))")
    else
        println("MultiTreeNode{$(T)}")
        println("                 data: $(node.data)")
        println("           has_parent: $(has_parent(node))")
        println("            has_child: $(has_child(node))")
        println("    has_right_sibling: $(has_right_sibling(node))")
    end
end


function has_child(node::MultiTreeNode)
    return isdefined(node, :left_child)
end

function has_parent(node::MultiTreeNode)
    return isdefined(node, :parent)
end

function has_right_sibling(node::MultiTreeNode)
    return isdefined(node, :right_sibling)
end

function is_root(node::MultiTreeNode)
    return !has_parent(node)
end

function is_leaf(node::MultiTreeNode)
    return !has_child(node)
end

function has_left_child(node::MultiTreeNode)
    return isdefined(node, :left_child)
end

function has_right_child(node::MultiTreeNode)
    if has_left_child(node)
        left_child = node.left_child
        if has_right_sibling(left_child)
            return true
        else
            return false
        end
    else
        return false
    end
end



# add tree as argument for count
# function remove!(node::MultiTreeNode)

#     if is_leaf(node)
#         if has_parent(node)
#             parent = node.parent
#             if node == 
#         end
#     else
#     end
# end





mutable struct MultiTree{T}
    count::Int
    root::MultiTreeNode{T}

    function MultiTree{T}(data::T) where {T}
        count = 1
        root  = MultiTreeNode{T}(data)
        return new(count, root)
    end

    function MultiTree(data::T) where {T}
        return MultiTree{T}(data)
    end
end

function Base.show(io::IO, ::MIME{Symbol("text/plain")}, tree::MultiTree{T}) where {T}
    if get(io, :compact, false)
        print("MultiTree{$(T)}(count = $(tree.count))")
    else
        println("MultiTree{$(T)}")
        println("    count: $(tree.count)")
        println("    root: $(tree.root)")
    end
end



function insert_as_child!(tree::MultiTree, parent_node::MultiTreeNode, new_node::MultiTreeNode)
    if has_child(parent_node)
        left_child             = parent_node.left_child

        left_child.parent      = new_node
        new_node.left_child    = left_child

        parent_node.left_child = new_node
        new_node.parent        = parent_node
    else
        parent_node.left_child = new_node
        new_node.parent        = parent_node
    end

    tree.count += 1
    return tree
end

function add_child!(tree::MultiTree, parent_node::MultiTreeNode, new_node::MultiTreeNode)
    if has_child(parent_node)
        left_child             = parent_node.left_child
        new_node.right_sibling = left_child
        parent_node.left_child = new_node
        new_node.parent        = parent_node
    else
        parent_node.left_child = new_node
        new_node.parent        = parent_node
    end

    tree.count += 1
    return tree
end

# add tree as argument for count
function add_sibling!(tree::MultiTree, left_sibling::MultiTreeNode, new_node::MultiTreeNode)
    if has_parent(left_sibling)

        parent          = left_sibling.parent
        new_node.parent = parent

        if has_right_sibling(left_sibling)
            right_sibling               = left_sibling.right_sibling
            left_sibling.right_sibling  = new_node
            new_node.right_sibling      = right_sibling
        else
            left_sibling.right_sibling  = new_node
        end

    else
        error("Root cannot have a sibling")
    end

    tree.count += 1
    return tree
end





struct TreeSearchHelper
    node::MultiTreeNode
    visited::Bool
    depth::Int
end



function bfs(
    root::MultiTreeNode;
    on_push_fcn::Fp    = do_nothing,
    on_visited_fcn::Fv = do_nothing,
    n_init             = 128
    ) where {Fp <: Function, Fv <: Function}


# function bfs(tree::Tree;
#     on_push_fcn::Fp = do_nothing,
#     on_visited_fcn::Fv = do_nothing
#     ) where {Fp <: Function, Fv <: Function}

    # n_init = div(tree.count, 2)
    queue = Queue{TreeSearchHelper}(n_init)
    cont  = TreeSearchHelper(root, false, 1)

    push!(queue, cont)
    on_push_fcn(cont)

    while !isempty(queue)
        
        cont = pop!(queue)

        if cont.visited
            on_visited_fcn(cont)
        else

            cont = TreeSearchHelper(cont.node, true, cont.depth)
            push!(queue, cont)
            on_push_fcn(cont)

            if has_child(cont.node)

                depth = cont.depth + 1
                child = cont.node.left_child
                cont  = TreeSearchHelper(child, false, depth)
                push!(queue, cont)
                on_push_fcn(cont)

                while has_right_sibling(child)
                    child = child.right_sibling
                    cont  = TreeSearchHelper(child, false, depth)
                    push!(queue, cont)
                    on_push_fcn(cont)
                end
            end

        end

    end

end

function dfs(
    root::MultiTreeNode;
    on_push_fcn::Fp    = do_nothing,
    on_visited_fcn::Fv = do_nothing,
    n_init             = 128
    ) where {Fp <: Function, Fv <: Function}

# function dfs(
#     tree::MultiTree;
#     on_push_fcn::Fp = do_nothing,
#     on_visited_fcn::Fv = do_nothing
#     ) where {Fp <: Function, Fv <: Function}

    # n_init = div(tree.count, 2)
    stack  = Stack{TreeSearchHelper}(n_init)
    cont = TreeSearchHelper(root, false, 1)

    push!(stack, cont)
    on_push_fcn(cont)

    while !isempty(stack)
        
        cont = pop!(stack)

        if cont.visited
            on_visited_fcn(cont)
        else

            cont = TreeSearchHelper(cont.node, true, cont.depth)
            push!(stack, cont)
            on_push_fcn(cont)

            if has_child(cont.node)

                depth = cont.depth + 1
                child = cont.node.left_child
                cont  = TreeSearchHelper(child, false, depth)
                push!(stack, cont)
                on_push_fcn(cont)

                while has_right_sibling(child)
                    child = child.right_sibling
                    cont  = TreeSearchHelper(child, false, depth)
                    push!(stack, cont)
                    on_push_fcn(cont)
                end
            end

        end # if
    end # while

end






function dfs(
    tree::MultiTree;
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
    tree::MultiTree;
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