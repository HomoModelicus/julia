



export  Token,
        TokenList,
        TokenCategory



# =========================================================================== #
# TokenCategory
# =========================================================================== #

@enum TokenCategory begin
    error_t    # token is not well formed
    no_match_t # not matched

    newline_t
    specialchar_t
    string_t
    number_t
    identifyer_t
    keyword_t
end


# export
for inst in instances(TokenCategory)
    @eval export $(Symbol(inst))
end


const default_token_value = Int(0)


# =========================================================================== #
# Token
# =========================================================================== #

struct Token
    first::StringPosition
    last::StringPosition
    
    category::TokenCategory

    # Float64               for floating numbers
    # bool                  for possibly true or false
    # Int                   for keywords
    # SpecialCharacterType  for specchars
    # value::Union{Float64, Bool, Int, SpecialCharacterType} # used for either numberical values or for errors
    value::Union{Float64, Int, SpecialCharacterType} # used for either numberical values or for errors



    function Token(
        first::StringPosition,
        last::StringPosition,
        category::TokenCategory,
        value = default_token_value)

        return new(first, last, category, value)
    end

    function Token(
        first::StringPosition,
        last::StringPosition,
        category::TokenCategory)

        return new(first, last, category, default_token_value)
    end

    function Token()
        first    = StringPosition()
        last     = StringPosition()
        category = error_t::TokenCategory
        return new(first, last, category)
    end

    function Token(category::TokenCategory)
        first    = StringPosition()
        last     = StringPosition()
        return Token(first, last, category)
    end

    function Token(strptr::StringPointer, new_index::Int, category::TokenCategory)
        first = StringPosition(strptr)
        last  = StringPosition(first, new_index)
        return Token(first, last, category)
    end

    function Token(strptr::StringPointer, new_index::Int, category::TokenCategory, value)
        first = StringPosition(strptr)
        last  = StringPosition(first, new_index)
        return Token(first, last, category, value)
    end

end








# =========================================================================== #
# TokenList
# =========================================================================== #


struct TokenList
    stack::Stack{Token}

    function TokenList(n_init = 8)
        stack = Stack{Token}(n_init)
        return new(stack)
    end
end

function Base.push!(token_list::TokenList, new_token)
    return push!(token_list.stack, new_token)
end

function Base.length(token_list::TokenList)
    return length(token_list.stack)
end

function Base.size(token_list::TokenList)
    return (length(token_list.stack), )
end

function Base.firstindex(token_list::TokenList)
    return 1
end

function Base.lastindex(token_list::TokenList)
    return token_list.stack.ptr
end

function Base.IndexStyle(::Type{TokenList})
    return IndexLinear()
end

function Base.IndexStyle(token_list::TokenList)
    return IndexStyle(TokenList)
end

function Base.getindex(token_list::TokenList, index::Int)
    return token_list.stack[index]
end

function Base.setindex!(token_list::TokenList, new_token, index::Int)
    return token_list.stack.data[index] = new_token
end


function Base.iterate(token_list::TokenList, index = 1)
    if index > token_list.stack.ptr
        return nothing
    else
        return (token_list.stack[index], index + 1)
    end
end


