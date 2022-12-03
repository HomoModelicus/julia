



module Symbolics


struct BipartiteGraph{T}
    matrix::Matrix{T}

    function BipartiteGraph{T}(n_row, n_col) where {T}
        matrix = zeros(T, n_row, n_col)
        return new(matrix)
    end

    function BipartiteGraph{T}(matrix::Matrix{T}) where {T}
        return new(matrix)
    end

    function BipartiteGraph(matrix::Matrix{T}) where {T}
        return BipartiteGraph{T}(matrix)
    end
end


function Base.eltype(::BipartiteGraph{T}) where {T}
    return T
end

function Base.size(bigraph::BipartiteGraph)
    return size(bigraph.matrix)
end

function Base.size(bigraph::BipartiteGraph, dims)
    return size(bigraph.matrix, dims)
end

function Base.length(bigraph::BipartiteGraph)
    return length(bigraph.matrix)
end

function Base.IndexStyle(bigraph::BipartiteGraph)
    return IndexCartesian()
end

function Base.IndexStyle(::Type{BipartiteGraph})
    return IndexCartesian()
end


function Base.getindex(bigraph::BipartiteGraph, index::Int)
    return bigraph.matrix[index]
end

function Base.setindex!(bigraph::BipartiteGraph, x, index::Int)
    return bigraph.matrix[index] = x
end

function Base.getindex(bigraph::BipartiteGraph, index::Vararg{Int, N}) where {N}
    return bigraph.matrix[index...]
end

function Base.setindex!(bigraph::BipartiteGraph, x, index::Vararg{Int, N}) where {N}
    return bigraph.matrix[index...] = x
end

function Base.getindex(bigraph::BipartiteGraph, index...)
    return bigraph.matrix[index...]
end

function Base.setindex!(bigraph::BipartiteGraph, x, index...)
    return bigraph.matrix[index...] = x
end



function Base.show(io::IO, mime::MIME"text/plain", bigraph::BipartiteGraph{T}) where {T}
    if get(io, :compact, false)
        print(io, "Main.Symbolics.BipartiteGraph{$T}($(size(bigraph,1)), $(size(bigraph,2)))")
    else
        println(io, "Main.Symbolics.BipartiteGraph{$T}($(size(bigraph,1)), $(size(bigraph,2)))")
        show(io, bigraph.matrix)
    end
end



const color_ansi_black   = "\u001b[30m"
const color_ansi_red     = "\u001b[31m"
const color_ansi_green   = "\u001b[32m"
const color_ansi_yellow  = "\u001b[33m"
const color_ansi_blue    = "\u001b[34m"
const color_ansi_magenta = "\u001b[35m"
const color_ansi_cyan    = "\u001b[36m"
const color_ansi_white   = "\u001b[37m"
const color_ansi_reset   = "\u001b[0m"



# const EquationBipartiteGraph = BipartiteGraph{Int}

# function EquationBipartiteGraph(n_col, n_row)
#     return BipartiteGraph{Int}(n_col, n_row)
# end

# the values doesnt really matter I think
# 
# but still, zeros for no-edge, 1 for edge
# the red and blue values are just arbitrary constants

const value_black = Int8(1)
const value_empty = Int8(0)
const value_red   = Int8(8)
const value_blue  = Int8(-1)



function print_redblue(bigraph::BipartiteGraph)

    n_row = size(bigraph, 1)
    n_col = size(bigraph, 2)
    
    ws_pre = " "
    ws_btw = "  "

    red   = "r"
    blue  = "b"
    black = "1"
    empty = "0"

    for ii = eachindex(1:n_row)
        str = ws_pre

        for jj = eachindex(1:n_col)

            if bigraph.matrix[ii, jj] == value_black
                sym   = black
                color = color_ansi_white # use white -> dark mode
            elseif bigraph.matrix[ii, jj] == value_red
                sym   = red
                color = color_ansi_red
            elseif bigraph.matrix[ii, jj] == value_blue
                sym   = blue
                color = color_ansi_blue
            else
                sym   = empty
                color = color_ansi_black
            end

            
            str = str * color * sym * ws_btw * color_ansi_reset
        end

        println(str)
    end
    println("\n")

end



function check_dimensions(bigraph::BipartiteGraph)
    n_row = size(bigraph, 1)
    n_col = size(bigraph, 2)
    
    if n_row != n_col
        error("dimensions must be the same in a well defined equation system")
    end
end





function swap_rows!(matrix::Matrix, row1, row2)
    for jj in 1:size(matrix, 2)
        tmp              = matrix[row1, jj]
        matrix[row1, jj] = matrix[row2, jj]
        matrix[row2, jj] = tmp
    end
end

function swap_cols!(matrix::Matrix, col1, col2)
    for ii in 1:size(matrix, 1)
        tmp              = matrix[ii, col1]
        matrix[ii, col1] = matrix[ii, col2]
        matrix[ii, col2] = tmp
    end
end



function row_n_nonzero!(matrix::Matrix{T}, row_vec::Vector) where {T}
    # sum for each row
    z     = zero(T)
    n_dim = length(row_vec)
    for ii = 1:n_dim
        sum::Int = 0
        for jj = 1:n_dim
            sum += Int(matrix[ii, jj] != z)
        end
        row_vec[ii] = sum
    end
    return row_vec
end

function col_n_nonzero!(matrix::Matrix{T}, col_vec::Vector) where {T}
    # sum for each col
    # sum!(col_vec, matrix)
    z     = zero(T)
    n_dim = length(col_vec)
    for jj = 1:n_dim
        sum::Int = 0
        for ii = 1:n_dim
            sum += Int(matrix[ii, jj] != z)
        end
        col_vec[jj] = sum
    end
    return col_vec
end


function find_first_black_in_row(matrix::Matrix, row)
    n_col = size(matrix, 2)
    for jj = 1:n_col
        if matrix[row, jj] == value_black
            return jj
        end
    end
end

function find_first_black_in_col(matrix::Matrix, col)
    n_row = size(matrix, 1)
    for ii = 1:n_row
        if matrix[ii, col] == value_black
            return ii
        end
    end
end





function swap_rows!(bigraph::BipartiteGraph, row1, row2)
    return swap_rows!(bigraph.matrix, row1, row2)
end

function swap_cols!(bigraph::BipartiteGraph, col1, col2)
    return swap_cols!(bigraph.matrix, col1, col2)
end


function row_n_nonzero!(bigraph::BipartiteGraph, row_vec::Vector)
    return row_n_nonzero!(bigraph.matrix, row_vec)
end

function col_n_nonzero!(bigraph::BipartiteGraph, col_vec::Vector)
    return col_n_nonzero!(bigraph.matrix, col_vec)
end

function find_first_black_in_row(bigraph::BipartiteGraph, row)
    return find_first_black_in_row(bigraph.matrix, row)
end

function find_first_black_in_col(bigraph::BipartiteGraph, col)
    return find_first_black_in_col(bigraph.matrix, col)
end


function mark_red!(bigraph::BipartiteGraph, row, col)
    bigraph[row, col] = value_red
end

function mark_black_to_blue_in_row!(bigraph::BipartiteGraph, row, black_col_sum)
    n_col = size(bigraph, 2)
    for jj = 1:n_col
        if bigraph[row, jj] == value_black
            bigraph[row, jj] = value_blue
            black_col_sum[jj] -= 1
        end
    end
end

function mark_black_to_blue_in_col!(bigraph::BipartiteGraph, col, black_row_sum)
    n_row = size(bigraph, 1)
    for ii = 1:n_row
        if bigraph[ii, col] == value_black
            bigraph[ii, col] = value_blue
            black_row_sum[ii] -= 1
        end
    end
end


function block_lower_triangular!(bigraph::BipartiteGraph{T}) where {T}



    # rule 1: equation (by row)
    # if an equation contains only one variable -> mark the variable in that equation red
    # the other occurances for that variable blue
    # increase the first eq index
    # 
    # check the row sum for == value_black
    # 

    # rule 2: variable (by col)
    # if a variable is only occured in one equation -> mark that location to red
    # mark the variables in that equation to blue
    # decrease the last eq index
    # 
    # check for the col sum for == value_black




    n_dim = size(bigraph, 1)


    black_row_sum = zeros(Int, n_dim)
    black_col_sum = zeros(Int, n_dim)
    row_n_nonzero!(bigraph.matrix, black_row_sum)
    col_n_nonzero!(bigraph.matrix, black_col_sum)


    equation_causility_index = zeros(Int, n_dim)

    first = 1
    last  = n_dim

    # do_it_equations = true
    # do_it_variables = true

    # was_set_in_equations = false
    # was_set_in_variables = false

    do_it = true
    while do_it # do_it_equations || do_it_variables

        # equations
        # was_set_in_equations = false
        do_it = false
        for ii = 1:n_dim
            if black_row_sum[ii] == value_black

                # reset the black sum
                black_row_sum[ii] = value_empty

                # search for the variable in the incidence matrix
                red_variable_col = find_first_black_in_row(bigraph, ii)
                mark_red!(bigraph, ii, red_variable_col)

                # mark every blacks in the column and reduce the black sum
                mark_black_to_blue_in_col!(bigraph, red_variable_col, black_row_sum)

                # set the equation causility
                equation_causility_index[ii] = first
                first += 1

                # was_set_in_equations = true
                do_it = true
            end
        end
        # do_it_variables = was_set_in_equations ? true : false
        if first > last break end



        # variables
        was_set_in_variables = false
        for ii = 1:n_dim
            if black_col_sum[ii] == value_black
                
                # reset the black sum
                black_col_sum[ii] = value_empty

                # search for the variable in the incidence matrix
                red_variable_row = find_first_black_in_col(bigraph, ii)
                mark_red!(bigraph, red_variable_row, ii)

                # mark every blacks in the column and reduce the black sum
                mark_black_to_blue_in_row!(bigraph, red_variable_row, black_col_sum)

                # set the equation causility
                equation_causility_index[red_variable_row] = last
                last -= 1

                # was_set_in_variables = true
                do_it = true
            end
        end
        # do_it_equations = was_set_in_variables ? true : false
        if first > last break end

    end

    return equation_causility_index
end


function permute_equations!(bigraph::BipartiteGraph, pvec)
    
    n_dim = size(bigraph, 2)

    for jj = 1:n_dim
        v = view(bigraph.matrix, 1:n_dim, jj)
        permute!(v, pvec)
    end

    n_dim_half = div(n_dim, 2)
    for jj = 1:n_dim_half
        for ii = 1:n_dim
            tmp                                = bigraph.matrix[ii, jj]
            bigraph.matrix[ii, jj]             = bigraph.matrix[ii, n_dim - jj + 1]
            bigraph.matrix[ii, n_dim - jj + 1] = tmp
        end
    end

    # for ii = 1:n_dim
    #     v = view(bigraph.matrix, ii, 1:n_dim)
    #     permute!(v, pvec)
    # end
end



# function inplace_permute!(a::Vector, pvec::Vector)

#     n_dim = length(a)

#     for ii = 1:n_dim
#         tmp   = a[ii]
#         a[ii] = a[pvec[ii]]
#     end

# end


end # module




module stest
using ..Symbolics


# n_dim = 3

# bigraph = Symbolics.BipartiteGraph{Int8}(n_dim, n_dim)

# bigraph.matrix[1, 3]  = Symbolics.value_black
# bigraph.matrix[2, :] .= Symbolics.value_black
# bigraph.matrix[3, 2]  = Symbolics.value_black


n_dim = 6

bigraph = Symbolics.BipartiteGraph{Int8}(n_dim, n_dim)

bigraph.matrix[1, 3] = Symbolics.value_black
bigraph.matrix[1, 4] = Symbolics.value_black
bigraph.matrix[1, 6] = Symbolics.value_black


bigraph.matrix[2, 1] = Symbolics.value_black
bigraph.matrix[2, 2] = Symbolics.value_black
bigraph.matrix[2, 5] = Symbolics.value_black
bigraph.matrix[2, 6] = Symbolics.value_black

bigraph.matrix[3, 2]  = Symbolics.value_black
bigraph.matrix[3, 3]  = Symbolics.value_black

bigraph.matrix[4, 1]  = Symbolics.value_black
bigraph.matrix[4, 3]  = Symbolics.value_black
bigraph.matrix[4, 5]  = Symbolics.value_black

bigraph.matrix[5, 2]  = Symbolics.value_black
bigraph.matrix[5, 6]  = Symbolics.value_black

bigraph.matrix[6, 3]  = Symbolics.value_black
bigraph.matrix[6, 6]  = Symbolics.value_black


# n_dim = 4

# bigraph = Symbolics.BipartiteGraph{Int8}(n_dim, n_dim)





# pretty printing
bigraph |> Symbolics.print_redblue



# equation_causility_index = Symbolics.block_lower_triangular!(bigraph)

# bigraph |> Symbolics.print_redblue

#=
Symbolics.permute_equations!(bigraph, equation_causility_index)

correct_equation_causility_index = collect(1:length(equation_causility_index))

bigraph |> Symbolics.print_redblue
=#

end

