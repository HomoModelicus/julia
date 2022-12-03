

module Ascii

export  AsciiString,
        #
        AsciiStringView,
        make_view,
        make_next_view,
        next_firstindex,
        PositionAsciiStringView,
        #
        StringPosition,
        #
        StringPointer,
        next!,
        nextline!,
        is_at_end





# =========================================================================== #
# StringPointer
# =========================================================================== #

mutable struct StringPointer
    index::Int # current index in the string
    line::Int
    column::Int
    const max_index::Int

    function StringPointer(max_index)
        return new(1, 1, 1, max_index)
    end
end


function next!(strptr::StringPointer)
    strptr.index += 1
    return strptr
end

function next!(strptr::StringPointer, increment::Int)
    strptr.index += increment
    return strptr
end

function nextline!(strptr::StringPointer)
    strptr.index += 1
    strptr.line  += 1
    strptr.column = 1
    return strptr
end

function is_valid(strptr::StringPointer)
    return strpos.index <= 0
end

function is_at_end(strptr::StringPointer)
    return strptr.index > strptr.max_index
end

# =========================================================================== #
# StringPosition
# =========================================================================== #


struct StringPosition
    index::Int  # most likely cannot be Int32 for general use-case
    line::Int   # could be maybe Int32
    column::Int # could be maybe Int32

    function StringPosition(index, line, column)
        return new(index, line, column)
    end

    function StringPosition(strpos::StringPosition, new_index::Int)
        # index  = strpos.index + increment
        index  = new_index
        line   = strpos.line
        column = strpos.column
        return StringPosition(index, line, column)
    end

    function StringPosition(strptr::StringPointer)
        return StringPosition(strptr.index, strptr.line, strptr.column)
    end

    function StringPosition()
        return StringPosition(0, 0, 0)
    end
end

function is_valid(strpos::StringPosition)
    return strpos.index <= 0
end

function Base.:(==)(strpos1::StringPosition, strpos2::StringPosition)
    return  strpos1.index  == strpos2.index &&
            strpos1.line   == strpos2.line &&
            strpos1.column == strpos2.column
end

function Base.isless(strpos1::StringPosition, strpos2::StringPosition)
    return isless(strpos1.index, strpos2.index)
end

# =========================================================================== #
# Utils
# =========================================================================== #


function limit_char(c, mod = 256)
    return Char( Int(c) % mod )
end

function string_to_ascii(str::S) where {S <: AbstractString}
    v = transcode(UInt16, str)
    a = map( limit_char, v )
    return a
end


# =========================================================================== #
# AsciiString
# =========================================================================== #

struct AsciiString <: AbstractArray{Char, 1}
    vector::Vector{Char}

    function AsciiString(str::S) where {S <: AbstractString}
        a = string_to_ascii(str)
        return new(a)
    end

    function AsciiString(n_size::Int)
        v = Vector{Char}(undef, n_size)
        return new(v)
    end
end

function Base.IndexStyle(::Type{AsciiString})
    return IndexLinear()
end

function Base.getindex(asciistr::AsciiString, index::Int)
    return asciistr.vector[index]
end

function Base.firstindex(asciistr::AsciiString)
    return firstindex(asciistr.vector)
end

function Base.lastindex(asciistr::AsciiString)
    return lastindex(asciistr.vector)
end

function Base.size(asciistr::AsciiString)
    return size(asciistr.vector)
end

function Base.String(asciistr::AsciiString)
    return String(asciistr.vector)
end

function to_string(asciistr::AsciiString)
    return String(asciistr.vector)
end



# =========================================================================== #
# AsciiStringView
# =========================================================================== #

"""
AsciiStringView
non owning view into a string
unsafe if the underlying vector gets deallocated
"""
struct AsciiStringView <: AbstractRange{Char}
    ptr::Ptr{Char}
    first::Int
    last::Int

    function AsciiStringView(
        asciistring::AsciiString,
        first::Int = firstindex(asciistring),
        last::Int = lastindex(asciistring))

        ptr = pointer(asciistring.vector)
        (first, last) = minmax(first, last)
        return new(ptr, first, last)
    end
    
    function AsciiStringView()
        return AsciiStringView(Ptr{Char}(0), 0, 0)
    end

    function AsciiStringView(ptr::Ptr{Char}, first::Int, last::Int)
        return new(ptr, first, last)
    end
end

function make_view(
    asciistring::AsciiString,
    first::Int = firstindex(asciistring),
    last::Int  = lastindex(asciistring))

    return AsciiStringView(asciistring, first, last)
end

function make_view(
    strview::AsciiStringView,
    first::Int = firstindex(strview),
    last::Int  = lastindex(strview))

    return AsciiStringView(strview.ptr, first, last)
end

function make_view(
    from_view::AsciiStringView,
    last::Int)

    return AsciiStringView(from_view.ptr, from_view.first, last)
end

function next_firstindex(strview::AsciiStringView, increment = 1)
    return strview.first + increment
end

function make_next_view(strview::AsciiStringView, increment = 1)
    return AsciiStringView(strview.ptr, strview.first + increment, strview.last)
end

function make_next_view(parent::AsciiStringView, successfull::AsciiStringView)
    ptr   = parent.ptr
    last  = parent.last
    first = successfull.last + 1
    return AsciiStringView(ptr, first, last)
end


function Base.length(asciisv::AsciiStringView)
    return asciisv.last - asciisv.first + 1
end

function Base.IndexStyle(::Type{AsciiStringView})
    return IndexLinear()
end

function Base.getindex(asciisv::AsciiStringView, index::Int) # ::Char
    return unsafe_load(asciisv.ptr, index - 1 + asciisv.first)
end

function Base.firstindex(asciisv::AsciiStringView)
    return asciisv.first
end

function Base.lastindex(asciisv::AsciiStringView)
    return asciisv.last
end

function Base.size(asciisv::AsciiStringView)
    return (length(asciisv), )
end

function Base.first(asciisv::AsciiStringView)
    return asciisv[1] # asciisv[ firstindex(asciisv) ]
end

function Base.last(asciisv::AsciiStringView)
    return asciisv[length(asciisv)] # asciisv[ lastindex(asciisv) ]
end

function Base.show(io::IO, ::MIME"text/plain", asciisv::AsciiStringView)
    if get(io, :compact, false)
        return show(io, asciisv)
    else
        println(io, "AsciiStringView with properties:")
        println(io, "   ptr: $(asciisv.ptr)")
        println(io, " first: $(asciisv.first)")
        println(io, "  last: $(asciisv.last)")
    end
end

function Base.show(io::IO, asciisv::AsciiStringView)
    print(io, "AsciiStringView($(asciisv.ptr), $(asciisv.first), $(asciisv.last))")
end

function Base.String(asciisv::AsciiStringView)
    return to_string(asciisv)
end

function to_string(asciisv::AsciiStringView)
    asciistr = to_ascii_string(asciisv)
    return String(asciistr)
end

function to_ascii_string_copy(asciisv::AsciiStringView)
    N   = length(asciisv)
    str = AsciiString(N)
    for ii in eachindex(1:N)
        str.vector[ii] = asciisv[ii]
    end
    return str
end

function to_ascii_string(asciisv::AsciiStringView)
    N   = length(asciisv)
    vec = unsafe_wrap(Vector{Char}, asciisv.ptr + sizeof(Char) * (asciisv.first - 1), N; own = false)
    return vec
end













"""
PositionAsciiStringView
non owning view into a string
unsafe if the underlying vector gets deallocated
"""
struct PositionAsciiStringView <: AbstractRange{Char}
    ptr::Ptr{Char}
    first::StringPosition
    last::StringPosition

    function PositionAsciiStringView(
        asciistring::AsciiString,
        first::StringPosition,
        last::StringPosition)

        ptr = pointer(asciistring.vector)
        return new(ptr, first, last)
    end

    function PositionAsciiStringView(ptr::Ptr{Char}, first::StringPosition, last::StringPosition)
        return new(ptr, first, last)
    end
end

function Base.length(asciisv::PositionAsciiStringView)
    return asciisv.last.index - asciisv.first.index + 1
end

function Base.IndexStyle(::Type{PositionAsciiStringView})
    return IndexLinear()
end

function Base.getindex(asciisv::PositionAsciiStringView, index::Int)
    return unsafe_load(asciisv.ptr, index - 1 + asciisv.first.index)
end

function Base.firstindex(asciisv::PositionAsciiStringView)
    return asciisv.first.index
end

function Base.lastindex(asciisv::PositionAsciiStringView)
    return asciisv.last.index
end

function Base.size(asciisv::PositionAsciiStringView)
    return (length(asciisv), )
end

function Base.first(asciisv::PositionAsciiStringView)
    return asciisv[1]
end

function Base.last(asciisv::PositionAsciiStringView)
    return asciisv[length(asciisv)]
end

function Base.show(io::IO, ::MIME"text/plain", asciisv::PositionAsciiStringView)
    if get(io, :compact, false)
        return show(io, asciisv)
    else
        println(io, "PositionAsciiStringView with properties:")
        println(io, "   ptr: $(asciisv.ptr)")
        println(io, " first: $(asciisv.first)")
        println(io, "  last: $(asciisv.last)")
    end
end

function Base.show(io::IO, asciisv::PositionAsciiStringView)
    print(io, "PositionAsciiStringView($(asciisv.ptr), ($(asciisv.first)), ($(asciisv.last)))")
end

function Base.String(asciisv::PositionAsciiStringView)
    return to_string(asciisv)
end

function to_string(asciisv::PositionAsciiStringView)
    asciistr = to_ascii_string(asciisv)
    return String(asciistr)
end

function to_ascii_string_copy(asciisv::PositionAsciiStringView)
    N   = length(asciisv)
    str = AsciiString(N)
    for ii in eachindex(1:N)
        str.vector[ii] = asciisv[ii]
    end
    return str
end

function to_ascii_string(asciisv::AsciiStringView)
    N   = length(asciisv)
    vec = unsafe_wrap(Vector{Char}, asciisv.ptr + sizeof(Char) * (asciisv.first - 1), N; own = false)
    return vec
end




end # module





