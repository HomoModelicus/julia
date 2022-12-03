


include("../src/ode_module.jl")


module control
using LinearAlgebra
using ..ode
using PyPlot
PyPlot.pygui(true)



function lqr_ode(der_q, time, q, A, B, Q, Rinv)
    # this function is assumed to be used with correct input

    # how to avoid allocations?
    (n_row, n_col) = size(A)

    P = reshape(q, n_row, n_col)

    t1  = P * A 
    t2  = A' * P
    t3  = P * B * Rinv * B' * P
    rhs = -(t1 + t2 - t3 + Q)

    # der_q[:] = reshape(rhs, n_row * n_col) # rhs[:]
    for ii in eachindex(rhs)
        der_q[ii] = rhs[ii]
    end

    return der_q
end


function create_lqr_ode(A, B, Q, R)
    (n_row, n_col) = size(A)
    if n_row != n_col
        error("Only matrix is accepted for A")
    end
    q_init = reshape(Matrix{Float64}(I, n_row, n_col), n_row * n_col)
    Rinv = inv(R)

    ode_fcn(der_q, time, q) = lqr_ode(der_q, time, q, A, B, Q, Rinv)
    return (ode_fcn, q_init, Rinv)

end


function create_kalman_filter_ode(A, C, Cov_sys, Cov_meas)
    # steady state
    (n_row, n_col) = size(A)
    if n_row != n_col
        error("Only matrix is accepted for A")
    end
    q_init = reshape(Matrix{Float64}(I, n_row, n_col), n_row * n_col)

    At = A'
    Ct = C'
    Cov_meas_inv = inv(Cov_meas)
    ode_fcn(der_q, time, q) = lqr_ode(der_q, time, q, At, Ct, Cov_sys, Cov_meas_inv)
    return (ode_fcn, q_init, Cov_meas_inv)

end


function solve_lqr_ode(ode_fcn, q_init, final_time;
    ode_solver = ode.Tsitouras45(),
    basic_options = ode.BasicOdeOptions(
        length(q_init);
        abs_tol = 1e-9,
        rel_tol = 1e-9,
        max_iter = 1_000_000),
    step_size_controller = ode.ClassicalStepSizeControl(),
    stepper_options = ode.StepperOptions(;
        max_step_size = 0.1)
    )

    time_interval = ode.TimeInterval(final_time, 0.0)

    ode_problem = ode.OdeProblem(
        ode_fcn,
        time_interval,
        q_init)

    (ode_res, step_stat) = ode.solve(
        ode_problem,
        ode_solver;
        basic_options        = basic_options,
        step_size_controller = step_size_controller,
        stepper_options      = stepper_options) 

    return (ode_res, step_stat)
end





end


module ktest
using ..control
using LinearAlgebra

m = 1.0
M = 5.0
L = 2.0
g = -10.0
d = 1.0

b = -1.0 # 1 for up

A = [
    0   1                       0                               0; 
    0   -g/M                    b * m*g/M                       0;
    0   0                       0                               1;
    0   -b * d / (M * L)        -b * (m + M) * g / (M * L)      0]

B = [0; 1/M; 0; b / (M*L)]

n_dim = 4
Q = Matrix{Float64}(I, n_dim, n_dim)
R = Matrix{Float64}(I * 0.0001, 1, 1)

final_time = 35.0


(ode_fcn, q_init, Rinv) = control.create_lqr_ode(A, B, Q, R)
(ode_res, step_stat) = control.solve_lqr_ode(ode_fcn, q_init, final_time)

q_final = ode_res.q.data[:, ode_res.q.ptr]
P = reshape(q_final, n_dim, n_dim)

K_lqr = Rinv * B' * P # gain matrix


C = [1.0    0   0   0]

Cov_sys  = Matrix{Float64}(I * 1.0, n_dim, n_dim)
Cov_meas = Matrix{Float64}(I * 1.0, 1, 1)
(steady_kalman_filter_ode, q_init, Cov_meas_inv) = control.create_kalman_filter_ode(A, C, Cov_sys, Cov_meas)


(kalman_ode_res, kalman_step_stat) = control.solve_lqr_ode(
    steady_kalman_filter_ode,
    q_init,
    final_time)

y_final = kalman_ode_res.q.data[:, kalman_ode_res.q.ptr]
Y = reshape(y_final, n_dim, n_dim)
K_kalmanfilter = Y * C' * Cov_meas


end