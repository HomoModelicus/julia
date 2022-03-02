


# dependencies:
# - none



module util


function matlab_display(obj)
    class_name = string( typeof(obj) )
    props = propertynames(obj)
    sp = map(string, props)
    L = map(length, sp)
    Lmax = Base.maximum(L)

    props_vec = Vector{String}(undef, length(sp))
    for kk = 1:length(sp)
        props_vec[kk] = "\t" * lpad(sp[kk], Lmax) * ": " * string( getproperty(obj, props[kk]) ) * "\n"
    end

    str = class_name * " with properties:\n"
    str_end = reduce(*, props_vec)
    return str * str_end * "\n"
end



function swap!(array::AbstractArray, i1::Int, i2::Int)
    tmp = array[i1];
    array[i1] = array[i2];
    array[i2] = tmp;
    return array
end

function mid_point(a::T, b::T)::T where {T}
    return (b - a) / 2 + a
end

function mid_point(a::T, b::T)::T where {T<:Integer}
    return floor( (b - a) / 2 + a )
end

function swappop!(array::AbstractArray, idx::Int)
	tmp = array[end]
	array[end] = array[idx]
	array[idx] = tmp
	return pop!(array)
end



function modulo_index(n, L)
	if n <= 0
		n = n % L
		n = L + n
		#  # L in domain 0.. -L+1
	end

	return  (n-1) % L + 1
end

function next_index(index, L)
    # ring indexing
    if index >= L
        index = one(typeof(index))
    else
        index = index + one(typeof(index))
    end
    return index
end

function prev_index(index, L)
    # ring indexing
    if index <= 1
        index = L
    else
        index = index - one(typeof(index))
    end
    return index
end


function is_vector(A)
    return length(size(A)) == 1
end

function is_matrix(A)
    return length(size(A)) == 2
end

function maximum(a::AbstractArray{T}) where {T}
    n = length(a)
    if n < 1
        return (nothing, zero(Int64))
    end

    max_elem = a[1]
    max_idx = one(Int64)

    @inbounds @simd for kk = 2:n
        @inbounds a_ = a[kk]
        if isless(max_elem, a_)
            max_elem = a_
            max_idx = kk
        end 
    end

    return (max_elem, max_idx)
end

function maximum(f, a::AbstractArray{T}) where {T}
    n = length(a)
    if n < 1
        return (nothing, zero(Int64))
    end

    max_elem = f(a[1])
    max_idx = one(Int64)

    @inbounds @simd for kk = 2:n
        @inbounds fa = f(a[kk])
        if isless( max_elem, fa )
            max_elem = fa
            max_idx = kk
        end
    end

    return (max_elem, max_idx)
end


function linspace(x_start, x_end, x_length::Int)
    if x_length <= 1
        return [x_end]
    end
    x_delta = (x_end - x_start) / (x_length - 1)
    x_ = collect( x_start:x_delta:x_end )
    return x_
end


function logspace(a, b, n::Int = 50)
	retval = 10 .^ collect( LinRange(a, b, n) )
end

function mesh_grid(x, y)
    X = [i for i in x, j in 1:length(y)]
    Y = [j for i in 1:length(x), j in y]
    return (X, Y)
end




function linear_search(
    x::Vector{T}, 
    xq::T; 
    left_init_index = 1) where {T}

    # it is assumed that the x is sorted in increasing order
    idx = 0 # if zero -> no valid index found

    L = length(x)

    # handle extrapolation
    if xq <= x[1]
        return 0
    elseif xq >= x[L]
        return L+1
    end

    # handle interpolation
    ii = left_init_index
    while ii <= L
        if xq <= x[ii]
            idx = ii-1
            break
        end
        ii += 1
    end

    return idx

end




function binary_search(
    x, 
    xq; 
    left_init_index = 1, 
    right_init_index = length(x))

    # it is assumed that the x is sorted in increasing order
    idx = 0 # if zero -> no valid index found
    # if -1     left extrapolated
    # if L+1    right extrapolated

    L = length(x)

    # handle extrapolation
    if xq < x[1]
        return 0
    elseif xq > x[L]
        return L+1
    end


    left_idx  = left_init_index
    right_idx = right_init_index
    mid_idx   = div(right_idx + left_idx, 2)

    while true

        if xq <= x[mid_idx]
            right_idx = mid_idx
        else # xq > curve.x[mid_idx]
            left_idx = mid_idx
        end

        mid_idx = div(right_idx + left_idx, 2)
        if mid_idx == left_idx
            break
        end
    end
    idx = left_idx

    return idx

end


end