
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

A short example, a vision for simple elements.






