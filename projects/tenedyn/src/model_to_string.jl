
# --------------------------------------------------------------------------- #
## General
# --------------------------------------------------------------------------- #

function to_string(model::Model, block::T) where {T <: AbstractBlock}
    error("Not implemented yet")
end

function create_string_vector(n::Int)
    return Vector{String}(undef, n)
end

struct StringBuildingBlocks
    eq::String
    ws::String
    sep::String

    function StringBuildingBlocks(;
        eq = " = ",
        ws = " ",
        sep = "_")

        return new(eq, ws, sep)
    end
end

const stringbuildingblocks = StringBuildingBlocks()


function find_block_name(model::Model, block::T) where {T <: AbstractBlock}
    block_index = model.map_node_to_index[block]
    block_name  = model.names[block_index]
    return block_name
end

function std_unary_outputpin_name()
    output_pin = "y"
    return output_pin
end

function std_unary_inputpin_name()
    input_pin = "x"
    return input_pin
end

function std_numbered_inputpin_name(n::Int)
    input_pin = "x" * "$(n)"
    return input_pin
end

function std_numbered_outputpin_name(n::Int)
    output_pin = "y" * "$(n)"
    return output_pin
end

function build_equation_assignment(lhs::String, rhs::String)
    str = lhs * stringbuildingblocks.eq * rhs
    return str
end



# --------------------------------------------------------------------------- #
## AbstractUnaryTransformer
# --------------------------------------------------------------------------- #
#=
Identity{T}  # OK
Gain{T} # OK
    g::T
    x::InputPin{T}
    y::OutputPin{T}

Sin{T} # OK
    x::InputPin{T}
    y::OutputPin{T}

UserDefinedUnaryFunction{T} # OK
    fcn
    x::InputPin{T}
    y::OutputPin{T}
=#

function to_string(model::Model, block::Identity)

    block_name = find_block_name(model, block)

    input_pin  = std_unary_inputpin_name()
    output_pin = std_unary_outputpin_name()

    eq_parameter_str = nothing
    
    lhs = block_name * stringbuildingblocks.sep * output_pin
    rhs = block_name * stringbuildingblocks.sep * input_pin

    eq_str    = create_string_vector(1)
    eq_str[1] = build_equation_assignment(lhs, rhs)

    return (eq_parameter_str, eq_str)
end

function to_string(model::Model, block::Gain)

    block_name = find_block_name(model, block)

    input_pin  = std_unary_inputpin_name()
    output_pin = std_unary_outputpin_name()

    eq_parameter_str_lhs_1 = block_name * stringbuildingblocks.sep * "g"
    eq_parameter_str_rhs_1 = "$(block.g)"

    eq_parameter_str    = create_string_vector(1)
    eq_parameter_str[1] = build_equation_assignment(eq_parameter_str_lhs_1, eq_parameter_str_rhs_1)
    
    lhs = block_name * stringbuildingblocks.sep * output_pin
    rhs = block_name * stringbuildingblocks.sep * input_pin * " * " * eq_parameter_str_lhs_1

    eq_str    = create_string_vector(1)
    eq_str[1] = build_equation_assignment(lhs, rhs)

    return (eq_parameter_str, eq_str)
end

function to_string(model::Model, block::Sin)

    block_name = find_block_name(model, block)

    input_pin  = std_unary_inputpin_name()
    output_pin = std_unary_outputpin_name()

    eq_parameter_str = nothing
    
    lhs = block_name * stringbuildingblocks.sep * output_pin
    rhs = "sin(" * block_name * stringbuildingblocks.sep * input_pin * ")"

    eq_str    = create_string_vector(1)
    eq_str[1] = build_equation_assignment(lhs, rhs)

    return (eq_parameter_str, eq_str)

end

function to_string(model::Model, block::UserDefinedUnaryFunction)

    block_name = find_block_name(model, block)
    block_index = model.map_node_to_index[block]

    eq_parameter_str = nothing

    input_pin  = std_unary_inputpin_name()
    output_pin = std_unary_outputpin_name()

    lhs = block_name * stringbuildingblocks.sep * output_pin

    arg = block_name * stringbuildingblocks.sep * input_pin
    rhs = "model.nodes[$(block_index)].fcn($(arg))"

    eq_str    = create_string_vector(1)
    eq_str[1] = build_equation_assignment(lhs, rhs)

    return (eq_parameter_str, eq_str)
end

# --------------------------------------------------------------------------- #
## AbstractBinaryTransformer
# --------------------------------------------------------------------------- #
#=
Plus
    x1::InputPin{T} 
    x2::InputPin{T}
    y::OutputPin{T}

Minus

Multiply
Divide
=#

function to_string_binary_template(model::Model, block::T, operand) where {T <: AbstractBinaryTransformer}

    block_name = find_block_name(model, block)

    input_pin_1  = std_numbered_inputpin_name(1)
    input_pin_2  = std_numbered_inputpin_name(2)
    output_pin   = std_unary_outputpin_name()

    eq_parameter_str = nothing
    
    lhs = block_name * stringbuildingblocks.sep * output_pin
    
    x1 = block_name * stringbuildingblocks.sep * input_pin_1
    x2 = block_name * stringbuildingblocks.sep * input_pin_2
    rhs = x1 * " " * operand * " " * x2

    eq_str    = create_string_vector(1)
    eq_str[1] = build_equation_assignment(lhs, rhs)

    return (eq_parameter_str, eq_str)

end

function to_string(model::Model, block::Plus)
    return to_string_binary_template(model, block, "+")
end

function to_string(model::Model, block::Minus)
    return to_string_binary_template(model, block, "-")
end

function to_string(model::Model, block::Multiply)
    return to_string_binary_template(model, block, "*")
end

function to_string(model::Model, block::Divide)
    return to_string_binary_template(model, block, "/")
end


# --------------------------------------------------------------------------- #
## AbstractSource
# --------------------------------------------------------------------------- #
#=
Constant{T}  # OK
    value::T
    y::OutputPin{T}

SinGenerator{T} # OK
    amplitude::T
    frequency::T
    phase::T
    y::OutputPin{T}

Step{T} # OK
=#

function to_string(model::Model, block::Constant)

    block_name = find_block_name(model, block)

    output_pin = std_unary_outputpin_name()

    eq_parameter_str = nothing

    lhs = block_name * stringbuildingblocks.sep * output_pin
    rhs = "$(block.value)"

    eq_str    = create_string_vector(1)
    eq_str[1] = build_equation_assignment(lhs, rhs)

    return (eq_parameter_str, eq_str)
end

function to_string(model::Model, block::SinGenerator)
    block_name = find_block_name(model, block)

    output_pin = std_unary_outputpin_name()

    eq_parameter_str_lhs_1 = block_name * stringbuildingblocks.sep * "amplitude"
    eq_parameter_str_lhs_2 = block_name * stringbuildingblocks.sep * "frequency"
    eq_parameter_str_lhs_3 = block_name * stringbuildingblocks.sep * "phase"
    
    eq_parameter_str_rhs_1 = "$(block.amplitude)"
    eq_parameter_str_rhs_2 = "$(block.frequency)"
    eq_parameter_str_rhs_3 = "$(block.phase)"

    eq_parameter_str    = create_string_vector(3)
    eq_parameter_str[1] = build_equation_assignment(eq_parameter_str_lhs_1, eq_parameter_str_rhs_1)
    eq_parameter_str[2] = build_equation_assignment(eq_parameter_str_lhs_2, eq_parameter_str_rhs_2)
    eq_parameter_str[3] = build_equation_assignment(eq_parameter_str_lhs_3, eq_parameter_str_rhs_3)

    lhs = block_name * stringbuildingblocks.sep * output_pin
    rhs = "$(eq_parameter_str_lhs_1) * sin($(eq_parameter_str_lhs_2) * time + $(eq_parameter_str_lhs_3))"
    
    eq_str    = create_string_vector(1)
    eq_str[1] = build_equation_assignment(lhs, rhs)


    return (eq_parameter_str, eq_str)
end

function to_string(model::Model, block::Step)

    block_name = find_block_name(model, block)

    output_pin = std_unary_outputpin_name()

    eq_parameter_str_lhs_1 = block_name * stringbuildingblocks.sep * "amplitude"
    eq_parameter_str_lhs_2 = block_name * stringbuildingblocks.sep * "time_delay"
    eq_parameter_str_rhs_1 = "$(block.amplitude)"
    eq_parameter_str_rhs_2 = "$(block.time_delay)"

    eq_parameter_str    = create_string_vector(2)
    eq_parameter_str[1] = build_equation_assignment(eq_parameter_str_lhs_1, eq_parameter_str_rhs_1)
    eq_parameter_str[2] = build_equation_assignment(eq_parameter_str_lhs_2, eq_parameter_str_rhs_2)

    lhs = block_name * stringbuildingblocks.sep * output_pin
    rhs = "time >= $(eq_parameter_str_lhs_2) ? $(eq_parameter_str_lhs_1) : zero(typeof(time))"
    
    eq_str    = create_string_vector(1)
    eq_str[1] = build_equation_assignment(lhs, rhs)


    return (eq_parameter_str, eq_str)
end


function to_string(model::Model, block::Curve)

    block_name  = find_block_name(model, block)
    block_index = model.map_node_to_index[block]

    eq_parameter_str = nothing

    output_pin = std_unary_outputpin_name()

    lhs = block_name * stringbuildingblocks.sep * output_pin

    arg = "time"
    rhs = "eval(model.nodes[$(block_index)], $(arg))"

    eq_str    = create_string_vector(1)
    eq_str[1] = build_equation_assignment(lhs, rhs)

    return (eq_parameter_str, eq_str)
end


# --------------------------------------------------------------------------- #
## AbstractIntegrator
# --------------------------------------------------------------------------- #
#=
Integrator # OK
=#

function to_string(model::Model, block::Integrator)

    block_name          = find_block_name(model, block)
    integrator_indicies = find_integrators(model)
    block_index         = model.map_node_to_index[block]
    integrator_index    = findfirst(integrator_indicies .== block_index)


    output_pin = std_unary_outputpin_name()

    eq_parameter_str    = nothing
    
    lhs = block_name * stringbuildingblocks.sep * output_pin
    rhs = "q[" * "$(integrator_index)" * "]"

    eq_str    = create_string_vector(1)
    eq_str[1] = build_equation_assignment(lhs, rhs)

    return (eq_parameter_str, eq_str)

end

# --------------------------------------------------------------------------- #
## Model
# --------------------------------------------------------------------------- #

function model_to_string(
    model::Model,
    forest,
    integrator_indices,
    tree_node_vecvec,
    evalulation_indices_vecvec)

    # for each node, get the string represenation
    # sort the parameter equation at the front, the assignments at the end
    # or better into two separate lists
    # if nothing == no parameter in that block -> skip ode_solver
    # 
    # for each equation == for each element in the forest
    # from the bottom up propagate each connections in a form of:
    # 
    # receiver_block_name_inputpinname = sender_block_name_outpinname

    # ode function structure:
    # section 1: node parameter assignments
    # section 2: for each equation:
    # from bottom nodes (source or integrator) its inner represenation
    # assignment to its outputpin
    # assignement to its receiver pins
    # 

    # create the strings for each node
    N_nodes = length(model.nodes)

    equation_param_vec      = Vector{Any}(undef, N_nodes)
    equation_assignment_vec = Vector{Any}(undef, N_nodes)

    for ii = 1:N_nodes
        (eq_parameter_str, eq_str)  = to_string(model, model.nodes[ii])
        equation_param_vec[ii]      = eq_parameter_str
        equation_assignment_vec[ii] = eq_str
    end
    
    # get rid of the nothing assignments
    for ii = N_nodes:-1:1
        if isnothing(equation_param_vec[ii])
            popat!(equation_param_vec, ii)
        end
    end

    # flatten the parameters
    L_eq_params = length(equation_param_vec)
    Ls          = map(length, equation_param_vec)
    N_param_eqs = sum(Ls)
    flat_equation_param_vec = create_string_vector(N_param_eqs)
    
    kk = 0
    for ii = 1:length(equation_param_vec)
        for jj = 1:Ls[ii]
            kk += 1
            flat_equation_param_vec[kk] = equation_param_vec[ii][jj]
        end
    end


    # for all trees:
    # bottom up create the connection strings
    n_trees        = length(forest)
    # connection_set = Set{String}()
    has_been_added = falses(N_nodes)

    eq_vecvec = datastructs.Stack{Any}(N_nodes) # preallocate with N_nodes

    for tt = 1:n_trees
        eval_indices = evalulation_indices_vecvec[tt]
        L = length(eval_indices)    

        for ii = 1:L
            node_idx = eval_indices[ii]
            node     = model.nodes[node_idx]
            
            # add the node equation
            if has_been_added[node_idx]
                continue
            else
                has_been_added[node_idx] = true
                Leq = length(equation_assignment_vec[node_idx])
                for bb = 1:Leq
                    push!(eq_vecvec, equation_assignment_vec[node_idx][bb])
                end

                # add the outgoing connection equations
                rhs_block_name = model.names[node_idx]

                symbol_list = get_output_pin_names(node)
                for sym in symbol_list
                    out_pin = getfield(node, sym)
                    
                    # handle outgoing signals
                    signal = out_pin.left_child_signal

                    while true
                        cont_obj       = signal.end_pin.containing_object
                        cont_obj_index = model.map_node_to_index[cont_obj]
                        lhs_name       = model.names[cont_obj_index]

                        # how to get the name of the input pin?
                        cont_obj_input_pin_symbol_list = get_input_pin_names(cont_obj)
                        
                        # find the input pin
                        inputpin_name = ""
                        for aa = 1:length(cont_obj_input_pin_symbol_list)
                            
                            if getfield(cont_obj, cont_obj_input_pin_symbol_list[aa]) == signal.end_pin
                                inputpin_name = string(cont_obj_input_pin_symbol_list[aa])
                                break
                            end
                        end
                        if isempty(inputpin_name)
                            error("Input pin could not be found")
                        end

                        conn = lhs_name * "_" * inputpin_name * " = " * rhs_block_name * "_" * string(sym)
                        push!(eq_vecvec, conn)

                        if has_right_sibling(signal)
                            signal = signal.right_sibling_signal
                        else
                            break
                        end
                    end # while outgoing signals
                end # for output pins
            end # if has been added
        end # for nodes in one tree

        # handle last assignemt to der_q[idx] = rhs
        node_idx             = eval_indices[end]
        integrator_index     = findfirst(node_idx .== integrator_indices)
        integrator_node_name = model.names[node_idx]

        rhs_str = integrator_node_name * "_x"
        der_eq = "der_q[" * "$(integrator_index)" * "] = " * rhs_str
        push!(eq_vecvec, der_eq)
    end # for trees

    # flatten eq_vecvec
    # eq_vecvec_data = eq_vecvec.data[1:eq_vecvec.ptr]
    # L_eq_vecvec = length(eq_vecvec_data)
    # Ls          = map(length, eq_vecvec_data)
    # N_param_eqs = sum(Ls)
    # flat_equation_assignments = create_string_vector(N_param_eqs)
    
    # kk = 0
    # for ii = 1:L_eq_vecvec
    #     for jj = 1:Ls[ii]
    #         kk += 1
    #         flat_equation_assignments[kk] = eq_vecvec_data[ii][jj]
    #     end
    # end

    flat_equation_assignments = eq_vecvec.data[1:eq_vecvec.ptr]


    # create function signature
    newline   = "\n"
    str_c     = ", "
    str_der_q = "der_q"
    str_time  = "time"
    str_q     = "q"
    str_model = "model"
    fcn_name  = "function generated_inner_ode_fcn"
    fcn_signature = fcn_name * "(" * str_der_q * str_c * str_time * str_c * str_q * str_c * str_model * ")"
    fcn_end = "return der_q\nend"
    
    
    # create function body
    fcn_body = [flat_equation_param_vec; flat_equation_assignments]
    fcn_body = map(x -> x * "\n", fcn_body)
    
    fcn_str = [fcn_signature; newline; newline; fcn_body; newline; newline; fcn_end]
    fcn_total_str = join(fcn_str)

    return fcn_total_str # (equation_param_vec, equation_assignment_vec, fcn_str)
end



