


# =========================================================================== #
# ChoiceAcceptor
# =========================================================================== #

struct ChoiceAcceptor{A, B} <: AbstractAcceptor
    first::A
    second::B
    
    function ChoiceAcceptor{A, B}(first::A, second::B) where {A <: AbstractAcceptor, B <: AbstractAcceptor}
        return new(first, second)
    end

    function ChoiceAcceptor(first::A, second::B) where {A <: AbstractAcceptor, B <: AbstractAcceptor}
        return ChoiceAcceptor{A, B}(first, second)
    end
end

function accept(
    acceptor::ChoiceAcceptor{A, B},
    array_view::AV
    ) where {A <: AbstractAcceptor, B <: AbstractAcceptor, AV <: AbstractView}

    res_opt1 = accept(acceptor.first, array_view)

    if has_value(res_opt1)
        return res_opt1
    else
        res_opt2 = accept(acceptor.second, array_view)
        return res_opt2
    end
end




# =========================================================================== #
# OptionalAcceptor
# =========================================================================== #


const OptionalAcceptor{A} = ChoiceAcceptor{A, AnyAcceptor} where {A}

function OptionalAcceptor{A}(inner::A) where {A <: AbstractAcceptor}
    return ChoiceAcceptor{A, AnyAcceptor}(inner, AnyAcceptor())
end

function OptionalAcceptor(inner::A) where {A <: AbstractAcceptor}
    return ChoiceAcceptor{A, AnyAcceptor}(inner, AnyAcceptor())
end



#=

# =========================================================================== #
# NChoiceParser
# =========================================================================== #

struct NChoiceParser <: AbstractParser
    inner_parsers::Tuple

    function NChoiceParser(p1::Vararg{P, N}) where {P <: AbstractParser, N}
        return new( p1 )
    end
end

function parse(parser::NChoiceParser, stringview)
    newsv = stringview
    for (ii, inner_parser) in enumerate(parser.inner_parsers)
        res = parse(inner_parser, newsv)
        if has_value(res)
            # succes, return
            return res
        else
            # try the other parser
            if ii >= N
                return res
            end
            continue
        end
    end
end

=#



