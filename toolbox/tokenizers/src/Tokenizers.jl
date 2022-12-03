


# whitespace e.g. space, newline etc... -> should the whitespace be its own token or not?
#   -> recover the original string vs saving space
# single characters -> special characters
# character combinations
# string
# number
# comment - what are the line comment, block comment, start end character or combination
# ?boolean - should that be a keyword or shall it have its own kind?
# identifyer
# keywords - must be easily extensible and recognizable

# a token contains
# - view part -> first, last Ascii.StringPosition
# - kind part ->    can it be something "universal"?
#                   how much information can be 
# - optional: value part

# it seems to me, that there is no one-size-fits-all







# include("D:/programming/src/julia/stdlib/Queues/Queues.jl")

include("D:/programming/src/julia/stdlib/stacks/Stacks.jl")
include("D:/programming/src/julia/stdlib/ascii/Ascii.jl")
include("D:/programming/src/julia/toolbox/tabulators/Tabulators.jl") # for check_utils



module Tokenizers
using ..Stacks
using ..Ascii
using ..Tabulators


export  preprocess_string,
        tokenize


include("specchar_types.jl")

include("token.jl")

include("abstract_tokenizer.jl") # independent


include("comment_tokenizers.jl") # AbstractTokenizer, Ascii
include("identifyer_tokenizers.jl")
include("number_tokenizers.jl")
include("specchar_tokenizers.jl")
include("string_tokenizers.jl")
include("whitespace_tokenizers.jl")


include("check_utils.jl") # needs Token and TokenList






function preprocess_string(text::S) where {S <: AbstractString}
    # utf8 -> ascii
    text_uint8 = transcode(UInt8, text)
    text_ascii = convert.(Char, text_uint8)
    return text_ascii 
end

function heuristics_for_init_token_size(n_char)
    # assumption: every 5th char is a token
    n_token = ceil(Int, n_char / 5)
    return n_token
end


macro skip_whitespace()
    ex = quote
        tokenize(WhiteSpaceSkipperTokenzier, text, strptr)
        if is_at_end(strptr); break; end
    end
    return esc(ex)
end

macro is_finished()
    ex = quote
        if is_at_end(strptr); break; end
    end
    return esc(ex)
end

macro push_if_matched()
    ex = quote
        if token.category != no_match_t::TokenCategory
            push!(token_list, token)
            next!(strptr)
        end
    end
    return esc(ex)
end

function tokenize(text; debug_mode = false)

    Ltext       = length(text)
    strptr      = StringPointer(Ltext)
    n_init      = heuristics_for_init_token_size(Ltext)
    token_list  = TokenList(n_init)

    while !is_at_end(strptr)

        if debug_mode
            @show strptr.index
        end

        @skip_whitespace


        token = tokenize(CLineCommentTokenizer, text, strptr)
        @push_if_matched
        @is_finished
        @skip_whitespace

        
        tokenize(CBlockCommentTokenizer, text, strptr)
        @is_finished
        @skip_whitespace
        

        token = tokenize(NewlineTokenizer, text, strptr)
        @push_if_matched
        @is_finished
        @skip_whitespace
        

        token = tokenize(FloatTokenizer, text, strptr)
        @push_if_matched
        @is_finished
        @skip_whitespace


        token = tokenize(IdentifyerTokenizer, text, strptr)
        @push_if_matched
        @is_finished
        @skip_whitespace

        
        token = tokenize(StringTokenizer, text, strptr)
        @push_if_matched
        @is_finished
        @skip_whitespace
        




        tokenize(CLineCommentTokenizer, text, strptr)
        @is_finished
        @skip_whitespace

        tokenize(CBlockCommentTokenizer, text, strptr)
        @is_finished
        @skip_whitespace



        
        token = tokenize(SpecCharTokenizer, text, strptr)
        @push_if_matched
        @is_finished
        @skip_whitespace

    end
    

    return token_list
end




end # module






#=
module ttest
using ..Tokenizers
using BenchmarkTools


str = """
Pt1 :: class
properties // here comes a comment
        T::Real
    end
    /*
    this block must be commented out
    */
    variables
        x::{Real, input} "this a string here"
        y::{Real, output}
    end
    equation
        T * der(y) + 20 * y - 10 = 5* x
    end
end
"""


raw_c_text_1 = """
Pt1 :: class 
        // this is a comment
        properties // every property is parameter in Modelica -> time indepedent
            T::Real
        end
        variables
            /* all of these variables must be abstracted out */
            x::{Real, input} "input signal"
            y::{Real, output} "output signal" // those are 
        end
        equations
            T * der(y) +...
                -4*y = +5* x -10
        end
    end
"""


# text = Tokenizers.preprocess_string(str)
text = Tokenizers.preprocess_string(raw_c_text_1)



n_rep    = 1000
rep_text = repeat( text, n_rep )





# token_list = Tokenizers.lex( text; debug_mode = false)
b = @benchmark token_list = Tokenizers.lex($rep_text; debug_mode = false)
show(stdout, "text/plain", b)

# table = Tokenizers.substitute(text, token_list)
# Tokenizers.showall(table)



# text length = 453 char
# n_tokens    = 64 tokens
# n_lines     = ~15
#
# factor    time micro-sec 10^-6s (median)
# 1         2.82 (n_token = 64, 15)
# 10        27.9 (n_token = 640, 150)
# 100       292  (n_token = 6_400, 1_500)
# 1000      3694 (n_token = 64_000, 15_000)


end

=#


