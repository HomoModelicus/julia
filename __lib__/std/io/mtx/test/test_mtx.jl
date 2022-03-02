
include("../../../../math/common/sparse/src/sparse_module.jl")
include("../src/mtx_module.jl")

module mtest
using ..sparse
using ..mtx
using PyPlot
PyPlot.pygui(true)

# url = raw"D:\programming\sparse_matrix_collection\add32\add32.mtx"
# @time mtx_content_add32 = mtx.read_mtx(url)

# url = raw"D:\programming\sparse_matrix_collection\arc130\arc130.mtx"
# @time mtx_content_arc130 = mtx.read_mtx(url)

# url = raw"D:\programming\sparse_matrix_collection\bp_1600\bp_1600.mtx"
# @time mtx_content_bp1600 = mtx.read_mtx(url)

# url = raw"D:\programming\sparse_matrix_collection\cage3\cage3.mtx"
# @time mtx_content_cage3 = mtx.read_mtx(url)

# url = raw"D:\programming\sparse_matrix_collection\epb1\epb1.mtx"
# @time mtx_content_epb1 = mtx.read_mtx(url)

# url = raw"D:\programming\sparse_matrix_collection\g7jac100sc\g7jac100sc.mtx"
# @time mtx_content_g7jac100sc = mtx.read_mtx(url)

# url = raw"D:\programming\sparse_matrix_collection\G67\G67.mtx"
# @time mtx_content_G67 = mtx.read_mtx(url)

# url = raw"D:\programming\sparse_matrix_collection\mark3jac140\mark3jac140.mtx"
# @time mtx_content_mark3jac140 = mtx.read_mtx(url)

# url = raw"D:\programming\sparse_matrix_collection\nemeth01\nemeth01.mtx"
# @time mtx_content_nemeth01 = mtx.read_mtx(url)

# url = raw"D:\programming\sparse_matrix_collection\nemeth06\nemeth06.mtx"
# @time mtx_content_nemeth06 = mtx.read_mtx(url)

# url = raw"D:\programming\sparse_matrix_collection\nemeth19\nemeth19.mtx"
# @time mtx_content_nemeth19 = mtx.read_mtx(url)

# url = raw"D:\programming\sparse_matrix_collection\nemeth20\nemeth20.mtx"
# @time mtx_content_nemeth20 = mtx.read_mtx(url)

# url = raw"D:\programming\sparse_matrix_collection\stomach\stomach.mtx"
# @time mtx_content_stomach = mtx.read_mtx(url)



# url = raw"D:\programming\sparse_matrix_collection\cfd1\cfd1.mtx"
# @time mtx_content_cfd1 = mtx.read_mtx(url)


# url = raw"D:\programming\sparse_matrix_collection\worms20_10NN\worms20_10NN.mtx"
# @time mtx_content_worms20_10NN = mtx.read_mtx(url)



url = raw"D:\programming\sparse_matrix_collection\cz628\cz628.mtx"
@time mtx_content_cz628 = mtx.read_mtx(url)




# mtx_content_arc130
# mtx_content_cage3
# mtx_content_nemeth20

spmat = mtx.mtx_to_sparse_csc(mtx_content_cz628) 

fmat = sparse.create_full(spmat)

PyPlot.figure()
PyPlot.spy(fmat)


end
