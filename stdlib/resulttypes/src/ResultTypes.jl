

module ResultTypes



include("stdexpected.jl")
export  StdUnexpected,
        make_unexpected,
        StdExpected,
        make_expected,
        has_value,
        value_or,
        expected_or,
        value


include("stdoptional.jl")
export  BadOptionalAccess,
        StdOptional,
        make_optional,
        and_then,
        or_else,
        value

        
include("stdpair.jl")
export  StdPair,
        make_pair


include("stdvariant.jl")
export  StdVariant,
        make_variant,
        Either,
        make_either,
        is_left,
        is_right


include("macros.jl")


end # module

