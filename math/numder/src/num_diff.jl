
function step_size(x0, zero_tol = 1e-15)
    #=
    if abs(x0) <= zero_tol
        x0 = copysign(zero_tol, x0)
    end
    =#
    h = sqrt( eps(x0) )
    return h
end

function step_size_cbrt(x0, zero_tol = 1e-15)
    #=
    if abs(x0) <= zero_tol
        x0 = copysign(zero_tol, x0)
    end
    =#
    h = cbrt( eps(x0) )
    return h
end



function numdiff_fw(f, x0)
    # f: R -> R
    #=
    h = step_size(x0)
    x1 = x0 + h
    f0 = f(x0)
    f1 = f(x1)
    g = (f1 - f0) / h
    return g
    =#
    h = step_size(x0)
    numdiff_fw(f, x0, h)
end

function numdiff_fw(f, x0, h)
    # f: R -> R
    f0 = f(x0)
    numdiff_fw(f, x0, h, f0)
end

function numdiff_fw(f, x0, h, f0)
    # f: R -> R
    x1 = x0 + h
    f1 = f(x1)
    g = (f1 - f0) / h
end



function numdiff_bw(f, x0)
    # f: R -> R
     #=
    h = step_size(x0)
    x1 = x0 - h
    f0 = f(x0)
    f1 = f(x1)
    g = (f0 - f1) / h
    =#
    h = step_size(x0)
    numdiff_bw(f, x0, h)
end

function numdiff_bw(f, x0, h)
    f0 = f(x0)
    numdiff_bw(f, x0, h, f0)
end

function numdiff_bw(f, x0, h, f0)
    x1 = x0 - h
    f1 = f(x1)
    g = (f0 - f1) / h
end

function numdiff_central(f, x0)
    # f: R -> R
    h = step_size_cbrt(x0)
    xm1 = x0 - h
    xp1 = x0 + h
    fm1 = f(xm1)
    fp1 = f(xp1)
    g = (fp1 - fm1) / (2*h)
    return g
end


function gradient_fw(f, x0)
    # f: R^n -> R
    # g_i = df / dx_i
    h = step_size.(x0)
    return gradient_fw(f, x0, h)
end

function gradient_fw(f, x0, h)
    # f: R^n -> R
    # g_i = df / dx_i
    f0 = f(x0)
    return gradient_fw(f, x0, h, f0)
end

function gradient_fw(f, x0, h, f0)
    # f: R^n -> R
    # g_i = df / dx_i
    g = similar(x0)
    x1 = copy(x0)
    for kk = 1:length(x0)
        x1[kk] += h[kk] 
        f1 = f(x1)
        g[kk] = (f1 - f0) / h[kk] 
        x1[kk] -= h[kk] 
    end
    return g
end


function directional_diff_fw(f, x0, d)
    h = step_size( norm(d) )
    return directional_diff_fw(f, x0, d, h)
end

function directional_diff_fw(f, x0, d, h)
    f0 = f(x0)
    return directional_diff_fw(f, x0, d, h, f0)
end

function directional_diff_fw(f, x0, d, h, f0)

    g = zero(eltype(x0))
    
    x1 = x0 + d * h
    f1 = f(x1)

    g = (f1 - f0) / h

    return g
end


function jacobian_fw(f, x0)
    # f: R^n -> R^m
    # g_ij = df_i / dx_j

    h = step_size.(x0)  # n-by-1
    return jacobian_fw(f, x0, h)
end

function jacobian_fw(f, x0, h)
    # f: R^n -> R^m
    # g_ij = df_i / dx_j

    f0 = f(x0)                  # m-by-1
    return jacobian_fw(f, x0, h, f0)   # m-by-n
end

function jacobian_fw(f, x0, h, f0)
    # f: R^n -> R^m
    # g_ij = df_i / dx_j

    jac = zeros(eltype(f0), length(f0), length(x0)) # m-by-n
    x1 = copy(x0)
    for kk = 1:length(x0)
        x1[kk] += h[kk] 
        f1 = f(x1)
        jac[:, kk] = (f1 .- f0) ./ h[kk]
        x1[kk] -= h[kk] 
    end
    return jac
end


function jacobian_fw!(jac, f, x0)
    # f: R^n -> R^m
    # g_ij = df_i / dx_j

    h = step_size.(x0)  # n-by-1
    return jacobian_fw!(jac, f, x0, h)
end

function jacobian_fw!(jac, f, x0, h)
    # f: R^n -> R^m
    # g_ij = df_i / dx_j

    f0 = f(x0)                  # m-by-1
    return jacobian_fw!(jac, f, x0, h, f0)   # m-by-n
end

function jacobian_fw!(jac, f, x0, h, f0)
    # f: R^n -> R^m
    # g_ij = df_i / dx_j

    f1 = similar(f0)
    x1 = copy(x0)
    for kk = 1:length(x0)
        x1[kk]     += h[kk] 
        f1         .= f(x1)
        jac[:, kk] .= (f1 .- f0) ./ h[kk]
        x1[kk]     -= h[kk] 
    end
    return jac
end

