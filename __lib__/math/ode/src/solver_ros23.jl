

# source:
# https://www.mathworks.com/help/pdf_doc/otherdocs/ode_suite.pdf


struct Ros23 <: AbstractRosenbrockSolver
end

function order(::Ros23)::Int
    return 2
end

function n_intermediates(::Ros23)
    return 3
end

function n_temporaries(::Ros23) 
    return 3 + 4
end

function stepper!(ode_solver::Ros23, ode_fcn, basic_options::BasicOdeOptions, stepper_temp)

    # renaming for better readability
    t          = stepper_temp.t_old;
	x          = stepper_temp.x_old;
	dt         = stepper_temp.dt;
    n_prob_dim = n_dim(stepper_temp)

    # constants
    d = 1 / (2 + sqrt(2))
    e32 = 6 + sqrt(2)

    # inherent variables:
    J    = stepper_temp.jac # zeros(n_dim, n_dim)
    dfdt = stepper_temp.dfdt

    # temporaries
    # maximally 4 temporaries are needed

    k1 = view( stepper_temp.der_x, 1:n_prob_dim, 1 )
    k2 = view( stepper_temp.der_x, 1:n_prob_dim, 2 )
    k3 = view( stepper_temp.der_x, 1:n_prob_dim, 3 ) 
    
    f0 = view( stepper_temp.tmp, 1:n_prob_dim, 1 )  # f0 = similar(x)
    f1 = view( stepper_temp.tmp, 1:n_prob_dim, 2 )  # f1 = similar(x)
    f2 = view( stepper_temp.tmp, 1:n_prob_dim, 3 )  # f2 = similar(x)
    
    f1_dt   = view( stepper_temp.tmp, 1:n_prob_dim, 4 )
    h       = view( stepper_temp.tmp, 1:n_prob_dim, 5 )
    dfdq1   = view( stepper_temp.tmp, 1:n_prob_dim, 6 )
    dfdq2   = view( stepper_temp.tmp, 1:n_prob_dim, 7 )
    x_step  = stepper_temp.x_tmp
    

    # reusable temporary, but is needed one down there
    rhs   = view( stepper_temp.tmp, 1:n_prob_dim, 7 ) # similar(x) 
    x_tmp = stepper_temp.x_tmp # similar(x)


    copy!(x_tmp, x)
    copy!(x_step, x)

    # derivatives
    ode_fcn(f0, t, x)
    
    # this needs h, x_step, dfdq1, dfdq2 -> 4 temporaries
    # inherent: J
    J    = numjac!(basic_options, ode_fcn, t, x, h, x_step, dfdq1, dfdq2, J)
    # temporary: f1_dt
    # inherent: dfdt
    dfdt = numder!(basic_options, ode_fcn, t, dt, x, f0, f1_dt, dfdt)

    # lu decomposition
    J .*= -d * dt
    for ii = 1:n_prob_dim
        J[ii, ii] += 1.0
    end
    luc = lu(J)


    # stages
    @. rhs = f0 + dt * d * dfdt
    k1 .= luc \ rhs

    @. x_tmp = x + dt * 0.5 * k1
    t1      = t + 0.5 * dt
    ode_fcn(f1, t1, x_tmp)
    @. rhs = f1 - k1
    k2  .= (luc \ rhs) + k1
    

    # new step
    stepper_temp.x_new = x + dt * k2
    stepper_temp.t_new = t + dt


    ode_fcn(f2, stepper_temp.t_new, stepper_temp.x_new)
    @. rhs = f2 - e32 * (k2 - f1) - 2 * (k1 - f0) + dt * d * dfdt
    k3 .= luc \ rhs

    # error estimation
    stepper_temp.x_est = stepper_temp.x_new + dt / 6 * (k1 - 2 * k2 + k3)

end


function numder!(basic_options, ode_fcn, t, dt, x, f0, f1_dt, dfdt)
    # h = sqrt(eps(abs(t)))
    h = 0.1 * dt
    ode_fcn(f1_dt, t + h, x)
    @. dfdt = (f1_dt - f0) / h
    return dfdt
end

function numjac!(basic_options, ode_fcn, t, x,
    h, x_step, dfdq1, dfdq2, J)

    n_dim = length(x)
    h .= basic_options.rel_tol .* abs.(x) .+ basic_options.abs_tol

    for ii = 1:n_dim
        
        x_step[ii] += h[ii]/2
        ode_fcn(dfdq2, t, x_step)
        
        x_step[ii] -= h[ii]
        ode_fcn(dfdq1, t, x_step)

        x_step[ii] += h[ii]/2

        J[:,ii] = (dfdq2 - dfdq1) ./ h[ii]
    end

    return J
end


#=
function numjac!(ode_fcn, t, x, f0, J, x1, f1)

    n = length(x)
    hs = 10 .* sqrt.(eps.(abs.(x)))

    for ii = 1:n
        x1[ii] += hs[ii]
        ode_fcn(f1, t, x1)
        J[:,ii] = (f1 - f0) ./ hs[ii]
        x1[ii] -= hs[ii]
    end

    return J
end
=#

