


function __oddify(n_eval::Int)
    if n_eval % 2 == 0
        n_eval += 1
    end
    return n_eval
end

function __calculate_gamma(n_eval::Int)
    gamma_k = zeros(n_eval-1)
    gamma_k[1] = 1/2
    for kk = 2:(n_eval-1)
        val = kk + 1
        for ii = 2:(kk-1)
            nom = ii
            den = ii + kk
            val *= (nom / den)
        end
        val *= 1/2
        gamma_k[kk] = val
    end
    return gamma_k
end


function __select_noise_sigma(sigma_k, first_idx)
    noise_sigma = 0.0
    if first_idx != 0
        noise_sigma = sigma_k[first_idx]
    end
    return noise_sigma
end

function __selection_criterion(T_ij, sigma_k, eta = 4.0, window_size = 3)
    n_eval = length(sigma_k) + 1
    first_idx_sigma = 0
    for ii = 1:(n_eval-1-window_size+1)

        min_s = min( sigma_k[ii:(ii+window_size-1)]... )
        max_s = max( sigma_k[ii:(ii+window_size-1)]... )
        
        if max_s <= eta * min_s
            first_idx_sigma = ii
            break        
        end
    end

    first_idx_sign = 0
    break_flag = false
    for ii = 2:(n_eval-2)
        
        sign_1 = sign( T_ij[1, ii+1] )
        for jj = 2:(n_eval - ii)
            sign_2 = sign( T_ij[jj, ii+1] )
            if sign_1 != sign_2
                first_idx_sign = ii
                break_flag = true
                break
            end
        end
        if break_flag
            break
        end

    end
    first_idx = min(first_idx_sign, first_idx_sigma)
    return first_idx
end

function __calculate_sigma(T_ij, gamma_k, n_eval)
    sigma_k = zeros(n_eval-1)
    for kk = 1:(n_eval-1)
        vi = view( T_ij, 1:(n_eval-kk), kk+1 )
        sum_T_ij = sum( vi.*vi )
        sigma_k[kk] = sqrt( gamma_k[kk] / (n_eval - kk) * sum_T_ij )
    end
    return sigma_k
end



# -------------------------- #
# dependent on the dimension #
# -------------------------- #




function __create_spacing(n_eval, x0::T, h::T) where {T <: Number}
    x_i = zeros(n_eval)

    x_i[ div(n_eval, 2)+1 ] = x0

    start_idx = div(n_eval, 2)
    for ii = start_idx:-1:1
        x_i[ii] = x0 - (start_idx + 1 - ii) * h
    end
    start_idx = div(n_eval, 2)+2
    for ii = start_idx:1:n_eval
        x_i[ii] = x0 + (ii - start_idx + 1) * h
    end

    return x_i
end

function __create_spacing(n_eval, x0::Vector{T}, h::Vector{T}) where {T <: Number}
    
    n_dim = length(x0)
    x_i = zeros(n_dim, n_eval)

    x_i[ :, div(n_eval, 2)+1 ] = x0

    start_idx = div(n_eval, 2)
    for ii = start_idx:-1:1
        x_i[:, ii] = x0 .- (start_idx + 1 - ii) .* h
    end
    start_idx = div(n_eval, 2)+2
    for ii = start_idx:1:n_eval
        x_i[:, ii] = x0 .+ (ii - start_idx + 1) .* h
    end

    return x_i
end





function __allocate_table(n_eval)
    T_ij = zeros(n_eval, n_eval)
    return T_ij
end

function __eval_function(fcn, x_i::Vector{T}, T_ij) where {T}
    for ii = 1:size(T_ij, 1)
        T_ij[ii, 1] = fcn( x_i[ii] )
    end
    return T_ij
end 

function __eval_function(fcn, x_i::Matrix{T}, T_ij) where {T}
    n_eval = size(T_ij, 2)
    for ii = 1:n_eval
        T_ij[ii, 1] = fcn( x_i[:, ii] )
    end
    return T_ij
end 

function __calculate_differences(T_ij, n_eval)
    for kk = 1:(n_eval-1)
        for ii = 1:(n_eval-kk)
            T_ij[ii, kk+1] = T_ij[ii+1, kk] - T_ij[ii, kk]
        end
    end

    return T_ij
end

function __difference_table(fcn, x_i::Vector{T}, n_eval::Int) where {T}
    # fcn: R -> R

    # allocate the table
    T_ij = __allocate_table(n_eval)

    # calculate the divided differences
    T_ij = __eval_function(fcn, x_i, T_ij)

    T_ij = __calculate_differences(T_ij, n_eval)
    
    return T_ij
end

function __difference_table(fcn, x_i::Matrix{T}, n_eval::Int) where {T}
    # fcn: R^n -> R

    # allocate the table
    T_ij = __allocate_table(n_eval)

    # calculate the divided differences
    T_ij = __eval_function(fcn, x_i, T_ij)

    T_ij = __calculate_differences(T_ij, n_eval)
    
    return T_ij
end











function estimate_noise(
    fcn, 
    x0;
    n_eval = 7, 
    h = 1e3 * sqrt.(eps.(x0))
    )
    # fcn : R -> R

    n_eval      = __oddify(n_eval)
    x_i         = __create_spacing(n_eval, x0, h)
    gamma_k     = __calculate_gamma(n_eval)
    T_ij        = __difference_table(fcn, x_i, n_eval)
    sigma_k     = __calculate_sigma(T_ij, gamma_k, n_eval)
    first_idx   = __selection_criterion(T_ij, sigma_k)
    noise_sigma = __select_noise_sigma(sigma_k, first_idx)

    return noise_sigma
end



function estimate_noise(
    fcn, 
    x0::Vector{T};
    step_direction = normalize( 0.5.-rand(length(x0)) ),
    n_eval::Int = 7, 
    h = 1e3 * sqrt.(eps.(x0))
    ) where {T}
    # fcn : R^n -> R 

    n_eval      = __oddify(n_eval)                                      # indepedent of dim
    x_i         = __create_spacing(n_eval, x0, step_direction .* h)     # double implementation
    gamma_k     = __calculate_gamma(n_eval)                             # indepedent of dim
    T_ij        = __difference_table(fcn, x_i, n_eval)                  # double implementation
    sigma_k     = __calculate_sigma(T_ij, gamma_k, n_eval)              # indepedent of dim
    first_idx   = __selection_criterion(T_ij, sigma_k)                  # indepedent of dim
    noise_sigma = __select_noise_sigma(sigma_k, first_idx)              # indepedent of dim

    return noise_sigma
end



function noisy_numdiff_fw(fcn, x0)
    noise_est = estimate_noise(fcn, x0)
    h = max( sqrt(noise_est), sqrt.(eps.(x0)) )
    return numdiff_fw(fcn, x0, h)
end
