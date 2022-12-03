





macro parse_class_superclasses_no_superclass(text, array_view, type_table)
    ex = quote
        exp_token_newline = ExpectedToken(newline_t::TokenCategory)
        eq_acc_newline    = EqualityAcceptor(exp_token_newline)
        res_opt           = accept(eq_acc_newline, array_view)
    
        if has_value(res_opt)
            # no superclass, early return
            # superclasses = empty_superclass_vector()
            # array_view   = res_opt.value
            # return (superclasses, array_view)
            array_view += 1
            return array_view
        end
    end
    
    return esc(ex)
end

macro parse_class_superclasses_check_for_superclass_symbol(text, array_view, type_table)

    ex = quote
        exp_token_lesst = ExpectedToken(specialchar_t::TokenCategory, less_t::SpecialCharacterType)
        exp_token_colon = ExpectedToken(specialchar_t::TokenCategory, colon_t::SpecialCharacterType)
    
        eq_acc_lt       = EqualityAcceptor(exp_token_lesst)
        eq_acc_c        = EqualityAcceptor(exp_token_colon)
    
        nseq_acc        = NSequenceAcceptor(eq_acc_lt, eq_acc_c)
        res_opt         = accept(nseq_acc, array_view)
    
        if has_value(res_opt)
            array_view += 2
        else
            error("Superclass <: symbol is expected but found: <error_handling>")
        end    
    end
  
    return esc(ex)
end

macro parse_class_superclasses_grab_and_update_table(text, array_view, type_table)

    ex = quote

        # grab
        superclass_name = extract_nth_as_symbol(text, array_view, 1)
        type_ptr        = TypePointer(superclass_name, type_table)

        # update the table
        push_sentinel_if_not_present!(type_table, superclass_name)

    end

    return esc(ex)
end

macro parse_class_superclasses_one_superclass(text, array_view, type_table)

    ex = quote
        exp_token_iden = ExpectedToken(identifyer_t::TokenCategory)
        eq_acc_iden    = EqualityAcceptor(exp_token_iden)
        res_opt        = accept(eq_acc_iden, array_view)
    
        if has_value(res_opt)
            # only one superclass
            @parse_class_superclasses_grab_and_update_table(text, array_view, type_table)

            array_view     += 1
            push!(class_ir.superclasses, type_ptr)
            # return ([type_ptr], array_view)
            return array_view
        end
    end

    return esc(ex)
end

function parse_class_superclasses_list(text, array_view::AV, type_table::TypeTable, class_ir::Class) where {AV <: AbstractView}

    exp_token_closingcurly = ExpectedToken(specialchar_t::TokenCategory, closing_curly_t::SpecialCharacterType)
    exp_token_comma        = ExpectedToken(specialchar_t::TokenCategory, comma_t::SpecialCharacterType)
    exp_token_iden         = ExpectedToken(identifyer_t::TokenCategory)


    while array_view.first <= array_view.last
        
        token = array_view[1]
        if exp_token_closingcurly == token
            # end of list
            break
        end

        if exp_token_comma == token
            # comma -> skip
            array_view += 1
            continue
        end
        
        if exp_token_iden == token
            @parse_class_superclasses_grab_and_update_table(text, array_view, type_table)

            array_view     += 1
            push!(class_ir.superclasses, type_ptr) # do not rename the type_ptr
            continue
        end


        # nothing could consumed this token -> throw an error
        error("Unrecognised token around line: $(token.first.line), column: $(token.first.column)")
        
    end

    next_array_view = array_view + 1
    return next_array_view
end

function parse_class_superclasses(text, array_view::AV, type_table::TypeTable, class_ir::Class) where {AV <: AbstractView}

    # check for no superclass
    @parse_class_superclasses_no_superclass(text, array_view, type_table)


    # check for superclass symbol
    @parse_class_superclasses_check_for_superclass_symbol(text, array_view, type_table)


    # check for one superclass
    @parse_class_superclasses_one_superclass(text, array_view, type_table)


    # check for potentially multiple superclasses
    exp_token_openingcurly = ExpectedToken(specialchar_t::TokenCategory, opening_curly_t::SpecialCharacterType)
    eq_acc_curly           = EqualityAcceptor(exp_token_openingcurly)
    res_opt                = accept(eq_acc_curly, array_view)

    if has_value(res_opt)
        array_view += 1
        return parse_class_superclasses_list(text, array_view, type_table, class_ir)
    else
        error("Expected a list of superclasses, but found: <error_handling>")
    end

end


