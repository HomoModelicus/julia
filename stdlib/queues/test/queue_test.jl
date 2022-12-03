

include("../src/Queues.jl")


# #=
module qtest
using ..Queues



queue = Queue{Int}()

push!(queue, 10)
push!(queue, 20)

push!(queue, 30)
push!(queue, 40)

# push!(queue, 50)
# push!(queue, 60)
# push!(queue, 70)
# push!(queue, 80)

# push!(queue, 90)


val = pop!(queue)



end
# =#
