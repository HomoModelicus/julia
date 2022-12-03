
include("../src/BinaryTrees.jl")

# #=
module ttest
using ..BinaryTrees
using ..TreeUtils
using BenchmarkTools


function create_tree(init_value = 0)

    tree = BinaryTree(init_value)

    node = tree.root

    child_1 = BinaryTreeNode(10)
    child_2 = BinaryTreeNode(20)
    child_3 = BinaryTreeNode(30)

    child_4 = BinaryTreeNode(40)
    child_5 = BinaryTreeNode(50)

    child_6 = BinaryTreeNode(60)
    child_7 = BinaryTreeNode(70)
    child_8 = BinaryTreeNode(80)

    child_9 = BinaryTreeNode(90)
    child_10 = BinaryTreeNode(100)

    child_11 = BinaryTreeNode(110)
    child_12 = BinaryTreeNode(120)





    # 0
    #   10
    #       40
    #       50
    #   20
    #       60
    #       70
    #          90
    #               110
    #               120
    #           100


    add_left_child!(tree, node, child_1)
    add_right_child!(tree, node, child_2)

    add_left_child!(tree, child_1, child_4)
    add_right_child!(tree, child_1, child_5)

    add_left_child!(tree, child_2, child_6)
    add_right_child!(tree, child_2, child_7)

    add_left_child!(tree, child_7, child_9)
    add_right_child!(tree, child_7, child_10)

    add_left_child!(tree, child_9, child_11)
    add_right_child!(tree, child_9, child_12)


    return tree
end

function repeat_tree(n_rep = 100)
    for ii = 1:n_rep
        r = round(Int, rand() * 100)
        tree = create_tree(r)
    end
end


tree = create_tree()

# b = @benchmark tree = create_tree()
# b = @benchmark tree = repeat_tree(100)


# println(" ================ ")
# inorder_tree_walk(tree, (node, depth) -> println(  "  "^depth * string(node.data) ) )

# println(" ================ ")
# preorder_tree_walk(tree, (node, depth) -> println(  "  "^depth * string(node.data) ) )

# println(" ================ ")
# postorder_tree_walk(tree, (node, depth) -> println(  "  "^depth * string(node.data) ) )



dfs(tree; on_push_fcn = TreeUtils.print_node_data)
# bfs(tree; on_push_fcn = Trees.print_node_data)


b = @benchmark dfs(tree; on_push_fcn = TreeUtils.print_node_data);



end # module

# =#