

include("../src/datastructs_module.jl")




module ttest
using ..datastructs

# still doesnt work correctly
#
# probably the rotations are wrong


rbtree  = datastructs.RedBlackTree(1)
n1      = datastructs.RedBlackTreeNode(2)
n2      = datastructs.RedBlackTreeNode(5)
n3      = datastructs.RedBlackTreeNode(7)
n4      = datastructs.RedBlackTreeNode(8)
n5      = datastructs.RedBlackTreeNode(11)
n6      = datastructs.RedBlackTreeNode(14)
n7      = datastructs.RedBlackTreeNode(15)
n8      = datastructs.RedBlackTreeNode(4)



insert!(rbtree, n6)
insert!(rbtree, n7)


insert!(rbtree, n1)
insert!(rbtree, n2)
insert!(rbtree, n3)
insert!(rbtree, n4)
insert!(rbtree, n5)


insert!(rbtree, n8)
datastructs.tree_view(rbtree)


# datastructs.tree_view(rbtree)

end










#=
module binary_tree_test
using ..datastructs



btree = datastructs.BinaryTree{Int}(10)
level1_left  = datastructs.BinaryTreeNode(5)
level1_right = datastructs.BinaryTreeNode(15)

level12_left  = datastructs.BinaryTreeNode(3)
level12_right = datastructs.BinaryTreeNode(7)

level22_left  = datastructs.BinaryTreeNode(12)
level22_right = datastructs.BinaryTreeNode(20)

level312_left  = datastructs.BinaryTreeNode(4)
level312_right = datastructs.BinaryTreeNode(2)

insert!(btree, level1_left)
insert!(btree, level1_right)

insert!(btree, level12_left)
insert!(btree, level12_right)

insert!(btree, level22_left)
insert!(btree, level22_right)

insert!(btree, level312_left)
insert!(btree, level312_right)

datastructs.tree_view(btree)


datastructs.successor(ttest.btree.node.left.right).data


end
=#