








function is_in_range(c::Char, firstchar, lastchar)
    return firstchar <= c <= lastchar
end

function is_underscore(c)
    return c == '_'
end

function is_first_identifyer_char(c)
    return  is_in_range(c, 'a', 'z') ||
            is_in_range(c, 'A', 'Z') ||
            is_underscore(c)
end

function is_possible_identifyer_char(c)
    return  is_in_range(c, 'a', 'z') ||
            is_in_range(c, 'A', 'Z') ||
            is_in_range(c, '0', '9') ||
            is_underscore(c)
end


function tokenize(tokenizer::IdentifyerTokenizer, text, strptr::StringPointer)

    ii = strptr.index

    first = 0
    last  = 0

    if is_first_identifyer_char(text[ii])

        # yes, it is an identifyer
        first = ii
        while ii <= strptr.max_index && is_possible_identifyer_char(text[ii])
            ii += 1
        end
        last = ii - 1
        token = Token(strptr, last, identifyer_t::TokenCategory)
        strptr.index = last
    else
        token = Token(strptr, last, no_match_t::TokenCategory)
    end

    
    return token
end


function tokenize(::Type{IdentifyerTokenizer}, text, strptr::StringPointer)
    tokenizer = IdentifyerTokenizer()
    return tokenize(tokenizer, text, strptr)
end

