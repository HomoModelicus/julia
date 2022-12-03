


function is_pos_sign(c)
    return c == '+'
end

function is_neg_sign(c)
    return c == '-'
end

function is_sign(text, index)
    return text[index] == '-' || text[index] == '+'
end

function is_decimal_digit(text, index)
    c = text[index]
    return  c == '1' ||
            c == '2' ||
            c == '3' ||
            c == '4' ||
            c == '5' ||
            c == '6' ||
            c == '7' ||
            c == '8' ||
            c == '9' ||
            c == '0'
end

function char_to_num(c)
    return UInt8(c) - UInt8(48)
end

function char_to_num(c, ToType::Type{T})::T where {T}
    return convert(ToType, UInt8(c) - UInt8(48))
end



function parse_sign(c::C) where {C <: AbstractChar}

    has_sign     = false
    is_negative  = false
    do_increment = true

    if is_neg_sign(c)
        has_sign    = true
        is_negative = true
    elseif is_pos_sign(c)
        has_sign = true
    else # no sign -> positive
        do_increment = false
    end

    return (has_sign, is_negative, do_increment)
end


function __integer_body(
    text::TextType,
    start_index::I,
    max_index::I,
    ::Type{T} = Int64
    ) where {
        TextType <: Union{AbstractString, Vector{Char}},
        I <: Integer,
        T <: Integer}

    ii  = start_index
    
    num = zero(T)
    ten = T(10)
    while ii <= max_index
        cn = char_to_num(text[ii], T)
        if cn > 9 || cn < 0
            break
        end
        num  = num * ten + cn
        ii  += 1
    end

    next_index = ii
    return (num, next_index)
end




function parse_integer(
    text::TextType,
    start_index::I,
    max_index::I = length(text),
    ::Type{T} = Int64,
    do_parse_sign = true
    )  where {TextType <: Union{AbstractString, Vector{Char}}, I <: Integer, T <: Integer}

    ii       = start_index
    c        = text[ii]

    (has_sign, is_negative, do_increment) = parse_sign(c)
    ii = do_increment ? ii + 1 : ii

    (num, next_index) = __integer_body(text, ii, max_index, T)

    num        = is_negative ? -num : num
    is_number  = next_index > (start_index + has_sign)
    next_index = is_number ? next_index : start_index

    return (num, next_index)
end




@inline function equivalent_sized_integer(T = Float64)
    s = sizeof(T)
    if s == 8
        Tout = Int64
    elseif s == 4
        Tout = Int32
    elseif s == 2
        Tout = Int16
    else
        Tout = Int64
    end
    return Tout
end

function parse_float(
    text,
    start_index,
    max_index = length(text),
    ::Type{T} = Float64,
    do_parse_sign = true
    ) where {T}

    Tint     = equivalent_sized_integer(T)
    ii       = start_index
    c        = text[ii]

    (has_sign, is_negative, do_increment) = parse_sign(c)
    ii = do_increment ? ii + 1 : ii

    (int_part, next_index) = __integer_body(text, ii, max_index, Tint)
    is_finished = ((next_index >= max_index) || (next_index == ii)) ? true : false
    ii = next_index    

    dec_part   = zero(Tint)
    dec_length = 0
    if !is_finished && text[ii] == '.'
        # decimal places
        ii += 1
        (dec_part, next_index) = __integer_body(text, ii, max_index, Tint)
        dec_length             = next_index - ii
        ii                     = next_index 
        is_finished = next_index >= max_index ? true : false
    end

    exp_part   = zero(Tint)
    exp_length = 0
    if !is_finished && (text[ii] == 'e' || text[ii] == 'E')
        # exponential part
        ii += 1
        (exp_part, next_index) = parse_integer(text, ii, max_index, Tint)
        exp_length             = next_index - ii
        is_finished = next_index >= max_index ? true : false
    end

    ten = T(10)
    num = T(int_part)
    if dec_length > 0
        num += T(dec_part) * ten^(-dec_length)
    end
    if exp_length > 0
        num *= ten^exp_part
    end


    num        = is_negative ? -num : num
    is_number  = next_index > (start_index + has_sign)
    next_index = is_number ? next_index : start_index

    return (num, next_index)

end


# --------------------------------------------------------------------------- #

function tokenize(tokenizer::IntegerTokenizer, text, strptr::StringPointer)

    do_parse_sign = true
    (num, next_index) = parse_integer(text, strptr.index, strptr.max_index, Int, do_parse_sign)

    if next_index <= strptr.index
        token = Token(strptr, next_index, no_match_t::TokenCategory)
    else
        token = Token(strptr, next_index-1, number_t::TokenCategory, num)
        strptr.index = next_index-1
    end

    return token

end

function tokenize(::Type{IntegerTokenizer}, text, strptr::StringPointer)
    tokenizer = IntegerTokenizer()
    return tokenize(tokenizer, text, strptr)
end


# --------------------------------------------------------------------------- #




function tokenize(tokenizer::FloatTokenizer, text, strptr::StringPointer)
    
    # do_parse_sign = tokenizer.parse_sign
    do_parse_sign = true
    (num, next_index) = parse_float(text, strptr.index, strptr.max_index, Float64, do_parse_sign)

    if next_index <= strptr.index
        token = Token(strptr, next_index, no_match_t::TokenCategory)
    else
        token = Token(strptr, next_index-1, number_t::TokenCategory, num)
        strptr.index = next_index-1
    end

    return token
end


function tokenize(::Type{FloatTokenizer}, text, strptr::StringPointer)
    tokenizer = FloatTokenizer()
    return tokenize(tokenizer, text, strptr)
end

