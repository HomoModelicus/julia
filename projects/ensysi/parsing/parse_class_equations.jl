

#=


reinit!(working_stacks.lhs_stack)
reinit!(working_stacks.rhs_stack)

next_index = 0
is_lhs     = true
ii         = start_index
while ii <= max_index
    
    token = token_list[ii]

    if token.category == string_t::TokenCategory
        error("Equation cannot have strings in-between")

    elseif token.category == specialchar_t::TokenCategory && token.value == dot_t::SpecialCharacterType

        # check for line continuation
        exp_3dots_tokens = (
            Token(0, 0, specialchar_t::TokenCategory, dot_t::SpecialCharacterType),
            Token(0, 0, specialchar_t::TokenCategory, dot_t::SpecialCharacterType),
            Token(0, 0, specialchar_t::TokenCategory, dot_t::SpecialCharacterType)
            )
        (full_match, next_index) = match_optional_token(token_list, ii, exp_3dots_tokens...)
        if full_match
            # found a line continuation
            exp_newline_token        = Token(0, 0, newline_t::TokenCategory)
            (full_match, next_index) = match_optional_token(token_list, ii, exp_newline_token)
            if !full_match
                error("After a line continuation a newline is expected")
            end
            ii = next_index
        end

    elseif token.category == specialchar_t::TokenCategory && token.value == equal_t::SpecialCharacterType
        # check for equation
        # exp_eq_token             = Token(0, 0, specialchar_t::TokenCategory, equal_t::SpecialCharacterType)
        # (full_match, next_index) = match_optional_token(token_list, ii, exp_eq_token)
        # if full_match
        #     is_lhs = false
        #     ii     = next_index
        # end
        is_lhs = false
        ii += 1

    elseif token.category == newline_t::TokenCategory
        # end of single equation
        next_index = ii + 1
        break
    else
        # push it onto stack
        if is_lhs
            push!(working_stacks.lhs_stack, token)
        else # rhs
            push!(working_stacks.rhs_stack, token)
        end
        ii += 1
    end

end

lhs             = valid_data(working_stacks.lhs_stack)
rhs             = valid_data(working_stacks.rhs_stack)
single_equation = RawEquation(lhs, rhs)

return (single_equation, next_index)

=#


function parse_class_single_equation(text, array_view, class_ir)
    
    lhs_stack = Stack{Token}(128)
    rhs_stack = Stack{Token}(128)
    

    exp_token_newline = ExpectedToken(newline_t::TokenCategory)
    exp_token_string  = ExpectedToken(string_t::TokenCategory)
    exp_token_equal   = ExpectedToken(specialchar_t::TokenCategory, equal_t::SpecialCharacterType)
    exp_token_dot     = ExpectedToken(specialchar_t::TokenCategory, dot_t::SpecialCharacterType)

    eq_acc         = EqualityAcceptor(exp_token_dot)
    nseq_lineconti = NSequenceAcceptor(eq_acc, eq_acc, eq_acc)
    nseq_err       = NSequenceAcceptor(eq_acc, eq_acc)
    


    is_lhs = true
    while array_view.first <= array_view.last
        
        token = array_view[1]

        if exp_token_string == token
            error("Equation cannot have strings in-between, found at: <error_handling>")
        end
        
        if exp_token_newline == token
            # end of single equation
            array_view += 1
            break
        end


        if exp_token_dot == token
            
            # how to handle object property access?
            # -> most likely create an operator for it as well as for comma

            res_opt = accept(nseq_lineconti, array_view)
            if has_value(res_opt)
                # line continuation found
                array_view += 3
                continue
            end
            
            res_opt_err = accept(nseq_err, array_view)
            if has_value(res_opt_err)
                error("Double dots found at line: $(token.first.line)")
            end

            
            # push it onto stack
            if is_lhs
                push!(lhs_stack, token)
            else # rhs
                push!(rhs_stack, token)
            end

            array_view += 1
            continue

        elseif exp_token_equal == token
            is_lhs = false
            array_view += 1
            continue

        else
            # push it onto stack
            if is_lhs
                push!(lhs_stack, token)
            else # rhs
                push!(rhs_stack, token)
            end
            array_view += 1
            continue
        end


        # nothing could consumed this token -> throw an error
        error("Unrecognised token around line: $(token.first.line), column: $(token.first.column)")

    end



    lhs             = valid_data(lhs_stack)
    rhs             = valid_data(rhs_stack)
    single_equation = RawEquation(lhs, rhs)
    push!(class_ir.rawequations, single_equation)

    return array_view
end



function parse_class_equations(text, array_view::AV, class_ir::Class) where {AV <: AbstractView}

    exp_token_end     = ExpectedToken(keyword_t::TokenCategory, kw_end_t::KeywordType)
    exp_token_newline = ExpectedToken(newline_t::TokenCategory)

    exp_token_number  = ExpectedTokenCategory(number_t::TokenCategory)
    exp_token_iden    = ExpectedToken(identifyer_t::TokenCategory)
    exp_token_der     = ExpectedToken(keyword_t::TokenCategory, kw_der_t::KeywordType)
    exp_token_leftp   = ExpectedToken(specialchar_t::TokenCategory, opening_paren_t::SpecialCharacterType)


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

        if  exp_token_iden   == token ||
            exp_token_number == token ||
            exp_token_der    == token ||
            exp_token_leftp  == token

            array_view = parse_class_single_equation(text, array_view, class_ir)
            continue
        end

        tmp = text[token.first.index:token.last.index]
        error("Unrecognised token around line: $(token.first.line), column: $(token.first.column), $(String(tmp))")

    end

    next_array_view = array_view + 1
    return next_array_view

end



