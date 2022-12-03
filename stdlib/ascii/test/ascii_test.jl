# #=

include("../src/Ascii.jl")


module stest
using ..Ascii

str = "hello world"
asciistr = AsciiString(str)

sv = AsciiStringView(asciistr, 3, 5);

# for (idx, val) in enumerate(sv)
#     println(idx)
#     println(val)
#     println("=====")
# end


# sv = AsciiStringView()

# show(sv)


end
# =#