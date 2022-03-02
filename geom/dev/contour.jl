

include("../../__lib__/std/util/src/util_module.jl")
include("../../__lib__/std/collections/gridded/src/gridded_module.jl")


module compgraph
using ..util


function contour_level(xs, ys, z, level)
    #   vertex    edges
	##  1-----2   .-1-.
    ##  |     |   |   |
    ##  |     |   4   2
    ##  |     |   |   |
    ##  4-----3   .-3-.

    Z = z .- level
    mask = Z .>= 0
    mark = mark_cells(mask)

    # show(stdout, MIME("text/plain"), mark)

    accum_array = zeros(2, 0)

    (n_row, n_col) = size(mark)

    

    # top search
    step_dir   = down::StepDirections
    first           = true
    start_edge      = 1
    rr              = 1
    for cc = 1:n_col
        id = mark[rr, cc]
        if id > 0 && (  id == 2 || id == 6 || id == 14 ||  id == 1 || id == 9 || id == 13 )
            (mark, accum_array) = __search_path!(xs, ys, Z, mark, accum_array, rr, cc, start_edge, first, step_dir, level)
        end
    end
    
    # bottom search
    step_dir   = up::StepDirections
    first           = true
    start_edge      = 3
    rr              = n_row
    for cc = 1:n_col
        id = mark[rr, cc]
        if id > 0 && ( id == 8 || id == 9 || id == 11 || id == 4 || id == 6 || id == 7)
            (mark, accum_array) = __search_path!(xs, ys, Z, mark, accum_array, rr, cc, start_edge, first, step_dir, level)
        end
    end


    # left search
    step_dir   = right::StepDirections
    first           = true
    start_edge      = 4
    cc              = 1
    for rr = 1:n_row
        id = mark[rr, cc]
        if id > 0 && ( id == 1 || id == 3 || id == 7 || id == 8 || id == 12 || id == 14)
            (mark, accum_array) = __search_path!(xs, ys, Z, mark, accum_array, rr, cc, start_edge, first, step_dir, level)
        end
    end

    # right search
    step_dir   = left::StepDirections
    first           = true
    start_edge      = 2
    cc              = n_col
    for rr = 1:n_row
        id = mark[rr, cc]
        if id > 0 &&  (id == 4 || id == 12 || id == 13 || id == 2 || id == 3 || id == 11)
            (mark, accum_array) = __search_path!(xs, ys, Z, mark, accum_array, rr, cc, start_edge, first, step_dir, level)
        end
    end




    # interior search
    step_dir = none::StepDirections
    first = true
    start_edge = 1
    for cc = 1:n_col-1
        for rr = 1:n_row-1
            id = mark[rr, cc]
            if id > 0
                (mark, accum_array) = __search_path!(xs, ys, Z, mark, accum_array, rr, cc, start_edge, first, step_dir, level)
            end
        end
    end
    


    return (accum_array, mark)
end


@enum StepDirections begin
    none
    up
    right
    down
    left
end

function __search_path!(xs, ys, Z, mark, accum_array, r, c, init_start_edge, first, step_dir::StepDirections, level)

    (n_row, n_col) = size(mark)
    start_idx = size(accum_array, 2) + 1
    
    # step_dir = none::StepDirections
    prev_step_dir = none::StepDirections # overrite for now

    stop_edge = Int8(127)
    while r >= 1 && c >= 1 && r <= n_row && c <= n_col && mark[r, c] > 0

        px = ( xs[c], xs[c+1], xs[c+1], xs[c] )
        py = ( ys[r], ys[r],   ys[r+1], ys[r+1] )
        pz = ( Z[r, c], Z[r, c+1], Z[r+1, c+1], Z[r+1, c] )


        # find start edge
        (start_edge, stop_edge) = find_start_and_stop_edge(mark, r, c)
        # if first 
        #     start_edge = init_start_edge
        # end


        #   vertex    edges
        ##  1-----2   .-1-.
        ##  |     |   |   |
        ##  |     |   4   2
        ##  |     |   |   |
        ##  4-----3   .-3-.


        # switch the start and stop edges
        if step_dir == none::StepDirections
            # do nothing
        elseif step_dir == up::StepDirections
            if start_edge != 3
                start_edge, stop_edge = stop_edge, start_edge
            end
        elseif step_dir == down::StepDirections
            if start_edge != 1
                start_edge, stop_edge = stop_edge, start_edge
            end
        elseif step_dir == left::StepDirections
            if start_edge != 2
                start_edge, stop_edge = stop_edge, start_edge
            end
        elseif step_dir == right::StepDirections
            if start_edge != 4
                start_edge, stop_edge = stop_edge, start_edge
            end
        end

        if start_edge == 127
            # unsuccessful search, break up
            break
        end

        if first

            pt = (start_edge, util.modulo_index(start_edge+1,4))
            (ct_x, ct_y) = lerp_interp(px, py, pz, pt)

            accum_array = add_point!(accum_array, level, 0)
            accum_array = add_point!(accum_array, ct_x, ct_y)
            first = false
        end

        pt = (stop_edge, util.modulo_index(stop_edge+1,4))
        (ct_x, ct_y) = lerp_interp(px, py, pz, pt)
        accum_array = add_point!(accum_array, ct_x, ct_y)


        mark[r, c] -= mark[r, c]
        
        prev_step_dir = step_dir
        if (stop_edge == 1)
            r -= 1;
            step_dir = up::StepDirections;
        elseif (stop_edge == 2)
            c += 1;
            step_dir = right::StepDirections;
        elseif (stop_edge == 3)
            r += 1;
            step_dir = down::StepDirections;
        elseif (stop_edge == 4)
            c -= 1;
            step_dir = left::StepDirections;
        end
        


    end # while


    end_idx = size(accum_array, 2)
    if start_idx >= 1
        accum_array[2,start_idx] = end_idx - start_idx
    end

    return (mark, accum_array)
end


function add_point!(accum_array, x, y)
    accum_array = hcat(accum_array, [x, y])
    return accum_array
end


function mark_cells(mask)
    (n_row, n_col) = size(mask)

    mark = zeros(Int8, n_row-1, n_col-1)

    for jj = 1:n_col-1
        for ii = 1:n_row-1
        
            f1 = mask[ii, jj]
            f2 = mask[ii, jj+1]
            f3 = mask[ii+1, jj+1]
            f4 = mask[ii+1, jj]
            
            mark[ii, jj] = f1 + f2 * 2 + f3 * 4 + f4 * 8
        
        end
    end

    mark[ mark .>= 15] .= 0

    return mark

end


function lerp_interp(px, py, pz, pt)

    tmp = pz[pt[2]] / pz[pt[1]];
    tmp = abs(tmp);

    if !isnan(tmp)
        lamda = 1 / (1 + tmp)
        ct_x = px[pt[1]] * (1-lamda) + px[pt[2]] * lamda
        ct_y = py[pt[1]] * (1-lamda) + py[pt[2]] * lamda
    else
        lamda = 0.5;
        ct_x = px[pt[1]] * (1-lamda) + px[pt[2]] * lamda
        ct_y = py[pt[1]] * (1-lamda) + py[pt[2]] * lamda
    end

    return (ct_x, ct_y)
end




function find_start_and_stop_edge(mark, r, c)
    id = mark[r, c]

    start_edge = Int8(127)
    stop_edge = Int8(127)

    if id == 0 || id == 15
        # impossible condition
        return (start_edge, stop_edge)
    end

    if id == 1 || id == 3 || id == 7
        start_edge = 4
    elseif id == 2 || id == 6 || id == 14
        start_edge = 1
    elseif id == 4 || id == 12 || id == 13
        start_edge = 2
    elseif id == 8 || id == 9 || id == 11
        start_edge = 3
    end

    if id == 1 || id == 9 || id == 13
        stop_edge = 1
    elseif id == 2 || id == 3 || id == 11
        stop_edge = 2
    elseif id == 4 || id == 6 || id == 7
        stop_edge = 3
    elseif id == 8 || id == 12 || id == 14
        stop_edge = 4
    end

    if id == 5 || id == 10
        start_edge = -1
        stop_edge = -1
    end

    start_edge = Int8(start_edge)
    stop_edge = Int8(stop_edge)

    return (start_edge, stop_edge)

end



end


module ctest
using ..util
using ..compgraph
using ..gridded
using PyPlot
PyPlot.pygui(true)

Nx = 10 # 10;
Ny = 8 # 8;

x_min = -1.0;
x_max = 2.0;

y_min = -2.0;
y_max = 3.0;


xs = collect( range(x_min, x_max, Nx) );
ys = collect( range(y_min, y_max, Ny) );

(xm, ym) = util.mesh_grid(xs, ys);

xm = xm'
ym = ym'
# zm = xm .+ ym;

# zm = xm.^2 .+ ym.^2

gmap = gridded.peaks()
zm = gmap.z'
xm = gmap.x
ym = gmap.y

xs = xm
ys = ym



level = 1.5;


# show(stdout, MIME("text/plain"), zm)
# println("")


(accum_array, mark) = compgraph.contour_level(xs, ys, zm, level)



PyPlot.figure()
PyPlot.grid()
PyPlot.contour(xm, ym, zm, [level], linewidths = 5, colors = :red)

PyPlot.plot( accum_array[1,2:end], accum_array[2,2:end], marker = :., markersize = 10 )



end



