

include("../src/tenedyn_module.jl")
include("../../__lib__/math/ode/src/ode_module.jl")

module modeldef
using ..tenedyn

function create_model_pi_controller_pt1(
    setpoint_amplitude,
    setpoint_time_delay,
    ctrl_kp,
    ctrl_ki,
    ctrl_integral_init_value,
    plant_T,
    plant_integral_init_value)


    # model definition
    setpoint = tenedyn.Step(setpoint_amplitude, setpoint_time_delay)


    ctrl_minus      = tenedyn.Minus()
    ctrl_prop_gain  = tenedyn.Gain(ctrl_kp)
    ctrl_int_gain   = tenedyn.Gain(ctrl_ki)
    ctrl_plus       = tenedyn.Plus()
    ctrl_integrator = tenedyn.Integrator(ctrl_integral_init_value)


    plant_pt1_minus      = tenedyn.Minus()
    plant_pt1_mult1T     = tenedyn.Gain(1/plant_T)
    plant_pt1_integrator = tenedyn.Integrator(plant_integral_init_value)

    sensor = tenedyn.Identity()


    model = tenedyn.Model()

    # add elements to the model
    push!(model, setpoint,              "ref")                  # 1

    push!(model, ctrl_minus,            "ctrl_minus")           # 2
    push!(model, ctrl_prop_gain,        "ctrl_prop_gain")       # 3
    push!(model, ctrl_int_gain,         "ctrl_int_gain")        # 4
    push!(model, ctrl_plus,             "ctrl_plus")            # 5
    push!(model, ctrl_integrator,       "ctrl_integrator")      # 6

    push!(model, plant_pt1_minus,       "plant_pt1_minus")      # 7
    push!(model, plant_pt1_mult1T,      "plant_pt1_mult1T")     # 8
    push!(model, plant_pt1_integrator,  "plant_pt1_integrator") # 9

    push!(model, sensor,                "sensor")               # 10



    # topology
    tenedyn.connect!(model, setpoint.y,             ctrl_minus.x1)


    tenedyn.connect!(model, ctrl_minus.y,           ctrl_prop_gain.x)
    tenedyn.connect!(model, ctrl_prop_gain.y,       ctrl_plus.x1)

    tenedyn.connect!(model, ctrl_minus.y,           ctrl_int_gain.x)
    tenedyn.connect!(model, ctrl_int_gain.y,        ctrl_integrator.x)
    tenedyn.connect!(model, ctrl_integrator.y,      ctrl_plus.x2)

    tenedyn.connect!(model, ctrl_plus.y,            plant_pt1_minus.x1)
    tenedyn.connect!(model, plant_pt1_integrator.y, plant_pt1_minus.x2)

    tenedyn.connect!(model, plant_pt1_minus.y,      plant_pt1_mult1T.x)
    tenedyn.connect!(model, plant_pt1_mult1T.y,     plant_pt1_integrator.x)

    tenedyn.connect!(model, plant_pt1_integrator.y, sensor.x)
    tenedyn.connect!(model, sensor.y,               ctrl_minus.x2)

    return model
end




function create_model_pi_controller_pt2(
    setpoint_time,
    setpoint_value,
    ctrl_kp,
    ctrl_ki,
    ctrl_integral_init_value,
    plant_T,
    plat_D,
    plant_x_integral_init_value,
    plant_v_integral_init_value)


    # model definition
    # setpoint = tenedyn.Step(setpoint_amplitude, setpoint_time_delay)
    setpoint = tenedyn.Curve(setpoint_time, setpoint_value)


    ctrl_minus      = tenedyn.Minus()
    ctrl_prop_gain  = tenedyn.Gain(ctrl_kp)
    ctrl_int_gain   = tenedyn.Gain(ctrl_ki)
    ctrl_plus       = tenedyn.Plus()
    ctrl_integrator = tenedyn.Integrator(ctrl_integral_init_value)


    plant_pt2_minus      = tenedyn.Minus()
    plant_pt2_plus       = tenedyn.Plus()
    
    plant_pt2_mult1T2    = tenedyn.Gain(1/plant_T^2)
    plant_pt2_mult2D1T   = tenedyn.Gain(-2 * plat_D / plant_T)

    plant_pt2_v_integrator = tenedyn.Integrator(plant_v_integral_init_value)
    plant_pt2_x_integrator = tenedyn.Integrator(plant_x_integral_init_value)
    

    sensor = tenedyn.Identity()


    model = tenedyn.Model()

    # add elements to the model
    push!(model, setpoint,                "ref")                      # 1

    push!(model, ctrl_minus,              "ctrl_minus")               # 2
    push!(model, ctrl_prop_gain,          "ctrl_prop_gain")           # 3
    push!(model, ctrl_int_gain,           "ctrl_int_gain")            # 4
    push!(model, ctrl_plus,               "ctrl_plus")                # 5
    push!(model, ctrl_integrator,         "ctrl_integrator")          # 6

    push!(model, plant_pt2_minus,         "plant_pt2_minus")          # 7
    push!(model, plant_pt2_plus,          "plant_pt2_plus")           # 8
    push!(model, plant_pt2_mult1T2,       "plant_pt2_mult1T2")        # 9
    push!(model, plant_pt2_mult2D1T,      "plant_pt2_mult2D1T")       # 10
    push!(model, plant_pt2_v_integrator,  "plant_pt2_v_integrator")   # 11
    push!(model, plant_pt2_x_integrator,  "plant_pt2_x_integrator")   # 12

    push!(model, sensor,                  "sensor")                   # 13



    # topology
    tenedyn.connect!(model, setpoint.y,                 ctrl_minus.x1)

    tenedyn.connect!(model, ctrl_minus.y,               ctrl_prop_gain.x)
    tenedyn.connect!(model, ctrl_prop_gain.y,           ctrl_plus.x1)
    tenedyn.connect!(model, ctrl_minus.y,               ctrl_int_gain.x)
    tenedyn.connect!(model, ctrl_int_gain.y,            ctrl_integrator.x)
    tenedyn.connect!(model, ctrl_integrator.y,          ctrl_plus.x2)

    tenedyn.connect!(model, ctrl_plus.y,                plant_pt2_minus.x1)

    tenedyn.connect!(model, plant_pt2_x_integrator.y,   plant_pt2_minus.x2)
    tenedyn.connect!(model, plant_pt2_minus.y,          plant_pt2_mult1T2.x)
    tenedyn.connect!(model, plant_pt2_mult1T2.y,        plant_pt2_plus.x1)
    tenedyn.connect!(model, plant_pt2_plus.y,           plant_pt2_v_integrator.x)
    tenedyn.connect!(model, plant_pt2_v_integrator.y,   plant_pt2_mult2D1T.x)
    tenedyn.connect!(model, plant_pt2_mult2D1T.y,       plant_pt2_plus.x2)
    tenedyn.connect!(model, plant_pt2_v_integrator.y,   plant_pt2_x_integrator.x)

    tenedyn.connect!(model, plant_pt2_x_integrator.y,   sensor.x)

    tenedyn.connect!(model, sensor.y,                   ctrl_minus.x2)

    return model
end


end


module modelsim
using ..tenedyn
using ..ode
using ..modeldef

function simulate(
    ode_fcn,
    init_cond;
    time_interval = ode.TimeInterval(1.0),
    solver = ode.Tsitouras45(),
    abs_tol = 1e-5,
    rel_tol = 1e-5,
    max_iter = 1000,
    step_size_controller = ode.ClassicalStepSizeControl(),
    max_step_size = 0.1)

    ode_problem = ode.OdeProblem(
        ode_fcn,
        time_interval,
        init_cond)
    
    basic_options = ode.BasicOdeOptions(
        ode_problem;
        abs_tol = abs_tol,
        rel_tol = rel_tol,
        max_iter = max_iter)

    stepper_options = ode.StepperOptions(;
        max_step_size = max_step_size)
        
    @time (ode_res, step_stat) = ode.solve(
        ode_problem,
        solver;
        basic_options        = basic_options,
        step_size_controller = step_size_controller,
        stepper_options      = stepper_options) # 

    return (ode_res, step_stat)
end

end


module odeplot
using ..ode
using ..modelsim

using PyPlot
PyPlot.pygui(true)

function plot_ode_res(ode_res, indices = (1,))

    t = ode.time(ode_res)
    q = ode.variables(ode_res)

    L = length(indices)

    figh = PyPlot.figure()

    a1 = PyPlot.subplot(L, 1, 1)
    PyPlot.grid()
    PyPlot.plot( t, q[indices[1], :] )

    for ii = 2:L
        PyPlot.subplot(L, 1, ii, sharex = a1)
        PyPlot.grid()
        PyPlot.plot( t, q[indices[ii], :] )
    end

    return figh
end

end


module simpipeline
using ..ode
using ..tenedyn

using ..modeldef
using ..modelsim
using ..odeplot


function create_parametrized_model_pi_controller_pt1()
    # model parameters
    setpoint_amplitude  = 2.0
    setpoint_time_delay = 0.5

    ctrl_kp = 10.0
    ctrl_ki = 18.0
    ctrl_integral_init_value = 0.0

    plant_T = 0.2
    plant_integral_init_value = 0.5

    ode_fcn = tenedyn.create_ode_function_pipeline(
        modeldef.create_model_pi_controller_pt1,
        setpoint_amplitude,
        setpoint_time_delay,
        ctrl_kp,
        ctrl_ki,
        ctrl_integral_init_value,
        plant_T,
        plant_integral_init_value)

    return ode_fcn
end



function run_simulation_pt1(ode_fcn)
    
    init_cond = [0.0, 0.0]

    (ode_res, step_stat) = modelsim.simulate(
            ode_fcn,
            init_cond;
            time_interval = ode.TimeInterval(5.0),
            abs_tol = 1e-7,
            rel_tol = 1e-7,
            max_iter = 1000)

            
    @show step_stat

    odeplot.plot_ode_res(ode_res, (1,2))

    return ode_res
end





function create_parametrized_model_pi_controller_pt2()
    # model parameters
    setpoint_amplitude  = 2.0
    setpoint_time_delay = 0.5

    setpoint_time  = [0.0, 0.5, 0.501, 1.0, 3.0, 3.01, 4.0]
    setpoint_value = [0.0, 0.0, 2.0,   2.0, 5.0, 0.0,  0.0]


    ctrl_kp = 3.0
    ctrl_ki = 15.0
    ctrl_integral_init_value = 0.0


    plant_T = 0.05
    plant_D = 0.35

    plant_integral_x_init_value = 0.0
    plant_integral_y_init_value = 0.0

    ode_fcn = tenedyn.create_ode_function_pipeline(
        modeldef.create_model_pi_controller_pt2,
        setpoint_time,
        setpoint_value,
        ctrl_kp,
        ctrl_ki,
        ctrl_integral_init_value,
        plant_T,
        plant_D,
        plant_integral_x_init_value,
        plant_integral_y_init_value)
        

    return ode_fcn
end

function run_simulation_pt2(ode_fcn)
    
    init_cond = [0.0, 0.0, 1.0]

    (ode_res, step_stat) = modelsim.simulate(
            ode_fcn,
            init_cond;
            time_interval = ode.TimeInterval(15.0),
            abs_tol = 1e-6,
            rel_tol = 1e-6,
            max_iter = 10000)

            
    @show step_stat

    odeplot.plot_ode_res(ode_res, (1, 2, 3))

    return ode_res
end


# ode_fcn = create_parametrized_model_pi_controller_pt1()
# ode_res = run_simulation_pt1(ode_fcn)


ode_fcn = create_parametrized_model_pi_controller_pt2()
ode_res = run_simulation_pt2(ode_fcn)


end