
mutable struct Node # is mutable necessary?
    weight_1::Float64 # parder wrt first input
    weight_2::Float64 # parder wrt second input
    parent_1::Int
    parent_2::Int
    
    function Node(w1, w2, p1, p2)
        obj = new(w1, w2, p1, p2)
        return obj
    end
end
function Node()
    return Node(0.0, 0.0, 0, 0)
end


struct Tape
    stack::datastructs.Stack{Node}
    
    function Tape()
        s = datastructs.Stack{Node}()
        obj = new(s)
        return obj
    end
end
function Base.push!(tape::Tape, node::Node)
    return push!( tape.stack, node )
end
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




mutable struct Variable # is mutable necessary?
    tape::Tape
    index::Int
    value::Float64
    function Variable(tape, index, value)
        return new(tape, index, value)
    end
end
function Variable(tape, value)
    return Variable(tape, 0, value)
end
function create_variable(tape::Tape, value)
    # input variables do not have parents -> 0
    node = Node(value, 0.0, 0, 0)
    push!(tape, node)
    last_index  = datastructs.last_valid_index(tape.stack)
    v           = Variable(tape, last_index, value)
    return v
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
    # create new variable
    tmp = -v1.value
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = -1.0
    dzdy = 0.0
    
    node = Node(dzdx, dzdy, v1.index, 0)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end

function Base.:+(v1::T, v2::T) where {T <: Variable}
    
    # create new variable
    tmp = v1.value + v2.value
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = 1.0
    dzdy = 1.0
    
    node = Node(dzdx, dzdy, v1.index, v2.index)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end
function Base.:+(v1::T, v2::N) where {T <: Variable, N <: Number}
    
    # create new variable
    tmp = v1.value + v2
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = 1.0
    dzdy = 0.0
    
    node = Node(dzdx, dzdy, v1.index, 0)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end
function Base.:+(v1::N, v2::T) where {T <: Variable, N <: Number}
    return v2 + v1
end

function Base.:-(v1::T, v2::T) where {T <: Variable}
    
    # create new variable
    tmp = v1.value - v2.value
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = 1.0
    dzdy = -1.0
    
    node = Node(dzdx, dzdy, v1.index, v2.index)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end
function Base.:-(v1::T, v2::N) where {T <: Variable, N <: Number}
    
    # create new variable
    tmp = v1.value - v2
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = 1.0
    dzdy = 0.0
    
    node = Node(dzdx, dzdy, v1.index, v2.index)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end
function Base.:-(v2::N, v1::T) where {T <: Variable, N <: Number}
    
    # create new variable
    tmp = -(v1.value - v2)
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = -1.0
    dzdy = 0.0
    
    node = Node(dzdx, dzdy, v1.index, 0)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end



function Base.:*(v1::T, v2::T) where {T <: Variable}
    
    # create new variable
    tmp = v1.value * v2.value
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = v2.value
    dzdy = v1.value
    
    node = Node(dzdx, dzdy, v1.index, v2.index)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end
function Base.:*(v1::T, v2::N) where {T <: Variable, N <: Number}
    
    # create new variable
    tmp = v1.value * v2
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = v2
    dzdy = v1.value
    
    node = Node(dzdx, dzdy, v1.index, 0)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end
function Base.:*(v1::N, v2::T) where {T <: Variable, N <: Number}
    return v2 * v1
end


function Base.:^(v1::T, v2::N) where {T <: Variable, N <: Number}
    
    # create new variable
    tmp = v1.value ^ v2
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = v2 * v1.value ^ (v2-1)
    dzdy = 0.0
    
    node = Node(dzdx, dzdy, v1.index, 0)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end

function Base.:^(v2::N, v1::T) where {T <: Variable, N <: Number}
    
    # create new variable
    tmp = v2 ^ v1.value
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = log(v2) * v2 ^ v1.value
    dzdy = 0.0
    
    node = Node(dzdx, dzdy, v1.index, 0)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end


function Base.:^(v1::T, v2::T) where {T <: Variable}
    
    # create new variable
    tmp = v1.value ^ v2.value
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = v2.value * v1.value ^ (v2.value - 1)
    dzdy = log(v1.value) * v1.value ^ v2.value
    
    node = Node(dzdx, dzdy, v1.index, v2.index)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end


# v1^v2


function Base.max(v1::T, v2::T) where {T <: Variable}
    # create new variable
    tmp = max(v1.value, v2.value)
    var = Variable(v1.tape, tmp)
    
    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = v1.value > v2.value
    dzdy = v1.value < v2.value
        
    node = Node(dzdx, dzdy, v1.index, v2.index)
    push!(v1.tape, node)
    
    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx
    
    return var
end
function Base.max(v1::T, v2::N) where {T <: Variable, N <: Number}
    # create new variable
    tmp = max(v1.value, v2)
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = v1.value > v2
    dzdy = v1.value < v2
    
    node = Node(dzdx, dzdy, v1.index, 0)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end
function Base.max(v2::N, v1::T) where {T <: Variable, N <: Number}
    # create new variable
    tmp = max(v1.value, v2)
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = v1.value > v2
    dzdy = v1.value < v2
    
    node = Node(dzdx, dzdy, v1.index, 0)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end






function Base.min(v1::T, v2::T) where {T <: Variable}
    # create new variable
    tmp = min(v1.value, v2.value)
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = v1.value < v2.value
    dzdy = v1.value > v2.value
    
    node = Node(dzdx, dzdy, v1.index, v2.index)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end
function Base.min(v1::T, v2::N) where {T <: Variable, N <: Number}
    # create new variable
    tmp = min(v1.value, v2)
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = v1.value < v2
    dzdy = v1.value > v2

    node = Node(dzdx, dzdy, v1.index, 0)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end
function Base.min(v2::N, v1::T) where {T <: Variable, N <: Number}
    # create new variable
    tmp = min(v1.value, v2)
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = v1.value < v2
    dzdy = v1.value > v2

    node = Node(dzdx, dzdy, v1.index, 0)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end


function Base.sin(v1::T) where {T <: Variable}
    
    # create new variable
    tmp = sin(v1.value)
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = cos(v1.value)
    
    node = Node(dzdx, 0.0, v1.index, 0)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end

function Base.cos(v1::T) where {T <: Variable}
    
    # create new variable
    tmp = cos(v1.value)
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = -sin(v1.value)
    
    node = Node(dzdx, 0.0, v1.index, 0)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end
function Base.tan(v1::T) where {T <: Variable}
    
    # create new variable
    tmp = tan(v1.value)
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = (1/cos(v1.value))^2
    
    node = Node(dzdx, 0.0, v1.index, 0)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end

function Base.abs(v1::T) where {T <: Variable}

    # create new variable
    tmp = abs(v1.value)
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = sign(v1.value)
    
    node = Node(dzdx, 0.0, v1.index, 0)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end

function Base.sqrt(v1::T) where {T <: Variable}

    # create new variable
    tmp = sqrt(v1.value)
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = 1 / sqrt(v1.value)
    
    node = Node(dzdx, 0.0, v1.index, 0)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end

function Base.exp(v1::T) where {T <: Variable}

    # create new variable
    tmp = exp(v1.value)
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = exp(v1.value)
    
    node = Node(dzdx, 0.0, v1.index, 0)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end

function Base.log(v1::T) where {T <: Variable}

    # create new variable
    tmp = log(v1.value)
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = 1 / (v1.value)
    
    node = Node(dzdx, 0.0, v1.index, 0)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end

function Base.sinh(v1::T) where {T <: Variable}

    # create new variable
    tmp = sinh(v1.value)
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = cosh(v1.value)
    
    node = Node(dzdx, 0.0, v1.index, 0)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end
function Base.cosh(v1::T) where {T <: Variable}

    # create new variable
    tmp = cosh(v1.value)
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = sinh(v1.value)
    
    node = Node(dzdx, 0.0, v1.index, 0)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end
function Base.tanh(v1::T) where {T <: Variable}

    # create new variable
    tmp = tanh(v1.value)
    var = Variable(v1.tape, tmp)

    # push it to the tape -> it creates a new node on the tape
    # calculate the partial derivatives with respect to the children == weights
    # set the parents of the newly created node
    dzdx = (1/cosh(v1.value))^2
    
    node = Node(dzdx, 0.0, v1.index, 0)
    push!(v1.tape, node)

    # get the last index from the tape
    idx       = datastructs.last_valid_index(v1.tape.stack)
    var.index = idx

    return var
end









struct Gradient
    der::Vector{Float64}
    function Gradient(n::Int)
        v = Vector{Float64}(undef, n)
        return new(v)
    end
end
function grad_wrt(g::Gradient, var::Variable)
    return g.der[ var.index ]
end

function grad(var::Variable)

    L = length(var.tape)
    g = Gradient(L)

    # seed
    g.der[var.index] = 1.0

    # traverse the tape in reverse
    for kk = L:-1:1

        node = var.tape.stack[kk]
        d = g.der[kk]

        # update the adjoints for its parent nodes
        if node.parent_1 > 0
            g.der[ node.parent_1 ] += node.weight_1 * d
        end
        if node.parent_2 > 0
            g.der[ node.parent_2 ] += node.weight_2 * d
        end
    end


    return g
end
