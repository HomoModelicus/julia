

module LinkedLists


# ============================================================================ #
# Linked List
# ============================================================================ #

# Linked List Node
mutable struct LinkedListNode{T}
    prev::LinkedListNode
    next::LinkedListNode
    data::T

    function LinkedListNode{T}(content::T) where {T}
        obj = new()
        obj.prev = obj
        obj.next = obj
        obj.data = content
        return obj
    end

    function LinkedListNode{T}() where {T}
        obj = new()
        obj.prev = obj
        obj.next = obj
        return obj
    end

    function LinkedListNode(content::T) where {T}
        return LinkedListNode{T}(content::T)
    end

    function LinkedListNode()
        return LinkedListNode(undef)
    end
end

function make_node(list)
	return LinkedListNode{eltype(list)}()
end



function Base.eltype( ::Type{ <: LinkedListNode{T}} ) where {T}
    return T
end

function Base.isempty(node::LinkedListNode)
    return node.data == undef
end



function Base.show(io::IO, elem::LinkedListNode{T}) where {T}
    println("LinkedListNode{$(T)} with properties:")
    println("\t prev:\t$(elem.prev)")
    println("\t next:\t$(elem.next)")
    print("\t data:\t")
    show(elem.data)
    print("\n\n")
end



# Linked List
mutable struct LinkedList{T}
    count::Int64
    node::LinkedListNode{T}

    function LinkedList{T}(content::T) where {T}
        count = 1
        node = LinkedListNode{T}(content)
        return new(count, node)
    end
    function LinkedList{T}() where {T}
        count = 1
        node = LinkedListNode{T}()
        return new(count, node)
    end
end

function LinkedList(content::T) where {T}
    return LinkedList{T}(content::T)
end

function Base.eltype( ::Type{ <: LinkedList{T} } ) where {T}
    return T
end 
function Base.length(linked_list::LinkedList)
    return linked_list.count
end

function Base.size(linked_list::LinkedList)
    return (linked_list.count,)
end

function Base.show(io::IO, list::LinkedList{T}) where {T}
    println("LinkedList{$(T)} with properties:")
    println("\t count:\t$(list.count)")
end


function Base.push!(linked_list::LinkedList, new_node::LinkedListNode)
    last_node               = linked_list.node.prev
    last_node.next          = new_node
    new_node.prev           = last_node
    linked_list.node.prev   = new_node
    new_node.next           = linked_list.node
    linked_list.count       += 1

    return linked_list
end


function Base.pop!(linked_list::LinkedList)::LinkedListNode
    node = linked_list.node.prev
    remove_element!(linked_list, linked_list.node.prev)
    return node
end

function remove_element!(linked_list::LinkedList, node::LinkedListNode)::LinkedList
    prev_node = node.prev
    next_node = node.next
    prev_node.next = next_node
    next_node.prev = prev_node
    node.prev = node
    node.next = node
    linked_list.count -= 1
    return linked_list
end

function remove_between!(list::LinkedList, t1::LinkedListNode, t2::LinkedListNode)::LinkedList
	# but not the ends
	next_node = t1.next;
	while next_node != t2
		nn = next_node.next
		remove_element!(list, next_node)
		next_node = nn
	end
	return list
end


function insert_after!(
    linked_list::LinkedList,
    old_node::LinkedListNode,
    new_node::LinkedListNode)::LinkedList
	# new node comes to the right of old node
    insert_before!(linked_list, old_node.next, new_node)
 end

function insert_before!(
    linked_list::LinkedList,
    old_node::LinkedListNode,
    new_node::LinkedListNode)::LinkedList

    prev_node = old_node.prev;
    next_node = old_node;

    prev_node.next = new_node;
    new_node.prev  = prev_node;

    next_node.prev = new_node;
    new_node.next  = next_node;
	linked_list.count += 1

    return linked_list
end

function append!(linked_list::LinkedList, new_node::LinkedListNode)
    push!(linked_list::LinkedList, new_node::LinkedListNode)
end

function prepend!(linked_list::LinkedList, new_node::LinkedListNode)
    insert_before!(linked_list, linked_list.node.next, new_node)
    return linked_list
end

function Base.iterate(linked_list::LinkedList, state = (1, linked_list.node) )
    state[1] > linked_list.count ? nothing : (state[2], (state[1]+1, state[2].next) )
end








function linked_list_to_array(list::LinkedList)

	array = Vector{eltype(list)}(undef, list.count)
	node = list.node
	for kk = 1:list.count
		next_node = node.next
		array[kk] = node.data
		node = next_node
	end
	return array
end

function array_to_linked_list(array::Vector{T}) where {T}
	L = length(array)
	list = LinkedList{eltype(array)}()
	list.node.data = array[1]
	for kk = 2:L
		node = new_node(list)
		node.data = array[kk]
		append!(list, node)
	end
	return list
end



end # module


