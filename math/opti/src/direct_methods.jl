
include("testfunctions.jl")



module opti
using LinearAlgebra

# include("line_search.jl")
include("opti_1d.jl")


function bracketing_line_search(fcn, x0, step_direction; max_iter = 100, alpha = 1.0, x_tol = 1e-2)

    obj_fcn(alpha) = fcn( x0 + step_direction * alpha )
    x_lo = 0.0
    x_hi = alpha
    bracketing_interval = bracket_min(obj_fcn, x_lo, x_hi, max_iter = max_iter)


    stat = golden_section_search(
        obj_fcn,
        bracketing_interval.x_lo,
        bracketing_interval.x_hi,
        max_iter = max_iter,
        x_tol = x_tol)

    x_sol = x0 + stat.x_sol * step_direction
    return (x_sol, stat.y_sol)
end


function basis(n_dim::Int, ii::Int)
    e_i = zeros(n_dim)
    e_i[ii] = 1.0
    return e_i
end

struct DirectMethodToleranceOptions
    f_abs_tol::Float64
    f_rel_tol::Float64
end
function DirectMethodToleranceOptions()
    f_abs_tol = 1e-10
    f_rel_tol = 1e-10
    return DirectMethodToleranceOptions(f_abs_tol, f_rel_tol)
end


function powell(
    fcn, 
    x0;
    max_iter = 100,
    step_size_tol = 1e-10,
    line_search_x_tol = 1e-2,
    reset_iter = 5 * length(x0),
    tol_options = DirectMethodToleranceOptions()
    )
    
    x = copy(x0)
    mach_eps = tol_options.f_abs_tol * 1e-5

    n_dim = length(x0)
    U = Matrix( one(eltype(x0)) * I , n_dim, n_dim )

    break_flag = false

    f_prev = fcn(x0)
    iter = 0
    for outer iter = 1:max_iter

        for ii = 1:n_dim
            (x, f_act) = bracketing_line_search(
                fcn, 
                x, 
                U[:, ii]; 
                max_iter = max_iter, 
                x_tol = line_search_x_tol)
            
                # stopping criteria for function value
            if abs(f_act - f_prev) <= tol_options.f_abs_tol || abs(f_act - f_prev) / ( abs(f_prev) == 0 ? mach_eps : abs(f_prev)) < tol_options.f_rel_tol
                break_flag = true
                break
            end
            
            println(" x = $(x) ")
        end

        if break_flag
            break
        end

        for ii = 2:n_dim
            U[:, ii-1] = U[:, ii]
        end
        d = x - U[:,n_dim]
        U[:,n_dim] = d
        (x_hat, f_act) = bracketing_line_search(
                fcn, 
                x, 
                U[:, n_dim]; 
                max_iter = max_iter, 
                x_tol = line_search_x_tol)
        println(" x_hat = $(x_hat) ")
        step = x_hat - x
        if norm(step) <= step_size_tol
            break
        end


        if iter % reset_iter == 0
            U = Matrix( one(eltype(x0)) * I , n_dim, n_dim )
        end

    end

    return (x, iter)

end










function exponential_annealing_schedule(iter, start_value = 1.0, gamma = 1.0)
    return gamma * start_value^iter
end

function fast_annealing_schedule(iter, start_value = 1.0)
    return start_value / iter
end

function logarithmic_annealing_schedule(iter, gamma = 1.0)
    return log( gamma * iter )
end 


function simulated_annealing(
    fcn,
    x0,
    rand_fcn;
    max_iter = 100,
    annealing_schedule = exponential_annealing_schedule
    )

    # gamma = 10
    # annealing_schedule(iter) = gamma * iter

    n_dim = length(x0)
    x_path = zeros(n_dim, max_iter)

    f_old = fcn(x0)
    x_best = x0
    f_best = f_old

    x_old = copy(x0)
    iter = 0
    for outer iter = 1:max_iter
        
        x_new = x_old + rand_fcn(x_old, iter)
        x_path[:, iter] = x_new

        f_new = fcn(x_new)
        df = f_new - f_old

        if df <= 0
            x_old = x_new
            f_old = f_new
        elseif rand() < exp( -df / annealing_schedule(iter) )
            x_old = x_new
            f_old = f_new
        end


        if f_new <= f_best
            x_best = x_new
            f_best = f_new
        end
    end


    return (x_best, f_best, iter, x_path)

end

function corana_update!(v, a, c, n_crit_cycles)
    for ii = 1:length(v)
        
        if a[ii] > 0.6 * n_crit_cycles
            v[ii] *= (1 + c[ii] / 0.4 * ( a[ii]/n_crit_cycles - 0.6 )  )
        elseif a[ii] < 0.4 * n_crit_cycles
            v[ii] /= (1 + c[ii] / 0.4 * (0.4 - a[ii]/n_crit_cycles))
        end

    end
    return v
end


function adaptive_simulated_annealing(
    fcn,
    x0,
    v,
    temperature,
    eps;
    n_crit_cycles = 20,
    neps = 4,
    n_crit_resets = max( 100, 5 * length(x0) ),
    gamma = 0.85,
    c = fill(2, length(x0)),
    max_iter = 100
    )

    



    x_best = copy(x0)
    x_old  = copy(x0)

    f_old  = fcn(x0)
    f_best = f_old

   
    

    y_arr = []
    n_dim = length(x0)
    uniform_random() = 2 * (rand() - 0.5)

    a = zeros(n_dim)
    counts_cycles = 0
    counts_resets = 0

    basis_vectors = Matrix{eltype(x0)}( one(eltype(x0)) * I, n_dim, n_dim )
    
    iter = 0
    for outer iter = 1:max_iter

        for ii = 1:n_dim
            x_new = x_old + basis_vectors[:,ii] * uniform_random() * v[ii]
            f_new = fcn(x_new)

            df = f_new - f_old
            if df < 0 || rand() < exp( df / temperature )
                x_old = x_new
                f_old = f_new
                a[ii] += 1
                if f_new < f_best
                    x_best = x_new
                    f_best = f_new
                end
            end
        end

        counts_cycles += 1
        # counts_cycles >= n_crit_cycles || continue
        if counts_cycles < n_crit_cycles
            continue
        end

        counts_cycles = 0
        corana_update!(v, a, c, n_crit_cycles)
        fill!(a, 0)
        counts_resets += 1
        if counts_resets < n_crit_resets
            continue
        end

        temperature *= gamma
        counts_resets = 0
        push!(y_arr, f_old)

        
        Ly = length(y_arr)
        cond = Ly > neps && y_arr[end] - y_best <= eps &&
         (all(abs(y_arr[end] - y_arr[end-u])) <= eps for u in 1:neps)
         
        if cond
            x_old = x_best
            f_old = f_best
        else
            break
        end

    end


    return (x_best, f_best)
end



end # opti


module otest
using ..optitestfun
using ..opti
using PyPlot
PyPlot.pygui(true)




fcn = optitestfun.rosenbrock # optitestfun.quadratic
x0 = [-1.8, -2.0] # [10, 8.0]

rand_fcn(x, iter) = 1 / log(iter+1) * randn( length(x) )

# (x_best, y_best, iter, x_path) = opti.simulated_annealing(
#     fcn,
#     x0,
#     rand_fcn;
#     max_iter = 300,
#     annealing_schedule = opti.fast_annealing_schedule) # opti.exponential_annealing_schedule)
    
v = [1.0, 1.0]
temp = 1.0
eps = 1e-1
(x_best, f_best) = opti.adaptive_simulated_annealing(
    fcn,
    x0,
    v,
    temp,
    eps;
    max_iter = 1000)

    


# PyPlot.figure()
# PyPlot.grid()
# PyPlot.plot(
#     x_path[1,:], x_path[2,:], linestyle = :none, marker = :.)
# PyPlot.plot( x_best[1], x_best[2], linestyle = :none, marker = :., color = :r, markersize = 15)





function test_powell()
    # fcn = optitestfun.quadratic
    # x0 = [10, 8.0]

    fcn(x) = optitestfun.rosenbrock(x, 2)
    x0 = [-1.8, -2.0]

    (x_sol, iter) = opti.powell( fcn, x0, step_size_tol = 1e-2, line_search_x_tol = 1e-3 )


    # xs = collect( range(-1.0, 10, 30) )
    # ys = collect( range(-1.0, 10, 30) )


    # zs = zeros( length(xs), length(ys) )
    # ii = 0
    # for xx in xs
    #     for yy in ys
    #         ii += 1
    #         zs[ii] = fcn([xx, yy]) 
    #     end
    # end



    # PyPlot.figure()
    # PyPlot.grid()
    # PyPlot.contour(xs, ys, zs, [1e-5, 1e-4, 1e-3, 1e-2, 1e-1, 0.2, 0.5, 1, 2, 5, 10, 20, 30, 50, 100])
end


end

