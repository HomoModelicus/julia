
include("../../__lib__/std/datastructs/src/datastructs_module.jl")
include("../../__lib__/std/collections/gridded/src/gridded_module.jl")



module tenedyn
using ..datastructs
using ..gridded

# To Do:
# - create submodels
# - refactor: simplify the logic
# - test out expression replacement: top-down, bottom-up


include("pin.jl")
include("signal.jl")
include("primitives.jl")
include("model.jl")
include("model_to_string.jl")



function create_callable_as_closure(ode_fcn_str, model)
    parsed_expr             = Meta.parse(ode_fcn_str)
    gen_ode_fcn             = eval(parsed_expr)
    ode_fcn(der_q, time, q) = gen_ode_fcn(der_q, time, q, model)
    
    return ode_fcn
end


function create_ode_function_pipeline(model_creation_function, args...)

    @time model = model_creation_function(args...)
    
    @time (forest, integrator_indices, tree_node_vecvec, evaluation_indices_vecvec) = compile(model)
    
    @time ode_fcn_str = model_to_string(
        model,
        forest,
        integrator_indices,
        tree_node_vecvec,
        evaluation_indices_vecvec)
    
    @time ode_fcn = create_callable_as_closure(ode_fcn_str, model)

    return ode_fcn
end


end

