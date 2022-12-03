


mutable struct SentinelType
end

const sentinel_type = SentinelType()



mutable struct BuiltinType
    name::Symbol
end

const RealType    = BuiltinType(:Real)
const IntegerType = BuiltinType(:Integer)
const BoolType    = BuiltinType(:Bool)



# this must be mutable to heap allocated
# to have stable memory address
# to have a pointer to it
mutable struct TypeTable
    const scope::Symbol
    table::Dict{Symbol, Any}

    function TypeTable(scope = :Global)

        table           = Dict{Symbol, Any}()
        table[:Real]    = RealType
        table[:Integer] = IntegerType
        table[:Bool]    = BoolType

        return new(scope, table)
    end
end

function Base.get(type_table::TypeTable, key, default)
    return get(type_table.table, key, default)
end

function Base.haskey(type_table::TypeTable, key)
    return haskey(type_table.table, key)
end

function push_sentinel_if_not_present!(type_table::TypeTable, key)
    is_in = haskey(type_table, key)
    if is_in
        # do nothing
    else
        type_table.table[key] = sentinel_type
    end
end




struct TypePointer
    name::Symbol
    ptr::TypeTable
    
    function TypePointer(name::Symbol, type_table::TypeTable)
        return new(name, type_table)
    end
end









