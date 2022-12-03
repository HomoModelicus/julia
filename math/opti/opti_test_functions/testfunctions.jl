
include("../../../std/util/src/util_module.jl")


module optitestfun
using ..util
using PyPlot
PyPlot.pygui(true)




function nd_quadratic(x)
    y = x' * x
    return y
end

function quad_with_norm_l1(x, x_sol, lamda = 0.1)
    dx = x - x_sol
    y = dx' * dx + lamda * sum( abs.(x) )
    return y
end


function ackley(x, a = 20, b = 0.2, c = 2*pi )
    d = length(x)
    e1 = -b * sqrt( 1/d * sum(x.^2) )
    e2 = 1/d * sum( cos.(c * x) )
    y = - a * exp(e1) - exp(e2) + a + exp(1.0)
    return y
end

function wheeler_ridge(x, a = 1.5)
	t = (x[1] * x[2] - a)^2 + (x[2] - a)^2;
	y = -exp(-t);
end

function booth(x)
# fcn: R^2 -> R
    y = (x[1] + 2 * x[2] - 7)^2 + (2 * x[1] + x[2] - 5)^2
end

function branin(x, a=1.0, b = 5.1/(4*pi^2), c = 5/pi, r = 6.0, s = 10.0, t = 1/(8*pi))
    y = a * (x[2] - b * x[1]^2 + c * x[1] - r)^2 + s * (1-t) * cos(x[1]) + s
    return y
end

function rosenbrock(x, a = 1.0, b = 5.0)
    y = (a - x[1])^2 + b * (x[2] - x[1]^2)^2
    return y
end

function michalewicz(x, dim = 2, m = 10.0)
	y = 0.0
	for dd = dim:-1:1
		xi = x[dd];
		t = sin(xi) * (sin(dd * xi^2 / pi))^(2*m);
		y = y + t;
	end
	y = -y;
end

function flower(x, a = 1.0, b = 1.0, c = 4.0)
	y = a * norm(x) + b * sin( c * atan(x[2], x[1]) );
end

function quadratic(x)
# fcn: R^2 -> R
	y = 0.8 * x[1]^2 + 1.2 * x[2]^2
end

function plot_ackley()

    x_vec = collect(-5:0.1:5)
    y_vec = collect(-6:0.1:6)
    Lx = length(x_vec)
    Ly = length(y_vec)
    
    
    (x_mat, y_mat) = util.mesh_grid(x_vec, y_vec)

    f = zeros(Lx, Ly)
    for ii = 1:Lx
        for jj = 1:Ly
            f[ii, jj] = ackley( [x_vec[ii], y_vec[jj]] )
        end
    end
    
    PyPlot.figure()
    PyPlot.surf(x_mat, y_mat, f)
end

function plot_booth()
    x_vec = collect(-10:0.1:10)
    y_vec = collect(-10:0.1:10)
    Lx = length(x_vec)
    Ly = length(y_vec)
    
    
    (x_mat, y_mat) = util.mesh_grid(x_vec, y_vec)

    f = zeros(Lx, Ly)
    for ii = 1:Lx
        for jj = 1:Ly
            f[ii, jj] = booth( [x_vec[ii], y_vec[jj]] )
        end
    end
    
    PyPlot.figure()
    PyPlot.contour(x_mat, y_mat, f)
end

function plot_branin()
    x_vec = collect(-6:0.1:20)
    y_vec = collect(-5:0.1:22)
    Lx = length(x_vec)
    Ly = length(y_vec)
    
    
    (x_mat, y_mat) = util.mesh_grid(x_vec, y_vec)

    f = zeros(Lx, Ly)
    for ii = 1:Lx
        for jj = 1:Ly
            f[ii, jj] = branin( [x_vec[ii], y_vec[jj]] )
        end
    end
    
    PyPlot.figure()
    PyPlot.contour(x_mat, y_mat, f, [1e-3, 1e-2, 1e-1, 1, 10, 20, 30, 50, 75, 100, 200, 300, 400, 500, 1000]) #, colors=PyPlot.ColorMap 
    
    # PyPlot.figure()
    # PyPlot.plot(f)

end


function plot_rosenbrock(x_domain = [-2, 2], y_domain = [-2, 2])

    x_vec = collect(x_domain[1]:0.1:x_domain[2])
    y_vec = collect(y_domain[1]:0.1:y_domain[2])
    Lx = length(x_vec)
    Ly = length(y_vec)
    
    
    (x_mat, y_mat) = util.mesh_grid(x_vec, y_vec)

    f = zeros(Lx, Ly)
    for ii = 1:Lx
        for jj = 1:Ly
            f[ii, jj] = rosenbrock( [x_vec[ii], y_vec[jj]] )
        end
    end
    
    PyPlot.figure()
    PyPlot.contour(x_mat, y_mat, f, [1e-3, 1e-2, 1e-1, 1, 10, 20, 30, 50, 75, 100, 200, 300, 400, 500, 1000]) #, colors=PyPlot.ColorMap 
    # PyPlot.contour(x_mat, y_mat, f) #, colors=PyPlot.ColorMap 
    
end

end # optitestfun




# ================================================================================================ #
# test function visualizations
# ================================================================================================ #
#=

# ------------------------------------------------------------------------------------------------ #
# ackley
# ------------------------------------------------------------------------------------------------ #

N_vec = 100;
x_vec = collect( LinRange(-10.0, 10.0, N_vec) );
y_vec = collect( LinRange(-10.0, 10.0, N_vec) );


(x_mat, y_mat) = meshgrid(x_vec, y_vec);
z_mat = map( (x,y) -> ackley([x, y]), x_mat, y_mat)


PyPlot.figure()
PyPlot.grid()
PyPlot.contour(x_mat, y_mat, z_mat)


# ------------------------------------------------------------------------------------------------ #
# quadratic
# ------------------------------------------------------------------------------------------------ #

N_vec = 100;
x_vec = collect( LinRange(-10.0, 10.0, N_vec) );
y_vec = collect( LinRange(-10.0, 10.0, N_vec) );

(x_mat, y_mat) = meshgrid(x_vec, y_vec);
z_mat = map( (x,y) -> quadratic([x, y]), x_mat, y_mat)

min_z = minimum(z_mat)
max_z = maximum(z_mat)
levels = logspace( log10(min_z), log10(max_z), 20 )

PyPlot.figure()
PyPlot.grid()
PyPlot.contour(x_mat, y_mat, z_mat, levels)


# ------------------------------------------------------------------------------------------------ #
# wheeler_ridge
# ------------------------------------------------------------------------------------------------ #

N_vec = 100;
x_vec = collect( LinRange(-10.0, 25.0, N_vec) );
y_vec = collect( LinRange(-3.0, 6.0, N_vec) );

(x_mat, y_mat) = meshgrid(x_vec, y_vec);
z_mat = map( (x,y) -> wheeler_ridge([x, y]), x_mat, y_mat)

# min_z = minimum(z_mat)
# max_z = maximum(z_mat)
# levels = logspace( log10(min_z), log10(max_z), 20 )

PyPlot.figure()
PyPlot.grid()
PyPlot.contour(x_mat, y_mat, z_mat)



# ------------------------------------------------------------------------------------------------ #
# rosenbrock2d
# ------------------------------------------------------------------------------------------------ #
N_vec = 100;
x_vec = collect( LinRange(-2.0, 2.0, N_vec) );
y_vec = collect( LinRange(-2.0, 2.0, N_vec) );

(x_mat, y_mat) = meshgrid(x_vec, y_vec);
z_mat = map( (x,y) -> rosenbrock2d([x, y], 0.5), x_mat, y_mat)

min_z = minimum(z_mat)
max_z = maximum(z_mat)
levels = logspace( log10(min_z), log10(max_z), 20 )

PyPlot.figure()
PyPlot.grid()
PyPlot.contour(x_mat, y_mat, z_mat, levels)
# PyPlot.contour(x_mat, y_mat, z_mat)


# ------------------------------------------------------------------------------------------------ #
# michalewicz
# ------------------------------------------------------------------------------------------------ #
N_vec = 100;
x_vec = collect( LinRange(0.0, 4.0, N_vec) );
y_vec = collect( LinRange(0.0, 4.0, N_vec) );

(x_mat, y_mat) = meshgrid(x_vec, y_vec);
z_mat = map( (x,y) -> michalewicz([x, y]), x_mat, y_mat)

PyPlot.figure()
PyPlot.grid()
PyPlot.contour(x_mat, y_mat, z_mat)

# ------------------------------------------------------------------------------------------------ #
# flower
# ------------------------------------------------------------------------------------------------ #

N_vec = 100;
x_vec = collect( LinRange(-3.0, 3.0, N_vec) );
y_vec = collect( LinRange(-3.0, 3.0, N_vec) );

(x_mat, y_mat) = meshgrid(x_vec, y_vec);
z_mat = map( (x,y) -> flower([x, y]), x_mat, y_mat)

PyPlot.figure()
PyPlot.grid()
PyPlot.contour(x_mat, y_mat, z_mat)

# ------------------------------------------------------------------------------------------------ #
# branin
# ------------------------------------------------------------------------------------------------ #

N_vec = 100;
x_vec = collect( LinRange(-6.0, 20.0, N_vec) );
y_vec = collect( LinRange(-6.0, 22.0, N_vec) );

(x_mat, y_mat) = meshgrid(x_vec, y_vec);
z_mat = map( (x,y) -> branin([x, y]), x_mat, y_mat)

PyPlot.figure()
PyPlot.grid()
PyPlot.contour(x_mat, y_mat, z_mat)

# ------------------------------------------------------------------------------------------------ #
# booth
# ------------------------------------------------------------------------------------------------ #

N_vec = 100;
x_vec = collect( LinRange(-10.0, 10.0, N_vec) );
y_vec = collect( LinRange(-10.0, 10.0, N_vec) );

(x_mat, y_mat) = meshgrid(x_vec, y_vec);
z_mat = map( (x,y) -> booth([x, y]), x_mat, y_mat)

PyPlot.figure()
PyPlot.grid()
PyPlot.contour(x_mat, y_mat, z_mat)

=#



