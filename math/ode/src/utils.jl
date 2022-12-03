
function step_size(x0)
    h = sqrt.( eps.( abs.(x0) ) )
    return h
end

function jacobian_fw!(ode_fcn, x0, jac::Matrix, h_tmp, f_tmp)
    # f: R^n -> R^m
    # g_ij = df_i / dx_j

    h_tmp .= sqrt.( eps.( abs.(x0) ) ) # n-by-1
    return jacobian_fw!(ode_fcn, x0, h_tmp, jac, f_tmp)
end

function jacobian_fw!(ode_fcn, x0, h, jac::Matrix, f_tmp)
    # f: R^n -> R^m
    # g_ij = df_i / dx_j

    f0    = ode_fcn(x0)                  # m-by-1
    copyto!(f_tmp, f0)
    return jacobian_fw!(ode_fcn, x0, h, f_tmp, jac)   # m-by-n
end

function jacobian_fw!(ode_fcn, x0, h, f0, jac::Matrix)
    # f: R^n -> R^m
    # g_ij = df_i / dx_j

    x1 = copy(x0)
    for kk = 1:length(x0)
        x1[kk]     += h[kk] 
        f1          = ode_fcn(x1)
        jac[:, kk]  = (f1 .- f0) ./ h[kk]
        x1[kk]     -= h[kk] 
    end
    return jac
end



function time_numdiff_fw!(ode_fcn, t0, dfdt_tmp)
    h = sqrt(eps(abs(t0)))
    return time_numdiff_fw!(ode_fcn, t0, h, dfdt_tmp)
end

function time_numdiff_fw!(ode_fcn, t0, h, dfdt_tmp)
    f0 = ode_fcn(t0)
    return time_numdiff_fw!(ode_fcn, t0, h, f0, dfdt_tmp)
end

function time_numdiff_fw!(ode_fcn, t0, h, f0, dfdt_tmp)
    f1 = ode_fcn(t0 + h)
    dfdt_tmp .= (f1 .- f0) ./ h
    return dfdt_tmp
end

