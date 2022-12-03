
# include("../../__lib__/std/datastructs/src/datastructs_module.jl")


# module rw
# using ..datastructs


abstract type AbstractVariable end
abstract type AbstractTape end
abstract type AbstractNode end


struct Node{T} <: AbstractNode
    parder1::T
    parder2::T
    parent1::Int
    parent2::Int

    function Node{T}(parder1::T, parder2::T, parent1::Int, parent2::Int) where {T}
        return new(parder1, parder2, parent1, parent2)
    end
end

function Node(parder1::T, parder2, parent1, parent2) where {T}
    return Node{T}(promote(parder1, parder2)..., parent1, parent2)
end



# function create_node(tape::T, dzdx, dzdy, x::V) where {T <: AbstractTape, V <: AbstractVariable}
    
#     node = Node(dzdx, dzdy, x.index, 0)
#     push!(tape, node)
    
#     return node
# end

struct Tape
    stack::Stack{Node}
    # stack::Vector{Node}

    function Tape()
        s = Stack{Node}()
        # s = Vector{Node}(undef, 0)
        obj = new(s)
        return obj
    end
end
function Base.push!(tape::Tape, node::Node)
    return push!( tape.stack, node )
    # push!(tape.stack, node)
    return tape
end

# function last_valid_index(vec::Vector{T}) where {T}
#     return length(vec)
# end


# struct Tape <: AbstractTape
#     stack::Stack{Node}
    
#     function Tape()
#         stack = Stack{Node}()
#         return new(stack)
#     end
# end

# function Base.push!(tape::Tape, node::Node)
#     return push!( tape.stack, node )
# end
function Base.peek(tape::Tape)
    return peek( tape.stack )
end
function Base.length(tape::Tape)
    return length( tape.stack )
end
function Base.isempty(tape::Tape)
    return isempty( tape.stack )
end
function Base.size(tape::Tape)
    return size( tape.stack )
end

macro tape(tape_name)
    ex = :($(esc(tape_name)) = Tape())
    return ex
end



# must be mutable in order to work with a hash map
# or let the indices in the struct
struct Variable{T} <: AbstractVariable
    value::T
    tape::Tape
    index::Int

    function Variable{T}(value::T, tape::Tape, index::Int) where {T}
        return new(value, tape, index)
    end
end

function create_variable(tape::Tape, value::T) where {T}

    node  = Node(value, zero(T), 0, 0)
    push!(tape, node)

    index = Stacks.last_valid_index(tape.stack)
    var   = Variable{T}(value, tape, index)

    return var
end

function create_temporary_variable(tape::Tape, value::T) where {T}
    index = Stacks.last_valid_index(tape.stack)
    var   = Variable{T}(value, tape, index)
    return var
end

macro variable(tape, varname, value)
    ex = :($(esc(varname)) = create_variable($tape, $value))
    return ex
end


function Base.zero(x::Variable)
    return create_variable(x.tape, zero(x.value))
end

function Base.one(x::Variable)
    return create_variable(x.tape, one(x.value))
end





function create_node(tape::Tape, dzdx, dzdy, x::V1, y::V2) where {V1 <: AbstractVariable, V2 <: AbstractVariable}
    return __create_node(tape, dzdx, dzdy, x.index, y.index)    
end
function create_node(tape::Tape, dzdx, dzdy, x::Int, y::Int)
    return __create_node(tape, dzdx, dzdy, x, y)    
end
function create_node(tape::Tape, dzdx, dzdy, x::Int, y::V2) where {V2 <: AbstractVariable}
    return __create_node(tape, dzdx, dzdy, x, y.index)
end

function create_node(tape::Tape, dzdx, dzdy, x::V1, y::Int) where {V1 <: AbstractVariable}
    return __create_node(tape, dzdx, dzdy, x.index, y)
end

function __create_node(tape::Tape, dzdx, dzdy, x_index::Int, y_index::Int)
    node = Node(dzdx, dzdy, x_index, y_index)
    push!(tape, node)
    
    return node
end



# operations:
# +, -, *, /
# v1^2
# 2^v1
# v1^v2
# min, max

# sqrt(v1)
# abs
# sin, cos, tan
# sinh, cosh, tanh
# exp, log

function Base.:+(v1::T) where {T <: Variable}
    return v1
end
function Base.:-(v1::T) where {T <: Variable}

    dzdx = -1.0
    dzdy = 0.0
    create_node(v1.tape, dzdx, dzdy, v1, 0);

    tmp = -v1.value
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end

function Base.:+(v1::T, v2::T) where {T <: Variable}
    
    dzdx = 1.0
    dzdy = 1.0
    create_node(v1.tape, dzdx, dzdy, v1, v2);

    tmp = v1.value + v2.value
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end

function Base.:+(v1::T, v2::N) where {T <: Variable, N <: Number}
    
    dzdx = 1.0
    dzdy = 0.0
    create_node(v1.tape, dzdx, dzdy, v1, 0);

    tmp = v1.value + v2
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end
function Base.:+(v1::N, v2::T) where {T <: Variable, N <: Number}
    return v2 + v1
end


function Base.:-(v1::T, v2::T) where {T <: Variable}

    dzdx = 1.0
    dzdy = -1.0
    create_node(v1.tape, dzdx, dzdy, v1, v2);

    tmp = v1.value - v2.value
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end
function Base.:-(v1::T, v2::N) where {T <: Variable, N <: Number}
    
    dzdx = 1.0
    dzdy = 0.0
    create_node(v1.tape, dzdx, dzdy, v1, 0);

    tmp = v1.value - v2
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end
function Base.:-(v1::N, v2::T) where {T <: Variable, N <: Number}
    
    dzdx = 0.0
    dzdy = -1.0
    create_node(v2.tape, dzdx, dzdy, 0, v2);

    tmp = v1 - v2.value
    var = create_temporary_variable(v2.tape, tmp)
    
    return var
end



function Base.:*(v1::T, v2::T) where {T <: Variable}
    
    dzdx = v2.value
    dzdy = v1.value
    create_node(v1.tape, dzdx, dzdy, v1, v2);

    tmp = v1.value * v2.value
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end
function Base.:*(v1::T, v2::N) where {T <: Variable, N <: Number}

    dzdx = convert(typeof(v1.value), v2)
    dzdy = v1.value
    create_node(v1.tape, dzdx, dzdy, v1, 0);

    tmp = v1.value * v2
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end
function Base.:*(v1::N, v2::T) where {T <: Variable, N <: Number}
    return v2 * v1
end


function Base.:/(v1::T, v2::T) where {T <: Variable}
    
    dzdx = 1 / v2.value
    dzdy = -v1.value / v2.value^2
    create_node(v1.tape, dzdx, dzdy, v1, v2);

    tmp = v1.value / v2.value
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end

function Base.:/(v1::T, v2::N) where {T <: Variable, N <: Number}
    return v1 * (1/v2)
end

function Base.:/(v1::N, v2::T) where {T <: Variable, N <: Number}
    dzdx = zero(N)
    dzdy = -v1.value / v2.value^2
    create_node(v1.tape, dzdx, dzdy, v1, v2);

    tmp = v1 / v2.value
    var = create_temporary_variable(v2.tape, tmp)
    
    return var
end




function Base.:^(v1::T, v2::N) where {T <: Variable, N <: Number}

    dzdx = v2 * v1.value ^ (v2-1)
    dzdy = 0.0
    create_node(v1.tape, dzdx, dzdy, v1, 0);

    tmp = v1.value ^ v2
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end

function Base.:^(v1::N, v2::T) where {T <: Variable, N <: Number}
    
    dzdx = log(v1) * v1 ^ v2.value
    dzdy = 0.0
    create_node(v2.tape, dzdx, dzdy, 0, v2);

    tmp = v1 ^ v2.value
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end


function Base.:^(v1::T, v2::T) where {T <: Variable}

    dzdx = v2.value * v1.value ^ (v2.value - 1)
    dzdy = log(v1.value) * v1.value ^ v2.value
    create_node(v1.tape, dzdx, dzdy, v1, v2);

    tmp = v1.value ^ v2.value
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end





function Base.max(v1::T, v2::T) where {T <: Variable}
   
    dzdx = v1.value > v2.value
    dzdy = v1.value < v2.value
    create_node(v1.tape, dzdx, dzdy, v1, v2);

    tmp = max(v1.value, v2.value)
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end

function Base.max(v1::T, v2::N) where {T <: Variable, N <: Number}

    dzdx = v1.value > v2
    dzdy = v1.value < v2
    create_node(v1.tape, dzdx, dzdy, v1, 0);

    tmp = max(v1.value, v2)
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end

function Base.max(v1::N, v2::T) where {T <: Variable, N <: Number}

    dzdx = v2.value > v1
    dzdy = v2.value < v1
    create_node(v2.tape, dzdx, dzdy, 0, v2);

    tmp = max(v1, v2.value)
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end






function Base.min(v1::T, v2::T) where {T <: Variable}

    dzdx = v1.value < v2.value
    dzdy = v1.value > v2.value
    create_node(v1.tape, dzdx, dzdy, v1, v2);

    tmp = min(v1.value, v2.value)
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end

function Base.min(v1::T, v2::N) where {T <: Variable, N <: Number}

    dzdx = v1.value < v2
    dzdy = v1.value > v2
    create_node(v1.tape, dzdx, dzdy, v1, 0);

    tmp = min(v1.value, v2)
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end

function Base.min(v1::N, v2::T) where {T <: Variable, N <: Number}

    dzdx = v2.value > v1
    dzdy = v2.value < v1
    create_node(v2.tape, dzdx, dzdy, 0, v2);

    tmp = max(v1, v2.value)
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end








function Base.sin(v1::T) where {T <: Variable}

    dzdx = cos(v1.value)
    dzdy = 0.0
    create_node(v1.tape, dzdx, dzdy, v1, 0);

    tmp = sin(v1.value)
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end

function Base.cos(v1::T) where {T <: Variable}
    
    dzdx = -sin(v1.value)
    dzdy = 0.0
    create_node(v1.tape, dzdx, dzdy, v1, 0);

    tmp = cos(v1.value)
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end

function Base.tan(v1::T) where {T <: Variable}
    
    dzdx = (1/cos(v1.value))^2
    dzdy = 0.0
    create_node(v1.tape, dzdx, dzdy, v1, 0);

    tmp = tan(v1.value)
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end

function Base.abs(v1::T) where {T <: Variable}
    
    dzdx = sign(v1.value)
    dzdy = 0.0
    create_node(v1.tape, dzdx, dzdy, v1, 0);

    tmp = abs(v1.value)
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end

function Base.sqrt(v1::T) where {T <: Variable}
        
    dzdx = 1 / sqrt(v1.value)
    dzdy = 0.0
    create_node(v1.tape, dzdx, dzdy, v1, 0);

    tmp = sqrt(v1.value)
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end

function Base.exp(v1::T) where {T <: Variable}

    dzdx = exp(v1.value)
    dzdy = 0.0
    create_node(v1.tape, dzdx, dzdy, v1, 0);

    tmp = exp(v1.value)
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end

function Base.log(v1::T) where {T <: Variable}

    dzdx = 1 / (v1.value)
    dzdy = 0.0
    create_node(v1.tape, dzdx, dzdy, v1, 0);

    tmp = log(v1.value)
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end

function Base.sinh(v1::T) where {T <: Variable}

    dzdx = cosh(v1.value)
    dzdy = 0.0
    create_node(v1.tape, dzdx, dzdy, v1, 0);

    tmp = sinh(v1.value)
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end

function Base.cosh(v1::T) where {T <: Variable}

    dzdx = sinh(v1.value)
    dzdy = 0.0
    create_node(v1.tape, dzdx, dzdy, v1, 0);

    tmp = cosh(v1.value)
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end

function Base.tanh(v1::T) where {T <: Variable}

    dzdx = (1/cosh(v1.value))^2
    dzdy = 0.0
    create_node(v1.tape, dzdx, dzdy, v1, 0);

    tmp = tanh(v1.value)
    var = create_temporary_variable(v1.tape, tmp)
    
    return var
end









struct Gradient{T}
    der::Vector{T}

    function Gradient{T}(n::Int) where {T}
        v = zeros(n)
        return new(v)
    end
end

function Gradient(n::Int)
    T = Float64
    return Gradient{T}(n)
end


function grad_wrt(g::Gradient, var::Variable)
    return g.der[ var.index ]
end

function create_gradient(var::Variable)

    L = length(var.tape)
    g = Gradient(L)

    # seed
    g.der[var.index] = one(Float64) # 1.0

    # traverse the tape in reverse
    for kk = L:-1:1

        node = var.tape.stack[kk]
        d    = g.der[kk]

        # update the adjoints for its parent nodes
        if node.parent1 > 0
            g.der[ node.parent1 ] += node.parder1 * d
        end
        if node.parent2 > 0
            g.der[ node.parent2 ] += node.parder2 * d
        end
    end


    return g
end





function derivative(::ReverseMode, fcn, x0::T) where {T <: Number}
    @tape t
    var = create_variable(t, x0)
    y   = fcn(var)
    gr  = create_gradient(y)
    g   = grad_wrt(gr, var)
    return g
end

function gradient(::ReverseMode, fcn, x0::Vector{T}) where {T <: Number}
    @tape t
    L       = length(x0)
    var_vec = Vector{Variable}(undef, L)
    
    for ii = 1:L
        var_vec[ii] = create_variable(t, x0[ii])
    end
    
    y  = fcn(var_vec)
    gr = create_gradient(y)
    g  = similar(x0)

    for ii = 1:L
        g[ii] = grad_wrt(gr, var_vec[ii])
    end

    return g
end

function jacobian(::ReverseMode, fcn, x0::Vector{T}) where {T <: Number}

    # f: R^n -> R^m
    # g_ij = df_i / dx_j

    @tape t
    L       = length(x0)
    var_vec = Vector{Variable}(undef, L)
    
    for ii = 1:L
        var_vec[ii] = create_variable(t, x0[ii])
    end
    
    y  = fcn(var_vec)
    m = length(y)
    jac = zeros(T, m, L) # m-by-n
    for ii = 1:m
        gr = create_gradient(y[ii])
    
        for jj = 1:L
            jac[ii, jj] = grad_wrt(gr, var_vec[jj])
        end

    end
   

    return jac

end


