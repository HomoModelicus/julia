
# =========================================================================== #
# Error Functions
# =========================================================================== #

abstract type AbstractErrorFunction
end

struct LeastSquaresErrorFunction <: AbstractErrorFunction
end

function (error_fcn::LeastSquaresErrorFunction)(meas::T, x::T) where {T <: Number}
    dx = -meas + x
    return dx^2
end
function (error_fcn::LeastSquaresErrorFunction)(meas::Vector{T}, x::Vector{T}) where {T}
    dx = sum( (-meas .+ x).^2 )
    return dx
end
function (error_fcn::LeastSquaresErrorFunction)(meas, x::Vector{T}) where {T}
    dx = sum( (-meas .+ x).^2 )
    return dx
end


function differentiate(error_fcn::LeastSquaresErrorFunction, meas, x)
    return -meas + x
end

function eval(error_fcn::LeastSquaresErrorFunction, meas, x)
    return error_fcn(meas, x)
end

function gradient!(error_fcn::LeastSquaresErrorFunction, y_meas, y_out, delta_e)
    for kk = 1:length(delta_e)
        delta_e[kk] = differentiate(error_fcn, y_meas[kk], y_out[kk])
    end
    return delta_e
end

# function error_gradient!(nn::NeuralNetwork, y_meas, y_out, delta_e)
#     return gradient!(nn.error_function, y_meas, y_out, delta_e)
# end
