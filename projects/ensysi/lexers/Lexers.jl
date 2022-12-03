

include("D:/programming/src/julia/toolbox/tokenizers/Tokenizers.jl")


module Lexers
using ..Tokenizers

# include("keyword_types.jl")
include("keywords.jl")





# struct KwToken
#
#     first::StringPosition
#     last::StringPosition
#     category::TokenCategory
#     value::Union{Float64, KeywordType, SpecialCharacterType}
#
#
#
#     function Token(
#         first::StringPosition,
#         last::StringPosition,
#         category::TokenCategory,
#         value = default_token_value)
#
#         return new(first, last, category, value)
#     end
# end






const keyword_map = KeywordMap()

function subsitute_keywords!(text, token_list, keyword_map = keyword_map)

    for (ii, token) in enumerate(token_list)
        # possibly valid identifyer
        # check whether it is a keyword

        if token.category == identifyer_t::TokenCategory

            keyword_type = get_keyword_type(text, token, keyword_map)

            if keyword_type != kw_no_keyword_t::KeywordType
                # keyword
                keyword_num = keyword_to_int(keyword_type)
                new_token = Token(
                    token.first,
                    token.last,
                    keyword_t::TokenCategory,
                    keyword_num)

                token_list[ii] = new_token
            end

        end
    end

    return token_list
end



function keyword_value_transformator(val)

    if val isa Int64
        return int_to_keyword(val)
    else
        return val
    end

end

function substitute(text, token_list::TokenList; value_transformator = keyword_value_transformator)
    return Tokenizers.substitute(text, token_list; value_transformator = value_transformator)
end



end


#=

include("../test/src.jl")

module ttest
using ..Lexers
using ..src

text = Lexers.preprocess_string(raw_c_text_1)

token_list = Lexers.tokenize( text; debug_mode = false)
token_list = Lexers.subsitute_keywords!(text, token_list)

table = Lexers.substitute(text, token_list)
Lexers.showall(table)


end

=#



