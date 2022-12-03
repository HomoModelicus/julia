
include("../../../opti/src/opti_module.jl")


module noisydiff
using ..opti
using LinearAlgebra

function pt1_smooth(t, input_signal; T = 1)
    # trapezoidal rule

    L = length(input_signal)
    y = zeros(L)

    y[1] = input_signal[1]

    for kk = 2:L
        dt = t[kk] - t[kk-1]
        f = dt / (2 * T + dt) # 2 * T / dt + 1
        y[kk] = (input_signal[kk] + input_signal[kk-1] - y[kk-1]) * f + y[kk-1] * 2 * T / (dt + 2 * T)
    end

    return y
end



function diff_sliding_least_squares_d1(t, y; w = 5)
# fitting a degree 1 polynomial in the window and return the derivative

    N = length(y)
    u = zeros(N-w)
    
    yv = view(y, 1:w)
    xv = view(t, 1:w)
    U1 = sum(yv)
    U2 = sum(yv .* xv)
    S1 = sum(xv)
    S2 = sum(xv.^2)
    jj = 0

    for ii = (w+1):N
        jj    += 1
        
        d     = w * S2 - S1^2
        a1    = (U2 * w - S1 * U1) / d
        u[jj] = a1
        
        x_old   = t[ii-w]
        x_new   = t[ii]
        y_old   = y[ii-w]
        y_new   = y[ii]
        S1      += x_new - x_old 
        S2      += x_new^2 - x_old^2
        U1      += y_new - y_old
        U2      += y_new * x_new - y_old * x_old
        
    end
    return u
end

function diff_sliding_least_squares_d3(t, y; w = 7)
    # fitting a degree 1 polynomial in the window and return the derivative

    N = length(y)
    u = zeros(N-w)
    
    yv = view(y, 1:w)
    xv = view(t, 1:w)
    U1 = sum(yv)
    U2 = sum(yv .* xv)
    U3 = sum(yv .* xv.^2)
    U4 = sum(yv .* xv.^3)
    
    S1 = sum(xv)
    S2 = sum(xv.^2)
    S3 = sum(xv.^3)
    S4 = sum(xv.^4)
    S5 = sum(xv.^5)
    S6 = sum(xv.^6)
    M = zeros(4, 4)
    b = zeros(4)
    jj = 0
    for ii = (w+1):N
        jj    += 1
        
        M[1,1] = w
        M[1,2] = S1
        M[1,3] = S2
        M[1,4] = S3
        
        M[2,2] = S2
        M[2,3] = S3
        M[2,4] = S4
        M[3,3] = S4
        M[3,4] = S5
        
        M[4,4] = S6
        b[1] = U1
        b[2] = U2
        b[3] = U3
        b[4] = U4
        
        S = Symmetric(M, :U)
        a = S \ b # todo : replace it with inplace operations
        
        x_old   = t[ii-w]
        x_new   = t[ii]
        y_old   = y[ii-w]
        y_new   = y[ii]
        
        u[jj] = a[2] + 2 * a[3] * x_new + 3 * a[4] * x_new^2
        
        S1      += x_new - x_old
        S2      += x_new^2 - x_old^2
        S3      += x_new^3 - x_old^3
        S4      += x_new^4 - x_old^4
        S5      += x_new^5 - x_old^5
        S6      += x_new^6 - x_old^6
        U1      += y_new - y_old
        U2      += y_new * x_new - y_old * x_old
        U3      += y_new * x_new^2 - y_old * x_old^2
        U4      += y_new * x_new^3 - y_old * x_old^3
            
    end
    return u
end

# function diff_tikhonov(t, y; w = 5, lamda = 0.1)
#     Ma = zeros(w, w)
#     Md = zeros(w, w)

#     N = length(t)
#     u = zeros(N)

#     for ii = (w+1):N
        
#         A = Ma + lamda * Md

#     end

#     return u
# end


function diff_fw(t, y)
    dt = diff(t)
    dy = diff(y)
    dy ./= dt
    return dy
end

function cumtrapezoidal(t, y)
    dt = diff(t)
    N = length(y)
    v1 = view(y, 1:N-1)
    v2 = view(y, 2:N)
    ys = v1 .+ v2
    ints = [0.0; 0.5 .* dt .* ys]
    ints = cumsum(ints)
    return ints
end



function tvd(t, y; lamda = 0.1, tol_options = opti.ToleranceOptions())

    # u0 = rand(length(y)) # copy(y)
    t_min = t[1]
    t_max = t[end]
    T = (t_max - t_min) / 100
    y_pred = pt1_smooth(t, y; T = T)
    u0 = [0.0; diff_fw(t, y_pred)]

    obj_fcn(u) = __obj_fcn(t, y, lamda, u)
    # stat = opti.cg_pr(obj_fcn, u0; tol_options = tol_options)
    (x_sol, y_sol, iter, stopping_crit) = opti.quasi_newton(obj_fcn, u0; tol_options = tol_options)
    return (x_sol, y_sol, iter, stopping_crit)
end

function __obj_fcn(t, y, lamda, u)
    i1 = __integral_1(u)
    i2 = __integral_2(t, y, u)
    return lamda * i1 + i2
end


function __integral_1(u)
    N = length(u)
    abs_du = 0.0
    @inbounds for kk = 1:(N-1)
        du = u[kk+1] - u[kk]
        abs_du += abs(du)
    end
    return abs_du / N
end

function __integral_2(t, y, u)
    N = length(y)
    
    # dt = diff(t)

    # vu1 = view(u, 1:N-1)
    # vu2 = view(u, 2:N)
    
    # int_u =[y[1]; 0.5 .* dt .* (vu1 .+ vu2)]
    # y_pred = cumsum(int_u)
    # g = (y_pred - y).^2
    # i1 = dt[1] * g[1]
    # iN = dt[end] * g[end]
    
    # ibulk = 0.0
    # for kk = 2:N-1
    #     ibulk += g[kk] * (dt[kk] + dt[kk-1])
    # end
    # ibulk += i1
    # ibulk += iN

    ibulk = 0.0
    y_pred = y[1]
    dt = t[2] - t[1]
    
    @inbounds for kk = 2:N-1
        dt1     = t[kk] - t[kk-1]
        us      = u[kk] + u[kk-1]
        int_u   = 0.5 * dt * us
        y_pred  += int_u
        g       = (y_pred - y[kk]).^2
        ibulk   += g * (dt + dt1)
        dt      = dt1
    end
    
    dt = t[N] - t[N-1]
    int_u = 0.5 * dt * (u[N] + u[N-1])
    y_pred += int_u
    g = (y_pred - y[N]).^2
    iN = dt * g
    # ibulk += i1
    ibulk += iN


    return ibulk
end



end