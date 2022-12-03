

# =========================================================================== #
# SequenceAcceptor
# =========================================================================== #

struct SequenceAcceptor{A, B} <: AbstractAcceptor
    first::A
    second::B
    
    function SequenceAcceptor{A, B}(first::A, second::B) where {A <: AbstractAcceptor, B <: AbstractAcceptor}
        return new(first, second)
    end

    function SequenceAcceptor(first::A, second::B) where {A <: AbstractAcceptor, B <: AbstractAcceptor}
        return SequenceAcceptor{A, B}(first, second)
    end
end

function accept(
    acceptor::SequenceAcceptor{A, B},
    array_view::AV
    ) where {A <: AbstractAcceptor, B <: AbstractAcceptor, AV <: AbstractView}

    res_opt1 = accept(acceptor.first, array_view)

    if has_value(res_opt1)
        # succes at first
        next_view = array_view + 1
        res_opt2  = accept(acceptor.second, next_view)
    
        last_accepted_view = value_or(res_opt2, ResultTypes.unsafe_value(res_opt1))
        full_view          = AV(last_accepted_view, array_view.first, last_accepted_view.last)
        full_res_opt       = StdOptional( has_value(res_opt2), full_view )
        return full_res_opt
    else
        # failed already at the 
        return res_opt1
    end

end




# =========================================================================== #
# TupleSequenceAcceptor
# =========================================================================== #

struct TupleSequenceAcceptor{N} <: AbstractAcceptor
    inner_acceptors::Tuple # NTuple{N, <: AbstractParser}, NTuple only works with one known type

    function TupleSequenceAcceptor{N}(p1::Vararg{<: AbstractAcceptor, N}) where {N}
        return new( p1... )
    end

    function TupleSequenceAcceptor(p1...)
        N = length(p1)
        return TupleSequenceAcceptor{N}(p1)
    end

    function TupleSequenceAcceptor{N}(p1...) where {N}
        return new( p1... )
    end
end



function accept(
    acceptor::TupleSequenceAcceptor,
    array_view::AV
    ) where {AV <: AbstractView}

    new_view = array_view
    N        = length(acceptor.inner_acceptors)

    for (ii, inner_parser) in enumerate(acceptor.inner_acceptors)

        res_opt = accept(inner_parser, new_view)

        if has_value(res_opt)
            # success, continue
            if ii < N
                new_view += 1
                continue
            end
            
            full_view    = AV(array_view, array_view.first, new_view.first)
            full_res_opt = StdOptional(true, full_view)
            
            return full_res_opt
        else
            # failure somewhere in the chain, at the i-th inner acceptor
            if ii == 1
                # the first element failed as well
                matched_view = make_zero_view(array_view)
            else
                new_view -= 1
                matched_view = AV(array_view, array_view.first, new_view.first)
            end

            res_opt = StdOptional(false, matched_view)
            return res_opt
        end
    end
end










# =========================================================================== #
# NSequenceAcceptor
# =========================================================================== #



struct NSequenceAcceptor{N, T} <: AbstractAcceptor
    inner_acceptors::NTuple{N, T}

    function NSequenceAcceptor{N, T}(p1::Vararg{T, N}) where {N, T <: AbstractAcceptor}
        return new(p1)
    end

    function NSequenceAcceptor(p1::Vararg{T, N}) where {N, T <: AbstractAcceptor}
        return NSequenceAcceptor{N, T}(p1...)
    end

    function NSequenceAcceptor(p1...)
        N = length(p1)
        T = typeof(p1[1])
        return NSequenceAcceptor{N, T}(p1)
    end

    # function NSequenceAcceptor{N}(p1...) where {N, T}
    #     return new( p1... )
    # end
end


function accept(
    acceptor::NSequenceAcceptor,
    array_view::AV
    ) where {AV <: AbstractView}

    new_view = array_view
    N        = length(acceptor.inner_acceptors)

    for (ii, inner_parser) in enumerate(acceptor.inner_acceptors)

        res_opt = accept(inner_parser, new_view)

        if has_value(res_opt)
            # success, continue
            if ii < N
                new_view += 1
                continue
            end
            
            full_view    = AV(array_view, array_view.first, new_view.first)
            full_res_opt = StdOptional(true, full_view)
            
            return full_res_opt
        else
            # failure somewhere in the chain, at the i-th inner acceptor
            if ii == 1
                # the first element failed as well
                matched_view = make_zero_view(array_view)
            else
                new_view -= 1
                matched_view = AV(array_view, array_view.first, new_view.first)
            end

            res_opt = StdOptional(false, matched_view)
            return res_opt
        end
    end
end



#=
# =========================================================================== #
# NTimesParser
# =========================================================================== #

# exactly n times
struct NTimesParser{T} <: AbstractParser
    inner_parser::T
    n_times::Int

    function NTimesParser{T}(parser::T, n_times = 1) where {T <: AbstractParser}
        n = convert(Int, n_times)
        return new(parser, n)
    end

    function NTimesParser(parser::T, n_times = 1) where {T <: AbstractParser}
        return NTimesParser{T}(parser, n_times)
    end
end

function parse(parser::NTimesParser, stringview)

    newsv = stringview

    for ii in Base.OneTo(parser.n_times)

        res = parse(parser.inner_parser, newsv)
        if has_value(res.value)
            # success, continue
            # newsv = res.stringview
            newsv = make_next_view(stringview, res.stringview)
            if ii >= parser.n_times

                sv        = make_view(stringview, stringview.first, res.stringview.last)
                value     = res.value
                res_total = ParsingResult(sv, value)

                return res_total
            end
        else
            # failure somewhere in the chain
            res_total = ParsingResult(stringview, typeof(parser.inner_parser))
            return res_total
        end
    end
end




# =========================================================================== #
# WhileTrueParser
# =========================================================================== #


# until char; until predicate true parser
# stops if the condition becomes false
struct WhileTrueParser{T} <: AbstractParser
    inner_parser::T

    function WhileTrueParser{T}(parser::T) where {T}
        return new(parser)
    end

    function WhileTrueParser(parser::T) where {T}
        return WhileTrueParser{T}(parser)
    end
end


function parse(parser::WhileTrueParser, stringview)

    newsv = stringview
    prev_res = ParsingResult(stringview, typeof(parser.inner_parser)) # this line with this architecture cannot be made type-stable

    while true
        res = parse(parser.inner_parser, newsv)

        if has_value(res.value)
            # success - do once again
            newsv    = make_next_view(stringview, res.stringview)
            prev_res = res

            # break the loop -> no more chars
            if newsv.first >= stringview.last
                sv        = make_view(stringview, stringview.first, res.stringview.last)
                value     = res.value
                res_total = ParsingResult(sv, value)
                return res_total
            end

        else
            # failure - return the previous result
            sv        = make_view(stringview, stringview.first, prev_res.stringview.last)
            value     = prev_res.value
            res_total = ParsingResult(sv, value)
            return res_total
        end
    end

end



# =========================================================================== #
# WhileFalseParser
# =========================================================================== #


# stops if the condition becomes true
struct WhileFalseParser{T} <: AbstractParser
    inner_parser::T

    function WhileFalseParser{T}(parser::T) where {T}
        return new(parser)
    end

    function WhileFalseParser(parser::T) where {T}
        return WhileFalseParser{T}(parser)
    end
end



function parse(parser::WhileFalseParser, stringview)

    # I need an offset/shift -> it is trivially 1 character
    # for elementary parsers it is easy, just the length of a something
    # -> most likely an other function def is needed
    # or
    # negation_parse -> if the underlying parser fails, it succeeds
    # not_parse like NotCharParser

    newsv = stringview
    prev_res = ParsingResult(stringview, typeof(parser.inner_parser))

    while true
        res = parse(parser.inner_parser, newsv)

        if has_value(res.value)

            # failure - return the previous result
            sv        = make_view(stringview, stringview.first, prev_res.stringview.first)
            value     = prev_res.value
            res_total = ParsingResult(sv, value)
            return res_total

        else
            # success - do once again
            # newsv    = make_next_view(stringview, res.stringview)
            newsv    = make_view(res.stringview, newsv.first + 1, stringview.last)
            prev_res = res

            # break the loop -> no more chars
            if newsv.first >= stringview.last
                sv        = make_view(stringview, stringview.first, res.stringview.last)
                value     = res.value
                res_total = ParsingResult(sv, value)
                return res_total
            end
        end
    end

end

=#

