


export  substitute,
        showall


function token_to_range(token)
    @inline
    return token.first.index:token.last.index
end


function do_nothing(kw_num)
end


function substitute(text, token_list::TokenList; value_transformator = do_nothing)

    valid_array = valid_data(token_list.stack)
    
    vec_first = map( tok -> string(tok.first.index),                valid_array )
    vec_last  = map( tok -> string(tok.last.index),                 valid_array )
    vec_cat   = map( tok -> string(tok.category),                   valid_array )
    vec_value = map( tok -> string(value_transformator(tok.value)), valid_array )
    vec_str   = map( tok -> String(text[token_to_range(tok)]),      valid_array )
    
    n_row   = length(valid_array)
    vec_str = Vector{String}(undef, n_row)
    for ii = 1:n_row
        token = valid_array[ii]
        if token.category == newline_t::TokenCategory
            vec_str[ii] = "\\n"
        else
            vec_str[ii] = String(text[token_to_range(token)])
        end
    end

    t = Tabulators.tabulate!(
        vec_first,
        vec_last,
        vec_cat,
        vec_value,
        vec_str)

    
    return t
end



function showall(t)
    return Tabulators.showall(t)
    # return show(stdout, "text/plain", x)
end



