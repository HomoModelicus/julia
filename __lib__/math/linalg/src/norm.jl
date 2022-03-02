


function norm_L1(a::Matrix{T}) where {T}
    col_abs_sums = sum(a, dims = 1)
    return maximum(col_abs_sums)
end

function norm_Linf(a::Matrix{T}) where {T}
    row_abs_sums = sum(a, dims = 2)
    return maximum(row_abs_sums)
end

function norm(a::Matrix{T}, norm_sym) where {T}
    if norm_sym === :1
        return norm_L1(a)
    elseif norm_sym === :2
        return norm_L2(a)
    elseif norm_sym === :inf
        return norm_Linf(a)
    else
        # some other p norm
        p = Float64(norm_sym)
        println("for other than 1, 2, or inf there is no implementation yet")
        return zero(T)
    end
end


