

include("../../../datastructs/src/datastructs_module.jl")


module lexer
using ..datastructs

export  lex_json, 
        TokenType,
        TokenElement,
        TokenList,
        is_left_bracket,
        is_right_bracket,
        is_left_curly_brace,
        is_right_curly_brace,
        is_comma,
        is_colon




function is_left_bracket(t::T) where {T <: Unsigned}
    return t == UInt8('[')
end
function is_right_bracket(t::T) where {T <: Unsigned}
    return t == UInt8(']')
end

function is_left_curly_brace(t::T) where {T <: Unsigned}
    return t == UInt8('{')
end
function is_right_curly_brace(t::T) where {T <: Unsigned}
    return t == UInt8('}')
end

function is_comma(t::T) where {T <: Unsigned}
    return t == UInt8(',')
end
function is_colon(t::T) where {T <: Unsigned}
    return t == UInt8(':')
end

function json_quote()
    return UInt8('"')
end

function is_json_whitespace(char_str::T) where {T <: Unsigned}
    # space " " 32
    # newline "\n" 10
    # carriage return "\r" 13
    # horztab "\t" 9
    return char_str == 32 || char_str == 10 || char_str == 9 || char_str == 13 
end






@enum TokenType begin
    left_curly_t
    right_curly_t
    left_brace_t
    right_brace_t
    colon_t
    comma_t

    null_t
    bool_false_t
    bool_true_t

    number_t
    string_t

    unknown_t
end

struct TokenElement
    type::TokenType
    array_index::Int
end
function TokenElement()
    return TokenElement(unknown_t::TokenType, -1)
end

struct TokenList
    token_stack::datastructs.Stack{TokenElement}
    number_stack::datastructs.Stack{Float64}
    string_stack::datastructs.Stack{String}
end
function TokenList(init_size::Int = 0)
    token_stack = datastructs.Stack{TokenElement}(init_size)
    number_stack = datastructs.Stack{Float64}()
    string_stack = datastructs.Stack{String}()

    return TokenList(token_stack, number_stack, string_stack)
end

function Base.getindex(token_list::TokenList, idx::Int)
    return token_list.token_stack[idx]
end

function Base.getindex(token_list::TokenList, I::Vararg{Int, N}) where {N}
    return token_list.token_stack[I]
end


function Base.show(io::IO, token_list::TokenList)
    println("TokenList object with:")
    println("\ttoken_stack with $(token_list.token_stack.ptr) elements")
    println("\tnumber_stack with $(token_list.number_stack.ptr) elements")
    println("\tstring_stack with $(token_list.string_stack.ptr) elements")
    
    return io
end




function is_left_bracket(t::TokenElement)::Bool
    return t.type == left_brace_t::TokenType
end

function is_right_bracket(t::TokenElement)::Bool
    return t.type == right_brace_t::TokenType
end

function is_left_curly_brace(t::TokenElement)::Bool
    return t.type == left_curly_t::TokenType
end

function is_right_curly_brace(t::TokenElement)::Bool
    return t.type == right_curly_t::TokenType
end

function is_comma(t::TokenElement)::Bool
    return t.type == comma_t::TokenType
end

function is_colon(t::TokenElement)::Bool
    return t.type == colon_t::TokenType
end






function lex_string(json_text, start_idx::Int)

    str_ptr_1::Int = 0
    str_ptr_2::Int = 0

    json_string = nothing
    if json_text[start_idx] != json_quote()
        return (start_idx, str_ptr_1, str_ptr_2)
    end
    L = length(json_text)
    firstidx = start_idx + 1
    @inbounds for ii = firstidx:L
        if json_text[ii] == json_quote()
            json_string = json_text.s[firstidx:ii-1]
            start_idx = ii+1

            str_ptr_1 = firstidx
            str_ptr_2 = ii-1
            break
        end
    end
    return (start_idx, str_ptr_1, str_ptr_2)
end

function lex_number(json_text, start_idx::Int, valid_chars; number_type = Float64)
    json_num = 0.0
    # valid_chars = ('-', 'e', 'E', '.', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' )

    success = false
    L = length(json_text)
    idx = 0
    @inbounds for cc in start_idx:L
        if any(json_text[cc] .== valid_chars) # cc in valid_chars
            idx += 1
        else
            break
        end
    end
    if idx > 0
        success = true
        json_string = SubString(json_text.s, start_idx:idx+start_idx-1)
        json_num = parse(number_type, json_string)
        start_idx += idx
    end
    return (start_idx, json_num, success)
    
end

function lex_bool(json_text, start_idx::Int, str_true, str_false)
    success = false

    Lt = 4 # length("true")
    Lf = 5 # length("false")
    
    L = length(json_text)
    Ltidx = min( Lt+start_idx-1, L )
    Lfidx = min( Lf+start_idx-1, L )

    substr_t = json_text[ start_idx:Ltidx ]
    substr_f = json_text[ start_idx:Lfidx ]
    
    json_bool = false
    if substr_t == str_true # "true"
        json_bool = true
        start_idx += Lt
        success = true
    elseif substr_f == str_false # "false"
        json_bool = false
        start_idx += Lf
        success = true
    end

    return (start_idx, json_bool, success)
end

function lex_null(json_text, start_idx::Int, null_str)
    success = false
    Ln = 4 # length("null")
    L = length(json_text)
    idx = start_idx:min(start_idx+Ln,L)

    
    substr = SubString(json_text.s, idx)
    if substr == null_str # "null"
        success = true
        start_idx += Ln
    end
    return (start_idx, success) 
end

function lex_json(json_text::T) where {T <: AbstractString}

    null_str = codeunits("null")
    str_true = codeunits("true")
    str_false = codeunits("false")
    valid_chars = ('-', 'e', 'E', '.', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' ) .|> UInt8

    Ls = length(json_text)
    if Ls < 1
        return tokens
    end

    start_idx::Int = 1

    token_list = TokenList()
    utf8 = codeunits(json_text)

    @inbounds while start_idx <= Ls
        
        (start_idx, str_ptr_1, str_ptr_2) = lex_string(utf8, start_idx)
        if str_ptr_1 != 0
            json_string = utf8.s[str_ptr_1:str_ptr_2]
            push!(token_list.string_stack, json_string)
            idx = token_list.string_stack.ptr
            push!(token_list.token_stack, TokenElement(string_t::TokenType, idx))
            continue
        end

        (start_idx, json_num, success) = lex_number(utf8, start_idx, valid_chars)
        if success
            push!(token_list.number_stack, json_num)
            idx = token_list.number_stack.ptr
            push!(token_list.token_stack, TokenElement(number_t::TokenType, idx))
            continue
        end

        (start_idx, json_bool, success) = lex_bool(utf8, start_idx, str_true, str_false)
        if success
            if json_bool
                push!(token_list.token_stack, TokenElement(bool_true_t::TokenType, 0))
            else
                push!(token_list.token_stack, TokenElement(bool_false_t::TokenType, 0))
            end
            continue
        end

        (start_idx, success) = lex_null(utf8, start_idx, null_str)
        if success
            push!(token_list.token_stack, TokenElement(null_t::TokenType, 0))
            continue
        end

        if is_json_whitespace(utf8[start_idx])
            start_idx += 1
       
        elseif is_left_curly_brace(utf8[start_idx])
            push!(token_list.token_stack, TokenElement(left_curly_t::TokenType, 0))
            start_idx += 1

        elseif is_right_curly_brace(utf8[start_idx])
            push!(token_list.token_stack, TokenElement(right_curly_t::TokenType, 0))
            start_idx += 1

        elseif is_left_bracket(utf8[start_idx])
            push!(token_list.token_stack, TokenElement(left_brace_t::TokenType, 0))
            start_idx += 1

        elseif is_right_bracket(utf8[start_idx])
            push!(token_list.token_stack, TokenElement(right_brace_t::TokenType, 0))
            start_idx += 1

        elseif is_colon(utf8[start_idx])
            push!(token_list.token_stack, TokenElement(colon_t::TokenType, 0))
            start_idx += 1

        elseif is_comma(utf8[start_idx])
            push!(token_list.token_stack, TokenElement(comma_t::TokenType, 0))
            start_idx += 1

        else
            fi = max(0, start_idx-10)
            ei = min(Ls, start_idx + 10)
            println("$(utf8.s[fi:ei])")
            error("Unexpected character: $(utf8.s[start_idx])")
        end

    end

    return token_list
end


end # lexer




module parser
using ..datastructs
using ..lexer


function parse_json(text)
    Lt = length(text)
    if Lt < 0
        return nothing
    end

    # transform everything into ascii
    token_list = lex_json(text) # @time 
    L = length(token_list.token_stack)
    if L < 1
        return nothing
    end

    start_idx = 1
    (start_idx, json_obj, tokens) = composite_object_parse(token_list, start_idx) # @time 
    return json_obj
end


function strip_key(token_list::TokenList, token_element::TokenElement)
    
    if token_element.type != lexer.string_t
        error("The key in an object must be a string")
    end
    idx = token_element.array_index
    str = token_list.string_stack[idx]
    if str[1] == '"'
        str = chop(str; head = 1, tail = 0)
    end
    if str[end] == '"'
        str = chop(str; head = 0, tail = 1)
    end
    return String(str)
end

function is_type_of(token_element::TokenElement, typedecl::TokenType)
    return token_element.type == typedecl
end

function is_string_type(token_element)
    return is_type_of(token_element, lexer.string_t)
end

function is_number_type(token_element)
    return is_type_of(token_element, lexer.number_t)
end


function composite_object_parse(tokens::TokenList, start_idx::Int)
    
    token_element = tokens[start_idx]

    if is_left_bracket(token_element) # array begin
        start_idx += 1
        return parse_array(tokens, start_idx)

    elseif is_left_curly_brace(token_element) # object begin
        start_idx += 1
        return parse_object(tokens, start_idx)

    else

        if is_string_type(token_element)

            start_idx += 1
            val = tokens.string_stack[ token_element.array_index ]
            return (start_idx, val, tokens)

        elseif is_number_type(token_element)

            start_idx += 1
            val = tokens.number_stack[ token_element.array_index ]
            return (start_idx, val, tokens)

        elseif is_type_of(token_element, lexer.null_t)
            start_idx += 1
            return (start_idx, NaN, tokens)

        elseif is_type_of(token_element, lexer.bool_true_t)
            start_idx += 1
            return (start_idx, true, tokens)

        elseif is_type_of(token_element, lexer.bool_false_t)
            start_idx += 1
            return (start_idx, false, tokens)

        end

        # default
        start_idx += 1
        return (start_idx, token_element, tokens)
    end
end

function parse_array(tokens, start_idx)

    array = Vector{Any}(undef, 0)
    
    t = tokens[1]
    if is_right_bracket(t)
        start_idx += 1
        return (start_idx, array, tokens)
    end

    while true # avoid infinite loop

        (start_idx, element_value, tokens) = composite_object_parse(tokens, start_idx)
        push!(array, element_value)

        t = tokens[start_idx]
        if is_right_bracket(t)
            start_idx += 1
            return (start_idx, array, tokens)
        elseif !is_comma(t)
            error("Expected a comma after object in the array")
        else
            start_idx += 1
            # tokens = tokens[2:end]
        end

    end

    return (start_idx, array, tokens)
end

function parse_object(tokens, start_idx)
    
    json_obj = Dict{String, Any}()
    
    t = tokens[start_idx]
    if is_right_curly_brace(t)
        return (start_idx, json_obj, tokens)
    end

    while true

        key = tokens[start_idx]
        key = strip_key(tokens, key)
        start_idx += 1 # start index is increased if it is a valid key == doesnt throw an error

        if !is_colon(tokens[start_idx])
            error("Expected a colon, but got: $(token[start_idx])")
        end

        start_idx += 1
        (start_idx, value, tokens) = composite_object_parse(tokens, start_idx)
        json_obj[key] = value

        t = tokens[start_idx]
        if is_right_curly_brace(t)
            start_idx += 1
            return (start_idx, json_obj, tokens)
        elseif !is_comma(t)
            error("Expected comma after object but got: $(t)")
        end

        start_idx += 1
    end
    return (start_idx, json_obj, tokens)
end




end # parser





module json
using ..lexer
using ..parser


function parse(json_text)
    return parser.parse_json(json_text)
end

end





