
function extrema(point_array::Vector{<: AbstractPoint}, is_less_x, is_less_y, large = [1e100 0 ; 0 1e100])
    # is_less_x(p1, p2) corresponds to the first dimension output, X

    L = length(point_array)
    if L == 1
        return (point_array[1], point_array[1], point_array[1], point_array[1])
    end

    PointType = eltype(point_array)


    # min_x = PointType(+Inf, 0)
    # max_x = PointType(-Inf, 0)
    # min_y = PointType(0, +Inf)
    # max_y = PointType(0, -Inf)

    # large = 1e300
    min_x = PointType(+large[1,1], +large[1,2])
    max_x = PointType(-large[1,1], -large[1,2])
    min_y = PointType(+large[2,1], +large[2,1])
    max_y = PointType(large[2,2], -large[2,2])

    is_odd = L % 2 == 1
    Lc = is_odd ? L-1 : L

    for kk = 1:2:Lc

        p1 = point_array[kk]
        p2 = point_array[kk+1]

        if is_less_x(p1, p2) # p1.x < p2.x
            if is_less_x(p1, min_x) # min_x.x > p1.x
                min_x = p1
            end
            if is_less_x(max_x, p2) # max_x.x < p2.x
                max_x = p2
            end
        else
            if is_less_x(p2, min_x) # min_x.x > p2.x
                min_x = p2
            end
            if is_less_x(max_x, p1) # max_x.x < p1.x
                max_x = p1
            end
        end

        if is_less_y(p1, p2) # p1.y < p2.y
            if is_less_y(p1, min_y) # min_y.y > p1.y
                min_y = p1
            end
            if is_less_y(max_y, p2) # max_y.y < p2.y
                max_y = p2
            end
        else
            if is_less_y(p2, min_y) # min_y.y > p2.y
                min_y = p2
            end
            if is_less_y(max_y, p1) # max_y.y < p1.y
                max_y = p1
            end
        end
    end
    if is_odd
        p1 = point_array[end]
        # check for the last element too
        if is_less_x(p1, min_x) # min_x.x > p1.x
            min_x = p1
        end
        if  is_less_x(max_x, p1) # max_x.x < p1.x
            max_x = p1
        end
        if is_less_y(p1, min_y) # min_y.y > p1.y
            min_y = p1
        end
        if is_less_y(max_y, p1) # max_y.y < p1.y
            max_y = p1
        end
    end
    return (min_x, max_x, min_y, max_y)
end

function extrema(point_array::Vector{<: AbstractPoint})
    L = length(point_array)
    if L == 1
        return (point_array[1], point_array[1], point_array[1], point_array[1])
    end

    PointType = eltype(point_array)
    min_x = PointType(+Inf, 0)
    max_x = PointType(-Inf, 0)
    min_y = PointType(0, +Inf)
    max_y = PointType(0, -Inf)

    is_odd = L % 2 == 1
    Lc = is_odd ? L-1 : L

    for kk = 1:2:Lc

        p1 = point_array[kk]
        p2 = point_array[kk+1]

        if p1.x < p2.x
            if min_x.x > p1.x
                min_x = p1
            end
            if max_x.x < p2.x
                max_x = p2
            end
        else
            if min_x.x > p2.x
                min_x = p2
            end
            if max_x.x < p1.x
                max_x = p1
            end
        end

        if p1.y < p2.y
            if min_y.y > p1.y
                min_y = p1
            end
            if max_y.y < p2.y
                max_y = p2
            end
        else
            if min_y.y > p2.y
                min_y = p2
            end
            if max_y.y < p1.y
                max_y = p1
            end
        end
    end
    if is_odd
        p1 = point_array[end]
        # check for the last element too
        if min_x.x > p1.x
            min_x = p1
        end
        if max_x.x < p1.x
            max_x = p1
        end
        if min_y.y > p1.y
            min_y = p1
        end
        if max_y.y < p1.y
            max_y = p1
        end
    end
    return (min_x, max_x, min_y, max_y)
end

function skew_extrema(point_array::Vector{<: AbstractPoint})
    geom.extrema( point_array,
                  (p1, p2) -> (p1.x + p1.y) < (p2.x + p2.y),
                  (p1, p2) -> (p1.y - p2.y) < (p1.x - p2.x) )
end

function extrema_y(point_array::Vector{<: AbstractPoint})
    L = length(point_array)
    if L == 1
        return (point_array[1], point_array[1], 1, 1)
    end

    PointType = eltype(point_array)
    min_y = PointType(0, +Inf)
    max_y = PointType(0, -Inf)
    idx_min = 0
    idx_max = 0

    is_odd = L % 2 == 1
    Lc = is_odd ? L-1 : L

    for kk = 1:2:Lc

        p1 = point_array[kk]
        p2 = point_array[kk+1]

        if p1.y < p2.y
            if min_y.y > p1.y
                min_y = p1
                idx_min = kk
            end
            if max_y.y < p2.y
                max_y = p2
                idx_max = kk+1
            end
        else
            if min_y.y > p2.y
                min_y = p2
                idx_min = kk+1
            end
            if max_y.y < p1.y
                max_y = p1
                idx_max = kk
            end
        end
    end
    if is_odd
        p1 = point_array[end]
        # check for the last element too
        if min_y.y > p1.y
            min_y = p1
            idx_min = L
        end
        if max_y.y < p1.y
            max_y = p1
            idx_max = L
        end
    end
    return (min_y, max_y, idx_min, idx_max)
end

function extrema_x(point_array::Vector{<: AbstractPoint})
    L = length(point_array)
    if L == 1
        return (point_array[1], point_array[1], 1, 1)
    end

    PointType = eltype(point_array)
    min_x = PointType(+Inf, 0)
    max_x = PointType(-Inf, 0)

    is_odd = L % 2 == 1
    Lc = is_odd ? L-1 : L

    for kk = 1:2:Lc

        p1 = point_array[kk]
        p2 = point_array[kk+1]

        if p1.x < p2.x
            if min_x.x > p1.x
                min_x = p1
                idx_min = kk
            end
            if max_x.x < p2.x
                max_x = p2
                idx_max = kk
            end
        else
            if min_x.x > p2.x
                min_x = p2
                idx_min = kk
            end
            if max_x.x < p1.x
                max_x = p1
                idx_max = kk
            end
        end
    end
    if is_odd
        p1 = point_array[end]
        # check for the last element too
        if min_x.x > p1.x
            min_x = p1
            idx_min = L
        end
        if max_x.x < p1.x
            max_x = p1
            idx_max = L
        end
    end
    return (min_x, max_x, idx_min, idx_max)
end
