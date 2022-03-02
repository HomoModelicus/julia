

# dormand prince
struct DormandPrince45 <: AbstractAdaptiveExplicitSolver
end

function order(::DormandPrince45)::Int
    return 5
end

function n_intermediates(::DormandPrince45)
    return 7 # to be checked
end

function n_temporaries(::DormandPrince45) 
    return 5
end

function stepper!(ode_solver::DormandPrince45, ode_fcn, stepper_options, stepper_temp::StepperTemporaries)
    
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
    k5 = view(stepper_temp.der_x, 1:n_prob_dim, 5)
    k6 = view(stepper_temp.der_x, 1:n_prob_dim, 6)
    k7 = view(stepper_temp.der_x, 1:n_prob_dim, 7)

    x2 = view(stepper_temp.x_tmp, 1:n_prob_dim, 1)
    x3 = view(stepper_temp.x_tmp, 1:n_prob_dim, 2)
    x4 = view(stepper_temp.x_tmp, 1:n_prob_dim, 3)
    x5 = view(stepper_temp.x_tmp, 1:n_prob_dim, 4)
    x6 = view(stepper_temp.x_tmp, 1:n_prob_dim, 5)
    
	
    # intermediate steps
	t2 = t + 1/5 * dt
    @. x2 = x + 1/5 * dt * k1
    ode_fcn(k2, t2, x2)

    t3 = t + 3/10 * dt
    @. x3 = x + dt * (3/40 * k1 + 9/40 * k2)
	ode_fcn(k3, t3, x3)

    t4 = t + 4/5 * dt
    @. x4 = x + dt * (44/45 * k1 - 56/15 * k2 + 32/9 * k3)
	ode_fcn(k4, t4, x4)

    t5 = t + 8/9 * dt
    @. x5 = x + dt * (19372/6561 * k1 - 25360/2187 * k2 + 64448/6561 * k3 - 212/729 * k4)
    ode_fcn(k5, t5, x5)

    t6 = t + dt
    @. x6 = x + dt * (9017/3168 * k1 -355/33 * k2 + 46732/5247 * k3 + 49/176 * k4 - 5103/18656 * k5)
    ode_fcn(k6, t6, x6)

    # new step
	stepper_temp.t_new    = t + dt
	@. stepper_temp.x_new = x + dt * (35/384*k1 + 500/1113 * k3 + 125/192 * k4 - 2187/6784* k5 + 11/84 * k6)
	ode_fcn(k7, stepper_temp.t_new, stepper_temp.x_new)
	
    # error estimation
	@. stepper_temp.x_est = x + dt * (5179/57600 * k1 + 7571/16695 * k3 + 393/640 * k4 - 92097/339200 * k5 + 187/2100 * k6 + 1/40 * k7)

end

