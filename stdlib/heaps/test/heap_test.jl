



include("../src/Heaps.jl")


module htest
using ..Heaps



using ..Heaps
using BenchmarkTools

Heaps_array = [16, 14, 10, 15, 7, 9, 3, 2, 4, 1]
b = Heaps.is_heap_until(Heaps_array, 2)


array = [5, 8, 2, 10, 9, 6, 1, 3, 7, 4]

h = Heaps.MinHeap(array)
h = Heaps.make_heap(htest.h)

Heaps.swap!(h, 7, 10)

for ii = 1:h.heap_size
    println( Heaps.is_heap_until(h, ii) )
end


h_sorted = sort!(h)



n = 1_000
array = rand(n)
h = Heaps.MaxHeap(array)

# b = @benchmark sort!(h)
# show(
#     stdout,
#     MIME("text/plain"),
#     b )





end

