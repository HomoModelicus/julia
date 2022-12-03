


struct MeshGenerationOptions
    distance_fcn
	node_spacing_fcn
	initial_spacing::Float64
	bounding_box::Rectangle
	fixed_points
	max_iteration::Int

    delta_point_tolerance::Float64 	   # = 0.001;
	retriangulation_threshold::Float64 # = 0.1;
	F_scale::Float64 				   # = 1.2;
	time_step_size::Float64 		   # = 0.2;
	geometrical_tolerance::Float64 	   # = 0.001 * initial_spacing;
	gradient_step::Float64 			   # = sqrt(eps)*initial_spacing;
end
function MeshGenerationOptions(
    distance_fcn,
	node_spacing_fcn,
	initial_spacing,
	bounding_box,
	fixed_points;
	max_iteration             = 10,
    delta_point_tolerance 	  = 0.001,
	retriangulation_threshold = 0.1,
	F_scale 				  = 1.2,
	time_step_size 			  = 0.1,
	geometrical_tolerance 	  = 0.001 * initial_spacing,
	gradient_step 			  = 10*sqrt(eps(1.0))*initial_spacing
    )

    return MeshGenerationOptions(
        distance_fcn,
        node_spacing_fcn,
        initial_spacing,
        bounding_box,
        fixed_points,
        max_iteration,
        delta_point_tolerance,
        retriangulation_threshold,
        F_scale,
        time_step_size,
        geometrical_tolerance,
        gradient_step)

end

function create_mesh(options::MeshGenerationOptions; visualize = false)


    # 1. create initial rough grid
    (xs, ys) = create_initial_meshgrid_distribution(options)
    (xs, ys) = shift_even_rows!(xs, ys, options)

    # 2. filter points
    (xs, ys) = remove_points_outside_region!(xs, ys, options)
    (xs, ys) = keep_interior_points!(xs, ys, options)

    # create the point array
    point_array = create_point_array(xs, ys, options)
    n_points = size(point_array,1)

    if visualize
        PyPlot.figure()
        PyPlot.grid()
        PyPlot.plot(xs, ys,
            marker = :., linestyle = :none, markersize = 10)
    end
    
    # For first iteration
	point_array_old = Inf # .* ones(n_points, 2); 

    # out params
    triangle_index = Matrix{Int}(undef, 0, 3)
    delmesh = DelaunayMesh()

    bars = Matrix{Int}(undef, 0, 2)

    # main loop
    iter = 0
    for outer iter = 1:options.max_iteration
        println("At iter: $(iter)")

        
        # 3. retriangluation
        dp_mat = point_array .- point_array_old
        # dp_vec = map( x -> sum(x.^2), dp_mat )
        dp_vec = sum(dp_mat.^2; dims=2)
        max_dp = maximum(dp_vec)
        # println(max_dp)

        if iter == 1 || max_dp >= options.retriangulation_threshold * options.initial_spacing
            println("Retriangulation at iter $(iter)")
            # Save current positions
            point_array_old = copy(point_array)
            
            # create delaunay triangulation
            pointtyped_point_array = matrix_to_point_array(point_array)
            delmesh = build_delaunay_mesh!(pointtyped_point_array)
            triangle_index = triangle_indices(delmesh)

            # compute centroids
            p1 = point_array[triangle_index[:, 1], :];
			p2 = point_array[triangle_index[:, 2], :];
			p3 = point_array[triangle_index[:, 3], :];
			triangle_centroids = (p1 .+ p2 .+ p3) ./ 3;


            # Keep interior triangles
			dist_at_triange_centroids = vec(mapslices( options.distance_fcn, triangle_centroids; dims = 2))
			bool_interior_triangle    = dist_at_triange_centroids .< (-options.geometrical_tolerance);
			triangle_index 			  = triangle_index[bool_interior_triangle, :]; 

            if visualize
                px = point_array[:,1]
                py = point_array[:,2]
                PyPlot.figure()
                PyPlot.grid()

                PyPlot.plot( px, py,
                    marker = :., linestyle = :none, markersize = 10)

                for tt = 1:size(triangle_index,1)
                    t = triangle_index[tt,:]
                    tx = px[ [t[1], t[2], t[3], t[1]]]
                    ty = py[ [t[1], t[2], t[3], t[1]]]
                    PyPlot.plot(tx, ty)
                end
            end




            # 4. Describe each bar by a unique pair of nodes
			# Interior bars duplicated
			bars = [	triangle_index[:, [1, 2]];
						triangle_index[:, [1, 3]];
						triangle_index[:, [2, 3]]
					] 
			
			# Bars as node pairs
            sort!(bars; dims = 2)
			bars = unique(bars; dims = 2);

        end # if

        # 6. Move mesh points based on bar lengths bar_lengths and forces F_bar
		bar_vector 			= point_array[bars[:, 1], :] - point_array[bars[:, 2], :]; 
		# bar_lengths 		= sqrt.( map( x -> sum(x.^2), bar_vector ) );
        bar_lengths         = vec(sqrt.( sum( bar_vector.^2; dims = 2) ))
		bar_midpoints 		= 0.5 .* ( point_array[bars[:, 1], :] + point_array[bars[:, 2], :] );
		hbars 				= vec(mapslices( options.node_spacing_fcn, bar_midpoints; dims = 2))
		desired_bar_length 	= hbars .* options.F_scale .* sqrt.( sum(bar_lengths.^2) ./ sum(hbars.^2) ); 

        # Bar forces (scalars)
		F_bar = max.(desired_bar_length - bar_lengths, 0.0)
        # println("F_bar = $(F_bar[1:5])")
		
		
		# Bar forces (x, y components)
		Fvec = F_bar .* bar_vector ./ bar_lengths

		
		n_bars = size(bar_vector, 1)
		F_total = zeros(n_points, 2)
		
		for bb = 1:n_bars
			
			start_index = bars[bb,1];
			end_index   = bars[bb,2];
			
			force_from_start_to_end = Fvec[bb,:]
			F_total[start_index,:]  = F_total[start_index,:] + force_from_start_to_end;
			F_total[end_index,:]    = F_total[end_index,:]   - force_from_start_to_end;
			
		end




        # Force  =  0 at fixed points
		F_total[1:size(options.fixed_points, 1), :] .= 0.0
		
		# Update node positions
		point_array = point_array .+ options.time_step_size * F_total;
		
		
		# 7. Bring outside points back to the boundary
		distance_at_points = vec(mapslices( options.distance_fcn, point_array; dims = 2))
		
		# Find points outside (distance_at_points > 0)
		outside = distance_at_points .> 0; 
		

        dist_out = distance_at_points[outside]
		tmp = point_array[outside,:]

        # arg = map( p -> [p[1] + options.gradient_step, p[2]], tmp )
        arg = copy(tmp)
        arg[:,1] .+= options.gradient_step
		dx = vec(mapslices( options.distance_fcn, arg; dims = 2))
		grad_x_of_distfun = ( dx - dist_out ) ./ options.gradient_step


        # arg = map( p -> [p[1], p[2] + options.gradient_step], tmp )
		arg = copy(tmp)
        arg[:,2] .+= options.gradient_step
        dy = vec(mapslices( options.distance_fcn, arg; dims = 2))
		grad_y_of_distfun = ( dy - dist_out ) ./ options.gradient_step;


        # Project back to boundary
		point_array[outside,:] .-= [dist_out .* grad_x_of_distfun     dist_out .* grad_y_of_distfun]


        # 8. Termination criterion: All interior nodes move less than dptol (scaled)
		delta_p_for_interior = options.time_step_size .* F_total[distance_at_points .< (-options.geometrical_tolerance), :];
		# delta_p_for_interior = sqrt.( map( x -> sum(x.^2), delta_p_for_interior ) );
        delta_p_for_interior = vec(sqrt.( sum( delta_p_for_interior.^2; dims = 2) ))
		if maximum(delta_p_for_interior) < options.initial_spacing * options.delta_point_tolerance
			break
		end


    end # for



    # final retriangluation
    
    # create delaunay triangulation
    pointtyped_point_array = matrix_to_point_array(point_array)
    delmesh = build_delaunay_mesh!(pointtyped_point_array)
    triangle_index = triangle_indices(delmesh)

    # compute centroids
    p1 = point_array[triangle_index[:, 1], :];
    p2 = point_array[triangle_index[:, 2], :];
    p3 = point_array[triangle_index[:, 3], :];
    triangle_centroids = (p1 .+ p2 .+ p3) ./ 3;


    # Keep interior triangles
    dist_at_triange_centroids = vec(mapslices( options.distance_fcn, triangle_centroids; dims = 2))
    bool_interior_triangle    = dist_at_triange_centroids .< (-options.geometrical_tolerance);
    triangle_index 			  = triangle_index[bool_interior_triangle, :]; 


    # set the valid in geometry indices
    delmesh.triangle_index = triangle_index
    
    return (point_array, triangle_index, delmesh)

end




function create_initial_meshgrid_distribution(options::MeshGenerationOptions)

    x_min = options.bounding_box.p1.x
    y_min = options.bounding_box.p1.y
    
    x_max = options.bounding_box.p2.x
    y_max = options.bounding_box.p2.y

    x_min = min(x_min, x_max)
    x_max = max(x_min, x_max)
    y_min = min(y_min, y_max)
    y_max = max(y_min, y_max)

    dx = x_max - x_min
    dy = y_max - y_min
    Nx = Int64( max(2, ceil(dx / options.initial_spacing) ) )
    Ny = Int64( max(2, ceil(dy / (sqrt(3)/2 * options.initial_spacing)) ) )
    
    xr = range(x_min, x_max, Nx)
    yr = range(y_min, y_max, Ny)


    
    (xs, ys) = util.mesh_grid(xr, yr)
    return (xs, ys)
    
end

function shift_even_rows!(xs, ys, options::MeshGenerationOptions)
    xs[:,2:2:end] .+=  options.initial_spacing / 2
    xs = vec(xs)
    ys = vec(ys)
    return (xs, ys)
end

function remove_points_outside_region!(xs, ys, options::MeshGenerationOptions)

    L = length(xs)
    dist = zeros(L)

    for ii = 1:L
        dist[ii] = options.distance_fcn( (xs[ii], ys[ii]) )
    end

    interior = dist .<= options.geometrical_tolerance

    xs = xs[interior]
    ys = ys[interior]
    return (xs, ys)
end

function keep_interior_points!(xs, ys, options::MeshGenerationOptions)
    
    L = length(xs)
    
    # Probability to keep point
    node_spacings_at_points = zeros(L)
    for ii = 1:L
        node_spacings_at_points[ii] = options.node_spacing_fcn( (xs[ii], ys[ii]) );
    end
	r0 = 1 ./ node_spacings_at_points.^2;
	max_r0 = maximum(r0)

	# Rejection method
	probability = rand(L);
	keep_point  = probability .< (r0 ./ max_r0);

    xs = xs[keep_point]
    ys = ys[keep_point]
    
    return (xs, ys)
end

function create_point_array(xs, ys, options::MeshGenerationOptions)

    #=
    Lf = length(options.fixed_points)
    Lx = length(xs)
    L = Lx + Lf
    point_array = Vector{MutablePoint}(undef, L)

    for ii = 1:Lf
        point_array[ii] = options.fixed_points[ii]
    end
    for ii = (Lf+1):L
        point_array[ii] = MutablePoint(xs[ii], ys[ii])
    end
    =#

    point_array = vcat(options.fixed_points, [xs ys])

    return point_array
end


