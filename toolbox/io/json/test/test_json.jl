
include("../src/json_module.jl")


module jtest
using ..json
using ..lexer
using ..parser
using BenchmarkTools

json_text_1 = """{"foo": [1, 2, {"bar": 2}]}"""



# json_text_2 = "{}"
# json_obj_2 = json.parse_json(json_text_2)


function simple()

json_text_3 = """{
    "a": 1,
    "b": 20e2,
    "c": [1, 2, 3],
    "d": ["first", "second", "third"],
    "e": [1, "bla", 3.14],
    "f": {
        "nested1": 10,
        "nested2": 20
    },
    "g": [false, false, true,false],
    "bla": "obj"
}"""


# @time tokens = json.lex_json(json_text_3)
json_obj_3 = json.parse(json_text_3)
end


function simple2()
    inner_str = """{
    "a": 1,
    "b": 20e2,
    "c": [1, 2, 3],
    "d": ["first", "second", "third"],
    "e": [1, "bla", 3.14],
    "f": {
        "nested1": 10,
        "nested2": 20
    },
    "g": [false, false, true,false]
    },
    """

json_text_3 = """ { "bla": [""" * chop(repeat(inner_str, 1000); head = 0, tail = 1) * "]}"


# 10 - 0.035886, allocs: 8410
# TokenList object with:
#         token_stack with 646 elements
#         number_stack with 90 elements
#         string_stack with 131 elements
#
# 100 - 0.328s, allocs: 93022
# TokenList object with:
#         token_stack with 6406 elements
#         number_stack with 900 elements
#         string_stack with 1301 elements
#
# 200 -  1.053 s, allocs: 187027
# 200 - 5ms, allocs: 110388

# 1000 - 28.5s, allocs:
# 1000 - 30ms allocs: 553602
# TokenList object with:
#         token_stack with 64006 elements
#         number_stack with 9000 elements
#         string_stack with 13001 elements
#
#


# tokens = json.lex_json(json_text_3)
#=
b = @benchmark json.lex_json($json_text_3)
show(
    stdout,
    MIME("text/plain"),
    b
)
=#

# json_obj_3 = json.parse(json_text_3)
end

function b_lex()
    json_text = "12345 true                                                                                "
    start_idx = 6

    b = BenchmarkTools.@benchmark lexer.lex_bool($json_text, $start_idx)
    show(
        stdout,
        MIME("text/plain"),
        b
    )
end



function benchmark_parse()
    url = "saved_mesh.txt"

    iostr = open(url, "r");
    iobuff = read(iostr, String);
    close(iostr);

    # dict = json.parse_json(iobuff) 
    
    # dict = json.parse(iobuff) 
    tokens = lexer.lex_json(iobuff)
end




function benchmark_it()
    b = BenchmarkTools.@benchmark benchmark_parse()
    show(
        stdout,
        MIME("text/plain"),
        b
    )
end


function test_parse_number()
    text_1 = "10"
    text_2 = " 10 "
    text_3 = "\t10\n"
    text_4 = "1e3"
    text_5 = "1.6e2"
    text_6 = "-1.6e2"
    text_7 = "-1.6e-2"

    num_1 = json.parse_number(text_1)
    num_2 = json.parse_number(text_2)
    num_3 = json.parse_number(text_3)
    num_4 = json.parse_number(text_4)
    num_5 = json.parse_number(text_5)
    num_6 = json.parse_number(text_6)
    num_7 = json.parse_number(text_7)
end




text = """
{
    "first": 10,
    "second": "this is a string",
    "a"  :  [10, 20, 30],
    "b": {
        "inner1": "value is 10",
        "inner2": 56
    }
}
"""

# b = @benchmark token_list = lexer.lex_json($text)
# show(stdout, MIME("text/plain"), b)

file_content = json.parse(text)

end