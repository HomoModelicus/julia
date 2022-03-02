# =========================================================================== #
# ErrorEstimationOptions
# =========================================================================== #

struct ErrorEstimationOptions{c}
    norm_type::Val{c}
    
    function ErrorEstimationOptions{c}() where {c}
        norm_type = Val(c)
        return new(norm_type)
    end
end

function ErrorEstimationOptions(;
    norm_type = 2)

    return ErrorEstimationOptions{norm_type}()
end

function ErrorEstimationOptions(norm_type = 2)
    return ErrorEstimationOptions{norm_type}()
end




mutable struct ErrorEstimation
    current::Float64
    last::Float64
end

function ErrorEstimation(current)
    return ErrorEstimation(current, current)
end

function ErrorEstimation()
    return ErrorEstimation(0.0)
end

function update!(err_est::ErrorEstimation)
    err_est.last = err_est.current
    return err_est
end


function is_step_acceptable(err_est::ErrorEstimation)
    return is_step_acceptable(err_est.current)
end

function is_step_acceptable(err_est::T) where {T <: Number}
    return err_est <= 1.0;
end

function error_estimation(
    x_new,
    x_old,
    x_est,
    basic_options::BasicOdeOptions,
    error_estimation_options::ErrorEstimationOptions{2})

    n_dim = length(x_old)
    err_est = 0.0
    rfac    = sqrt( 1/n_dim * max( dot(x_new, x_new), dot(x_old, x_old) ) )
    for kk = 1:length(x_new)
        atol     = basic_options.abs_tol[kk]
        rtol     = basic_options.rel_tol[kk] * rfac
        scaling  = max(atol, rtol)
        tmp      = (x_new[kk] - x_est[kk]) / scaling
        err_est += tmp^2
    end
    err_est = sqrt(err_est)

    return err_est
end

function error_estimation(
    x_new,
    x_old,
    x_est,
    basic_options::BasicOdeOptions,
    error_estimation_options::ErrorEstimationOptions{Inf})

    err_est = 0.0
    for kk = 1:length(x_new)
        rfac     = max(abs(x_new[kk]), abs(x_old[kk]))
        atol     = basic_options.abs_tol[kk]
        rtol     = basic_options.rel_tol[kk] * rfac
        scaling  = max(atol, rtol)
        tmp      = abs(x_new[kk] - x_est[kk]) / scaling

        if err_est < tmp
            err_est = tmp
        end
    end

    return err_est
end