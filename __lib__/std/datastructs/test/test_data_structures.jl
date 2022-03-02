

include("../src/datastructs_module.jl")


module dstest
using ..datastructs

# import datastructs
# import .datastructs

# tree = datastructs.BinaryTree{Int}(100)
# n1 = datastructs.BinaryTreeNode{Int}(120)
# n2 = datastructs.BinaryTreeNode{Int}(110)
# n3 = datastructs.BinaryTreeNode{Int}(90)
# n4 = datastructs.BinaryTreeNode{Int}(80)

# insert!(tree, n1)
# datastructs.inorder_tree_walk(tree)



function test_linked_list()

    #=
    n1 = LinkedListNode();
    n2 = LinkedListNode(10);
    n3 = LinkedListNode(10.0);
    n4 = LinkedListNode([1,2,3]);
    =#

    ll = datastructs.LinkedList{Int}(0);


    n1 = datastructs.LinkedListNode{Int}(10);
    n2 = datastructs.LinkedListNode{Int}(20);
    n3 = datastructs.LinkedListNode{Int}(30);
    n4 = datastructs.LinkedListNode{Int}(40);
    n5 = datastructs.LinkedListNode{Int}(50);


    push!(ll, n1)
    push!(ll, n2)
    push!(ll, n3)
    push!(ll, n4)
    push!(ll, n5)
    #=
    =#
end




function test_basics_should_not_allocate()
    stack = datastructs.Stack{Int}(10)

    push!(stack, 10) # allocation
    push!(stack, 20) # allocation
    push!(stack, 30)
    push!(stack, 40) # allocation
    push!(stack, 50)
end



function test_performance_push()
    stack = datastructs.Stack{Float64}()

    N = 100
    rnb = rand(N) .+ 0.2

    for rr in rnb
        if rr >= 0.5
            push!(stack, rr)
        end
    end

end


function test_performance_push_pop()
    stack = datastructs.Stack{Float64}()

    N = 100
    rnb = rand(N) .+ 0.2

    for rr in rnb
        if rr >= 0.5
            push!(stack, rr)
        else
            bla = pop!(stack)
        end
    end

end


function test_stack_push(rnb::Vector{Float64})
    stack = datastructs.Stack{Float64}()
    #N = 1e3
    #rnb = rand(N) .+ 0.2
    for rr in rnb
        push!(stack, rr)
    end
end

function test_stack_allocation(rnb::Vector{Float64})
    # N = 1e3
    stack = datastructs.Stack{Float64}(length(rnb))

    #rnb = rand(N) .+ 0.2
    for rr in rnb
        push!(stack, rr)
    end

end

function test_array_push(rnb::Vector{Float64})
    stack = Array{Float64, 1}()


    for rr in rnb
        push!(stack, rr)
    end
end


using BenchmarkTools

function benchmark_it()

    global N = 2^20-1
    rnb = rand(Int(N)) .+ 0.2

    println("=== test_array_push ===")
    show(stdout, MIME("text/plain"), @benchmark dstest.test_array_push(rand(Int(N)) .+ 0.2))
    println("\n\n")


    println("=== test_stack_push ===")
    show(stdout, MIME("text/plain"), @benchmark dstest.test_stack_push(rand(Int(N)) .+ 0.2))
    println("\n\n")


    println("=== test_stack_allocation ===")
    show(stdout, MIME("text/plain"), @benchmark dstest.test_stack_allocation(rand(Int(N)) .+ 0.2))
    println("\n\n")

end

end
