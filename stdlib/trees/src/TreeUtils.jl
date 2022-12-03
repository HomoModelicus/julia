
module TreeUtils

export  print_node_data,
        do_nothing


function print_node_data(cont) # BinaryTreeSearchHelper
    if cont.visited
        ws = "  "
        print( ws^cont.depth )
        print( cont.node.data )
        print('\n')
    end
end

function print_node_data(node, depth::Int)
    println(  "   "^depth * string(node.data) )
end

function do_nothing(cont)
    # do nothing
    return nothing
end




end # module