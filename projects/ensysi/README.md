
# Ensysi - Experimental System Simulation Language

- This a Modelica-like domain specific language
- Modelica has the huge advantage for allowing acausal modelling by mathematical equations and not assignments
- The causality between the equations can be determined if we know the whole model structure
- The sparse structure of the equations can be efficiently exploited by inlining the integrators (see: https://people.inf.ethz.ch/fcellier/Pubs/OO/esm_95.pdf)
- Algebraic equations can be used for many important applications: e.g. mass balance, Ohm's law, etc...
- The project is under constructions, as of today, the differential-algebraic solver is not yet written and the language/compiler itself needs extensions and 

Plans to be implemented:
- abstract classes
- connector classes
- (multiple) inheritance
- models as subelements
- connect statements, flow and potential variables
- dae solver(s)

A short example, a vision for simple elements:
- typedef like structures for RealInput
- left-to-right class definitions with blocks for each purpose: properties, variables, models, equations, algorithms
- multiple inheritance for collecting behaviour from each parents
- main function for simulation start / entry point

```julia
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
    
    Pt1 :: class  <: AbstractSISO
        properties
            T::Real
        end
        equations
            T * der(y) +...
                y = x
        end
    end
    
    
    /* main function for entry point, for simulation start */
    main :: function
        pt1 = Pt1(
              .T = 0.1          // parametrization in the object
              .y.initial = 3.0  // initial value
              )
        
        solver_options = SolverOptions(
              .type    = bdf3,
              .abs_tol = 1e-6,
              .rel_tol = 1e-8,
              .t_stop  = 5.0)
        
        simulate!(
          .object = pt1,
          .solver_options = solver_options
          )
        
    end
```

