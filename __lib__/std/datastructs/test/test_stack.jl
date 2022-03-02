
include("../src/datastructs_module.jl")



module stest
using ..datastructs


function test_stack_basics()
    stack = datastructs.Stack{Int}()

    show(stack)
    push!(stack, 10) # allocation
    show(stack)
    push!(stack, 20) # allocation
    show(stack)
    push!(stack, 30)
    show(stack)
    push!(stack, 40) # allocation
    show(stack)
    push!(stack, 50)
    show(stack)

    v1 = pop!(stack)
    v2 = pop!(stack)
    v3 = pop!(stack)
    v4 = pop!(stack)
    v5 = pop!(stack)

    try
        v5 = pop!(stack)
    catch except
        println(except.msg)
    end
end

function test_stack_basics2()
    stack = datastructs.Stack{Int}(6)

    show(stack)
    push!(stack, 10) # allocation
    show(stack)
    push!(stack, 20) # allocation
    show(stack)
    push!(stack, 30)
    show(stack)
    push!(stack, 40) # allocation
    show(stack)
    push!(stack, 50)
    show(stack)

    v1 = pop!(stack)
    show(stack)
    v2 = pop!(stack)
    show(stack)
    v3 = pop!(stack)
    show(stack)
    v4 = pop!(stack)
    show(stack)
    v5 = pop!(stack)
    show(stack)

    # try
    #     v5 = pop!(stack)
    # catch except
    #     println(except.msg)
    # end
    return stack
end














function test_queue_basics()
    queue = datastructs.Queue{Int}(5)

    show(queue)
    push!(queue, 10) # allocation
    show(queue)
    push!(queue, 20) # allocation
    show(queue)
    push!(queue, 30)
    show(queue)
    push!(queue, 40) # allocation
    show(queue)
    push!(queue, 50)
    show(queue)

    v1 = pop!(queue)
    show(queue)
    v2 = pop!(queue)
    show(queue)
    v3 = pop!(queue)
    show(queue)
    v4 = pop!(queue)
    show(queue)
    v5 = pop!(queue)
    show(queue)
    # try
    #     v5 = pop!(stack)
    # catch except
    #     println(except.msg)
    # end
    return queue
end


function test_queue_basics2()
    queue = datastructs.Queue{Int}(5)

    show(queue)
    push!(queue, 10) # allocation
    show(queue)
    push!(queue, 20) # allocation
    show(queue)
    push!(queue, 30)
    show(queue)
    push!(queue, 40) # allocation
    show(queue)
    push!(queue, 50)
    show(queue)

    v1 = pop!(queue)
    show(queue)


    push!(queue, 60)
    show(queue)
    push!(queue, 70)
    show(queue)
    push!(queue, 80)
    show(queue)
    push!(queue, 90)
    show(queue)

    # v2 = pop!(queue)
    # show(queue)
    # v3 = pop!(queue)
    # show(queue)
    # v4 = pop!(queue)
    # show(queue)
    # v5 = pop!(queue)
    # show(queue)

    return queue
end

# stack = test_stack_basics2()

# queue = test_queue_basics2()

v1 = [1.0, 0]
v2 = [1.0, 1]
v3 = [1.0, 2]
v4 = [1.0, 3]
v5 = [1.0, 4]


# stack = datastructs.MatrixStack(2, 3)
stack = MatrixStack(2, 3)
push!(stack, v1)
push!(stack, v2)
push!(stack, v3)
push!(stack, v4)


end


