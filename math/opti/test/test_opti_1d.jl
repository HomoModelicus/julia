
function test_bracket()
    f(x) = cos(x)

    a = 0
    b = 0.1

    bracketing_int = opti.bracket_min(f, a, b, )
    show(bracketing_int)

end

function test_golden()
    # fcn(x) = cos(x)
    fcn(x) = x^2
    
    a = 0
    b = 0.1
    bracketing_int = opti.bracket_min(fcn, a, b)

    stat = opti.golden_section_search(fcn, bracketing_int.x_lo, bracketing_int.x_hi)

    println("The found min: $(stat.x_sol) with value: $(stat.y_sol) with iterations: $(stat.iter)")

end