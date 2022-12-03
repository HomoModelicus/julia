



# --------------------------------------------------------------------------- #
function tokenize(tokenizer::StringTokenizer, text, strptr::StringPointer)

    is_well_formed = false
    index          = strptr.index

    if text[index] == '"'
        index += 1
        
        while index <= strptr.max_index
            if text[index] == '"' && text[index-1] != '\\'
                is_well_formed = true
                break
            end
            index += 1
        end

        category = is_well_formed ? string_t::TokenCategory : error_t::TokenCategory
        token    = Token(strptr, index, category)
    else
        token    = Token(no_match_t::TokenCategory)
    end

    strptr.index = is_well_formed ? index : strptr.index

    return token
end


function tokenize(::Type{StringTokenizer}, text, strptr::StringPointer)
    tokenizer = StringTokenizer()
    return tokenize(tokenizer, text, strptr)
end






# --------------------------------------------------------------------------- #
function tokenize(tokenizer::DocStringTokenizer, text, strptr::StringPointer)

    is_well_formed = false
    index          = strptr.index

    if text[index] == '"' && text[index+1] == '"' && text[index+2] == '"'
        index += 3
        
        while index <= strptr.max_index
            if text[index-3] != '\\' && text[index] == '"' && text[index-1] == '"' && text[index-2] == '"'
                is_well_formed = true
                break
            end
            index += 1
        end

        category = is_well_formed ? string_t::TokenCategory : error_t::TokenCategory
        token    = Token(strptr, index, category)
    else
        token    = Token(no_match_t::TokenCategory)
    end

    strptr.index = is_well_formed ? index : strptr.index

    return token
end

function tokenize(::Type{DocStringTokenizer}, text, strptr::StringPointer)
    tokenizer = DocStringTokenizer()
    return tokenize(tokenizer, text, strptr)
end



