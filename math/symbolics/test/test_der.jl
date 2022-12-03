

include("../src/Symbolics.jl")

module stest
using ..Symbolics

Symbolics.@variable v 1.0
Symbolics.@variable z 0.2
Symbolics.@variable x 0.5


sigma0 = 10

ex = v - z * sigma0 * abs(v)

str = Symbolics.to_string(ex)

der = Symbolics.derivative(ex, x)
str_der = Symbolics.to_string(der)

sder = Symbolics.simplify(der)
str_sder = Symbolics.to_string(sder)




end



#=
module stest
using ..symbolics



# symbolics.@variable x 10
# symbolics.@variable y 0.2
# symbolics.@variable z 3
# e1 = x + y
# e2 = x / y
# e3 = z ^ (x + y)
# e4 = -x
# e5 = -x - y
# e6 = sin(x + y - z * x)
# e3_val = symbolics.evaluate(e3)
# str1 = symbolics.to_string( stest.e1 )
# str2 = symbolics.to_string( stest.e2 )
# str3 = symbolics.to_string( stest.e3 )
# str4 = symbolics.to_string( stest.e4 )
# str5 = symbolics.to_string( stest.e5 )
# str6 = symbolics.to_string( stest.e6 )
# e7 = y * 10
# str7 = symbolics.to_string( stest.e7 )
# e8 = 10 * y
# str8 = symbolics.to_string( stest.e8 )
# e9 = 10 + (x - y)
# str9 = symbolics.to_string( stest.e9 )
# # !!!
# # this doesnt work correctly now
# # e10 = y * 10 * (x * 2 - 3*z)
# e10 = x * y * x * (x * 2 - 3*z)
# str10 = symbolics.to_string( stest.e10 ) 




function paren_test()

    symbolics.@variable x 10
    symbolics.@variable y 0.2
    symbolics.@variable z 3


    e1 = x + y
    e2 = x / y

    e3 = z ^ (x + y)

    e4 = -x
    e5 = -x - y
    e6 = sin(x + y - z * x)

    # e3_val = symbolics.evaluate(e3)


    # str1 = symbolics.to_string( stest.e1 )
    # str2 = symbolics.to_string( stest.e2 )
    # str3 = symbolics.to_string( stest.e3 )
    # str4 = symbolics.to_string( stest.e4 )
    # str5 = symbolics.to_string( stest.e5 )
    # str6 = symbolics.to_string( stest.e6 )

    # e7 = y * 10
    # str7 = symbolics.to_string( stest.e7 )
    # e8 = 10 * y
    # str8 = symbolics.to_string( stest.e8 )

    # e9 = 10 + (x - y)
    # str9 = symbolics.to_string( stest.e9 )


    # !!!
    # this doesnt work correctly now
    # e7 = y * 10 * (x * 2 - 3*z)
    e7 = x * y * x * (x * 2 - 3*z)
    str7 = symbolics.to_string( stest.e7 ) 




    # str = symbolics.to_string( stest.e6 ) 

    # x_val = symbolics.evaluate(x)
    # y_val = symbolics.evaluate(x)

    # e1_val = symbolics.evaluate(e1)


end

function test_derivative_simpli()
    symbolics.@variable x 10
    symbolics.@variable y 0.2
    symbolics.@variable z 3
    symbolics.@variable w 5


    u = -x

    ex1 = x + y
    ex2 = x * y + z
    ex3 = x + y + z
    ex4 = x * y * z
    ex5 = sin(x)

    # str = symbolics.to_string(ex2)


    der_ex3       = symbolics.derivative(stest.ex3, stest.x)
    der_str3      = symbolics.to_string(der_ex3)
    @time s_der_ex3     = symbolics.simplify(der_ex3)
    str_s_der_ex3 = symbolics.to_string(s_der_ex3)



    der_ex4       = symbolics.derivative(stest.ex4, stest.x)
    der_str4      = symbolics.to_string(der_ex4)
    @time s_der_ex4     = symbolics.simplify(der_ex4)
    str_s_der_ex4 = symbolics.to_string(s_der_ex4)
end



function harmonic_osc(der_q, time, q)
    der_q[1] = q[2]
    der_q[2] = -5.0 * q[1] - q[2]

    return der_q
end




# symbolics.@variable x 10
# symbolics.@variable v 0.2

# q = Vector{symbolics.Variable}(undef, 2)
# der_q = Vector{Any}(undef, 2)

# q[1] = x
# q[2] = v


# der_q = harmonic_osc(der_q, 0.0, q)

# jac = symbolics.jacobian(der_q, q)
# sjac = symbolics.simplify(jac)
# sjac = symbolics.simplify(sjac)






# symbolics.@variable a 30.0

# expr1 = a + 1.0


end


=#
