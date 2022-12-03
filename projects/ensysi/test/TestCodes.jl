

module TestCodes

export  raw_c_text_1,
        raw_c_text_2,
        raw_c_text_3,
        raw_c_text_4,
        raw_c_text_5,
        raw_p_text_1,
        raw_ex_1,
        raw_ex_simplified_1,
        raw_ex_simplified_2



#=

every parameter can be default initialized, if not, zero is assumed
for class parameters every field is zerod out -> this is the default constructor


=#


#=
"""
println :: function(str::String) -> Nothing
    // function body
end
"""



"""
Pt1 :: class
    properties
        T::Real
    end
    variables
        x::{Real, input}
        y::{Real, output}
    end
    equation
        T * der(y) + y = x
    end
end
"""

"""
AbstractSI :: class (Abstract)
    variables
        x::RealInput
    end
end
"""

"""
RealInput :: class (connector) = {Real, input} // basically a typedef
// should be the same as
x::RealInput <=> x::{Real, input}
"""

"""
MechPort :: class (connector)
    variables
        x::{Real, potetial}
        F::{Real, flow}
    end
end
"""
=#

raw_c_text_1 = """
    Pt1 :: class 
        // this is a comment
        properties // every property is parameter in Modelica -> time indepedent
            T::Real = 0.1
            G::Real = 1
        end
        variables
            /* all of these variables must be abstracted out */
            x::{Real, input} "input signal"
            y::{Real, output} "output signal" // those are 
        end
        equations
            T * der(y) +...
                y = x * G
        end
    end
"""


raw_c_text_2 = """
    RealInput :: class (connector) = {Real, input}
"""

raw_c_text_3 = """
    RealOutput :: class (connector) = {Real, output}
"""

raw_c_text_4 = """
    RealInput  :: class (connector) = {Real, input}
    RealOutput :: class (connector) = {Real, output}

    AbstractSI :: class (abstract) 
        variables // or properties
            x::RealInput // connectors are always variables
        end
    end
    
    AbstractSO :: class (abstract) 
        variables
            x::RealOutput
        end
    end

    AbstractSISO :: class (abstract)  <: {AbstractSI, AbstractSO}
    end

    Pt1 :: class  <: {AbstractSISO}
        properties
            T::Real
        end
        equations
            T * der(y) +...
                y = x
        end
    end
"""

raw_c_text_5 = """
    Pt1 :: class  <: AbstractSISO
        properties
            T::Real "time constant"
        end
        variables
            v::Real /* this is the speed */
        end
        equations
            der(y) = v // line comment
            T * v + y = x
        end
    end
"""

raw_p_text_1 = """
SimplePackage :: package
/* this package is for test */

    class (abstract) AbstractSI
        variables // or properties
            x::RealInput // connectors are always variables
        end
    end
    
    AbstractSO :: class (abstract) 
        variables
            x::RealOutput
        end
    end

    Pt1 :: class  <: AbstractSISO
        properties
            T::Real "time constant"
        end
        variables
            v::Real /* this is the speed */
        end
        equations
            der(y) = v // line comment
            T * v + y = x
        end
    end
end
"""



raw_ex_1 = """

	RealInput  :: class (connector) = {Real, input}
	RealOutput :: class (connector) = {Real, output}
	
	
	AbstractSI :: class(abstract)
		variables
			x::RealInput
		end
	end
	
	AbstractSO :: class(abstract)
		variables
			y::RealOutput
		end
	end
	
	AbstractSISO :: class(abstract) <: {AbstractSI, AbstractSO} end

	SineGenerator :: class <: AbstractSO
		properties
			A::Real = 1
			omega::Real = 1
			phi0::Real = 0
		end
		equations
			y = A * sin(omega * time + phi0)
		end
	end

	Pt1 :: class <: AbstractSISO
		properties
			G::Real = 1
			T::Real = 0.1
		end
		variables
			v::Real
		end
		equations
			v = der(y)
			T * v + y = G * x
		end
	end
	
	ExcitedPt1 :: class
		models
			plant::Pt1 = Pt1()
			excitation::SineGenerator = SineGenerator(.A = 2)
		end
		equations
			connect(plant.x, excitation.y)
		end
	end
	
	


	/* here comes the simulation function */
	
	excited_pt1_sim :: procedure
		
		/* model definition */
		excited_pt1 = ExcitedPt1(
			.excitation = SineGenerator(.omega = 10)
			.plant = Pt1(.G = 0.5)
			)
		
		/* solver options */
		opt = SolverOptions(
				.abs_tol = 1e-6,
				.rel_tol = 1e-7
				)
		
		/* simulation definition */
		simulate(
			.model = excited_pt1,
			.solver_options = opt)
	end
"""




raw_ex_simplified_1 = """

SineGenerator :: class
		properties
			A::Real = 1
			omega::Real = 1
			phi0::Real = 0
		end
        variables
            y::{Real, output}
        end
		equations
			y = A * sin(omega * time + phi0)
		end
	end

	Pt1 :: class
		properties
			G::Real = 1
			T::Real = 0.1
		end
		variables
			v::Real
            x::{Real, input}
            y::{Real, output}
		end
		equations
			v = der(y)
			T * v + y = G * x
		end
	end
	
	ExcitedPt1 :: class
		models
			plant::Pt1 // in case of omission, the default parameters are used
			excitation::SineGenerator = SineGenerator(.A = 2)
		end
		equations
			connect(plant.x, excitation.y)
		end
	end

"""



raw_ex_simplified_2 = """

    ExcitedPt1 :: class

        variables
            v::Real
            x::Real            
            y::{Real, output}
        end

        properties
            A::Real     = 1
            omega::Real = 1
            phi0::Real  = 0

            G::Real = 1
            T::Real = 0.1
        end

        equations
            A * sin(omega * time + phi0) = x
            der(y)                       = v
            (G * x - y) / T              = v
        end
	end

"""



raw_ex_simplified_3 = """

LotkaVolterra :: class

    properties
        alpha::Real = 0.66
        beta::Real  = 1.33
        gamma::Real = 1
        delta::Real = 1
    end

    variables
        x::Real
        y::Real
    end

    equations
        der(x) = alpha * x     - beta * x * y
        der(y) = delta * x * y - gamma * y
    end
end

"""



raw_ex_simplified_4 = """

LotkaVolterra :: class

    properties
        a11::Real
        a12::Real
        a21::Real
        a22::Real

        b11::Real
        b12::Real
        b21::Real
        b22::Real
    end
    variables
        x1::Real
        x2::Real
    end
    equations
        a11 * der(x1) + a12 * der(x2) = b11 * x1 + b12 * x2
        a21 * der(x1) + a22 * der(x2) = b21 * x1 + b22 * x2
    end
end
"""

raw_ex_simplified_5 = """

SimplePumpComposite :: class
    properties
        /* global, to be done */
        pi::Real = 3.14

        /* a side */    
        p0_a::Real = 1e5
        K1_a::Real = 120
        a_a::Real = 1e6
        Cw_a::Real = 20e-11 // m^3/Pa -> 20 cm^3/bar 

        /* b side */
        p0_b::Real = 1e5
        K1_b::Real = 150
        a_b::Real  = 1e6
        Cw_b::Real = 20e-11

        /* pump */
        Vh::Real      = 4500e-9
        eta_vol::Real = 0.8
        eta_hm::Real  = 0.8

        /* motor */
        M_motor_t::Real    = 0.1
        M_motor_ampl::Real = 0.8
        J::Real = 15e-6
    end
    variables // 13 equations
        /* a side 3 */
        p_a::Real
        Q_a::Real
        Q_ap::Real

        /* b side 3 */
        p_b::Real
        Q_b::Real
        Q_bp::Real

        /* pump 6 */
        Q_act::Real
        Q_th::Real
        omega::Real
        dp_pump::Real
        M_th::Real
        M_act::Real


        /* motor 1 */
        M_motor::Real
    end
    equations // 13 equations
        p0_a - p_a      = K1_a * a_a * Q_a
        Cw_a * der(p_a) = Q_a - Q_ap
        
        Q_ap = Q_bp

        p_b - p0_b      = K1_b * a_b * Q_b
        Cw_b * der(p_b) = Q_b - Q_bp

        Q_act = Q_bp

        Q_act   = Q_th * eta_vol
        Q_th    = omega * Vh / (2*pi)

        J * der(omega) = M_motor - M_act

        M_act   = M_th * 1 / eta_hm
        M_th    = dp_pump * Vh / (2*pi)
        dp_pump = sign(Q_act) * (p_b - p_a)

        
        M_motor = (sign(time - M_motor_t) + 1) / 2 * M_motor_ampl
    end
end
"""


raw_ex_simplified_6 = """

SimpleHydrostaticsComposite :: class

    properties
        A_force::Real = 1
        m_a::Real = 1
        A_a::Real = 1
        Cw_a::Real = 1
        K1::Real = 1
        a::Real = 1
    end
    variables // 11
        F_a::Real

        x_a::Real
        v_a::Real
        p_a::Real

        Q_a::Real
        Q_b::Real
        Q_p::Real

        x_b::Real
        v_b::Real
        p_b::Real

        F_b::Real
    end
    equations // 11
        F_a = A_force * sin(time) // some time function

        // der(x_a)       = v_a
        v_a = der(x_a)
        m_a * der(v_a) = p_a * A_a - F_a

        A_a * v_a = Q_a
        Cw_a * der(p_a) = Q_a - Q_p // -Q_a - Q_p

        p_a - p_b = K1 * a * Q_p

        
        Cw_b * der(p_b) = Q_p - Q_b
        A_b * v_b = Q_b

        // der(x_b)       = v_b
        v_b = der(x_b)
        m_b * der(v_b) = p_b * A_b - F_b

        F_b = c * x_b
    end
end
"""

raw_ex_simplified_7 = """

PIControlledPt2Plant :: class
    properties
        kp::Real = 3
        ki::Real = 0.5
        T::Real = 0.5
        D::Real = 0.3
    end

    variables
        ref::Real
        err::Real
        up::Real
        ui::Real
        u::Real
        x::Real
        v::Real
    end

    equations
        ref     = step(time)
        err     = ref - x
        up      = kp * err
        der(ui) = ki * err
        u       = up + ui
        der(x)  = v
        T^2 * der(v) + 2 * D * T * v + x = u
    end
end
"""

end

