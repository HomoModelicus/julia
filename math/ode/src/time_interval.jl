
# =========================================================================== #
# TimeInterval
# =========================================================================== #

struct TimeInterval
    t_start::Float64
    t_end::Float64
end

function TimeInterval(t_end)
    TimeInterval(0.0, t_end)
end

function TimeInterval(x::A) where {A <: AbstractArray{T} where T}
    TimeInterval(x[1], x[2])
end