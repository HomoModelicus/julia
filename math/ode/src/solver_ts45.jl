

# Tsitouras
struct Tsitouras45 <: AbstractAdaptiveExplicitSolver
end

function order(::Tsitouras45)::Int
    return 5 # ??? or just 5
end

function n_intermediates(::Tsitouras45)
    return 7 # to be checked
end

function n_temporaries(::Tsitouras45) 
    return 1
end

function stepper!(ode_solver::Tsitouras45, ode_fcn, stepper_options, stepper_temp::StepperTemporaries)
    
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

    x_tmp = view(stepper_temp.x_tmp, 1:n_prob_dim, 1)

    # x2 = view(stepper_temp.x_tmp, 1:n_prob_dim, 1)
    # x3 = view(stepper_temp.x_tmp, 1:n_prob_dim, 2)
    # x4 = view(stepper_temp.x_tmp, 1:n_prob_dim, 3)
    # x5 = view(stepper_temp.x_tmp, 1:n_prob_dim, 4)
    # x6 = view(stepper_temp.x_tmp, 1:n_prob_dim, 5)
        
        
    # older paper: this works
    # https://www.researchgate.net/publication/251743368_Runge-Kutta_Pairs_of_Orders_54_using_the_Minimal_Set_of_Simplifying_Assumptions
    c2 = 0.231572163526079
    c3 = 0.212252555252816
    c4 = 0.596693497318054
    c5 = 0.797009955708112
    c6 = 1

    b1 = 0.091937670648056
    b2 = 1.156529958312496
    b3 = -0.781330409541651
    b4 = 0.197624776163019
    b5 = 0.271639883438847
    b6 = 0.063598120979232

    bt1 = 0.092167469090589
    bt2 = 1.131750860603267
    bt3 = -0.759749304413104
    bt4 = 0.205573577541223
    bt5 = 0.264767065074229
    bt6 = 0.040490332103796
    bt7 = 1 / 40


    a32 = -0.059103796886580
    a42 = 4.560080615554683
    a52 = -2.443935658802774
    a62 = 9.516251378071800

    a43 = -4.006458683473722
    a53 = 2.631461258707441
    a63 = -8.467630087008555

    a54 = 0.524706566208284
    a64 = -0.987888827522473

    a65 = 0.867009765724064

    a21 = 0.231572163526079 #  c2
    a31 = 0.271356352139396 # c3 - (a32)
    a41 = 0.043071565237093434 # c4 - (a42 + a43)
    a51 = 0.08477778959516069 #  c5 - (a52 + a53 + a54)
    a61 = 0.0722577707351637 # c6 - (a62 + a63 + a64 + a65)

    #=
    c2 = 0.161
    c3 = 0.327
    c4 = 0.9
    c5 = 0.9800255409045097
    c6 = 1.0
    c7 = 1.0

    b1 = 0.09646076681806523
    b2 = 0.01
    b3 = 0.4798896504144996
    b4 = 1.379008574103742
    b5 = -3.290069515436081
    b6 = 2.324710524099774

    # original paper values
    # bt1 = 0.001780011052226
    # bt2 = 0.000816434459657
    # bt3 = -0.007880878010262
    # bt4 = 0.144711007173263
    # bt5 = -0.582357165452555
    # bt6 = 0.458082105929187
    # bt7 = 1 / 66

    # source: https://github.com/SciML/DiffEqDevTools.jl/blob/master/src/ode_tableaus.jl#L866-L920
    # the original paper values do not work
    # but I dont get where these values come from...
    bt1 = 0.09468075576583945
    bt2 = 0.009183565540343254
    bt3 = 0.4877705284247616
    bt4 = 1.2342975669304789
    bt5 = -2.707712349983525
    bt6 = 1.8666284181705870
    bt7 = 1 / 66

    # this still doesnt work
    # https://github.com/SciML/OrdinaryDiffEq.jl/blob/master/src/tableaus/low_order_rk_tableaus.jl
    # bt1 = -0.001780011052226
    # bt2 = -0.000816434459657
    # bt3 = 0.007880878010262
    # bt4 = -0.144711007173263
    # bt5 = 0.582357165452555
    # bt6 = -0.458082105929187
    # bt7 = 1 / 66


   
    a32 = 0.3354806554923570
    a42 = -6.359448489975075
    a52 = -11.74888356406283
    a62 = -12.92096931784711

    a43 = 4.362295432869581
    a53 = 7.495539342889836
    a63 = 8.159367898576159

    a54 = -0.09249506636175525
    a64 = -0.07158497328140100

    a65 = -0.02826905039406838

    a21 = 0.161
    a31 = -0.008480655492356992
    a41 = 2.8971530571054944
    a51 = 5.32586482843926
    a61 = 5.86145544294642
    
    =#    


	
    # intermediate steps
	t2 = t + c2 * dt
    # @. x2 = x + dt * a21 * k1
    @. x_tmp = x + dt * a21 * k1
    ode_fcn(k2, t2, x_tmp)

    t3 = t + c3 * dt
    # @. x3 = x + dt * (a31 * k1 + a32 * k2)
	@. x_tmp = x + dt * (a31 * k1 + a32 * k2)
    ode_fcn(k3, t3, x_tmp)

    t4 = t + c4 * dt
    # @. x4 = x + dt * (a41 * k1 + a42 * k2 + a43 * k3)
	@. x_tmp = x + dt * (a41 * k1 + a42 * k2 + a43 * k3)
    ode_fcn(k4, t4, x_tmp)

    t5 = t + c5 * dt
    # @. x5 = x + dt * (a51 * k1 + a52 * k2 + a53 * k3 + a54 * k4)
    @. x_tmp = x + dt * (a51 * k1 + a52 * k2 + a53 * k3 + a54 * k4)
    ode_fcn(k5, t5, x_tmp)

    t6 = t + c6 * dt
    # @. x6 = x + dt * (a61 * k1 + a62 * k2 + a63 * k3 + a64 * k4 + a65 * k5)
    @. x_tmp = x + dt * (a61 * k1 + a62 * k2 + a63 * k3 + a64 * k4 + a65 * k5)
    ode_fcn(k6, t6, x_tmp)

    # new step
	stepper_temp.t_new    = t + dt
	@. stepper_temp.x_new = x + dt * (b1 * k1 + b2 * k2 + b3 * k3 + b4 * k4 + b5 * k5 + b6 * k6)
	ode_fcn(k7, stepper_temp.t_new, stepper_temp.x_new)
	
    # error estimation
	@. stepper_temp.x_est = x + dt * (bt1 * k1 + bt2 * k2 + bt3 * k3 + bt4 * k4 + bt5 * k5 + bt6 * k6 + bt7 * k7)

end





