







function parse_class(text, array_view::AV, type_table) where {AV <: AbstractView}

    (class_name, array_view)     = parse_class_name(text, array_view)
    class_ir                     = Class(class_name)

    token = array_view[1]
    if haskey(type_table, class_name)
        error("Multiple redefinition of class: $(class_name), at line: $(token.first.line)")
    end

    (class_modifyer, array_view) = parse_class_modifyer(text, array_view)
    array_view                   = parse_class_superclasses(text, array_view, type_table, class_ir)

    
    class_ir.class_modifyer = class_modifyer


    exp_token_newline    = ExpectedToken(newline_t::TokenCategory)
    exp_token_end        = ExpectedToken(keyword_t::TokenCategory,      kw_end_t::KeywordType)
    exp_token_properties = ExpectedToken(keyword_t::TokenCategory,      kw_properties_t::KeywordType)
    exp_token_variables  = ExpectedToken(keyword_t::TokenCategory,      kw_variables_t::KeywordType)
    exp_token_equations  = ExpectedToken(keyword_t::TokenCategory,      kw_equations_t::KeywordType)
    exp_token_models     = ExpectedToken(keyword_t::TokenCategory,      kw_models_t::KeywordType)

    is_well_formed   = false
    intro_array_view = array_view
    while array_view.first <= array_view.last

        token = array_view[1]
        if exp_token_end == token
            # class parsing can be stopped
            is_well_formed = true
            break
        end

        if exp_token_newline == token
            # newline -> skip
            array_view += 1
            continue
        end

        if exp_token_properties == token
            array_view += 1
            array_view = parse_class_properties(text, array_view, type_table, class_ir)
            continue
        end

        if exp_token_variables == token
            array_view += 1
            array_view = parse_class_variables(text, array_view, type_table, class_ir)
            continue
        end
        
        if exp_token_equations == token
            array_view += 1
            array_view = parse_class_equations(text, array_view, class_ir)
            continue
        end

        # not yet, first, figure out, how to represent values, not only types
        # some sort of value | type tag?
        # (models, array_view) = parse_class_models(text, array_view)

        # nothing could consumed this token -> throw an error
        error("Unrecognised token around line: $(token.first.line), column: $(token.first.column)")

    end

    token = intro_array_view[1]
    if !is_well_formed
        error("Class is not well formed, possibly missing end, around line: $(token.first.line)")
    end

    # push this class to the type table
    type_table.table[class_name] = class_ir 

    next_array_view = array_view + 1
    return (class_ir, next_array_view)
end




