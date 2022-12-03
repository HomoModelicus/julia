# Ros3p
# source: https://publikationsserver.tu-braunschweig.de/servlets/MCRFileNodeServlet/dbbs_derivate_00033192/Rang-Informatikbericht-2013-05.pdf


struct Ros34 <: AbstractRosenbrockSolver
end

function order(::Ros34)::Int
    return 3
end

function n_intermediates(::Ros34)
    return 6 + 3
end

function n_temporaries(::Ros34) 
    return 1
end

function stepper!(ode_solver::Ros34, ode_fcn, stepper_options, stepper_temp)
    
# source: 
# http://www.hysafe.org/science/eAcademy/docs/ACMTransactionsOnMathematicalSoftware_v8_p93to113.pdf

    # renaming for better readability
    t          = stepper_temp.t_old;
	x          = stepper_temp.x_old;
	dt         = stepper_temp.dt;
    n_prob_dim = n_dim(stepper_temp)

    # views into the temporaries
    fsal = view(stepper_temp.der_x, 1:n_prob_dim, 1)

    h_tmp = view(stepper_temp.der_x, 1:n_prob_dim, 2)
    f_tmp = view(stepper_temp.der_x, 1:n_prob_dim, 3)
    dfdt  = view(stepper_temp.der_x, 1:n_prob_dim, 4)

    offset = 4
    _k1 = view(stepper_temp.der_x, 1:n_prob_dim, 1 + offset)
    _k2 = view(stepper_temp.der_x, 1:n_prob_dim, 2 + offset)
    _k3 = view(stepper_temp.der_x, 1:n_prob_dim, 3 + offset)
    _k4 = view(stepper_temp.der_x, 1:n_prob_dim, 4 + offset)
    k5 = view(stepper_temp.der_x, 1:n_prob_dim, 5 + offset)
    x_tmp = stepper_temp.x_tmp
    J     = stepper_temp.jac

    # coeffs
    gamma = 1/2

    d1 = 1/2
    d2 = -3/2
    d3 = 121/50
    d4 = 29/250

    g21 = -4
    g31 = 186/25
    g32 = 6/5
    g41 = -56/125
    g42 = -27/125
    g43 = -1/5

    a21 = 1
    a31 = 24/25
    a32 = 3/25
    a41 = a31
    a42 = a32

    c2 = 1
    c3 = 3/5
    c4 = c3

    b1 = 98/108
    b2 = 11/72
    b3 = 25/216

    bt1 = 19/18
    bt2 = 1/4
    bt3 = 25/216
    bt4 = 125/216




    k1 = similar(x)
    k2 = similar(x)
    k3 = similar(x)
    k4 = similar(x)
    

    # calculate the derivatives
    f_q(q) = ode_fcn(x_tmp, t, q) # k2 is just a dummy
    J      = jacobian_fw!(f_q, x, J, h_tmp, f_tmp)
    f_t(t) = ode_fcn(x_tmp, t, x) # k2 is just a dummy
    dfdt   = time_numdiff_fw!(f_t, t, dfdt)
    

    # setting up the lhs matrix
    J .*= -dt * gamma
    for ii = 1:size(J,1)
        J[ii,ii] += 1.0
    end

    # LU decomposition
    luc = lu(J)

    # f1 = fsal
    f1 = similar(x)
    ode_fcn(f1, t, x)
    k1 = f1 + dt * d1 * dfdt
    k1 .= luc \ k1

    t2 = t + c2 * dt
    @. x_tmp = x + dt * a21 * k1
    ode_fcn(k2, t2, x_tmp)
    k2 = k2 + dt * d2 * dfdt + g21 * k1
    k2 .= luc \ k2

    t3 = t + c3 * dt
    @. x_tmp = x + dt * (a31 * k1 + a32 * k2)
    ode_fcn(k4, t3, x_tmp)
    k3 = k4 + dt * d3 * dfdt + (g31 * k1 + g32 * k2)
    k3 .= luc \ k3

    # f at t3, x3 the same as at t4, x4
    k4 = k4 + dt * d4 * dfdt + (g41 * k1 + g42 * k2 + g43 * k3)
    k4 .= luc \ k4

    # new step
	stepper_temp.t_new    = t + dt
	@. stepper_temp.x_new = x + dt * (b1 * k1 + b2 * k2 + b3 * k3)
	ode_fcn(k5, stepper_temp.t_new, stepper_temp.x_new)
	
    # error estimation
	@. stepper_temp.x_est = x + dt * (bt1 * k1 + bt2 * k2 + bt3 * k3 + bt4 * k4)


end


#=


    # setting up the lhs matrix
    J .*= -1.0
    for ii = 1:size(J,1)
        J[ii,ii] += 1.0 / (dt * gamma)
    end

    # LU decomposition
    luc = lu(J)

    igh = 1 / (gamma * dt)

    f1 = fsal
    @. k1 = f1 * igh + d1 / gamma * dfdt
    k1 .= luc \ k1

    t2 = t + c2 * dt
    @. x_tmp = x + dt * a21 * k1
    ode_fcn(k2, t2, x_tmp)
    @. k2 = k2 * igh + d2 / gamma * dfdt + g21 * k1 / (gamma * dt)
    k2 .= luc \ k2

    t3 = t + c3 * dt
    @. x_tmp = x + dt * (a31 * k1 + a32 * k2)
    ode_fcn(k4, t3, x_tmp)
    @. k3 = k4 * igh + d3 / gamma * dfdt + (g31 * k1 + g32 * k2) / (gamma * dt)
    k3 .= luc \ k3

    # f at t3, x3 the same as at t4, x4
    @. k4 = k4 * igh + d4 / gamma * dfdt + (g41 * k1 + g42 * k2 + g43 * k3) / (gamma * dt)
    k4 .= luc \ k4

    # new step
	stepper_temp.t_new    = t + dt
	@. stepper_temp.x_new = x + dt * (b1 * k1 + b2 * k2 + b3 * k3)
	ode_fcn(k5, stepper_temp.t_new, stepper_temp.x_new)
	
    # error estimation
	@. stepper_temp.x_est = x + dt * (bt1 * k1 + bt2 * k2 + bt3 * k3 + bt4 * k4)


=#






#=

VecDoub ytemp(n),dydxnew(n);
Int i;
Doub xph = x + h;
for (i=0;i<n;i++)
{ 
	for (Int j=0;j<n;j++)
	{
		a[i][j] = -dfdy[i][j];
		a[i][i] += 1.0/(gam*h);
	}
}


what is k is actually g

gam
F = lu(M)


ytemp = dydx + h * d1 * dfdx;
k1    = F \ ytemp


ytemp = y + a21 * k1;
ode_fcn(dydxnew, x + c2 * h, ytemp);
ytemp = dydxnew + h * d2 * dfdx + c21 * k1 / h;
k2    = F \ ytemp


ytemp = y + a31 * k1 + a32 * k2;
ode_fcn(dydxnew, x + c3 * h, ytemp);
ytemp = dydxnew + h * d3 * dfdx + (c31 * k1 + c32 * k2) / h;
k3    = F \ ytemp

ytemp = y + a41 * k1 + a42 * k2 + a43 * k3;
ode_fcn(dydxnew, x + c4 * h, ytemp);
ytemp = dydxnew + h * d4 * dfdx + (c41 * k1 + c42 * k2 + c43 * k3) / h;
k4    = F \ ytemp


ytemp = y + a51 * k1 + a52 * k2 + a53 * k3 + a54 * k4;
ode_fcn(dydxnew, x+h, ytemp);
k6    = dydxnew + (c51 * k1 + c52 * k2 + c53 * k3 + c54 * k4) / h;
k5    = F \ k6


ytemp += k5;
ode_fcn(dydxnew, x + h, ytemp);
k6 = dydxnew + (c61 * k1 + c62 * k2 + c63 * k3 + c64 * k4 + c65 * k5) / h;
	

yerr = F \ k6

yout = ytemp + yerr;

=#

#=
function stepper!(ode_solver::Tsitouras45, ode_fcn, stepper_temp::StepperTemporaries)
    
    # renaming for better readability
    t          = stepper_temp.t_old;
	x          = stepper_temp.x_old;
	dt         = stepper_temp.dt;
    n_prob_dim = n_dim(stepper_temp)

    # views into the temporaries
    fsal = view(stepper_temp.der_x, 1:n_prob_dim, 1)
    g1 = view(stepper_temp.der_x, 1:n_prob_dim, 1+1)
    g2 = view(stepper_temp.der_x, 1:n_prob_dim, 2+1)
    g3 = view(stepper_temp.der_x, 1:n_prob_dim, 3+1)
    g4 = view(stepper_temp.der_x, 1:n_prob_dim, 4+1)
    k5 = view(stepper_temp.der_x, 1:n_prob_dim, 5+1)
    k6 = view(stepper_temp.der_x, 1:n_prob_dim, 6+1)
    k7 = view(stepper_temp.der_x, 1:n_prob_dim, 7+1)

    x_tmp = view(stepper_temp.x_tmp, 1:n_prob_dim, 1)
        
    # coeffs of the time derivatives dfdt
    d1=  0.25
    d2= -0.1043
    d3=  0.1035
    d4= -0.0362

    # coeffs of the intermediate time steps
    c2 = 0.386
    c3 = 0.21
    c4 = 0.63
    
    gamma = 0.25


    # calculate the derivatives
    f_q(q) = ode_fcn(g2, t, q) # g2 is just a dummy
    J      = numder.jacobian_fw(f_q, x)
    f_t(t) = ode_fcn(g2, t, x) # g2 is just a dummy
    dfdt   = numdiff_fw(f_t, t)

    # setting up the lhs matrix
    M = -J
    for ii = 1:size(M,1)
        M[ii,ii] += 1.0 / (dt * gamma)
    end

    # https://github.com/SciML/OrdinaryDiffEq.jl/blob/master/src/tableaus/rosenbrock_tableaus.jl


    # LU decomposition
    luc = lu(M)

    g1 .= fsal + dt * d1 * dfdt
    g1 .= luc \ g1

    @. x_tmp = x + a21 * g1
    t2       = t + c2 * dt
    ode_fcn(g2, t2, x_tmp)
    @. x_tmp = g2 + dt * d2 * dfdt + c21 * g1 / dt
    g2      .= luc \ x_tmp

    @. x_tmp = x + a31 * g1 + a32 * g2
    t3       = t + c3 * dt
    ode_fcn(g3, t3, x_tmp)
    @. x_tmp = g3 + dt * d3 * dfdt + (c31 * g1 + c32 * g2) / dt
    g3      .= luc \ x_tmp

    @. x_tmp = x + a41 * g1 + a42 * g2 + a43 * g3
    t4       = t + c4 * dt
    ode_fcn(g4, t4, x_tmp)
    @. x_tmp = g4 + dt * d4 * dfdt + (c41 * g1 + c42 * g2 + c43 * g3) / dt
    g4      .= luc \ x_tmp

    @. x_tmp = x + a51 * g1 + a52 * g2 + a53 * g3 + a54 * g4
    t_new    = t + dt
    ode_fcn(g5, t_new, x_tmp)
    @. x_tmp = g5 + (c51 * g1 + c52 * g2 + c53 * g3 + c54 * g4) / dt
    g5      .= luc \ x_tmp


    ytemp += k5
    ode_fcn(dydxnew, t_new, ytemp)
    k6 = dydxnew + (c61 * g1 + c62 * g2 + c63 * g3 + c64 * g4 + c65 * k5) / dt
        

    yerr = luc \ k6

    yout = ytemp + yerr





    
    	
    # intermediate steps
	t2 = t + c2 * dt
    @. x2 = x + dt * a21 * g1
    ode_fcn(g2, t2, x2)

    t3 = t + c3 * dt
    @. x3 = x + dt * (a31 * g1 + a32 * g2)
	ode_fcn(g3, t3, x3)

    t4 = t + c4 * dt
    @. x4 = x + dt * (a41 * g1 + a42 * g2 + a43 * g3)
	ode_fcn(g4, t4, x4)

    t5 = t + c5 * dt
    @. x5 = x + dt * (a51 * g1 + a52 * g2 + a53 * g3 + a54 * g4)
    ode_fcn(k5, t5, x5)

    t6 = t + c6 * dt
    @. x6 = x + dt * (a61 * g1 + a62 * g2 + a63 * g3 + a64 * g4 + a65 * k5)
    ode_fcn(k6, t6, x6)

    # new step
	stepper_temp.t_new    = t + dt
	@. stepper_temp.x_new = x + dt * (b1 * g1 + b2 * g2 + b3 * g3)
	ode_fcn(k7, stepper_temp.t_new, stepper_temp.x_new)
	
    # error estimation
	@. stepper_temp.x_est = x + dt * (bt1 * g1 + bt2 * g2 + bt3 * g3)

        
end
=#
