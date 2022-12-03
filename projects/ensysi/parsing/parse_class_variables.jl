



function parse_class_single_variables(text, array_view::AV, type_table::TypeTable, class_ir::Class) where {AV <: AbstractView}

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
    exp_token_iden         = ExpectedToken(identifyer_t::TokenCategory)
    exp_token_openingcurly = ExpectedToken(specialchar_t::TokenCategory, opening_curly_t::SpecialCharacterType)

    eq_acc_iden            = EqualityAcceptor(exp_token_iden)
    eq_acc_openingcurly    = EqualityAcceptor(exp_token_openingcurly)
    choice_acc             = ChoiceAcceptor(eq_acc_iden, eq_acc_openingcurly)
    res_opt                = accept(choice_acc, array_view)

    if has_value(res_opt)
        if exp_token_iden == array_view[1]
            type_as_symbol      = extract_nth_as_symbol(text, array_view, 1)
            type_ptr            = TypePointer(type_as_symbol, type_table)
            causility_type      = cas_acausal_t::CausalityKind
            potentiality_type   = pot_potential_t::PotentialityKind

            variable = ClassVariable(name_as_symbol, type_ptr, causility_type, potentiality_type)
            push!(class_ir.variables, variable)

            next_array_view = array_view + 1
        else # curly
            
            array_view += 1

            exp_token_closingcurly = ExpectedToken(specialchar_t::TokenCategory, closing_curly_t::SpecialCharacterType)
            exp_token_newline      = ExpectedToken(newline_t::TokenCategory)
            exp_token_comma        = ExpectedToken(specialchar_t::TokenCategory, comma_t::SpecialCharacterType)

            exp_token_input        = ExpectedToken(keyword_t::TokenCategory, kw_input_t::KeywordType)
            exp_token_output       = ExpectedToken(keyword_t::TokenCategory, kw_output_t::KeywordType)
            exp_token_acausal      = ExpectedToken(keyword_t::TokenCategory, kw_acausal_t::KeywordType)
   
            exp_token_potential    = ExpectedToken(keyword_t::TokenCategory, kw_potential_t::KeywordType)
            exp_token_flow         = ExpectedToken(keyword_t::TokenCategory, kw_flow_t::KeywordType)
            exp_token_stream       = ExpectedToken(keyword_t::TokenCategory, kw_stream_t::KeywordType)
            
            causility_type    = cas_no_causality_t::CausalityKind
            potentiality_type = pot_no_potentiality_t::PotentialityKind

            is_type_defined         = false
            is_causality_defined    = false
            is_potentiality_defined = false

            type_ptr        = TypePointer(:?, type_table) # default error

            while array_view.first <= array_view.last
                token = array_view[1]

                # skip on comma or newline
                if exp_token_closingcurly == token
                    break
                end

                if exp_token_newline == token || exp_token_comma == token
                    array_view += 1
                    continue
                end

                if exp_token_iden == token
                    if is_type_defined
                        error("Multiple type definition at: $(token.first.line), column: $(token.first.column)")
                    else
                        # this is the type
                        is_type_defined = true
                        type_as_symbol  = extract_nth_as_symbol(text, array_view, 1)
                        type_ptr        = TypePointer(type_as_symbol, type_table)
                        array_view     += 1
                    end

                    continue
                end

                
                if  exp_token_input   == token ||
                    exp_token_output  == token ||
                    exp_token_acausal == token

                    if is_causality_defined
                        error("Multiple causality definition at: $(token.first.line), column: $(token.first.column)")
                    else
                        sym                  = token.value |> KeywordType |> Symbol |> String |> s -> s[4:end-2] |> Symbol
                        causility_type       = symbol_to_causality_type(sym)
                        is_causality_defined = true
                        array_view          += 1
                    end

                    continue
                end
            
            
                if  exp_token_potential == token ||
                    exp_token_flow      == token ||
                    exp_token_stream    == token

                    if is_potentiality_defined
                        error("Multiple potentiality definition at: $(token.first.line), column: $(token.first.column)")
                    else
                        sym                     = token.value |> KeywordType |> Symbol |> String |> s -> s[4:end-2] |> Symbol
                        causility_type          = symbol_to_potentiality_type(sym)
                        is_potentiality_defined = true
                        array_view             += 1
                    end

                    continue
                end


                error("Unrecognised token around line: $(token.first.line), column: $(token.first.column)")

            end # while

            if !is_type_defined
                error("Type is not defined around: ...")
            end

            if causility_type == cas_no_causality_t::CausalityKind
                causility_type = cas_acausal_t::CausalityKind
            end

            if potentiality_type == pot_no_potentiality_t::PotentialityKind
                potentiality_type = pot_potential_t::PotentialityKind
            end

            variable = ClassVariable(name_as_symbol, type_ptr, causility_type, potentiality_type)
            push!(class_ir.variables, variable)

            next_array_view = array_view + 1
        end
    else
        error("Expected a type name e.g. Real or a type list e.g. {Real, input} after :: but found: <error_handling>")
    end

    return next_array_view
end




function parse_class_variables(text, array_view::AV, type_table::TypeTable, class_ir::Class) where {AV <: AbstractView}

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
            array_view = parse_class_single_variables(text, array_view, type_table, class_ir)
            continue
        end

        error("Unrecognised token around line: $(token.first.line), column: $(token.first.column)")

    end

    next_array_view = array_view + 1
    return next_array_view
end



