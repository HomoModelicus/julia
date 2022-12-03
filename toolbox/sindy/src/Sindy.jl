

module Sindy
using LinearAlgebra


# one needs to create a library matrix
# solve the least squares problem
# resolve the least squares problem for the relevant contributing indices/variables



struct LinsolverOptions
    singular_value_tol::Float64
end
function LinsolverOptions()
    return LinsolverOptions(-1.0)
end
function is_defined_linsolver_option(val)
    return val == -1.0
end

function default_singular_value_tolerance(singular_values)
    return length(singular_values) * maximum( eps.(singular_values) )
end


function qr_solve(A, b, options::LinsolverOptions)
    n_lib   = size(A,2)
    dec     = qr(A)
    rhs     = dec.Q' * b
    rhs     = rhs[1:n_lib, :]
    Xi      = dec.R \ rhs
    return Xi
end

function svd_solve(A, b, options::LinsolverOptions)
    singval = svd(A)

    singval_tol = options.singular_value_tol
    if is_defined_linsolver_option(options.singular_value_tol)
        # create the truncation parameter for pseudo inverse
        singval_tol = default_singular_value_tolerance(singval.S)
    end

    # select the relevant singular values
    bool = singval.S .>= singval_tol

    # calculate the pseudo inverse
    St   = singval.S[bool]
    iSt  = 1.0 ./ St
    Ut   = singval.U[:, bool]
    VtT  = singval.Vt[bool, :]
    Xi   = (VtT' .* iSt') * (Ut' * b)
    return Xi
end


struct SparsifingOptions
    threshold::Float64
    max_iter::Int
    linsolver
    linsolver_options::LinsolverOptions
end
function SparsifingOptions(;
    threshold = 0.025,
    max_iter = 10,
    linsolver = svd_solve,
    linsolver_options = LinsolverOptions()
    )
    return SparsifingOptions(threshold, max_iter, linsolver, linsolver_options)
end





function sparsify_dynamics(
    dermat::Matrix,
    libmat::Matrix,
    options::SparsifingOptions = SparsifingOptions()
    )

    # init solution
    (n_row, n_dim) = size(dermat)
    Xi = options.linsolver(libmat, dermat, options.linsolver_options)

    
    for iter = 1:options.max_iter
    
        # determine the relevant contributions
        small_idx = abs.(Xi) .<= options.threshold
        Xi[small_idx] .= 0.0

        
        
        # for all state variables
        for dd = 1:n_dim
            # get the indices for the non-neglible contributions from the library
            big_idx = .!small_idx[:,dd]
            
            # select from the library the contributing factors column wise and 
            # create the qr decomposition for it
            # v = view(libmat, 1:n_row, big_idx)
            # dec = qr(v)

            # # solve the least squares problem for the contributing factors
            # # for all time points
            # u = view( dermat, 1:n_row, dd)

            # b = dec.Q' * u

            # n = sum(big_idx)
            # rhs = b[1:n, :]

            # truncated = dec.R \ rhs
            # Xi[big_idx, dd] = truncated


            # u = view(libmat, 1:n_row, big_idx)
            u = libmat[1:n_row, big_idx]
            v = view( dermat, 1:n_row, dd)
            Xi[big_idx, dd] = options.linsolver(u, v, options.linsolver_options)

        end

    end

    return Xi
end


function create_poly_lib(datamat::Matrix; polyorder::Int = 3)
   
    (n_row, n_col) = size(datamat)

    if polyorder < 1 || polyorder > 5
        error("Not implemented for other poly order")
    end

    if polyorder >= 1
        idx     = create_indices_1(n_col)
        names_1 = create_names(idx)
        theta_1 = create_sub_matrix_1(datamat, idx)
    end

    if polyorder >= 2
        idx     = create_indices_2(n_col)
        names_2 = create_names(idx)
        theta_2 = create_sub_matrix_2(datamat, idx)
    end

    if polyorder >= 3
        idx     = create_indices_3(n_col)
        names_3 = create_names(idx)
        theta_3 = create_sub_matrix_3(datamat, idx)
    end

    if polyorder >= 4
        idx     = create_indices_4(n_col)
        names_4 = create_names(idx)
        theta_4 = create_sub_matrix_4(datamat, idx)
    end

    if polyorder >= 5
        idx     = create_indices_5(n_col)
        names_5 = create_names(idx)
        theta_5 = create_sub_matrix_5(datamat, idx)
    end

    unit_vec = ones(n_row)
    name_0 = "const"
    if polyorder == 1
        names   = [name_0; names_1]
        libmat  = [unit_vec theta_1]
    elseif polyorder == 2
        names   = [name_0; names_1; names_2]
        libmat  = [unit_vec theta_1  theta_2]
    elseif polyorder == 3
        names   = [name_0; names_1; names_2; names_3]
        libmat  = [unit_vec theta_1  theta_2  theta_3]
    elseif polyorder == 4
        names   = [name_0; names_1; names_2; names_3; names_4]
        libmat  = [unit_vec theta_1  theta_2  theta_3  theta_4]
    elseif polyorder == 5
        names   = [name_0; names_1; names_2; names_3; names_4; names_5]
        libmat  = [unit_vec theta_1  theta_2  theta_3  theta_4  theta_5]
    end

    return (libmat, names)
end

function create_names(idx)
    (N, n_dim) = size(idx)
    names = Vector{String}(undef, N)
    for ii = 1:N
        v = view(idx, ii, 1:n_dim)
        names[ii] = string(v)
    end
    return names
end

function create_sub_matrix_1(datamat, idx)
    return copy(datamat)
end
function create_sub_matrix_2(datamat, idx)
    n_var = size(idx,1)
    n_row = size(datamat, 1)
    theta = zeros(n_row, n_var)

    for vv = 1:n_var
        c1 = view(datamat, 1:n_row, idx[vv, 1])
        c2 = view(datamat, 1:n_row, idx[vv, 2])
        
        theta[:, vv] = c1 .* c2
    end

    return theta
end
function create_sub_matrix_3(datamat, idx)
    n_var = size(idx,1)
    n_row = size(datamat, 1)
    theta = zeros(n_row, n_var)

    for vv = 1:n_var
        c1 = view(datamat, 1:n_row, idx[vv, 1])
        c2 = view(datamat, 1:n_row, idx[vv, 2])
        c3 = view(datamat, 1:n_row, idx[vv, 3])
        
        theta[:, vv] = c1 .* c2 .* c3
    end

    return theta
end
function create_sub_matrix_4(datamat, idx)
    n_var = size(idx,1)
    n_row = size(datamat, 1)
    theta = zeros(n_row, n_var)

    for vv = 1:n_var
        c1 = view(datamat, 1:n_row, idx[vv, 1])
        c2 = view(datamat, 1:n_row, idx[vv, 2])
        c3 = view(datamat, 1:n_row, idx[vv, 3])
        c4 = view(datamat, 1:n_row, idx[vv, 4])

        theta[:, vv] = c1 .* c2 .* c3 .* c4
    end

    return theta
end
function create_sub_matrix_5(datamat, idx)
    n_var = size(idx,1)
    n_row = size(datamat, 1)
    theta = zeros(n_row, n_var)

    for vv = 1:n_var
        c1 = view(datamat, 1:n_row, idx[vv, 1])
        c2 = view(datamat, 1:n_row, idx[vv, 2])
        c3 = view(datamat, 1:n_row, idx[vv, 3])
        c4 = view(datamat, 1:n_row, idx[vv, 4])
        c5 = view(datamat, 1:n_row, idx[vv, 5])

        theta[:, vv] = c1 .* c2 .* c3 .* c4 .* c5
    end

    return theta
end

function create_indices_1(n_col)
    rr = 0
    for ii = 1:n_col
        rr += 1
    end
    

    idx = zeros(Int, rr, 1)
    rr = 0
    for ii = 1:n_col
        rr += 1
        idx[rr, 1] = ii
    end

    return idx
end
function create_indices_2(n_col)
    rr = 0
    for jj = 1:n_col
        for ii = jj:n_col
            rr += 1
        end
    end

    idx = zeros(Int, rr, 2)
    rr = 0
    for jj = 1:n_col
        for ii = jj:n_col
            rr += 1
            idx[rr, 1] = ii
            idx[rr, 2] = jj
        end
    end

    return idx
end
function create_indices_3(n_col)
    rr = 0
    for kk = 1:n_col
        for jj = kk:n_col
            for ii = jj:n_col
                rr += 1
            end
        end
    end

    idx = zeros(Int, rr, 3)
    rr = 0
    for kk = 1:n_col
        for jj = kk:n_col
            for ii = jj:n_col
                rr += 1
                idx[rr, 1] = ii
                idx[rr, 2] = jj
                idx[rr, 3] = kk
            end
        end
    end

    return idx
end
function create_indices_4(n_col)
    rr = 0
    for ll = 1:n_col
        for kk = ll:n_col
            for jj = kk:n_col
                for ii = jj:n_col
                    rr += 1
                end
            end
        end
    end

    idx = zeros(Int, rr, 4)
    rr = 0
    for ll = 1:n_col
        for kk = ll:n_col
            for jj = kk:n_col
                for ii = jj:n_col
                    rr += 1
                    idx[rr, 1] = ii
                    idx[rr, 2] = jj
                    idx[rr, 3] = kk
                    idx[rr, 4] = ll
                end
            end
        end
    end

    return idx
end

function create_indices_5(n_col)
    rr = 0
    for mm = 1:n_col
        for ll = mm:n_col
            for kk = ll:n_col
                for jj = kk:n_col
                    for ii = jj:n_col
                        rr += 1
                    end
                end
            end
        end
    end

    idx = zeros(Int, rr, 5)
    rr = 0
    for mm = 1:n_col
        for ll = mm:n_col
            for kk = ll:n_col
                for jj = kk:n_col
                    for ii = jj:n_col
                        rr += 1
                        idx[rr, 1] = ii
                        idx[rr, 2] = jj
                        idx[rr, 3] = kk
                        idx[rr, 4] = ll
                        idx[rr, 5] = mm
                    end
                end
            end
        end
    end

    return idx
end


# gather observations from e.g. an ode solution, or measurements
# create the library matrix
# create the derivative of the measurements
# sparsify_dynamics -> Xi
# Xi are the relevant sparse coefficients for the library
# if the library is not a valid representation of the true dynamics possibly loss of accuracy or ? not sparse?
#
# 
# My idea:
#   - try to do this for a window
#   - update the least squares estimates as time pass -> like in adaptive controllers
#   - what to do if some of the variables cannot be observed?
#
# To Do:
#   - find out the relevant sensitivity factors, e.g. max_iter, library matrix, data size
#   - find out a way for variables which cannot be observed, Kalman filter? -> observer for the hidden variables? or something like in the collocation method?
#   - find out ways for derivatives
#       o total variation denoising
#       o polynomial fitting, sinusoidal fitting etc...
#       o 











end




