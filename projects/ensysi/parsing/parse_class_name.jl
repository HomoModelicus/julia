




function parse_class_name(text, array_view::AV) where {AV <: AbstractView}

    exp_token_iden  = ExpectedToken(identifyer_t::TokenCategory)
    exp_token_colon = ExpectedToken(specialchar_t::TokenCategory, colon_t::SpecialCharacterType)
    exp_token_class = ExpectedToken(keyword_t::TokenCategory,     kw_class_t::KeywordType )

    eq_acc_iden  = EqualityAcceptor(exp_token_iden)
    eq_acc_colon = EqualityAcceptor(exp_token_colon)
    eq_acc_class = EqualityAcceptor(exp_token_class)

    nseq_acc = NSequenceAcceptor(eq_acc_iden, eq_acc_colon, eq_acc_colon, eq_acc_class)
    res_opt  = accept(nseq_acc, array_view)

    if has_value(res_opt)
        name_as_symbol  = extract_nth_as_symbol(text, res_opt.value, 1)
        next_array_view = array_view + 4

        return (name_as_symbol, next_array_view)
    else
        error("Expected a name before a class e.g. Pt1 :: class, but found: <error handling to be written>?")
    end

end



