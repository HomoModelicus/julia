
struct HeunEuler <: AbstractAdaptiveExplicitSolver
end

function order(::HeunEuler)::Int
    return 2
end

function n_intermediates(::HeunEuler)
    return 3 # to be checked
end

function n_temporaries(::HeunEuler) 
    return 1
end

function stepper!(ode_solver::HeunEuler, ode_fcn, stepper_options, stepper_temp::StepperTemporaries)
    
    # renaming for better readability
    t          = stepper_temp.t_old;
	x          = stepper_temp.x_old;
	dt         = stepper_temp.dt;
    n_prob_dim = n_dim(stepper_temp)

    # views into the temporaries
    k1 = view(stepper_temp.der_x, 1:n_prob_dim, 1)
    k2 = view(stepper_temp.der_x, 1:n_prob_dim, 2)
    k3 = view(stepper_temp.der_x, 1:n_prob_dim, 3)

    x2 = view(stepper_temp.x_tmp, 1:n_prob_dim, 1)
	
    # intermediate steps
	t2 = t + 1 * dt
	@. x2 = x + 1 * dt * k1
	ode_fcn(k2, t2, x2)
	
    # new step
	stepper_temp.t_new    = t + dt
	@. stepper_temp.x_new = x + dt * (1/2 * k1 + 1/2 * k2)
	ode_fcn(k3, stepper_temp.t_new, stepper_temp.x_new)
	
    # error estimation
	@. stepper_temp.x_est = x + dt * 1 * k1
end

