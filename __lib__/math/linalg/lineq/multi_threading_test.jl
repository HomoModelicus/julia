
module multi
using BenchmarkTools
using PyPlot
PyPlot.pygui(true)

# println(Threads.nthreads())

function write_tid()
    n_dim = 5_000_000
    vec = zeros(Float64, n_dim)
    Threads.@threads for kk = 1:n_dim
        vec[kk] = Threads.threadid()
    end
    # for kk = 1:n_dim
    #     vec[kk] = Threads.threadid()
    # end
end

function mandelbrot(x::T, y::T; max_iter::Int = 100_000) where {T <: Real}
    # x and y are interpreted as complex numbers
    # z = x + i*y
    # z * z = (x^2 - y^2, 2*x*y)

    z0_x = zero(T)
    z0_y = zero(T)

    critical_norm = 2 * one(T)

    x_old = x
    y_old = y
    n_old = x^2 + y^2

    x_new = zero(T)
    y_new = zero(T)

    iter = 0
    for outer iter = 1:max_iter
        x_new = x_old^2 - y_old^2 + x
        y_new = 2 * x_old * y_old + y
        n_new = x_new^2 + y_new^2
        if n_new > critical_norm
            break
        end
        # if abs(n_new - n_old) <= 10 * eps(n_old)
        #     break
        # end
        n_old = n_new
        x_old = x_new
        y_old = y_new
    end

    return iter

end

function mandelbrot_matrix(;
    max_iter = 100,
    x_min = -2.0,
    x_max = 1.0,
    y_min = -1.0,
    y_max = -y_min,
    n_y_pixels = 1000,
    n_x_pixels = ceil(Int, (x_max - x_min) / (y_max - y_min) * n_y_pixels)
    )
    
    x_range = range(x_min, x_max, n_x_pixels)
    y_range = range(y_min, y_max, n_y_pixels)
    
    pixels = zeros(Float64, n_y_pixels, n_x_pixels)
    Threads.@sync for ii = 1:n_x_pixels # Threads.@threads 
        Threads.@spawn for jj = 1:n_y_pixels
            @inbounds pixels[jj, ii] = (max_iter - mandelbrot(x_range[ii], y_range[jj]; max_iter = max_iter) ) / max_iter
        end
    end

    return pixels
end


function test_tid()

    b = @benchmark write_tid()
    show(stdout, MIME("text/plain"), b)
    println("\n\n")
    @time write_tid()
end


function plot_mandelbrot()

    @benchmark pixels = mandelbrot_matrix(n_y_pixels = 3000, x_min = -1.5, x_max = -1.2, y_min = -0.1)
    
    # PyPlot.figure()
    # PyPlot.imshow(pixels, cmap = PyPlot.cm.cubehelix )
    
end



end






