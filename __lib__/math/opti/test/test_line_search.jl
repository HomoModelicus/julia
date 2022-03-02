function test_line_search()
    fcn(x) = x[1]^2 + x[2]^2

    x0 = [1.0, 2]
    step_direction = [-1.0, -1.0]
    f0 = fcn(x0)
    step_size = opti.line_search(fcn, x0, step_direction, f0)
    println(step_size)
    x1 = x0 + step_direction * step_size
    println(x1)
end
