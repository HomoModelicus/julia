


# --------------------------------------------------------------------------- #
abstract type AbstractTokenizer end

abstract type AbstractWhitespaceTokenizer   <: AbstractTokenizer end
abstract type AbstractNewlineTokenizer      <: AbstractTokenizer end
abstract type AbstractNumberTokenizer       <: AbstractTokenizer end
abstract type AbstractStringTokenizer       <: AbstractTokenizer end
abstract type AbstractCommentTokenizer      <: AbstractTokenizer end
abstract type AbstractIdentifyerTokenizer   <: AbstractTokenizer end


# --------------------------------------------------------------------------- #
# this is not implemented yet
# struct WhiteSpaceTokenzier <: AbstractWhitespaceTokenizer
# end

struct WhiteSpaceSkipperTokenzier <: AbstractWhitespaceTokenizer
end

# --------------------------------------------------------------------------- #
struct NewlineTokenizer <: AbstractNewlineTokenizer
end

# --------------------------------------------------------------------------- #
struct SpecCharTokenizer <: AbstractTokenizer
end

# --------------------------------------------------------------------------- #
struct IntegerTokenizer <: AbstractNumberTokenizer
    parse_sign::Bool # shal the sign included into the number?

    function IntegerTokenizer(parse_sign = true)
        return new(parse_sign)
    end
end

struct FloatTokenizer <: AbstractNumberTokenizer
    parse_sign::Bool # shal the sign included into the number?

    function FloatTokenizer(parse_sign = true)
        return new(parse_sign)
    end
end

# --------------------------------------------------------------------------- #
struct StringTokenizer <: AbstractStringTokenizer
end

struct DocStringTokenizer <: AbstractStringTokenizer
end

# --------------------------------------------------------------------------- #
struct CLineCommentTokenizer <: AbstractCommentTokenizer
end

struct CBlockCommentTokenizer <: AbstractCommentTokenizer
end

# --------------------------------------------------------------------------- #
struct IdentifyerTokenizer <: AbstractIdentifyerTokenizer
end






function tokenize(tokenizer::AbstractTokenizer, text, strptr::StringPointer)
    error("to be implemented")
end



