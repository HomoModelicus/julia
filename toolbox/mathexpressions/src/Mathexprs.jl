

include("D:/programming/src/julia_projects/fluffsky/version_5/lexers/Lexers.jl")


# include("../tokenizers/Tokenizers.jl")
include("../../../stdlib/trees/src/BinaryTrees.jl")


# implement
# - cont literal
# - parameter type, name, with some fixed value from somewhere else
# - variable, name, undefined value
#
# - operator type
#
# - shunting yard algorithm -> reverse polish notation
# - reverse polish -> binary tree (mutable first)
# - binary tree expression -> text form again back
# - scan: number of variables, what variables there



module Mathexprs
using ..Tokenizers
using ..Lexers
using ..Ascii
using ..BinaryTrees
using ..Stacks
using ..Queues



# +
# -
# *
# /
# ^ 
# ,
# .
# der
# (
# )

@enum MathTokenKind begin
    mt_no_token_t

    mt_symbol_t
    mt_operator_t
end

@enum SymbolKind begin
    symbol_const_t
    symbol_parameter_t
    symbol_variable_t
end

@enum OperatorKind begin
    operator_plus_t
    operator_minus_t
    operator_prod_t
    operator_div_t
    operator_power_t
    operator_comma_t
    operator_dot_t
    operator_der_t
    operator_opening_paren_t
    operator_closing_paren_t
    operator_call_t
end

struct ExprToken
    first::StringPosition
    last::StringPosition

    token_kind::MathTokenKind
    token_subkind::Union{SymbolKind, OperatorKind}

    function ExprToken(first, last, token_kind, token_subkind)
        return new(
            first,
            last,
            token_kind,
            token_subkind)
    end
end


function get_token_kinds(token_list, index)

    N     = length(token_list)
    token = token_list[index]
    
    if token.category == newline_t::TokenCategory || token.category == string_t::TokenCategory
        return (mt_no_token_t::MathTokenKind, symbol_const_t::SymbolKind)
    end
    
    if token.category == number_t::TokenCategory
        return (mt_symbol_t::MathTokenKind, symbol_const_t::SymbolKind)
    end

    if token.category == specialchar_t::TokenCategory
        k = mt_operator_t::MathTokenKind
        
        token.value == dot_t::SpecialCharacterType           && return (k, operator_dot_t::OperatorKind             )
        token.value == comma_t::SpecialCharacterType         && return (k, operator_comma_t::OperatorKind           )
        token.value == opening_paren_t::SpecialCharacterType && return (k, operator_opening_paren_t::OperatorKind   )
        token.value == closing_paren_t::SpecialCharacterType && return (k, operator_closing_paren_t::OperatorKind   )
        token.value == plus_t::SpecialCharacterType          && return (k, operator_plus_t::OperatorKind            )
        token.value == minus_t::SpecialCharacterType         && return (k, operator_minus_t::OperatorKind           )
        token.value == prod_t::SpecialCharacterType          && return (k, operator_prod_t::OperatorKind            )
        token.value == div_t::SpecialCharacterType           && return (k, operator_div_t::OperatorKind             )
        token.value == carot_t::SpecialCharacterType         && return (k, operator_power_t::OperatorKind           )

        error("Something went wrong")
    end

    if token.category == identifyer_t::TokenCategory
        # lookahed necessary

        if index == N
            return (mt_symbol_t::MathTokenKind, symbol_variable_t::SymbolKind)
        end

        next_token = token_list[index + 1]
        if next_token.category == specialchar_t::TokenCategory && next_token.value == opening_paren_t::SpecialCharacterType
            return (mt_operator_t::MathTokenKind, operator_call_t::OperatorKind)
        else
            return (mt_symbol_t::MathTokenKind, symbol_variable_t::SymbolKind)
        end

        error("Something went wrong")
    end

    if token.category == keyword_t::TokenCategory

        if token.value == keyword_to_int(kw_der_t::KeywordType)
            return (mt_operator_t::MathTokenKind, operator_der_t::OperatorKind)

        elseif token.value == keyword_to_int(kw_true_t::KeywordType)
            return (mt_symbol_t::MathTokenKind, symbol_const_t::SymbolKind)

        elseif token.value == keyword_to_int(kw_false_t::KeywordType)
            return (mt_symbol_t::MathTokenKind, symbol_const_t::SymbolKind)

        end

        show(token)
        error("Something went wrong")
    end
    
    
    error("Something went wrong")
end


function create_expression_token_list(token_list)

    N = length(token_list)
    expr_token_list = Stack{ExprToken}(N)

    for index = 1:N
        token = token_list[index]
        (token_kind, token_subkind) = get_token_kinds(token_list, index)
        if token_kind == mt_no_token_t::MathTokenKind
            continue
        end
        expr_token = ExprToken(token.first, token.last, token_kind, token_subkind)
        push!(expr_token_list, expr_token)
    end
    
    return Stacks.valid_data(expr_token_list)
end



# prio list
# ()
# fcn call, .
# ^
# *, /
# +, -
# ,

const PrecendeceType = Int8

struct SymbolicOperator
    is_associative::Bool
    precendence::PrecendeceType

    is_binary::Bool
    kind::OperatorKind

    name::Symbol # for function calls
end

struct SymbolicVariable
    name::Symbol
    value::Float64
    is_parameter::Bool
end





const power_operator      = SymbolicOperator(false, 3, true, operator_power_t::OperatorKind,    Symbol("^") )

const prod_operator       = SymbolicOperator(true,  4, true, operator_prod_t::OperatorKind,     Symbol("*") )
const div_operator        = SymbolicOperator(false, 4, true, operator_div_t::OperatorKind,      Symbol("/") )

const plus_operator       = SymbolicOperator(true,  5, true, operator_plus_t::OperatorKind,     Symbol("+") )
const minus_operator      = SymbolicOperator(false, 5, true, operator_minus_t::OperatorKind,    Symbol("-") )

const comma_operator      = SymbolicOperator(false, 6, true, operator_comma_t::OperatorKind,    Symbol(",") )
const dot_operator        = SymbolicOperator(false, 2, true, operator_dot_t::OperatorKind,     Symbol(".") )
const der_operator        = SymbolicOperator(false, 2, false, operator_der_t::OperatorKind,     Symbol("der") ) 

const leftparen_operator  = SymbolicOperator(false, 1, false, operator_opening_paren_t::OperatorKind, Symbol("(") )
const rightparen_operator = SymbolicOperator(false, 1, false, operator_closing_paren_t::OperatorKind, Symbol(")") )

generate_call_operator(sym) = SymbolicOperator(false, 2, false, operator_call_t::OperatorKind, sym )


function create_symbolic_list(text, expr_token_list, token_list)
    T = Union{SymbolicOperator, SymbolicVariable}
    N = length(expr_token_list)
    symbol_list = Vector{T}(undef, N)

    for ii = 1:N
        token = expr_token_list[ii]

        if token.token_kind == mt_operator_t::MathTokenKind

            token.token_subkind == operator_plus_t::OperatorKind            && (sym = plus_operator)
            token.token_subkind == operator_minus_t::OperatorKind           && (sym = minus_operator)
            token.token_subkind == operator_prod_t::OperatorKind            && (sym = prod_operator)
            token.token_subkind == operator_div_t::OperatorKind             && (sym = div_operator)
            token.token_subkind == operator_power_t::OperatorKind           && (sym = power_operator)
            token.token_subkind == operator_comma_t::OperatorKind           && (sym = comma_operator)

            token.token_subkind == operator_dot_t::OperatorKind             && (sym = dot_operator)
            token.token_subkind == operator_der_t::OperatorKind             && (sym = der_operator)
            token.token_subkind == operator_opening_paren_t::OperatorKind   && (sym = leftparen_operator)
            
            token.token_subkind == operator_closing_paren_t::OperatorKind   && (sym = rightparen_operator)


            if token.token_subkind == operator_call_t::OperatorKind
                fcn_name = Symbol( String( text[ token.first.index:token.last.index ]) )
                sym = generate_call_operator(fcn_name)
            end

        elseif token.token_kind == mt_symbol_t::MathTokenKind

            if token.token_subkind == symbol_const_t::SymbolKind

                id_name     = Symbol("")
                id_value    = token_list[ii].value
                id_is_param = true

            elseif token.token_subkind == symbol_parameter_t::SymbolKind

                id_name     = Symbol( String( text[ token.first.index:token.last.index ]) )
                id_value    = zero(Float64) # just for convention
                id_is_param = true

            elseif token.token_subkind == symbol_variable_t::SymbolKind

                id_name     = Symbol( String( text[ token.first.index:token.last.index ]) )
                id_value    = zero(Float64)
                id_is_param = false

            end
            
            sym = SymbolicVariable( id_name , id_value, id_is_param)

        else
            error("Something went wrong")
        end

        symbol_list[ii] = sym

    end # for

    return symbol_list
end


const NodeType = Union{SymbolicOperator, SymbolicVariable}

function shunting_yard(symbolic_list)

    N                    = length(symbolic_list)
    T                    = NodeType
    reverse_polish_queue = Queue{T}(N)
    operator_stack       = Stack{SymbolicOperator}(N)

    for ii = 1:N

        sym_elem = symbolic_list[ii]

        if isa(sym_elem, SymbolicVariable)
            push!(reverse_polish_queue, sym_elem)

        elseif isa(sym_elem, SymbolicOperator)

            # checks:
            # - for precendence and associativity

            if sym_elem.kind == operator_closing_paren_t::OperatorKind
                
                found_left_paren = false
                while !isempty(operator_stack)
                    op = pop!(operator_stack)

                    if op.kind == operator_opening_paren_t::OperatorKind
                        found_left_paren = true
                        break
                    end

                    push!(reverse_polish_queue, op)
                end

                if !found_left_paren
                    error("Unmatched parenthesis")
                end

                if !isempty(operator_stack)
                    next_op = peek(operator_stack)
                    if next_op == operator_call_t::OperatorKind
                        next_op = pop!(operator_stack)
                        push!(reverse_polish_queue, next_op)
                    end
                end

                continue
            end

            while true
                if isempty(operator_stack)
                    push!(operator_stack, sym_elem)
                    break
                end

                op = peek(operator_stack)

                if op.kind == operator_opening_paren_t::OperatorKind
                    push!(operator_stack, sym_elem)
                    break
                end

                # higher priority, must be evaluated first
                if sym_elem.precendence < op.precendence
                    push!(operator_stack, sym_elem)
                    break
                else
                    if op.is_associative && sym_elem.precendence == op.precendence
                        push!(operator_stack, sym_elem)
                        break
                    else
                        pop!(operator_stack)
                        push!(reverse_polish_queue, op)
                    end
                end
            end
            
        else
            error("Something went wrong")
        end
    end

    while !isempty(operator_stack)
        elem = pop!(operator_stack)
        push!(reverse_polish_queue, elem)
    end

    return reverse_polish_queue
end

function create_expression_tree(reverse_polish_queue)

    T     = Union{SymbolicOperator, SymbolicVariable}
    N     = length(reverse_polish_queue)
    stack = Stack{BinaryTreeNode}(N)

    # create vector with the binary tree node entries
    # afterwards connect them

    while !isempty(reverse_polish_queue)

        elem = pop!(reverse_polish_queue)
        node = BinaryTreeNode(elem)

        if isa(elem, SymbolicVariable)
            push!(stack, node)
        
        elseif isa(elem, SymbolicOperator)

            if elem.is_binary
                node.right = pop!(stack)
                node.left  = pop!(stack)
                
                node.left.parent  = node
                node.right.parent = node

            else # unary
                node.left = pop!(stack)
                node.left.parent  = node
            end

            push!(stack, node)

        else
            error("Something went wrong")
        end

    end
    
    root = pop!(stack)
    return root
end

function print_node(cont)

    if cont.visited
        ws   = "  "
        ws1  = "   "
        # dots = "...." 
        dots = "___" 
        for ii = 2:cont.depth
            print( "|" * ws )
        end
        print( ws1^(cont.depth - 1) * "|" * dots )
        
        val = cont.node.data
        if val isa SymbolicVariable
            if val.name == Symbol("")
                println(val.value)
            else
                println(val.name)
            end
        elseif val isa SymbolicOperator
            println(val.name)
        else
            println("?????????") # for "error" handling
        end
    end


end

function print_tree(root)
    BinaryTrees.dfs(root, on_push_fcn = print_node)
end



function symbols_contained(root)

    stack     = Stack{Symbol}(8)
    der_stack = Stack{Symbol}(8)

    on_push(cont) = begin
        if cont.visited
            sym_elem = cont.node.data
            if isa(sym_elem, SymbolicVariable) &&
                !sym_elem.is_parameter &&
                sym_elem.name != Symbol("")

                    push!(stack, sym_elem.name)

                    parent_data = cont.node.parent.data
                    if  isa(parent_data, SymbolicOperator) &&
                        parent_data.kind == operator_der_t::OperatorKind || 
                        (parent_data.kind == operator_call_t::OperatorKind &&
                         parent_data.name == der_operator.name)

                            push!(der_stack, sym_elem.name)
                    end
            end
        end
    end

    BinaryTrees.dfs(root, on_push_fcn = on_push)

    vars = Stacks.valid_data(stack)
    unique!(identity, vars)

    der_vars = Stacks.valid_data(der_stack)
    unique!(identity, der_vars)


    return (vars, der_vars)
end



end # module



# #=
module mtest
using ..Mathexprs
# using ..Tokenizers
using ..Lexers
using ..TreeUtils
using ..BinaryTrees


str1 = """
    this - 10 + T * der(y) - zet * sin(time * omega + phase)
"""


str1 = """
    (sin(obj.prop.sub) + cos(y))^2 + der(x)
"""

# str1 = """
#     (sin(obj-prop-sub) + cos(y))^2 + der(x)
# """


text       = Lexers.preprocess_string(str1)
token_list = Lexers.tokenize( text; debug_mode = false)
table      = Lexers.substitute(text, token_list)
Lexers.showall(table)


expr_token_list      = Mathexprs.create_expression_token_list(token_list)
symbolic_list        = Mathexprs.create_symbolic_list(text, expr_token_list, token_list)
reverse_polish_queue = Mathexprs.shunting_yard(symbolic_list)
root                 = Mathexprs.create_expression_tree(reverse_polish_queue)


Mathexprs.print_tree(root)
# (vars, der_vars) = Mathexprs.variables_contained(root)


end

# =#


