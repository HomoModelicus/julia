
# bogaczki shampine
struct BogaczkiShampine23 <: AbstractAdaptiveExplicitSolver
end

function order(::BogaczkiShampine23)::Int
    return 3
end

function n_intermediates(::BogaczkiShampine23)
    return 4
end

function n_temporaries(::BogaczkiShampine23) 
    return 2
end

function stepper!(ode_solver::BogaczkiShampine23, ode_fcn, stepper_options, stepper_temp::StepperTemporaries)
    
    # renaming for better readability
    t          = stepper_temp.t_old;
    x          = stepper_temp.x_old;
    dt         = stepper_temp.dt;
    n_prob_dim = n_dim(stepper_temp)

    # views into the temporaries
    k1 = view(stepper_temp.der_x, 1:n_prob_dim, 1)
    k2 = view(stepper_temp.der_x, 1:n_prob_dim, 2)
    k3 = view(stepper_temp.der_x, 1:n_prob_dim, 3)
    k4 = view(stepper_temp.der_x, 1:n_prob_dim, 4)

    x2 = view(stepper_temp.x_tmp, 1:n_prob_dim, 1)
    x3 = view(stepper_temp.x_tmp, 1:n_prob_dim, 2)
    
    # intermediate steps
    t2 = t + 1/2 * dt
    @. x2 = x + 1/2 * dt * k1
    ode_fcn(k2, t2, x2)
    
    t3 = t + 3/4 * dt
    @. x3 = x + 3/4 * dt * k2
    ode_fcn(k3, t3, x3)
    
    # new step
    stepper_temp.t_new = t + dt
    @. stepper_temp.x_new = x + dt * (2/9 * k1 + 1/3 * k2 + 4/9 * k3)
    ode_fcn(k4, stepper_temp.t_new, stepper_temp.x_new)
    
    # error estimation
    @. stepper_temp.x_est = x + dt * (7/24 * k1 + 1/4 * k2 + 1/3 * k3 + 1/8 * k4)
end


