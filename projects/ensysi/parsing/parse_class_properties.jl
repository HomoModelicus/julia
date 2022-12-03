

# value for properties are only numerical values



function parse_class_single_property(text, array_view, type_table::TypeTable, class_ir::Class)

    # here we already know that this is an identifyer
    name_as_symbol = extract_nth_as_symbol(text, array_view, 1)
    array_view    += 1


    # colon-colon :: check
    exp_token_colon = ExpectedToken(specialchar_t::TokenCategory, colon_t::SpecialCharacterType)
    eq_acc          = EqualityAcceptor(exp_token_colon)
    nseq_acc        = NSequenceAcceptor(eq_acc, eq_acc)
    res_opt         = accept(nseq_acc, array_view)

    if has_value(res_opt)
       array_view += 2
    else
        error("Expected a :: operator but found: <error_handling>, at line: at column:") 
    end


    # type section
    exp_token_iden = ExpectedToken(identifyer_t::TokenCategory)
    eq_acc_iden    = EqualityAcceptor(exp_token_iden)
    res_opt        = accept(eq_acc_iden, array_view)
    
    if has_value(res_opt)
        type_name = extract_nth_as_symbol(text, array_view, 1)
        type_ptr  = TypePointer(type_name, type_table)
    else
        error("Expected a type but found: <error_handling>")
    end
    array_view += 1


    # possibly value, if no default value present, Float64(0) is assumed 
    exp_token_equal = ExpectedToken(specialchar_t::TokenCategory, equal_t::SpecialCharacterType)
    
    if exp_token_equal == array_view[1]
        # value present
        array_view += 1
        
        exp_token_num = ExpectedTokenCategory(number_t::TokenCategory)


        # check for boolean as well
        if exp_token_num == array_view[1]
            value = array_view[1].value
        else
            error("Expected a number or a boolean, but found: <error_handling>")
        end

    else
        # use default
        default_value = zero(Float64)
        value         = default_value
    end

    property = ClassProperty(name_as_symbol, type_ptr, value)
    push!(class_ir.properties, property)

    array_view += 1
    return array_view
end



function parse_class_properties(text, array_view::AV, type_table::TypeTable, class_ir::Class) where {AV <: AbstractView}


    exp_token_end     = ExpectedToken(keyword_t::TokenCategory, kw_end_t::KeywordType)
    exp_token_newline = ExpectedToken(newline_t::TokenCategory)
    exp_token_iden    = ExpectedToken(identifyer_t::TokenCategory)

    while array_view.first <= array_view.last
        token = array_view[1]

        if exp_token_end == token
            # stop case
            break
        end

        if exp_token_newline == token
            # newline -> skip
            array_view += 1
            continue
        end

        if exp_token_iden == token
            array_view  = parse_class_single_property(text, array_view, type_table, class_ir)
            continue
        end

        error("Unrecognised token around line: $(token.first.line), column: $(token.first.column)")

    end

    next_array_view = array_view + 1
    return next_array_view

end





