





function get_specchar_type(c)
    # return type

    c == '"'  && return quote_t::SpecialCharacterType
    c == '.'  && return dot_t::SpecialCharacterType
    c == ','  && return comma_t::SpecialCharacterType
    c == ':'  && return colon_t::SpecialCharacterType
    c == ';'  && return semicolon_t::SpecialCharacterType
    c == '('  && return opening_paren_t::SpecialCharacterType
    c == ')'  && return closing_paren_t::SpecialCharacterType
    c == '['  && return opening_bracket_t::SpecialCharacterType
    c == ']'  && return closing_bracket_t::SpecialCharacterType
    c == '{'  && return opening_curly_t::SpecialCharacterType
    c == '}'  && return closing_curly_t::SpecialCharacterType
    c == '+'  && return plus_t::SpecialCharacterType
    c == '-'  && return minus_t::SpecialCharacterType
    c == '*'  && return prod_t::SpecialCharacterType
    c == '/'  && return div_t::SpecialCharacterType
    c == '^'  && return carot_t::SpecialCharacterType    
    c == '<'  && return less_t::SpecialCharacterType     
    c == '>'  && return greater_t::SpecialCharacterType
    c == '='  && return equal_t::SpecialCharacterType
    c == '?'  && return question_mark_t::SpecialCharacterType
    c == '|'  && return vertical_bar_t::SpecialCharacterType
    c == '&'  && return ampersand_t::SpecialCharacterType
    c == '!'  && return exclamation_mark_t::SpecialCharacterType
    c == '#'  && return hashtag_t::SpecialCharacterType
    c == '$'  && return dollar_t::SpecialCharacterType
    c == '\\' && return backwardslash_t::SpecialCharacterType
    c == '@'  && return at_t::SpecialCharacterType
    c == '_'  && return underscore_t::SpecialCharacterType
    c == '`'  && return modifyer_t::SpecialCharacterType
    c == '~'  && return tilde_t::SpecialCharacterType
    
    # else
    return no_specchar_t::SpecialCharacterType

end




function tokenize(tokenizer::SpecCharTokenizer, text, strptr::StringPointer)
    # maybe use Dict{Char, Int} ?

    type  = get_specchar_type( text[strptr.index] )

    if type == no_specchar_t::SpecialCharacterType
        token = Token(strptr, strptr.index, no_match_t::TokenCategory)
    else
        token = Token(strptr, strptr.index, specialchar_t::TokenCategory, type)
    end

    return token
end


function tokenize(::Type{SpecCharTokenizer}, text, strptr::StringPointer)
    tokenizer = SpecCharTokenizer()
    return tokenize(tokenizer, text, strptr)
end






