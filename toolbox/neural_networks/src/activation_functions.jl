
# =========================================================================== #
# Activation Functions
# =========================================================================== #


abstract type AbstractActivationFunction
end

struct TanhActivationFunction <: AbstractActivationFunction
end

function (act_fcn::TanhActivationFunction)(x)
    return tanh(x)
end

function differentiate(act_fcn::TanhActivationFunction, x)
    return one(typeof(x)) - act_fcn(x)^2
end

function eval(act_fcn::TanhActivationFunction, x)
    return act_fcn(x)
end



struct ReluActivationFunction <: AbstractActivationFunction
end

function (act_fcn::ReluActivationFunction)(x)
    T = typeof(x)
    z = zero(T)
    return (x < z) * z + (x >= z) * x
end

function differentiate(act_fcn::ReluActivationFunction, x)
    T = typeof(x)
    z = zero(T)
    return (x < z) * z + (x >= z) * one(T)
end

function eval(act_fcn::ReluActivationFunction, x)
    return act_fcn(x)
end





struct IdentityActivationFunction <: AbstractActivationFunction
end

function (act_fcn::IdentityActivationFunction)(x)
    return x
end

function differentiate(act_fcn::IdentityActivationFunction, x)
    return one(typeof(x))
end

function eval(act_fcn::IdentityActivationFunction, x)
    return act_fcn(x)
end
