
include("../src/tenedyn_module.jl")
include("../../__lib__/math/ode/src/ode_module.jl")

module ttest
using ..tenedyn
using ..datastructs
using ..ode
using PyPlot
PyPlot.pygui(true)


struct OdeParams_PiPt1

    setpoint_amplitude::Float64
    setpoint_time_delay::Float64
    ctrl_kp::Float64
    ctrl_ki::Float64
    ctrl_integral_init_value::Float64
    plant_T::Float64
    plant_integral_init_value::Float64


    function OdeParams_PiPt1()
        setpoint_amplitude  = 2.0
        setpoint_time_delay = 0.5

        ctrl_kp = 10.0
        ctrl_ki = 5.0
        ctrl_integral_init_value = 0.0

        plant_T = 0.2
        plant_integral_init_value = 0.5

        return new(
            setpoint_amplitude,
            setpoint_time_delay,
            ctrl_kp,
            ctrl_ki,
            ctrl_integral_init_value,
            plant_T,
            plant_integral_init_value)
    end
end

function step(time, a, td)
    return time >= td ? a : zero(typeof(time))
end

function manual_ode_fcn(der_q, time, q, params::OdeParams_PiPt1)
    
    u2 = q[1]
    x  = q[2]
    
    e  = step(time, params.setpoint_amplitude, params.setpoint_time_delay) - x
    u1 = params.ctrl_kp * e
    u  = u1 + u2
    
    der_q[1] = params.ctrl_ki * e
    der_q[2] = (u - x) / params.plant_T

    return der_q
end




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

function create_parametrized_model()
    
    # model parameters
    setpoint_amplitude  = 2.0
    setpoint_time_delay = 0.5

    ctrl_kp = 10.0
    ctrl_ki = 5.0
    ctrl_integral_init_value = 0.0

    plant_T = 0.2
    plant_integral_init_value = 0.5


    @time model = create_model_pi_controller_pt1(
        setpoint_amplitude,
        setpoint_time_delay,
        ctrl_kp,
        ctrl_ki,
        ctrl_integral_init_value,
        plant_T,
        plant_integral_init_value)

    return model
end

function create_odefcn_pi_controller_pt1()

    # model parameters
    setpoint_amplitude  = 2.0
    setpoint_time_delay = 0.5

    ctrl_kp = 10.0
    ctrl_ki = 5.0
    ctrl_integral_init_value = 0.0

    plant_T = 0.2
    plant_integral_init_value = 0.5


    @time model = create_model_pi_controller_pt1(
        setpoint_amplitude,
        setpoint_time_delay,
        ctrl_kp,
        ctrl_ki,
        ctrl_integral_init_value,
        plant_T,
        plant_integral_init_value)


    @time (forest, integrator_indices, tree_node_vecvec, evalulation_indices_vecvec) = tenedyn.compile(model)


    ode_fcn = tenedyn.create_ode_function(
        model,
        forest,
        integrator_indices,
        tree_node_vecvec,
        evalulation_indices_vecvec)

    return ode_fcn
end

function run_simulation(ode_fcn)

    time_interval = ode.TimeInterval(50.0)
    init_cond     = [0.0, 0.5]

    ode_problem = ode.OdeProblem(
        ode_fcn,
        time_interval,
        init_cond)

    ode_solver = ode.Tsitouras45()
    
    basic_options = ode.BasicOdeOptions(
        ode_problem;
        abs_tol = 1e-5,
        rel_tol = 1e-5,
        max_iter = 1000
    )

    step_size_controller = ode.ClassicalStepSizeControl()

    stepper_options = ode.StepperOptions(;
        max_step_size = 5.0)
        
    @time (ode_res, step_stat) = ode.solve(
        ode_problem,
        ode_solver;
        basic_options        = basic_options,
        step_size_controller = step_size_controller,
        stepper_options      = stepper_options
        ) # 

    # t = ode.time(ode_res)
    # q = ode.variables(ode_res)


    return ode_res
end



function plot_ode_res(ode_res)

    t = ode.time(ode_res)
    q = ode.variables(ode_res)

    figh = PyPlot.figure()
    a1 = PyPlot.subplot(2,1,1)

    PyPlot.grid()
    PyPlot.plot( t, q[1, :] )

    PyPlot.subplot(2,1,2, sharex = a1)
    PyPlot.grid()
    PyPlot.plot( t, q[2, :] )

    return figh
end


# after creation of a function string from the tree, only this is needed for more speed:
# fcn_str         = "fcn(t) = sin(t) + 3"
# parsed_expr     = Meta.parse(fcn_str)
# callable_object = eval(parsed_expr)

#=
ode_fcn_str_prefix  = "ode_fcn(der_q, time, q) = "
str_begin           = "begin "
str_end             = " end"
body                = "der_q[1] = - 0.2 * q[1] + sin(time) ;"

ode_fcn_str = ode_fcn_str_prefix * str_begin * body * str_end
=#


function create_callable(ode_fcn_str)

    parsed_expr = Meta.parse(ode_fcn_str)
    ode_fcn     = eval(parsed_expr)

    return ode_fcn
end


function sim2(ode_fcn)

    
    time_interval = ode.TimeInterval(5.0)
    init_cond     = [0.0, 0.5]

    ode_problem = ode.OdeProblem(
        ode_fcn,
        time_interval,
        init_cond)

    ode_solver = ode.Tsitouras45()
    
    basic_options = ode.BasicOdeOptions(
        ode_problem;
        abs_tol = 1e-5,
        rel_tol = 1e-5,
        max_iter = 1000
    )

    step_size_controller = ode.ClassicalStepSizeControl()

    stepper_options = ode.StepperOptions(;
        max_step_size = 0.1)
        
    @time (ode_res, step_stat) = ode.solve(
        ode_problem,
        ode_solver;
        basic_options        = basic_options,
        step_size_controller = step_size_controller,
        stepper_options      = stepper_options
        ) # 

    return ode_res
end


function plot_sim2(ode_res)

    t = ode.time(ode_res)
    q = ode.variables(ode_res)

    figh = PyPlot.figure()
    PyPlot.grid()
    PyPlot.plot( t, q[1, :] )

    return figh
end


model = create_parametrized_model()

(forest,
integrator_indices,
tree_node_vecvec,
evaluation_indices_vecvec) = tenedyn.compile(model)

@time fcn_body = tenedyn.model_to_string(
    model,
    forest,
    integrator_indices,
    tree_node_vecvec,
    evaluation_indices_vecvec)

function create_callable_as_closure(ode_fcn_str, model)
    parsed_expr             = Meta.parse(ode_fcn_str)
    gen_ode_fcn             = eval(parsed_expr)
    ode_fcn(der_q, time, q) = gen_ode_fcn(der_q, time, q, model)
    
    return ode_fcn
end


ode_fcn = create_callable_as_closure(fcn_body, model)
# ode_res = sim2(ode_fcn);




end # module



