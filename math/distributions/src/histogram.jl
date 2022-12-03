
function emp_cdf(rnb::Vector{T}) where {T}
    x = sort(rnb)
    x_eps = x .+ eps.(x)

    L = length(x)
    y1 = collect( 0:(L-1) ) ./ L
    y2 = collect( 1:L ) ./ L

    
    cdf_x = reshape( hcat( x, x_eps )', 2*L, 1)
    cdf_y = reshape( hcat( y1, y2 )', 2*L, 1)

    return (cdf_x, cdf_y)
end




function bin_size_scott(sigma, n)
    h = sigma * 3.49 / cbrt(n)
    return h
end


function histogram(rnb::Vector{T}, n_bin::Int) where {T}

    (x_min, x_max)             = extrema(rnb)
    bin_edges                  = collect( range(x_min, x_max, n_bin+1) )
    # (bin_edges, freq, bin_idx) = histogram(rnb, bin_edges)

    # return (bin_edges, freq, bin_idx)

    (bin_edges, freq) = histogram(rnb, bin_edges)

    return (bin_edges, freq)

end

function histogram(rnb::Vector{T}, bin_edges::Vector{T}) where {T}
    # it is assumed that the bin edges are sorted
    Lr      = length(rnb)
    Le      = length(bin_edges)
    freq    = zeros(Int, Le-1)
    # bin_idx = zeros(Int, Lr) # zero means that it is outside of the edges
    srnb    = sort(rnb)
    

    start_idx = 1 + SimpleSearches.binary_search( srnb, bin_edges[1] )
    end_idx   = SimpleSearches.binary_search( srnb, bin_edges[end] )
    end_idx   = min(Lr, end_idx)

    ee = 2
    for rr = start_idx:end_idx
        
        if srnb[rr] <= bin_edges[ee]
            # increase the frequency in the current bin
            freq[ee-1] += 1
            # bin_idx[rr] = ee-1
        else
            # move to the next bin
            ee += 1
            freq[ee-1] += 1
            if ee > Le
                break
            end
        end

    end

    # return (bin_edges, freq, bin_idx)
    return (bin_edges, freq)
end


function histogram_2d(rnb::Matrix{T}, n_bin_x::Int, n_bin_y::Int) where {T}

    (x_min, x_max)             = extrema(  view(rnb, 1, :)  )
    (y_min, y_max)             = extrema(  view(rnb, 2, :)  )

    x_bin_edges   = collect( range(x_min, x_max, n_bin_x + 1) )
    y_bin_edges   = collect( range(y_min, y_max, n_bin_y + 1) )

    (x_bin_edges, y_bin_edges, freq) = histogram_2d(rnb, x_bin_edges, y_bin_edges)

    return (x_bin_edges, y_bin_edges, freq)

end

function is_inside_box_2d(x, y, x_min, x_max, y_min, y_max)
    return x_min <= x <= x_max && y_min <= y <= y_max
end


function histogram_2d(rnb::Matrix{T}, x_bin_edges::Vector{T}, y_bin_edges::Vector{T}) where {T}
    # it is assumed that the bin edges are sorted
    (n_dim, Lr)      = size(rnb)

    Lxe      = length(x_bin_edges)
    Lye      = length(y_bin_edges)

    freq    = zeros(Int, Lxe-1, Lye-1)

    x_min = x_bin_edges[1]
    x_max = x_bin_edges[end]
    y_min = y_bin_edges[1]
    y_max = y_bin_edges[end]

    for rr = 1:Lr
        x = rnb[1, rr]
        y = rnb[2, rr]
        
        if is_inside_box_2d(x, y, x_min, x_max, y_min, y_max)
            x_left_idx = SimpleSearches.binary_search(x_bin_edges, x)
            y_left_idx = SimpleSearches.binary_search(y_bin_edges, y)

            freq[x_left_idx, y_left_idx] += 1

        end
    end

    return (x_bin_edges, y_bin_edges, freq)

end




#=
function histogram_2d_OLD(rnb::Matrix{T}, x_bin_edges::Vector{T}, y_bin_edges::Vector{T}) where {T}
    # it is assumed that the bin edges are sorted
    (n_dim, Lr)      = size(rnb)

    Lxe      = length(x_bin_edges)
    Lye      = length(y_bin_edges)

    freq    = zeros(Int, Lxe-1, Lye-1)
    # bin_idx = zeros(Int, Lr) # zero means that it is outside of the edges

    srnb  = copy(rnb)
    p = sortperm( view( rnb, 1, : )  ) # sort by x
    permute!(rnb, p)

    x_start_idx = 1 + util.binary_search( view(srnb, 1, : ), x_bin_edges[1] )
    x_end_idx   = util.binary_search( view(srnb, 1, : ), x_bin_edges[end] )
    x_end_idx   = min(Lr, x_end_idx)


    
    x_edge_idx = 2
    x_left_idx = x_start_idx
    while x_edge_idx <= Lxe

        x_right_idx = util.binary_search( view(srnb, 1, : ), x_bin_edges[x_edge_idx] )
        if x_right_idx > Lr
            break
        end
        # sort the sub array by y
        sort!( view(srnb, 2, x_left_idx:x_right_idx ) )

        # find the first y index which is inside the box
        y_start_idx = 1 + util.binary_search( view(srnb, 2, x_left_idx:x_right_idx), y_bin_edges[1] )
        y_start_idx += x_left_idx
        y_end_idx   = util.binary_search( view(srnb, 2, x_left_idx:x_right_idx), y_bin_edges[end] )
        y_end_idx   += x_left_idx
        y_end_idx   = min(Lr, y_end_idx)

        # loop over the sub array and put them into the right bin

        ee = 2
        for rr = y_start_idx:y_end_idx
            
            if srnb[rr] <= y_bin_edges[ee]
                # increase the frequency in the current bin
                freq[x_edge_idx, ee-1] += 1
                bin_idx[rr] = ee-1
            else
                # move to the next bin
                ee += 1
                freq[x_edge_idx, ee-1] += 1
                if ee > Lye
                    break
                end
            end

        end

    end
    

    

    # return (bin_edges, freq, bin_idx)
    return (x_bin_edges, y_bin_edges, freq)
end
=#

