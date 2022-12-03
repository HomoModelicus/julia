


module SimpleSearches


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


