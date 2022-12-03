



# include("D:/programming/src/julia/stdlib/resulttypes/ResultTypes.jl")
# include("D:/programming/src/julia/stdlib/arrayviews/ArrayViews.jl")


include("../../../stdlib/resulttypes/src/ResultTypes.jl")
include("../../../stdlib/arrayviews/src/ArrayViews.jl")



module Acceptors

using ..ResultTypes
using ..ArrayViews


export  AbstractAcceptor,
        accept,
        #
        AnyAcceptor,
        NothingAcceptor,
        EqualityAcceptor,
        #
        SequenceAcceptor,
        TupleSequenceAcceptor,
        NSequenceAcceptor,
        #
        ChoiceAcceptor,
        OptionalAcceptor




abstract type AbstractAcceptor end
# an acceptor accepts an array_view
# returns an optional where 


# basic boolean operators
include("basic_acceptors.jl")


# combinators
include("sequence_acceptors.jl")
include("choice_acceptors.jl")




end # module



