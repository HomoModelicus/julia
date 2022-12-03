

export KeywordType

@enum KeywordType begin
    kw_no_keyword_t

    kw_true_t
    kw_false_t

    kw_end_t

    kw_class_t
    kw_properties_t
    kw_variables_t
    kw_models_t
    kw_equations_t
    kw_algorithms_t
    
    kw_abstract_t
    kw_connector_t
    kw_block_t
    kw_model_t


    kw_package_t
    kw_function_t
    kw_procedure_t

    # kw_Bool_t
    # kw_Integer_t
    # kw_Real_t

    kw_input_t
    kw_output_t
    kw_acausal_t

    kw_potential_t
    kw_flow_t
    kw_stream_t

    kw_der_t


    kw_SolverOptions_t
    kw_simulate_t
end


for inst in instances(KeywordType)
    @eval export $(Symbol(inst))
end











export int_to_keyword, keyword_to_int


function int_to_keyword(num::Int)
    return KeywordType(num)
end

function keyword_to_int(kw_type::KeywordType)
    return Int(kw_type)
end



# for inst in instances(KeywordType)
#     @eval export $(Symbol(inst))
# end


function key_value_pairs()

    vec = [
        Pair("true",            kw_true_t::KeywordType)
        Pair("false",           kw_false_t::KeywordType)

        Pair("end",             kw_end_t::KeywordType)

        Pair("class",           kw_class_t::KeywordType)
        Pair("properties",      kw_properties_t::KeywordType)
        Pair("variables",       kw_variables_t::KeywordType)
        Pair("models",          kw_models_t::KeywordType)
        Pair("equations",       kw_equations_t::KeywordType)
        Pair("algorithms",      kw_algorithms_t::KeywordType)
    
        Pair("abstract",        kw_abstract_t::KeywordType)
        Pair("connector",       kw_connector_t::KeywordType)
        Pair("block",           kw_block_t::KeywordType)
        Pair("model",           kw_model_t::KeywordType)

        Pair("package",         kw_package_t::KeywordType)
        Pair("function",        kw_function_t::KeywordType)
        Pair("procedure",       kw_procedure_t::KeywordType)
        

        # Pair("Bool",          kw_Bool_t::KeywordType)
        # Pair("Integer",       kw_Integer_t::KeywordType)
        # Pair("Real",          kw_Real_t::KeywordType)

        Pair("input",           kw_input_t::KeywordType)
        Pair("output",          kw_output_t::KeywordType)
        Pair("acausal",         kw_acausal_t::KeywordType)

        Pair("potential",       kw_potential_t::KeywordType)
        Pair("flow",            kw_flow_t::KeywordType)
        Pair("stream",          kw_stream_t::KeywordType)

        Pair("der",             kw_der_t::KeywordType)

        Pair("SolverOptions",   kw_SolverOptions_t::KeywordType)
        Pair("simulate",        kw_simulate_t::KeywordType)
    ]

end

abstract type AbstractKeywordMap end


struct KeywordMap <: AbstractKeywordMap
    keywords::Vector{Vector{Char}}
    values::Vector{KeywordType}
    lengths::Vector{Int}
    n_keywords::Int

    __firsts::Vector{Int}
    __lasts::Vector{Int}

    function KeywordMap()
        kwpairs  = key_value_pairs()
        keywords = map(x -> x.first,  kwpairs)
        values   = map(x -> x.second, kwpairs)

        (kw, val, lengths, firsts, lasts) = preprocess_kw(keywords, values)
        to_char_vec(x) = map(xx->convert.(Char, xx), transcode.(UInt8, x))
        ascii_keywords = to_char_vec(kw)
        n = length(kw)
        return new(ascii_keywords, val, lengths, n, firsts, lasts)
    end
end



function str_isless(a, b)
    if length(a) == length(b)
        return a < b
    else
        return length(a) < length(b)
    end
end


function preprocess_kw(keywords, values)
    
    n_item = length(keywords)
    
    kw     = copy(keywords)
    val    = copy(values)



    pvec    = sortperm(kw, lt = str_isless)
    kw      = kw[pvec]
    val     = val[pvec]
    lengths = length.(kw)

    
    min_length = lengths[1]
    max_length = lengths[end]

    n_l = max_length - min_length + 1
    firsts = zeros(Int, n_l)
    lasts  = zeros(Int, n_l)

    L_act = lengths[1] - 1
    for ii = 1:n_item
        if lengths[ii] > L_act
            fidx         = lengths[ii] - min_length + 1
            firsts[fidx] = ii
            L_act        = lengths[ii]
        end
    end

    for ii = 1:n_l
        start_idx = firsts[ii]
        if start_idx < 1
            continue
        end
        start_val = lengths[start_idx]
        while start_idx <= n_item && lengths[start_idx] <= start_val
            start_idx += 1
        end
        lasts[ii] = start_idx - 1
    end

    return (kw, val, lengths, firsts, lasts)
end

function Base.get(kwmap::KeywordMap, key, default)

    Lk = length(key)
    if Lk < kwmap.lengths[1] || Lk > kwmap.lengths[end]
        return default
    end
    # else might be there

    idx   = Lk - kwmap.lengths[1] + 1
    first = kwmap.__firsts[idx]
    last  = kwmap.__lasts[idx]
    if first > 0
        for ii = first:last
            kw = kwmap.keywords[ii]
            is_same = true
            for kk = 1:Lk
                if kw[kk] != key[kk]
                    is_same = false
                    break
                end
            end
            if is_same
                return kwmap.values[ii]
            end
        end
    end

    return default
end


function get_keyword_type(text, token::Token, keyword_map::M) where {M <: AbstractKeywordMap}

    identifier = view(text, token.first.index:token.last.index)
    type       = get(keyword_map, identifier, kw_no_keyword_t::KeywordType)

    return type
end

function get_keyword_type(name::String, keyword_map::M) where {M <: AbstractKeywordMap}
    type = get(keyword_map, name, kw_no_keyword_t::KeywordType)
    return type
end

function get_keyword_type(name::Symbol, keyword_map::M) where {M <: AbstractKeywordMap}
    return get_keyword_type(string(name), keyword_map)
end



