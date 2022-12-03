






mutable struct ClassProperty
    name::Symbol # name of the property, not the type
    type_ptr::TypePointer
    value::Union{Float64, Int, Bool}

    function ClassProperty(name, type_ptr, value)
        return new(name, type_ptr, value)
    end

    # function ClassProperty(name, type_ptr, value::T) where {T}
    #     return ClassProperty{T}(name, type_ptr, value)
    # end
end






#=
struct PropertyType
    name::Symbol
end

struct Property
    name::Symbol
    type::PropertyType

    function Property(name::Symbol, type::PropertyType)
        return new(name, type)
    end
end

function Property(name::Symbol, typename::Symbol)
    return Property(name, PropertyType(typename))
end


function to_string(property::Property)
    str = "$(property.name)::$(property.type.name)"
    return str
end
=#




