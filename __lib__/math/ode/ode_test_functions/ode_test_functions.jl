

# matlab like function definitions

module odesample


# harmonic ode with damping
# Lotka–Volterra equations
# duffin eq
# hopf
# van der pol
# heat eq
# logistic
# lorenz
# euler rigid body



# =========================================================================== #
# General
# =========================================================================== #


function std_zero(x)
    return 0.0
end



# =========================================================================== #
# Harmonic Oscillator
# =========================================================================== #

struct HarmonicOscillatorOptions{T<:Function}
    m::Float64
    d::Float64
    c::Float64
    f::T # function
    function HarmonicOscillatorOptions{T}(m, d, c, f::T) where {T <: Function}
        return new(m, d, c, f)
    end
end
function HarmonicOscillatorOptions(m, d, c, f)
    HarmonicOscillatorOptions{typeof(f)}(m, d, c, f)
end
function HarmonicOscillatorOptions(m, d, c)
    HarmonicOscillatorOptions{typeof(std_zero)}(m, d, c, std_zero)
end

function HarmonicOscillatorOptions()
    return HarmonicOscillatorOptions(1.0, 0.3, 2.0)
end

function HarmonicOscillatorOptions(;
    m = 1.0,
    d = 0.3,
    c = 2.0,
    f = std_zero)
    return HarmonicOscillatorOptions(m, d, c, f)
end


function harmonic_oscillator!(der_q, t, q, options::HarmonicOscillatorOptions)

    x = q[1]
    v = q[2]

    dxdt = v
    dvdt = 1/options.m * (options.f(t) - options.c * x - options.d * v )

    der_q[1] = dxdt
    der_q[2] = dvdt

    return der_q
end


function harmonic_oscillator_controller!(der_q, t, q, options::HarmonicOscillatorOptions)

    x = q[1]
    v = q[2]

    dxdt = v
    dvdt = 1/options.m * (options.f(t, q) - options.c * x - options.d * v )
    
    der_q[1] = dxdt
    der_q[2] = dvdt

    return der_q
end



# =========================================================================== #
# Brusselator equations
# =========================================================================== #

struct BrusselatorOptions
    a::Float64
    b::Float64
end
function BrusselatorOptions()
    return BrusselatorOptions(1.0, 3.0)
end


function brusselator!(der_q, t, q, options::BrusselatorOptions)
    x = q[1]
    y = q[2]

    dxdt = options.a + x^2 * y - options.b * x - x
    dydt = options.b * x - x^2 * y

    der_q[1] = dxdt
    der_q[2] = dydt

    return der_q
end



# =========================================================================== #
# Lotka–Volterra equations
# =========================================================================== #


struct LotkaVolterraOptions
    a::Float64
    b::Float64
    c::Float64
    d::Float64
end
function LotkaVolterraOptions()
    return LotkaVolterraOptions(1.1, 0.4, 0.4, 0.1)
end

function lotkavolterra!(der_q, t, q, options::LotkaVolterraOptions)
    x = q[1]
    y = q[2]

    dxdt = options.a * x - options.b * x * y
    dydt = options.d * x * y - options.c * y

    der_q[1] = dxdt
    der_q[2] = dydt

    return der_q
end


# =========================================================================== #
# Duffin equations
# =========================================================================== #

struct DuffinOptions
    d::Float64
    c1::Float64
    c3::Float64
    F::Float64
    omega::Float64
end
function DuffinOptions()
    return DuffinOptions(0.02, 1.0, 5.0, 8.0, 0.5)
end


function duffin!(der_q, t, q, options)
    x = q[1]
    v = q[2]

    dxdt = v
    dvdt = omega.F * cos(options.omega * t) - options.d * v - options.c1 * x - options.c3 * x^3

    der_q[1] = dxdt
    der_q[2] = dvdt

    return der_q
end



# =========================================================================== #
# Hopf equations
# =========================================================================== #

struct HopfOptions
    a::Float64
    b::Float64
end
function HopfOptions()
    return HopfOptions(0.1, 0.75)
end

function hopf!(der_q, t, q, options::HopfOptions)
    x = q[1]
    y = q[2]

    dxdt = - x + options.a * y + x^2 * y
    dydt = options.b - options.a *y - x^2 * y

    der_q[1] = dxdt
    der_q[2] = dydt

    return der_q
end


# =========================================================================== #
# Van der Pol equations
# =========================================================================== #

struct VanDerPolOptions
    d::Float64
end
function VanDerPolOptions()
    return VanDerPolOptions(1.0)
end

function van_der_pol!(der_q, t, q, options::VanDerPolOptions)

    x = q[1]
    v = q[2]

    dxdt = v
    dvdt = options.d * (1 - x^2) * v - x

    der_q[1] = dxdt
    der_q[2] = dvdt

    return der_q
end


# =========================================================================== #
# Heat equations
# =========================================================================== #

struct HeatOptions
    tau::Float64
end
function HeatOptions()
    return HeatOptions(2.0)
end

function heat_eq!(der_q, t, q, options::HeatOptions)
    der_q[1] = -options.tau * q
    return der_q
end


# =========================================================================== #
# Logistic equations
# =========================================================================== #


struct LogisticOptions
    tau::Float64
end
function LogisticOptions()
    return LogisticOptions(1.0)
end

function logistic!(der_q, t, q, options::LogisticOptions)
    der_q[1] = options.tau * q * (1 - q)
    return der_q
end



# =========================================================================== #
# Lorenz equations
# =========================================================================== #

struct LorenzOptions
    sigma::Float64
    rho::Float64
    beta::Float64
end
function LorenzOptions()
    return LorenzOptions(10.0, 28.0, 8/3)
end

function lorenz!(der_q, t, q, options::LorenzOptions)

    x = q[1]
    y = q[2]
    z = q[3]
    
    dxdt = options.sigma * (y - x)
    dydt = x * (options.rho - z) - y
    dzdt = x * y - options.beta * z

    der_q[1] = dxdt
    der_q[2] = dydt
    der_q[3] = dzdt

    return der_q
end


# =========================================================================== #
# Euler Rigid Body equations
# =========================================================================== #
# not implemented yet


# =========================================================================== #
# Stiff test 1
# =========================================================================== #

function stiff_test_v1(der_q, t, q)

    der_q[1] = -0.013 * q[1] - 1000 * q[1] * q[3]
    der_q[2] = -2500 * q[2] * q[3]
    der_q[3] = -0.013 * q[1] - 1000 * q[1] * q[3] -2500 * q[2] * q[3]

end



end


