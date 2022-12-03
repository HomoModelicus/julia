
include("../../../../math/common/sparse/src/sparse_module.jl")


module mtx
using ..sparse

# mtrx is a file format for storing sparse matrices
# coming from https://sparse.tamu.edu/?per_page=100
# 
# there is a heading which seems to be 13 lines
# 
# the first non header row contains the number of cols, rows and nnz
#
# extracted files consist of 3 cols
# first col = column index in 1 based indexing
# second col = row index in 1 based indexing
# third col = data
#
# there is a space between the cols


struct MtxBody
    n_row::Int
    n_col::Int
    nnz::Int
    row_index::Vector{Int}
    col_index::Vector{Int}
    data::Vector{Float64}
end

struct MtxFileContent{T}
    header::Vector{T}
    body::MtxBody
end




function read_mtx(url::String)
    iostr = open(url, "r");
    iobuff = read(iostr, String);
    close(iostr);

    mtx_content = parse_mtx(iobuff)
    return mtx_content
end




function find_first_nonheader_index(lines)
    Ll = length(lines)
    kk = 0
    for outer kk = 1:Ll
        line = strip( lines[kk] )
        if line[1] == '%'
            continue
        else
            break
        end
    end
    first_non_header_index = kk
    return first_non_header_index
end

function extract_header(lines, first_non_header_index)
    header = lines[1:first_non_header_index-1]
    return header
end

function interpret_body(lines, first_non_header_index)

    L = length(lines)-1

    # handle first row separately
    line    = lines[first_non_header_index]
    strvec  = split(line, " ")
    n_row   = parse(Int, strvec[1])
    n_col   = parse(Int, strvec[2])
    nnz     = parse(Int, strvec[3])

    row_index = zeros(Int, nnz)
    col_index = zeros(Int, nnz)
    data      = zeros(Float64, nnz)

    ii = 0
    for kk = (first_non_header_index+1):L
        ii += 1

        strvec = split(lines[kk], " ")
        rr     = parse(Int, strvec[1])
        cc     = parse(Int, strvec[2])
        dd     = parse(Float64, strvec[3])

        row_index[ii]   = rr
        col_index[ii]   = cc
        data[ii]        = dd
    end


    body = MtxBody(n_row, n_col, nnz, row_index, col_index, data)
    return body
end

function parse_mtx(iobuff)

    mtx_content = iobuff
    lines       = split(iobuff, "\n")

    first_non_header_index = find_first_nonheader_index(lines)
    header = extract_header(lines, first_non_header_index)
    body   = interpret_body(lines, first_non_header_index)

    mtx_content = MtxFileContent(header, body)
    return mtx_content
end



function mtx_to_sparse_csc(mtx_content::MtxFileContent)

    return sparse.SparseMatrixCSC(
        mtx_content.body.n_row,
        mtx_content.body.n_col,
        mtx_content.body.data,
        mtx_content.body.row_index,
        mtx_content.body.col_index)

end



end # module





