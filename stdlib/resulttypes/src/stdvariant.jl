




# =========================================================================== #
# - StdVariant
# =========================================================================== #

"""
StdVariant{T}
a or b or c or...
at the same memory location
"""
struct StdVariant{T}
    # index::Int
    value::T

    function StdVariant{T}(value) where {T}
        return new(value)
    end
end
# var = make_variant(10, Int, Float64, Bool)
# sizeof(var) -> 16
# but sizeof(Union{Int, Float64, Bool}) -> max of the sizes = 8
# it probably needs to track the Union, so we have value of 8 bytes, and 8 byte pointer to the DataType


function make_variant(value::U, t...) where {U}
    # callable with 10, Int, Float64
    UnionType = Union{t...}
    variant   = StdVariant{UnionType}(value)
    return variant
end

# this can create those variant objects
# but how to get out the Union{...} types out -> for copying the value
# or setting it to an other type
#
# how to get the index() method from c++?

function value_type(variant::StdVariant)
    return typeof(variant.value)
end

function union_type(variant::StdVariant)
    return typeof(variant).types[1]
end

function possible_types(variant::StdVariant)
    ut_orig = union_type(variant)
    ut      = ut_orig

    # specialization up to level 6
    break_flag = false

    # level 1 Union{Int}
    (t1, ut, break_flag) = isa(ut, Union) ? (ut.a, ut.b, false) : (ut, nothing, true)
    if break_flag; types = (t1,); return types; end

    # level 2 Union{Int, Float64}
    (t2, ut, break_flag) = isa(ut, Union) ? (ut.a, ut.b, false) : (ut, nothing, true)
    if break_flag; types = (t1, t2); return types; end

    # level 3 Union{Int, Float64, UInt8}
    (t3, ut, break_flag) = isa(ut, Union) ? (ut.a, ut.b, false) : (ut, nothing, true)
    if break_flag; types = (t1, t2, t3); return types; end

    # level 4 
    (t4, ut, break_flag) = isa(ut, Union) ? (ut.a, ut.b, false) : (ut, nothing, true)
    if break_flag; types = (t1, t2, t3, t4); return types; end

    # level 5 
    (t5, ut, break_flag) = isa(ut, Union) ? (ut.a, ut.b, false) : (ut, nothing, true)
    if break_flag; types = (t1, t2, t3, t4, t5); return types; end

    # level 6
    (t6, ut, break_flag) = isa(ut, Union) ? (ut.a, ut.b, false) : (ut, nothing, true)
    if break_flag; types = (t1, t2, t3, t4, t5, t6); return types; end

    # level 7
    (t7, ut, break_flag) = isa(ut, Union) ? (ut.a, ut.b, false) : (ut, nothing, true)
    if break_flag; types = (t1, t2, t3, t4, t5, t6, t7); return types; end

    # # level 8
    (t8, ut, break_flag) = isa(ut, Union) ? (ut.a, ut.b, false) : (ut, nothing, true)
    if break_flag; types = (t1, t2, t3, t4, t5, t6, t7, t8); return types; end

    acc = ()
    (ut, accumulator) = __rec_possible_types(ut_orig, acc)
    return accumulator
end

function __rec_possible_types(ut, accumulator)

    (t1, ut, break_flag) = isa(ut, Union) ? (ut.a, ut.b, false) : (ut, nothing, true)
    if break_flag
        return (ut, accumulator)
    else
        accumulator = (accumulator..., t1)
        return __rec_possible_types(ut, accumulator)
    end

end

function index(variant::StdVariant)
    type_list = possible_types(variant)
    act_type  = value_type(variant)

    ii = 0
    for outer ii = eachindex(type_list)
        if act_type == type_list[ii]
            break
        end
    end

    return ii
end




# Switch https://github.com/andyferris/Switches.jl
# =========================================================================== #
# - Either
# =========================================================================== #

struct Either{A, B}
    value::Union{A, B}

    function Either{A, B}(value::T) where {A, B, T <: Union{A, B}}
        return new(value)
    end
end

function make_either(::Type{A}, ::Type{B}, value::T) where {A, B, T <: Union{A, B}}
    return Either{A, B}(value)
end

function is_left(eit::Either{A, B}) where {A, B}
    return typeof(eit.value) == A ? true : false
end

function is_right(eit::Either{A, B}) where {A, B}
    return !is_left(eit)
end



# should it make something any better?
# # =========================================================================== #
# # - ThreeWay
# # =========================================================================== #

# struct ThreeWay{A, B, C}
#     value::Union{A, B, C}

# end



