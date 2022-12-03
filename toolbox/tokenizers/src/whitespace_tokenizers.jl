

function is_newline(c)
    return c == '\n'
end

# --------------------------------------------------------------------------- #
function tokenize(tokenizer::NewlineTokenizer, text, strptr::StringPointer)
    
    first = 0
    if is_newline(text[strptr.index])
        first = strptr.index
        token = Token(strptr, first, newline_t::TokenCategory)
        # nextline!(strptr)
        strptr.line  += 1
        strptr.column = 1
    else
        token = Token(strptr, 0, no_match_t::TokenCategory)
    end

    return token
end

function tokenize(::Type{NewlineTokenizer}, text, strptr::StringPointer)
    tokenizer = NewlineTokenizer()
    return tokenize(tokenizer, text, strptr)
end






# --------------------------------------------------------------------------- #

function tokenize(tokenizer::WhiteSpaceSkipperTokenzier, text, strptr::StringPointer)

    ii = strptr.index
    while ii <= strptr.max_index
        if  !( isspace( text[ii] ) && !is_newline(text[ii]) )
            break
        end
        ii += 1
        next!(strptr)
    end

    # strptr.index = max(1, ii)

    return strptr
end

function tokenize(::Type{WhiteSpaceSkipperTokenzier}, text, strptr::StringPointer)
    tokenizer = WhiteSpaceSkipperTokenzier()
    return tokenize(tokenizer, text, strptr)
end




