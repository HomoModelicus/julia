




function parse_class_modifyer(text, array_view::AV) where {AV <: AbstractView}

    exp_token_openingparen = ExpectedToken(specialchar_t::TokenCategory, opening_paren_t::SpecialCharacterType)
    exp_token_mod          = ExpectedTokenCategory(keyword_t::TokenCategory)
    exp_token_closingparen = ExpectedToken(specialchar_t::TokenCategory, closing_paren_t::SpecialCharacterType)
    
    eq_acc_leftparen       = EqualityAcceptor(exp_token_openingparen)
    eq_acc_iden            = EqualityAcceptor(exp_token_mod)
    eq_acc_rightparen      = EqualityAcceptor(exp_token_closingparen)
    nseq_acc               = TupleSequenceAcceptor(eq_acc_leftparen, eq_acc_iden, eq_acc_rightparen)

    opt_acc = OptionalAcceptor(nseq_acc)
    res_opt = accept(opt_acc, array_view)

    if has_value(res_opt)
        # if the AnyAcceptor succeeds:
        # the view last is zero, the first is the previous index
        accepted_view = res_opt.value
        L             = length(accepted_view)

        if L > 0

            modifyer_symbol   = extract_nth_as_symbol(text, res_opt.value, 2)
            modifyer_optional = symbol_to_class_modifyer(modifyer_symbol)

            if has_value(modifyer_optional)
                modifyer_kind   = modifyer_optional.value
                next_array_view = array_view + 3
            else
                error("Unrecognised class modifyer found: $(String(modifyer_symbol)), at line: <error_handling>")
            end
        else
            # use default
            modifyer_kind   = model_t::ClassModifyerKind
            next_array_view = array_view
        end
    else
        error("This never shall be executed, if yes, something went wrong")
    end

    return (modifyer_kind, next_array_view)
end

