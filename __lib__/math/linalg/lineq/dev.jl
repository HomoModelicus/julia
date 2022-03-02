


module lineq
using LinearAlgebra


function linear_index(i, j, sz)
    n_row = sz[1]
    return i + (j - 1) * n_row
end

function matrix_index(k, sz)
    n_row = sz[1]
    (j, r) = divrem(k, n_row)
    j = (r>0) + j
    i = k - (j-1) * n_row
    return (i, j)
end



struct JacobiOptions
    max_iter::Int
    n_iter_norm_check::Int
    delta_x_tol::Float64
    damping::Float64
end
function JacobiOptions()
    return JacobiOptions(100, 10, 1e-6, 1.0)
end
function JacobiOptions(;
    max_iter = 100,
    n_iter_norm_check = 10,
    delta_x_tol = 1e-15,
    damping = 1.0)

    return JacobiOptions(
        max_iter,
        n_iter_norm_check,
        delta_x_tol,
        damping)
end

function delta_x_norm_check(x_new, x_old, options)
    break_flag = false
    norm_dx = norm(x_new - x_old)
    if norm_dx <= options.delta_x_tol
        break_flag = true
    end
    return break_flag
end

function jacobi_iteration(A, b, options::JacobiOptions = JacobiOptions())
    
    n_dim = length(b)
    x_old = zeros(eltype(b), n_dim)
    x_new = zeros(eltype(b), n_dim)
    
    d_vec = diag(A)

    use_damping = options.damping == 1.0

    iter_norm_check = 0
    iter = 0
    for outer iter = 1:options.max_iter
        iter_norm_check += 1

        # stepping algorithm
        x_new = ( b + d_vec .* x_old - (A * x_old) ) ./ d_vec

        if use_damping
            x_new = x_new * options.damping + x_old * (1 - options.damping)
        end

        # check for stopping conditions
        if iter_norm_check >= options.n_iter_norm_check
            iter_norm_check = 0
            break_flag = delta_x_norm_check(x_new, x_old, options)
            if break_flag
                break
            end
        end
    
        # update x_old
        x_old = x_new
    end

    return (x_new, iter)
end


struct GaussSeidelOptions
    max_iter::Int
    n_iter_norm_check::Int
    delta_x_tol::Float64
    damping::Float64
end
function GaussSeidelOptions()
    return GaussSeidelOptions(100, 10, 1e-6, 1.0)
end
function GaussSeidelOptions(;
    max_iter = 100,
    n_iter_norm_check = 10,
    delta_x_tol = 1e-15,
    damping = 1.0)

    return GaussSeidelOptions(
        max_iter,
        n_iter_norm_check,
        delta_x_tol,
        damping)
end

function gauss_seidel_iteration(A, b, options::GaussSeidelOptions)

    n_dim = length(b)
    x_old = zeros(eltype(b), n_dim)
    x_new = zeros(eltype(b), n_dim)
    
    d_vec = diag(A)

    use_damping = options.damping == 1.0

    iter_norm_check = 0
    iter = 0
    for outer iter = 1:options.max_iter
        iter_norm_check += 1
        
        # stepping algorithm
        

        if use_damping
            x_new = x_new * options.damping + x_old * (1 - options.damping)
        end


        # check for stopping conditions
        if iter_norm_check >= options.n_iter_norm_check
            iter_norm_check = 0
            break_flag = delta_x_norm_check(x_new, x_old, options)
            if break_flag
                break
            end
        end

    end

    return (x_new, iter)
end


end # dev


module dtest
using ..lineq
using LinearAlgebra

function create_matrix(n_dim = 8)

    A = zeros(Float64, n_dim, n_dim)

    main_diag = [1; 4 * ones(n_dim-2); 4]
    side_diag = -ones(n_dim-1)
    sideside_diag = -ones(n_dim-3)
    
    main_diag_idx = diagind(A, 0)
    side_m1_diag_idx = diagind(A, 1)
    side_p1_diag_idx = diagind(A, -1)
    
    side_m3_diag_idx = diagind(A, 3)
    side_p3_diag_idx = diagind(A, -3)
    
    
    
    A[ main_diag_idx ] = main_diag
    A[ side_m1_diag_idx ] = side_diag
    A[ side_p1_diag_idx ] = side_diag
    A[ side_m3_diag_idx ] = sideside_diag
    A[ side_p3_diag_idx ] = sideside_diag

    return A
end

function create_vector(n_dim = 8)

    b = zeros(n_dim)
    b[1]   = -1.0
    b[end] = 2.0

    return b
end

n_dim = 8 # 100
A = create_matrix(n_dim)
b = create_vector(n_dim)

x_theo = A \ b


# jac_options = lineq.JacobiOptions(delta_x_tol = 1e-10, max_iter = 10000, damping = 1.0)
# (x_jac, iter) = lineq.jacobi_iteration(A, b, jac_options)

# println("Norm diff between theo and jac: $(norm(x_theo - x_jac))")
# println("Needed iterations: $(iter)")


gs_options = lineq.GaussSeidelOptions(delta_x_tol = 1e-10, max_iter = 100, damping = 1.0)
(x_gs, iter) = lineq.gauss_seidel_iteration(A, b, gs_options)


println("Norm diff between theo and gs: $(norm(x_theo - x_gs))")
println("Needed iterations: $(iter)")


D = diagm( diag(A) )
E = -LowerTriangular(A)
F = -UpperTriangular(A)



end



