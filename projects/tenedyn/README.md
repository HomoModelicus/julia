
# Tenedyn - Text node dynamics - Signal Flow based Modelling

- This is a Simulink-like signal flow based simulation tool
- The aim is to create a model based on ordinary differential equations (ode), by means of primitive elements, like Sum() or Sin() or Integrator()
- The integrators define the state variables in the system, up to this point no algebraic loop is allowed, so differential-algebraic equations are not permitted yet
- For later stages submodels/compounds are planned in order to make composite objects


In what follows I'll show you a small working example for a simple pt1 plant with a pi controller.

The result looks like as expected with a step target:
-first row: controller integrator output
-second row: plant position, as expected slowly reaching the step target

<img src="https://github.com/HomoModelicus/julia/blob/main/projects/tenedyn/tenedyn_pt1pi.png" width="350" height="300">


Include the required paths:
- the tenedyn module itself
- and the ode module is used for solving the resulting system
```julia
include("../src/tenedyn_module.jl")
include("../../../math/ode/src/ode_module.jl")

```

Definition of a simple pt1 model with pi controller:
- first the elementary objects are created for the plant, controller and sensor
- then the topology/connectivity between those are defined
- finally, we return the model object which can be later "compiled" -> transpiled into Julia code/strings for the ode solver

```julia
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
```

We write a simple reusable function for simulating a not yet specified model.
```julia

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
```


We create a parameterized model for the pt1-pi model:
```julia
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

    ctrl_kp = 6.0 # 10
    ctrl_ki = 6.0 # 18
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
```

We write the simulation driver code, which also contains a visualization step:
```julia
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
```



At last we can simulate the defined, parameterized model with the given solver and tolerances.
This demonstrates the typical workflow in a simulation environment:
- model build up
- parametrization
- ode/dae settings
- simulation run
- plausibilization

```julia
ode_fcn = create_parametrized_model_pi_controller_pt1()
ode_res = run_simulation_pt1(ode_fcn)
```



