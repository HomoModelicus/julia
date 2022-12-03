




# parse the equations
# token -> tree
# normalization, some tree manipulation
# algorithm of tarjan, graphs, bipartite graphs
# integrator inlining with very simple and easy fixed step size solver
# 
# 
# solve the entry point question
# process only the relevant classes
# 
# but for starters, lets only deal with one class





# include("../lexers/Lexers.jl")
include("D:/programming/src/julia/toolbox/mathexpressions/Mathexprs.jl")


# include("D:/programming/src/julia/stdlib/resulttypes/ResultTypes.jl") # already included in lexers
# include("D:/programming/src/julia/stdlib/arrayviews/ArrayViews.jl")   # already included in lexers
include("D:/programming/src/julia/toolbox/acceptorcombinators/Acceptors.jl")


module Parsers

# basics
using ..Stacks
using ..ResultTypes
using ..ArrayViews
using ..Acceptors
using ..BinaryTrees

# applications
using ..Tokenizers
using ..Lexers
using ..Mathexprs


include("expected_token.jl")

include("ir_typetable.jl")
include("ir_property.jl")
include("ir_variable.jl")
include("ir_rawequation.jl")
include("ir_class.jl")






function extract_nth_token(array_view::AV, index::Int) where {AV <: AbstractView}
    return array_view[index]
end

function extract_text_as_symbol(text, token)
    return Symbol(String(text[token.first.index:token.last.index]))
end

function extract_nth_as_symbol(text, array_view::AV, index::Int) where {AV <: AbstractView}
    token = extract_nth_token(array_view, index)
    return extract_text_as_symbol(text, token)
end



include("parse_class_name.jl")
include("parse_class_modifyer.jl")
include("parse_class_superclasses.jl")
include("parse_class_properties.jl")
include("parse_class_variables.jl")
include("parse_class_equations.jl")
include("parse_class.jl")




# =========================================================================== #
# Entry point for parsing
# =========================================================================== #


# text must be expanded into a more widely useful object
# file, source must/should be also known
#
# for starters, it can only parse a class
# extension for the main function entry point
function parse(text, token_list::TokenList)

    # initializations
    array_view        = ArrayView(token_list.stack.data, 1, token_list.stack.ptr)
    class_stack       = Stack{Class}(8)
    global_type_table = TypeTable(:Global)

    exp_token_newline = ExpectedToken(newline_t::TokenCategory)
    exp_token_class   = ExpectedToken(keyword_t::TokenCategory, kw_class_t::KeywordType )

    while array_view.first <= array_view.last
        
        token = array_view[1]

        # skip newline characters
        if exp_token_newline == token
            array_view += 1
            continue
        end

        if exp_token_class == token
            array_view            -= 3 # go back to the identifyer
            (class_ir, array_view) = parse_class(text, array_view, global_type_table)
            push!(class_stack, class_ir)
        end

        array_view += 1

    end

    # copy the valid classes
    class_list = valid_data(class_stack)
    return (global_type_table, class_list)
end



function process_rawequations(text, class_object::Class)
    
    n_equations          = length(class_object.rawequations)
    binarytree_equations = Vector{BinaryTreeEquation}(undef, n_equations)

    #   plus_node 
    #   /       \
    # lhs        *
    #           / \
    #         -1   rhs

    for ii = 1:n_equations

        token_list           = class_object.rawequations[ii].lhs

        expr_token_list      = Mathexprs.create_expression_token_list(token_list)
        symbolic_list        = Mathexprs.create_symbolic_list(text, expr_token_list, token_list)
        reverse_polish_queue = Mathexprs.shunting_yard(symbolic_list)
        root_lhs             = Mathexprs.create_expression_tree(reverse_polish_queue)


        token_list           = class_object.rawequations[ii].rhs

        expr_token_list      = Mathexprs.create_expression_token_list(token_list)
        symbolic_list        = Mathexprs.create_symbolic_list(text, expr_token_list, token_list)
        reverse_polish_queue = Mathexprs.shunting_yard(symbolic_list)
        root_rhs             = Mathexprs.create_expression_tree(reverse_polish_queue)


        m1           = Mathexprs.SymbolicVariable(Symbol(""), -1, false)
        plus_node    = BinaryTreeNode{Mathexprs.NodeType}(Mathexprs.plus_operator)
        mult_node    = BinaryTreeNode{Mathexprs.NodeType}(Mathexprs.prod_operator)
        mult_m1_node = BinaryTreeNode{Mathexprs.NodeType}(m1)
        

        plus_node.left      = root_lhs
        root_lhs.parent     = plus_node
        plus_node.right     = mult_node
        mult_node.parent    = plus_node
        mult_node.left      = mult_m1_node
        mult_m1_node.parent = mult_node
        mult_node.right     = root_rhs
        root_rhs.parent     = mult_node

        (symbols, der_symbols)   = Mathexprs.symbols_contained(plus_node)
        binarytree_equation      = BinaryTreeEquation(root_lhs, root_rhs, plus_node, symbols, der_symbols)
        binarytree_equations[ii] = binarytree_equation

    end
    
    return binarytree_equations
end

function process_binary_tree_equations(binarytree_equations, class_object::Class)

    n_equations        = length(binarytree_equations)
    onesided_equations = Vector{OneSidedEquation}(undef, n_equations)

    stack = Stack{ClassVariable}(32)

    for ii = 1:n_equations

        bineq = binarytree_equations[ii]

        Ls = length(bineq.symbols)
        Ld = length(bineq.der_symbols)

        if Ld > 0
            Stacks.reinit!(stack)
            for jj = 1:Ld
                idx = findfirst( x -> bineq.der_symbols[jj] == x.name, class_object.variables)
                if !isnothing(idx)
                    var = class_object.variables[idx]
                    push!(stack, var)
                end
            end
            der_variables = Stacks.valid_data(stack)
        else
            der_variables = Vector{ClassVariable}(undef, 0)
        end
        
        if Ls > 0
            Stacks.reinit!(stack)
            for jj = 1:Ls
                idx = findfirst( x -> bineq.symbols[jj] == x.name, class_object.variables)
                if !isnothing(idx)
                    var = class_object.variables[idx]
                    push!(stack, var)
                end
            end
            algebraic_variables = Stacks.valid_data(stack)
        else
            algebraic_variables = Vector{ClassVariable}(undef, 0)
        end

        onesided_equations[ii] = OneSidedEquation(bineq.fcn, algebraic_variables, der_variables)
    end

    return onesided_equations
end


function equations_to_system(onesided_equations, class_object::Class)

    n_equations = length(onesided_equations)
    equations   = Vector{BinaryTreeNode}(undef, n_equations)

    remaining_set = Set{ClassVariable}(class_object.variables)
    der_set       = Set{ClassVariable}()
    alg_set       = Set{ClassVariable}()
    for ii = 1:n_equations
        equations[ii] = onesided_equations[ii].fcn
        union!(der_set, onesided_equations[ii].der_variables)
        union!(alg_set, onesided_equations[ii].algebraic_variables)
    end

    alg_set             = setdiff(alg_set, der_set)
    der_variables       = der_set.dict |> keys |> collect
    algebraic_variables = alg_set.dict |> keys |> collect
    
    remaining_set = setdiff(remaining_set, der_set)
    remaining_set = setdiff(remaining_set, alg_set)

    if length(remaining_set) > 1
        error("The class still contains variables for which there is no equation")
    end

    onesided_equation_system = OneSidedEquationSystem(equations, algebraic_variables, der_variables)
    return onesided_equation_system
end


# assumption here: 
# the number of variables == number of equations
# first columns belong to the derivative variables
# the remaining ones to algebraic ones
function create_bipartite_matrix(onesided_equation_system, onesided_equations)

    n_equations = length(onesided_equations)
    matrix      = zeros(Int8, n_equations, n_equations)
    _1          = Int8(1)

    alg_vars = onesided_equation_system.algebraic_variables
    der_vars = onesided_equation_system.der_variables

    n_der = length(der_vars)
    n_alg = length(alg_vars)

    
    for jj = 1:n_der
        der_var = der_vars[jj]
        for ii = 1:n_equations
            eq  = onesided_equations[ii]
            idx = findfirst(x -> der_var == x, eq.der_variables)
            if !isnothing(idx)
                matrix[ii, jj] = _1
            end
        end
    end

    for jj = 1:n_alg
        alg_var = alg_vars[jj]
        for ii = 1:n_equations
            eq  = onesided_equations[ii]
            idx = findfirst(x -> alg_var == x, eq.algebraic_variables)
            if !isnothing(idx)
                matrix[ii, jj + n_der] = _1
            end
        end
    end

    return matrix
end


end # module





include("D:/programming/src/julia/stdlib/graphs/Graphs.jl")

include("../test/TestCodes.jl")

module ttest

using ..Graphs


# basics
using ..Stacks
using ..ResultTypes
using ..ArrayViews
using ..Acceptors


# applications
using ..Tokenizers
using ..Lexers
using ..Parsers
using ..TestCodes
using ..Mathexprs



# text = Lexers.preprocess_string(TestCodes.raw_ex_simplified_2)
# text = Lexers.preprocess_string(TestCodes.raw_ex_simplified_3)
# text = Lexers.preprocess_string(TestCodes.raw_ex_simplified_4)
# text = Lexers.preprocess_string(TestCodes.raw_ex_simplified_5)
# text = Lexers.preprocess_string(TestCodes.raw_ex_simplified_6)
text = Lexers.preprocess_string(TestCodes.raw_ex_simplified_7)




token_list = Lexers.tokenize( text; debug_mode = false)
token_list = Lexers.subsitute_keywords!(text, token_list)


# only for debugging/visualizing
# table = Lexers.substitute(text, token_list)
# Lexers.showall(table)




(global_type_table, class_list) = Parsers.parse(text, token_list)


class_object             = class_list[1]
binarytree_equations     = Parsers.process_rawequations(          text,                     class_object       )
onesided_equations       = Parsers.process_binary_tree_equations( binarytree_equations,     class_object       )
onesided_equation_system = Parsers.equations_to_system(           onesided_equations,       class_object       )
matrix                   = Parsers.create_bipartite_matrix(       onesided_equation_system, onesided_equations ) # not correct: the variable order shall match the same order as in the matrix




bipgraph                             = Graphs.MatrixBipartiteGraph(                      matrix                         )
adj_matrix_flow                      = Graphs.bipartite_to_max_flow_graph(               bipgraph                       )
flow_digraph                         = Graphs.MatrixDirectedGraph(                       adj_matrix_flow                )
max_flow_matrix                      = Graphs.ford_fulkerson(                            flow_digraph                   )
assignment                           = Graphs.find_bipartite_matching(                   max_flow_matrix                )
depgraph                             = Graphs.bipartite_dependency_graph(                bipgraph, assignment           )
scc_sets                             = Graphs.strongly_connected_components(             depgraph                       )
(sorted_bipgraph, eq_perm, var_perm) = Graphs.sort_bipartite_graph(                      bipgraph, scc_sets, assignment )
block_sizes                          = Graphs.strongly_connected_components_block_sizes( scc_sets                       )




sorted_variables = class_object.variables[var_perm]
sorted_equations = onesided_equation_system.equations[eq_perm]



# expression trees
# reverse polish notation fails for some reason for unary minus
# most likely the handling of unary minus is not correct somewhere
# possible candidates are: parsing the tokens, or popping from the stack 2 items instead of only 1

end

