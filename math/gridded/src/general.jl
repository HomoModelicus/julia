
# =========================================================================== #
# General
# =========================================================================== #

function ramp(x_start, x_delta, x_end)
    return collect( x_start:x_delta:x_end )
end

function linspace(x_start, x_end, x_length::Int)
    if x_length <= 1
        return [x_end]
    end
    x_delta = (x_end - x_start) / (x_length - 1)
    x_ = collect( x_start:x_delta:x_end )
    return x_
end


function mesh_grid(x, y)
    X = [i for i in x, j in 1:length(y)]
    Y = [j for i in 1:length(x), j in y]
    return (X, Y)
end


function logspace(a, b, n::Int = 50)
	retval = 10 .^ collect( LinRange(a, b, n) )
end

function mesh_grid(x, y)
    X = [i for i in x, j in 1:length(y)]
    Y = [j for i in 1:length(x), j in y]
    return (X, Y)
end
