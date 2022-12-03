


# =========================================================================== #
# AnyAcceptor
# =========================================================================== #

# excepts everything
# the result optional is true
# the view last is zero, the first is the previous index
struct AnyAcceptor <: AbstractAcceptor
end

function accept(
    acceptor::AnyAcceptor,
    array_view::AV
    ) where {AV <: AbstractView}

    matched_view = AV(array_view, array_view.first, 0)

    res_opt = StdOptional(true, matched_view)
    return res_opt
end


# =========================================================================== #
# NothingAcceptor
# =========================================================================== #

# rejects everything
# the result optional is false
# the view last is zero, the first is the previous index
struct NothingAcceptor <: AbstractAcceptor
end

function accept(
    acceptor::NothingAcceptor,
    array_view::AV
    ) where {AV <: AbstractView}

    matched_view = AV(array_view, array_view.first, 0)

    res_opt = StdOptional(false, matched_view)
    return res_opt
end






# basic boolean operators
# ==
# !=
# < <=
# > >=



# =========================================================================== #
# EqualityAcceptor
# =========================================================================== #

struct EqualityAcceptor{T} <: AbstractAcceptor
    acceptant::T # element is compared with, by ==

    function EqualityAcceptor{T}(acceptant::T) where {T}
        return new(acceptant)
    end

    function EqualityAcceptor(acceptant::T) where {T}
        return EqualityAcceptor{T}(acceptant)
    end
end

function accept(
    acceptor::EqualityAcceptor,
    array_view::AV
    ) where {AV <: AbstractView}

    elem  = array_view[firstindex(array_view)]
    is_eq = acceptor.acceptant == elem
    
    if is_eq
        matched_view = AV(array_view, array_view.first, array_view.first)
    else
        matched_view = make_zero_view(array_view)
    end
    
    res_opt = StdOptional(is_eq, matched_view)
    return res_opt
end












