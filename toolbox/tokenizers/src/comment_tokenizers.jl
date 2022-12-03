




function tokenize(tokenizer::CLineCommentTokenizer, text, strptr::StringPointer)

    ii = strptr.index
    if text[ii] == '/' && text[ii+1] == '/'

        # comment case
        while ii <= strptr.max_index
            if text[ii] == '\n'
                break
            end
            ii += 1
            strptr.index += 1
        end

        
        token = Token(strptr, strptr.index, newline_t::TokenCategory)

        # strptr.index += 1 # skip the newline char
        strptr.line  += 1
        strptr.column = 1
    else
        token = Token(strptr, 0, no_match_t::TokenCategory)
    end

    
    return token
end

function tokenize(::Type{CLineCommentTokenizer}, text, strptr::StringPointer)
    tokenizer = CLineCommentTokenizer()
    return tokenize(tokenizer, text, strptr)
end


# --------------------------------------------------------------------------- #

function tokenize(tokenizer::CBlockCommentTokenizer, text, strptr::StringPointer)

    ii  = strptr.index
    if text[ii] == '/' && text[ii+1] == '*'

        # comment case
        col            = strptr.column
        n_newline      = 0
        ii            += 2
        col           += 2
        is_well_formed = false

        while ii <= strptr.max_index-1
            if text[ii] == '\n'
                n_newline += 1
                col        = 1
            end
            if text[ii] == '*' && text[ii+1] == '/'
                is_well_formed = true
                break
            end
            ii  += 1
            col += 1
        end

        strptr.index  = ii + 2
        strptr.line  += n_newline
        strptr.column = col

    end

    return strptr
end

function tokenize(::Type{CBlockCommentTokenizer}, text, strptr::StringPointer)
    tokenizer = CBlockCommentTokenizer()
    return tokenize(tokenizer, text, strptr)
end


