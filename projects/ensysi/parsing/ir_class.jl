







function empty_superclass_vector()
    return Vector{TypePointer}(undef, 0)
end



@enum ClassModifyerKind begin
    no_modifyer_match_t # kind of error case

    abstract_t
    connector_t
    block_t
    model_t
end


mutable struct Class
    name::Symbol
    class_modifyer::ClassModifyerKind
    superclasses::Vector{TypePointer}

    properties::Vector{ClassProperty}
    variables::Vector{ClassVariable}
    models::Vector{TypePointer}

    rawequations::Vector{RawEquation}

    function Class(name, class_modifyer, superclasses, properties, variables, models, rawequations)
        return new(name, class_modifyer, superclasses, properties, variables, models, rawequations)
    end

    function Class(name)
        class_modifyer = no_modifyer_match_t::ClassModifyerKind

        superclasses    = Vector{TypePointer}(   undef, 0)
        properties      = Vector{ClassProperty}( undef, 0)
        variables       = Vector{ClassVariable}( undef, 0)
        models          = Vector{TypePointer}(   undef, 0)
        rawequations    = Vector{RawEquation}(   undef, 0)

        sizehint!(superclasses, 4)
        sizehint!(properties,   8)
        sizehint!(variables,    8)
        sizehint!(models,       4)
        sizehint!(rawequations, 8)

        return new(name, class_modifyer, superclasses, properties, variables, models, rawequations)
    end
end



function symbol_to_class_modifyer(modifyer_symbol::Symbol)
    is_successfull = false
    index          = 0
    to_be_matched  = Symbol(String(modifyer_symbol) * "_t")

    for (ii, inst) in enumerate( instances(ClassModifyerKind) )
        if to_be_matched == Symbol(inst)
            is_successfull = true
            index = ii
            break
        end
    end

    modifyer = is_successfull ? ClassModifyerKind(index - 1) : no_modifyer_match_t::ClassModifyerKind
    res_opt  = StdOptional{ClassModifyerKind}(is_successfull, modifyer)
    return res_opt
end








mutable struct ExtClass
    name::Symbol
    class_modifyer::ClassModifyerKind
    superclasses::Vector{TypePointer}

    properties::Vector{ClassProperty}
    variables::Vector{ClassVariable}
    models::Vector{TypePointer}

    binary_equations::Vector{BinaryTreeEquation}
end





#=


@enum ClassAnnotationType begin
    no_annotation_t
    abstract_t
    connector_t
    block_t
    model_t
end

# algorithms # add it later
struct Class
    name::Symbol
    class_annotation::ClassAnnotationType
    superclasses::Vector{Symbol}

    properties::Vector{Property}
    variables::Vector{Variable}
    equations::Vector{RawEquation}

    function Class(name, class_annotation, superclasses, properties, variables, equations)
        return new(name, class_annotation, superclasses, properties, variables, equations)
    end
end

function Class(name)
    class_annotation = no_annotation_t::ClassAnnotationType
    superclasses = Vector{Symbol}(undef, 0)
    properties   = Vector{Property}(undef, 0)
    variables    = Vector{Variable}(undef, 0)
    equations    = Vector{RawEquation}(undef, 0)

    return Class(name, class_annotation, superclasses, properties, variables, equations)
end


function has_class_annotation(class_obj::Class)
    return class_obj.class_annotation != no_annotation_t::ClassAnnotationType
end


function n_superclasses(class_obj::Class)
    return length(class_obj.superclasses)
end

function has_superclasses(class_obj::Class)
    return n_superclasses(class_obj) > 0
end

function n_properties(class_obj::Class)
    return length(class_obj.properties)
end

function n_variables(class_obj::Class)
    return length(class_obj.variables)
end

function n_equations(class_obj::Class)
    return length(class_obj.equations)
end




function class_annotation_to_string(class_obj::Class)
    if has_class_annotation(class_obj)
        str_annotation = "($(class_obj.annotation))"
    else
        str_annotation = ""
    end

    return str_annotation
end

function class_superclasses_to_string(class_obj::Class)
    if has_superclasses(class_obj)
        inner_str      = join(map( x -> String(x), class_obj.superclasses ), ", ")
        str_supertypes = "<: {" * inner_str * "}"
    else
        str_supertypes = ""
    end

    return str_supertypes
end

function class_properties_to_string(class_obj::Class)
    if n_properties(class_obj) > 0
        str_properties = join(map( x -> to_string(x), class_obj.properties ), "\n\t\t")
        str_properties = "properties\n\t\t" * str_properties * "\n" * "\tend\n"
    else
        str_properties = ""
    end
    
    return str_properties
end

function class_variables_to_string(class_obj::Class)

    if n_variables(class_obj) > 0
        str_variables = join(map( x -> to_string(x), class_obj.variables ), "\n\t\t")
        str_variables = "variables\n\t\t" * str_variables * "\n" * "\tend\n"
    else
        str_variables = ""
    end

    return str_variables
end

function class_equation_to_string(class_obj::Class, text)

    if n_equations(class_obj) > 0
        str_equations = join(map( x -> to_string(x, text), class_obj.equations ), "\n\t\t")
        str_equations = "equations\n\t\t" * str_equations * "\n" * "\tend\n"
    else
        str_equations = ""
    end

    return str_equations
end

function to_string(class_obj::Class, text)

    str_annotation = class_annotation_to_string(class_obj)
    str_supertypes = class_superclasses_to_string(class_obj)
    str_properties = class_properties_to_string(class_obj)
    str_variables  = class_variables_to_string(class_obj)
    str_equations  = class_equation_to_string(class_obj, text)
    
    str = """
    class$(str_annotation) $(class_obj.name) $(str_supertypes)
    \t$(str_properties)
    \t$(str_variables)
    \t$(str_equations)
    end
    """

    return str
end

=#










