function reduce_array_for_convex_hull!(point_array::Vector{<:AbstractPoint})::Vector{<:AbstractPoint}
    if length(point_array) <= 8
        return point_array
    end

    (min_x, max_x, min_y, max_y) = extrema(point_array)
    (skew_min_x, skew_max_x, skew_min_y, skew_max_y) = skew_extrema(point_array)

    approx_hull_array = [
        min_x,
        skew_min_x,
        min_y,
        skew_min_y,
        max_x,
        skew_max_x,
        max_y,
        skew_max_y]

    # approx_hull_array = [
    #     min_x,
    #     min_y,
    #     max_x,
    #     max_y]

    u_approx_hull_array = unique(p->p.x, approx_hull_array)
    uu_approx_hull_array = unique(p->p.y, u_approx_hull_array)
    approx_hull = naive_graham_scan!(uu_approx_hull_array)

    N_triangles = length(approx_hull)-2
    triangles = Vector{Triangle{Point{Float64}}}(undef, N_triangles)
    for kk = 1:N_triangles
        triangles[kk] = Triangle(approx_hull[1], approx_hull[kk+1], approx_hull[kk+2])
    end


    # bool = falses( length(point_array) )
    # for kk = 1:N_triangles
    #     bool_tmp = is_in_triangle.([triangles[kk]], point_array)
    #     bool = bool .| bool_tmp
    # end

    # reduced_array = [
    #     approx_hull_array...,
    #     point_array[.!bool]...
    #     ]

    for kk = 1:N_triangles
        bool_tmp = is_in_triangle.([triangles[kk]], point_array)
        point_array = point_array[.!bool_tmp]
    end

    uu_reduced_array = [
        approx_hull...,
        point_array...
        ]

    # u_reduced_array = unique(p->p.x, reduced_array)
    # uu_reduced_array = unique(p->p.y, u_reduced_array)
    return uu_reduced_array
end

function graham_scan!(point_array::Vector{<:AbstractPoint})
    reduced_array = reduce_array_for_convex_hull!(point_array)
    return naive_graham_scan!(reduced_array)
end

function naive_graham_scan!(point_array::Vector{<:AbstractPoint})
    # opti possibility: dont calculate the angle, but only the ordering is relevant
    L = length(point_array)
    if L <= 3
        return point_array
    end

    y_ = y(point_array);
    (miny, idx) = findmin(y_)
    point_array[idx], point_array[end] = point_array[end], point_array[idx]
    p0 = point_array[end]

    phi = Vector{Float64}(undef, L)
    for kk = 1:(L-1)
        # v = point_array[kk] - p0
        # phi[kk] = atan(v[2], v[1])
        phi[kk] = atan(point_array[kk].y - p0.y, point_array[kk].x - p0.x)
    end
    phi[end] = 1e308 # missing # missing is greater than anything else
    iU2S = sortperm(phi)
    point_array = point_array[iU2S]

    ElementType = eltype(point_array)
    stack = datastructs.Stack{ElementType}(L)

    push!(stack, p0)
    push!(stack, point_array[1])
    push!(stack, point_array[2])

    for kk = 3:(L-1)
        while nonleft_turn(
                datastructs.peek(stack, 1),
                datastructs.peek(stack, 0),
                point_array[kk] )
            pop!(stack)
        end
        push!(stack, point_array[kk])
    end
    ch = stack.data[1:stack.ptr]
    return ch
end

function nonleft_turn(p1::T, p2::T, p3::T)::Bool where {T<:AbstractPoint}
    # a = p2 - p1
    # b = p3 - p2
    # return cross2(a, b) <= 0

    a_x = p2.x - p1.x
    a_y = p2.y - p1.y

    b_x = p3.x - p2.x
    b_y = p3.y - p2.y
    return cross2(a_x, a_y, b_x, b_y) <= 0
end


function jarvis3!(point_array::Vector{<:AbstractPoint})
	L = length(point_array)
    if L <= 3
        return point_array
    end

    reduced_array = reduce_array_for_convex_hull!(point_array)
    L = length(reduced_array)
    (min_y, max_y, idx_min, idx_max) = extrema_y(reduced_array)

	stack = datastructs.Stack{Point{Float64}}(L)
	push!(stack, min_y)

	# util.swappop!(reduced_array, idx_min)
	util.swap!(reduced_array, idx_min, L)
	L = L - 1

    phi = Vector{Float64}(undef, L)
	ref_point = peek(stack, 0)

	a_x = zero(Float64)
	a_y = zero(Float64)
	b_x = zero(Float64)
	b_y = zero(Float64)

	for kk = 1:L
		# a_x = 1
		# a_y = 0
		b_x = reduced_array[kk].x - ref_point.x
		b_y = reduced_array[kk].y - ref_point.y
		sin_ = cross2(1.0, 0.0, b_x, b_y)
		cos_ = dot2(1.0, 0.0, b_x, b_y)
		phi[kk] = cos_ / sin_ # cotangent, the angle is irrelevant, only the ordering is important
		# phi[kk] = atan(reduced_array[kk].y - ref_point.y, reduced_array[kk].x - ref_point.x)
	end
	(minphi, idx) = findmax(phi) # for cotangent the min angle is the max value

	push!(stack, reduced_array[idx])
	util.swappop!(reduced_array, idx)
	# pop!(phi) # must be popped, in order to not search in the last not used element in findmin
	# L = L - 1
	first = true
	while true
		prev_point = peek(stack, 1)
		ref_point = peek(stack, 0)
		for kk = 1:L
			a_x = ref_point.x - prev_point.x
			a_y = ref_point.y - prev_point.y
			b_x = reduced_array[kk].x - ref_point.x
			b_y = reduced_array[kk].y - ref_point.y
			sin_ = cross2(a_x, a_y, b_x, b_y)
			cos_ = dot2(a_x, a_y, b_x, b_y)
			phi[kk] = cos_ / sin_ # cotangent, the angle is irrelevant, only the ordering is important
			# phi[kk] =  sin_ / cos_
			# phi[kk] = atan(reduced_array[kk].y - ref_point.y, reduced_array[kk].x - ref_point.x)
		end
		if first
			phi[isnan.(phi)] .= -Inf
			first = false
		end
		phi_view = view(phi, 1:L)
		(minphi, idx) = findmax(phi_view) # for cotangent the min angle is the max value
		if min_y == reduced_array[idx]
			break
		end
		push!(stack, reduced_array[idx])
		util.swap!(reduced_array, idx, L)
		# util.swappop!(reduced_array, idx)
		# pop!(phi) # must be popped, in order to not search in the last not used element in findmin
		L = L - 1
	end

	ch = [stack.data[1:stack.ptr]...]
	return ch

end

function jarvis2!(point_array::Vector{<:AbstractPoint})
	L = length(point_array)
    if L <= 3
        return point_array
    end

    reduced_array = reduce_array_for_convex_hull!(point_array)
    L = length(reduced_array)
    (min_y, max_y, idx_min, idx_max) = extrema_y(reduced_array)

	stack = datastructs.Stack{Point{Float64}}(div(L,2)+1)
	push!(stack, min_y)

	# util.swappop!(reduced_array, idx_min)
	util.swap!(reduced_array, idx_min, L)
	L = L - 1

    phi = Vector{Float64}(undef, L)
	ref_point = peek(stack, 0)

	a_x = zero(Float64)
	a_y = zero(Float64)
	b_x = zero(Float64)
	b_y = zero(Float64)

	for kk = 1:L
		# a_x = 1
		# a_y = 0
		b_x = reduced_array[kk].x - ref_point.x
		b_y = reduced_array[kk].y - ref_point.y
		sin_ = cross2(1.0, 0.0, b_x, b_y)
		cos_ = dot2(1.0, 0.0, b_x, b_y)
		phi[kk] = cos_ / sin_ # cotangent, the angle is irrelevant, only the ordering is important
		# phi[kk] = atan(reduced_array[kk].y - ref_point.y, reduced_array[kk].x - ref_point.x)
	end
	(minphi, idx) = findmax(phi) # for cotangent the min angle is the max value

	push!(stack, reduced_array[idx])
	util.swappop!(reduced_array, idx)
	# pop!(phi) # must be popped, in order to not search in the last not used element in findmin
	# L = L - 1
	first = true
	while true
		prev_point = peek(stack, 1)
		ref_point = peek(stack, 0)
		for kk = 1:L
			a_x = ref_point.x - prev_point.x
			a_y = ref_point.y - prev_point.y
			b_x = reduced_array[kk].x - ref_point.x
			b_y = reduced_array[kk].y - ref_point.y
			sin_ = cross2(a_x, a_y, b_x, b_y)
			cos_ = dot2(a_x, a_y, b_x, b_y)
			phi[kk] = cos_ / sin_ # cotangent, the angle is irrelevant, only the ordering is important
			# phi[kk] =  sin_ / cos_
			# phi[kk] = atan(reduced_array[kk].y - ref_point.y, reduced_array[kk].x - ref_point.x)
		end
		if first
			phi[isnan.(phi)] .= -Inf
			first = false
		end
		(minphi, idx) = findmax(phi) # for cotangent the min angle is the max value
		if min_y == reduced_array[idx]
			break
		end
		push!(stack, reduced_array[idx])
		util.swappop!(reduced_array, idx)
		pop!(phi) # must be popped, in order to not search in the last not used element in findmin
		L = L - 1
	end

	ch = [stack.data[1:stack.ptr]...]
	return ch

end


function jarvis_march!(point_array::Vector{<:AbstractPoint})

    L = length(point_array)
    if L <= 3
        return point_array
    end

    reduced_array = reduce_array_for_convex_hull!(point_array)
    L = length(reduced_array)
    (min_y, max_y, idx_min, idx_max) = extrema_y(reduced_array)
    # p_1 = reduced_array[1]
    # p_L = reduced_array[end]
    # reduced_array[1], reduced_array[idx_min] = reduced_array[idx_min], p_1
    # reduced_array[end], reduced_array[idx_max] = reduced_array[idx_max], p_L
    # at the index 1 is the point with min y coord, at L with max y


    stack_left = datastructs.Stack{Point{Float64}}(div(L,2)+1)
    stack_right = datastructs.Stack{Point{Float64}}(div(L,2)+1)

    push!(stack_right, min_y)
    push!(stack_left, max_y)

	# pop the min element, the angles shall not be computed for this point
	util.swappop!(reduced_array, idx_min)
	L = L - 1

    phi = Vector{Float64}(undef, L)

	idx = 0 # new local declaration
    # right segment
    while true
		ref_point = peek(stack_right, 0)
        for kk = 1:L
            phi[kk] = atan(reduced_array[kk].y - ref_point.y, reduced_array[kk].x - ref_point.x)
        end

        (minphi, idx) = findmin(phi)
        if max_y == reduced_array[idx]
            break
        end
        push!(stack_right, reduced_array[idx])
		util.swappop!(reduced_array, idx)
		pop!(phi) # must be popped, in order to not search in the last not used element in findmin
		L = L - 1
    end

	# at idx it is known that tha max_y is there, but min_y is missing now in the array
	# put min_y at idx
	reduced_array[idx] = min_y
    # left segment
	while true
		ref_point = peek(stack_left, 0)
        for kk = 1:L
            phi[kk] = π + atan(reduced_array[kk].y - ref_point.y, reduced_array[kk].x - ref_point.x)
        end

        (minphi, idx) = findmin(phi)
        if min_y == reduced_array[idx]
            break
        end
        push!(stack_left, reduced_array[idx])
		util.swappop!(reduced_array, idx)
		pop!(phi) # must be popped, in order to not search in the last not used element in findmin
		L = L - 1
    end



	ch = [
	stack_right.data[1:stack_right.ptr]...
	stack_left.data[1:stack_left.ptr]...
	]
	return ch
end



# function quick_hull!(point_array::Vector{<:AbstractPoint})
#
# 	L = length(point_array)
# 	if L <= 3
# 		return point_array
# 	end
#
# 	reduced_array = reduce_array_for_convex_hull!(point_array)
# 	L = length(reduced_array)
# 	(min_y, max_y, idx_min, idx_max) = extrema_y(reduced_array)
#
#
#
# end

function incremental_hull!(point_array::Vector{<:AbstractPoint})


	L = length(point_array)
    if L <= 3
        return point_array
    end

    reduced_array = reduce_array_for_convex_hull!(point_array)

    L = length(reduced_array)
    (min_y, max_y, idx_min, idx_max) = extrema_y(reduced_array)

	aL = reduced_array[end]
	aLm1 = reduced_array[end-1]

	reduced_array[idx_min] = aL
	reduced_array[idx_max] = aLm1
	pop!(reduced_array)
	pop!(reduced_array)

	list = initial_hull!(reduced_array, max_y, min_y)
	L = length(reduced_array)-1 # p3 is in the array

	for kk = L:-1:1
		new_point = reduced_array[kk]
		bools = is_lefts(list, new_point)
		if all(bools)
			continue
		else
			(t1, t2) = tangent_points_to_hull(list, bools)
			datastructs.remove_between!(list, t1, t2)
			new_node = datastructs.new_node(list)
			new_node.data = new_point
			datastructs.insert_after!(list, t1, new_node)
		end
	end

	return datastructs.linked_list_to_array(list)
end

function tangent_points_to_hull(list, bools)
	node = list.node
	kk = 1
	L = length(list)
	if bools[1] == true
		while kk <= L && bools[kk] == true
			node = node.next
			kk += 1
		end
		t1 = node
		while kk <= L && bools[kk] == false
			node = node.next
			kk += 1
		end
		t2 = node
	else
		while kk <= L && bools[kk] == false
			node = node.next
			kk += 1
		end
		t2 = node
		while kk <= L && bools[kk] == true
			node = node.next
			kk += 1
		end
		t1 = node
	end
	return (t1, t2)
end

function initial_hull!(reduced_array, p1, p2)

	list = datastructs.LinkedList{Point{Float64}}()
	# n1 = datastructs.new_node(list)
	n2 = datastructs.new_node(list)
	n3 = datastructs.new_node(list)

	list.node.data = p1

	idx = length(reduced_array)
	while idx >= 1
		p3 = reduced_array[idx]
		if !is_on_line(p1, p2, p3)

			if is_left(p1, p2, p3)
				# n1.data = p1
				n2.data = p2
				n3.data = p3
			else
				# n1.data = p1
				n2.data = p3
				n3.data = p2
			end
			break
		end
		pop!(reduced_array)
		idx -= 1
	end

	datastructs.insert_after!(list, list.node, n2)
	datastructs.insert_after!(list, n2, n3)

	return list
end

function is_lefts(polygon_list::datastructs.LinkedList, new_point::AbstractPoint)

	bools = falses(polygon_list.count)
	node2 = polygon_list.node.next

	p1 = polygon_list.node.data
	p2 = node2.data

	for kk = 1:length(polygon_list)
		b = is_left_on(p1, p2, new_point)
		bools[kk] = b
		node2 = node2.next
		p1 = p2
		p2 = node2.data
	end

	return bools
end


#=
function incremental_hull!(point_array::Vector{<:AbstractPoint})


	L = length(point_array)
    if L <= 3
        return point_array
    end

    reduced_array = reduce_array_for_convex_hull!(point_array)

    L = length(reduced_array)
    (min_y, max_y, idx_min, idx_max) = extrema_y(reduced_array)

	list = datastructs.LinkedList{Point{Float64}}()
	list.node.data = min_y

	node = datastructs.new_node(list)
	node.data = max_y
	datastructs.insert_after!(list, list.node, node)


	aL = reduced_array[end]
	aLm1 = reduced_array[end-1]

	reduced_array[idx_min] = aL
	reduced_array[idx_max] = aLm1
	pop!(reduced_array)
	pop!(reduced_array)
	L = L - 2


	node = datastructs.new_node(list)

	# ensure that the 3. point is not on the line
	p1 = list.node.data
	p2 = list.node.next.data
	line_12 = Line(list.node.data, list.node.next.data)
	while true
		p = reduced_array[end]
		if is_on_line(line_12, p)
			pop!(reduced_array)
		else
			break
		end
	end
	node.data = reduced_array[end]
	pop!(reduced_array)
	datastructs.insert_after!(list, list.node.next, node)


	# enforce that the third point is om the left of 1 and 2
	p3 = list.node.next.next.data
	if is_left(line_12, p3)
		# fine, counter clockwise order
	else
		# swap 2 and 3
		p2 = list.node.next.data
		p3 = list.node.next.next.data
		list.node.next.data = p3
		list.node.next.next.data = p2
	end



	idx = length(reduced_array)
	while idx >= 1
		new_point = reduced_array[idx]
		bools = is_lefts(list, new_point)

		idx -= 1
		if all(bools)
			continue
		else
			(n1, n2) = find_transition_points(list, bools)
			new_node = datastructs.new_node(list)
			new_node.data = new_point
			if n1.data == n2.data
				datastructs.insert_after!(list, n2, new_node)
				continue
			end
			n2 = n2.next
			next_node = n1.next
			while next_node.data != n2.data
				nn = next_node.next
				datastructs.remove_element!(list, next_node)
				next_node = nn
			end
			datastructs.insert_after!(list, n1, new_node)
		end
	end

	return datastructs.linked_list_to_array(list)

end



function find_transition_points(list, bools)
	L = length(list)
	first_zero = 0
	last_zero = 0

	if bools[1] == false
		# backwards search for first zero
		kk = 1
		while bools[kk] == false
			kk = kk - 1
			if kk == 0
				kk = L
			end
		end
		first_zero = util.modulo_index(kk + 1, L)

		kk = 1
		while bools[kk] == false
			kk = kk + 1
		end
		last_zero = kk - 1

	else # bools[1] == true
		# forward search
		kk = 1
		while bools[kk] == true
			kk = kk + 1
		end
		first_zero = kk

		# kk = kk + 1
		while bools[kk] == false
			if kk == L
				kk = 0
			end
			kk = kk + 1
		end
		if kk == 1
			kk = L + 1
		end
		last_zero = util.modulo_index(kk - 1, L)
	end

	node = list.node
	kk = 1

	if first_zero > last_zero
		# search backwards

		### TO DO ###
		# what happens if first_zero == L
		kk = L
		while kk >= first_zero
			kk = kk - 1
			node = node.prev
		end
		n1 = node

		kk = 1
		node = list.node
		while kk < last_zero
			kk = kk + 1
			node = node.next
		end
		n2 = node
	else
		# search forward
		while kk < first_zero
			kk = kk + 1
			node = node.next
		end
		n1 = node
		while kk < last_zero
			kk = kk + 1
			node = node.next
		end
		n2 = node
	end

	return (n1, n2)
end


function is_lefts(polygon_list::datastructs.LinkedList, new_point::AbstractPoint)

	bools = falses(polygon_list.count)

	node2 = polygon_list.node.next

	p1 = polygon_list.node.data
	p2 = node2.data

	for kk = 1:length(polygon_list)
		b = is_left_on(p1, p2, new_point)
		bools[kk] = b
		node2 = node2.next
		p1 = p2
		p2 = node2.data
	end

	return bools
end


# function is_in_polygon_list(list::datastructs.LinkedList, new_point::AbstractPoint)
# 	#stupid linear algo
#
# 	bool = true
# 	p1 = list.node.data
# 	node2 = list.node.next
# 	p2 = node2.data
# 	line_12 = Line(p1, p2)
#
# 	while p2 != list.node
# 		if !is_left_on(line_12, new_point)
# 			bool = false
# 			break
# 		end
# 		p1 = p2
# 		node2 = node2.next
# 		p2 = node2.data
# 	end
#
# 	return bool
# end
=#
