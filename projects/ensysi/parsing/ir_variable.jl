











@enum CausalityKind begin
    cas_no_causality_t
    cas_acausal_t
    cas_input_t
    cas_output_t
end

@enum PotentialityKind begin
    pot_no_potentiality_t
    pot_potential_t
    pot_flow_t
    pot_stream_t
end


mutable struct ClassVariable
    name::Symbol # name of the variable, not the type
    type_ptr::TypePointer
    causility_type::CausalityKind
    potentiality_type::PotentialityKind

    function ClassVariable(name, type_ptr, causility_type, potentiality_type)
        return new(name, type_ptr, causility_type, potentiality_type)
    end

end




function symbol_to_causality_type(sym::Symbol)
    type = cas_no_causality_t::CausalityKind

    if sym == :acausal
        type = cas_acausal_t::CausalityKind
    elseif sym == :input
        type = cas_input_t::CausalityKind
    elseif sym == :ouput
        type = cas_ouput_t::CausalityKind
    end

    return type
end

function symbol_to_potentiality_type(sym::Symbol)
    type = pot_no_potentiality_t::PotentialityKind

    if sym == :potential
        type = pot_potential_t::PotentialityKind
    elseif sym == :flow
        type = pot_flow_t::PotentialityKind
    elseif sym == :stream
        type = pot_stream_t::PotentialityKind
    end

    return type
end





#=

@enum CausalityType begin
    no_causality_t
    acausal_t
    input_t
    output_t
end

@enum PotentialityType begin
    no_potentiality_t
    potential_t
    flow_t
    stream_t
end

function symbols(::Type{CausalityType})
    cas_syms = (:acausal, :input, :output)
    return cas_syms
end


function symbols(::Type{PotentialityType})
    pot_syms = (:potential, :flow, :stream)
    return pot_syms
end





function symbollist_to_variabletype(symbol_list)
    n_sym = length(symbol_list)

    if n_sym == 1
        # treated as the type name
        typename          = symbol_list[1]
        causility_type    = acausal_t::CausalityType
        potentiality_type = potential_t::PotentialityType
    else
        # one is the typename the other might be CausalityType and/or PotentialityType

        causility_type    = no_causality_t::CausalityType
        potentiality_type = no_potentiality_t::PotentialityType
        
        cas_index = 0
        pot_index = 0

        for ii = 1:n_sym
            sym = symbol_list[ii]

            if pot_index < 1
                pot_type = symbol_to_potentiality_type(sym)
                if pot_type != no_potentiality_t::PotentialityType
                    pot_index = ii
                    potentiality_type = pot_type
                end
            end

            if cas_index < 1
                cas_type = symbol_to_causality_type(sym)
                if cas_type != no_causality_t::CausalityType
                    cas_index = ii
                    causility_type = cas_type
                end
            end
        end # for

        if cas_index == 0 && pot_index == 0
            error("Multiple symbols for a type, but no definition for PotentialityType or CausalityType")
        end

        n_remaining = n_sym - Int(cas_index > 0) - Int(pot_index > 0)
        if n_remaining > 1
            error("Too many symbols for type definition")
        end

        type_index = 0
        for ii = 1:n_sym
            if !(ii == cas_index || ii == pot_index)
                type_index = ii
                break
            end
        end

        typename = symbol_list[type_index]

    end # if

    return (typename, causility_type, potentiality_type)
end


function check_disallowed_typename(typename)
    pot_syms = symbols(PotentialityType)
    cas_syms = symbols(CausalityType)

    not_allowed_names = (pot_syms..., cas_syms...)

    # check names
    for ii in eachindex(not_allowed_names)
        if typename == not_allowed_names[ii]
            error("Encountered a disallowed type name for a variable, found: $(name)")
        end
    end

end


struct VariableType
    name::Symbol
    causility_type::CausalityType
    potentiality_type::PotentialityType

    function VariableType(name::Symbol, causility_type, potentiality_type)
        check_disallowed_typename(name)
        return new(name, causility_type, potentiality_type)
    end
end

function VariableType(name)
    causility_type    = acausal_t::CausalityType
    potentiality_type = potential_t::PotentialityType

    return VariableType(name, causility_type, potentiality_type)
end


function to_string(vartype::VariableType)
    str = "{$(vartype.name), $(vartype.causility_type), $(vartype.potentiality_type)}"
    return str
end




function is_builtin(vartype::VariableType, keyword_map)
    return lexing.get_keyword_type(vartype.name, keyword_map)
end




struct Variable
    name::Symbol
    type::VariableType
    defining_class

    function Variable(name::Symbol, type::VariableType)
        return new(name, type)
    end
end

function Variable(name::Symbol, typename::Symbol, causility_type::CausalityType, potentiality_type::PotentialityType)
    return Variable(name, VariableType(typename, causility_type, potentiality_type))
end


function to_string(variable::Variable)
    str = "$(variable.name)::$(to_string(variable.type))"
    return str
end


=#

