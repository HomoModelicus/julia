


module Tabulators


function __align_helper(str_vec)
    Ls      = map(str -> length(str), str_vec)
    Lmax    = maximum(Ls)
    dL      = Lmax .- Ls
    return dL
end

function left_align!(str_vec::Vector{S}, separator = "", is_rightmost = false) where {S <: AbstractString}
    # text whitespace

    dL = __align_helper(str_vec)
    ws = " "

    for ii = eachindex(str_vec)[begin:end-1]
        str_vec[ii] = str_vec[ii] * (ws^dL[ii]) * separator
    end
    if is_rightmost
        str_vec[end] = str_vec[end] * (ws^dL[end])
    else
        str_vec[end] = str_vec[end] * (ws^dL[end]) * separator
    end

    return str_vec
end

function right_align!(str_vec::Vector{S}, separator = "", is_rightmost = false) where {S <: AbstractString}
    # text whitespace

    dL = __align_helper(str_vec)
    ws = " "

    for ii = eachindex(str_vec)[begin:end-1]
        str_vec[ii] = (ws^dL[ii]) * str_vec[ii] * separator
    end
    if is_rightmost
        str_vec[ii] = (ws^dL[ii]) * str_vec[ii]
    else
        str_vec[ii] = (ws^dL[ii]) * str_vec[ii] * separator
    end

    return str_vec
end


abstract type AbstractAlignment end
struct LeftAlignment <: AbstractAlignment
    separator::String
    
    function LeftAlignment(sep = "    ")
        return new(string(sep))
    end
end

struct RightAlignment <: AbstractAlignment
    separator::String
    
    function RightAlignment(sep = "    ")
        return new(string(sep))
    end
end


function align!(aligment::LeftAlignment, str_vec, is_rightmost = false)
    return left_align!(str_vec, aligment.separator, is_rightmost)
end

function align!(aligment::RightAlignment, str_vec, is_rightmost = false)
    return right_align!(str_vec, aligment.separator, is_rightmost)
end

function tabulate!(alignment::A, str_tuple::Vararg{Vector{S}}) where {S <: AbstractString, A <: AbstractAlignment}

    n_vec = length(str_tuple)
    is_rightmost = false
    for ii = eachindex(str_tuple)
        if ii == n_vec
            is_rightmost = true
        end
        align!(alignment, str_tuple[ii], is_rightmost)
    end

    return str_tuple
end

function tabulate!(str_tuple::Vararg{Vector{S}}) where {S <: AbstractString}
    alignment = LeftAlignment()
    return tabulate!(alignment, str_tuple...)
end


function showall(str_tuple::Vararg{Vector{S}}) where {S <: AbstractString}
    n_vec = length(str_tuple)
    if n_vec < 1
        return nothing
    end
    L = length(str_tuple[1])
    for jj = 1:L
        for ii = 1:n_vec
            print(str_tuple[ii][jj])
        end
        print('\n')
    end
end

function showall(str_tuple)
    return showall(str_tuple...)
end


end


#=
module ttest
using ..tabulators

str_1 = ["sfbf", "fdg dfger", "dfgd", "a", "dfg d"]
str_2 = ["fdg dfger", "a", "sfbf", "dfgd", "dfg d"]
str_3 = ["sfbf", "fdg dfger", "dfgd", "a", "dfg d"]


t = tabulators.tabulate!(copy(ttest.str_1), copy(ttest.str_2)) # |> tabulators.showall


end
=#

