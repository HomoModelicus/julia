
# this cannot be implemented so
# most likely even to ccall the object is copied
# so that it gets a different pointer returned and the pointer 
# points to nowhere
# 
# function Base.getindex(obj::StdPair, index::Int)
#     # ptr  = @pointer(obj)
#     ptr = ccall(:jl_value_ptr, Ptr{Cvoid}, (Any,), obj)
#     println(ptr)
#     offs = fieldoffset(StdPair, index)
#     ptr  = ptr + offs
#     T    = fieldtype(StdPair, index)
#     ptr  = convert(Ptr{T}, ptr)
#     val  = Base.pointerref(ptr, Int(1), 1)
#     return val
# end



function create_union_type(x1, inputtuple...)
    t1 = typeof(x1)
    t  = typeof(inputtuple)
    ut = Union{t1, t.types...}
    return ut
end


macro pointer(obj)
    expr = :( ccall(:jl_value_ptr, Ptr{Cvoid}, (Any,), $(obj)) )
    return esc(expr)
end





function __outer_type_name(inexpr)
    lhs       = inexpr.args[1]
    # lhstr     = String(lhs)
    return lhs
end

function __field_types(inexpr)
    types = inexpr.args[2].args
    return types
end

function __type_name( inner_type_name, field_types, outer_type_name)
    type_name = Symbol(inner_type_name * join( map(String, field_types), "_") * "_" * outer_type_name)
    return type_name
end

macro StdPairType(inexpr)

    outer_type_name = __outer_type_name(inexpr)
    outer_type_str  = String(outer_type_name)
    field_types     = __field_types(inexpr)
    (T1, T2)        = field_types
    type_name       = __type_name( "__StdPair_", field_types, outer_type_str)
    
    sdef = quote
        struct $(type_name)
            first::$(T1)
            second::$(T2)
        end

        const $(outer_type_name) = $(type_name)

        function Base.show(io::IO, ::MIME{Symbol("text/plain")}, obj::$(type_name))
            print($outer_type_str)
            print("(")
            print(obj.first)
            print(", ")
            print(obj.second)
            print(")\n")
        end
    end
    
    return esc(sdef)
end


# assumption:
# inexpr is a 
# lhs = (T1, T2...)
macro StdTupleType(inexpr)
    
    outer_type_name = __outer_type_name(inexpr)
    outer_type_str  = String(outer_type_name)
    field_types     = __field_types(inexpr)
    type_name       = __type_name( "__StdTuple_", field_types, outer_type_str)
    N               = length(field_types)

    struct_header = "struct $(type_name)\n"
    struct_end    = "end"
    struct_fields = ntuple( ii -> string("_", ii, :(::), field_types[ii], "\n"), N)
    struct_def    = Meta.parse( string( struct_header, struct_fields..., struct_end) )

    
    if_header     = "if index == 1"
    if_end        = "end"
    elseif_prefix = "elseif index == "
    return_prefix = "return obj._"

    str = if_header * return_prefix * "1\n"
    for ii = 2:N
        numstr = string(ii) * '\n'
        str    = str * elseif_prefix * numstr * return_prefix * numstr
    end
    getindex_if_str = str * if_end
    if_def          = Meta.parse(getindex_if_str)

    expr = quote
        $(struct_def)

        const $(outer_type_name) = $(type_name)

        function Base.getindex(obj::$(type_name), index::Int)
            $(if_def)
        end
    end

    return esc(expr)
end



# StdPair and StdTuple can create immutable structs 
# given the TYPES of the fields in order
# 
# StdTuple defines the getindex method for the generated type as well
# 
# there is no possibility with macros to get the type of the input
# 

# what could be created is:
# usage:
# a = 10; b = 20; c = 30;
# ### @StdTuple tup_var = TupType(a, b, c)
# =>
# generate first the holding struct
# generate getindex, because of the tuple behaviour
# create the assignment to the lhs variable
# by doing this, knowing the concrete types is not important any more
# the code shall work, but the compiler is tortured more
#
# struct __StdTuple_TupType{T1, T2, T3}
#     _1::T1
#     _2::T2
#     _3::T3
#
#     function __StdTuple_Tup{T1, T2, T3}(in1, in2, in3) where {T1, T2, T3}
#         return new(in1, in2, in3)
#     end
#
#     function __StdTuple_Tup(in1::T1, in2::T2, in3::T3) where {T1, T2, T3}
#         return __StdTuple_Tup{T1, T2, T3}(in1, in2, in3)
#     end
# end
# 
# 
# + getindex shall also be generated
# 
# renaming for nicer usage
# const TupType = __StdTuple_TupType{T1, T2, T3} where {T1, T2, T3}
# 
# tup_var = __StdTuple_TupType(a, b, c) # <- here comes the assignment
#

#
# Advantage over built-in Tuple
# - mutability could be controlled by the user
# - in case of isbitstype -> stack allocation
# - 


# assumption:
# tup_var = TupType(a, b, c)
# getindex doesnt throw BoundsError and might return stupid values
# if the index is not in the range
macro StdTuple(inexpr)

    var_name  = inexpr.args[1]
    rhs       = inexpr.args[2]
    type_name = rhs.args[1]
    n_fields  = length(rhs.args) - 1
    

    # type def
    field_types    = ntuple( ii -> string("T", ii) , n_fields)
    type_list      = "{" * join(field_types, ", ") * "}"
    full_type_name = string(type_name) * type_list
    
    # struct def
    struct_header  = "struct $(full_type_name)\n"
    struct_end     = "end"
    struct_fields  = ntuple( ii -> string("_", ii, :(::), field_types[ii], "\n"), n_fields)
    

    # constructor
    args         = join( rhs.args[2:end], ", ")
    args_sim     = join( map( (t) -> string(t[1], "::",t[2]), zip(rhs.args[2:end], field_types) ), ", " )
    ctor_str     = "function $(full_type_name)($(args)) where $(type_list)\n" * "return new($(args))\n" * "end\n"
    ctor_sim_str = "function $(string(type_name))($(args_sim)) where $(type_list)\n" * "return $(full_type_name)($(args)) \n" * "end\n"

    # ctor_def     = Meta.parse(ctor_str)
    # ctor_sim_def = Meta.parse(ctor_sim_str)
    full_struct_str = string(
                        struct_header,
                        struct_fields...,
                        "\n",
                        ctor_str,
                        ctor_sim_str,
                        struct_end)
    struct_def     = Meta.parse( full_struct_str )

    # getindex
    if_block_fcn(ii::Int) = "index == $(ii) && return obj._$(ii)\n"
    if_str       = join( ntuple(if_block_fcn, n_fields), "\n")
    getindex_str = "function Base.getindex(obj::$(type_name), index::Int)\n" * if_str * "end"
    getindex_def = Meta.parse(getindex_str)

    expr = quote
        
        $(struct_def)

        $(getindex_def)

        $(var_name) = $(rhs)
    end

    return esc(expr)
end




