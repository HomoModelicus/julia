

const default_token_value = Int(0)


export ExpectedToken

struct ExpectedToken
    category::TokenCategory
    value::Union{Float64, Int, SpecialCharacterType, KeywordType}

    function ExpectedToken(category, value = default_token_value)
        return new(category, value)
    end

    function ExpectedToken(category)
        return ExpectedToken(category, default_token_value)
    end
end

function Base.:(==)(expected_token_1::ExpectedToken, expected_token_2::ExpectedToken)
    return  expected_token_1.category == expected_token_2.category &&
            expected_token_1.value    == expected_token_2.value
end


function Base.:(==)(expected_token::ExpectedToken, act_token::Token)
    if expected_token.category == act_token.category

        if expected_token.category == keyword_t::TokenCategory
            exp_val = Int(expected_token.value)
            act_val = Int(act_token.value)
        else
            exp_val = expected_token.value
            act_val = act_token.value
        end
        return exp_val == act_val
    else
        return false
    end        
end

# is this overload even necessary? -> yes, otherwise false is returned... hmmm...
function Base.:(==)(act_token::Token, expected_token::ExpectedToken)
    return Base.:(==)(expected_token, act_token)
end


# --------------------------------------------------------------------------- #

struct ExpectedTokenCategory
    category::TokenCategory
end


function Base.:(==)(expected_token_1::ExpectedTokenCategory, expected_token_2::ExpectedTokenCategory)
    return expected_token_1.category == expected_token_2.category
end

function Base.:(==)(expected_token::ExpectedTokenCategory, act_token::Token)
    return expected_token.category == act_token.category
end

function Base.:(==)(act_token::Token, expected_token::ExpectedTokenCategory)
    return Base.:(==)(expected_token, act_token)
end



