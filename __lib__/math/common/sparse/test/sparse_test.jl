
module stest
using LinearAlgebra
using BenchmarkTools
using ..sparse

function test_create_sparse_vec()
    data = [10, 20, 1e-11, -30, 1e-5, 50, 1e-50]
    index = [1, 10, 15, 20]
    # vec = sparse.SparseVector(data, index)

    vec2 = sparse.create_sparse(data)

end

function test_create_sparse_mat()

    n_row = 5
    n_col = 3

    data        = [10,  20, 30, 40, 50, 60, 70, 80, 90]
    row_index   = [1,   2,  3,  4,  5,  1,  1,  4,  5, n_row]
    col_index   = [1,   1,  1,  2,  2,  2,  3,  3,  3, n_col]
    

    spmat = sparse.SparseMatrixCOO(data, row_index, col_index)

end


function test_add()

    data_x  = [3.3, 4, 5, 6, 10, 4,  5,  2,  3]
    index_x = [3,   4, 6, 8, 12, 15, 16, 18, 20, 25]

    sp_x = sparse.SparseVector(data_x, index_x)

    data_y  = [5.0, 2, 3, 5, 2, 3,  5,  2,  3]
    index_y = [4,   5, 6, 7, 8, 14, 15, 16, 18, 25]

    sp_y = sparse.SparseVector(data_y, index_y)

    sp_z = sparse.add(sp_x, sp_y)

    show(sp_z)
    
end


function test_matrix_vector_mult()

    n_row = 5
    n_col = 3

    data        = [10,  20, 30, 40, 50, 60, 70, 80, 90]
    row_index   = [1,   2,  3,  4,  5,  1,  1,  4,  5, n_row]
    col_index   = [1,   1,  1,  2,  2,  2,  3,  3,  3, n_col]
    

    spmat = sparse.SparseMatrixCOO(data, row_index, col_index)

    fvec = [10.0, 5, 6]

    res = spmat * fvec # sparse.matrix_vector_prod(spmat, fvec)
    show(res)

    fmat = sparse.create_full(spmat)
    res_theo = fmat * fvec
    show(res_theo)

    show(res_theo - res)


end



function create_matrix(n_dim = 8)

    A = zeros(Float64, n_dim, n_dim)

    main_diag = [1; 4 * ones(n_dim-2); 4]
    side_diag = -ones(n_dim-1)
    sideside_diag = -ones(n_dim-3)
    
    main_diag_idx = diagind(A, 0)
    side_m1_diag_idx = diagind(A, 1)
    side_p1_diag_idx = diagind(A, -1)
    
    side_m3_diag_idx = diagind(A, 3)
    side_p3_diag_idx = diagind(A, -3)
    
    
    
    A[ main_diag_idx ] = main_diag
    A[ side_m1_diag_idx ] = side_diag
    A[ side_p1_diag_idx ] = side_diag
    A[ side_m3_diag_idx ] = sideside_diag
    A[ side_p3_diag_idx ] = sideside_diag

    return A
end

function test_csc()
    n_dim = 8
    A = create_matrix(n_dim)
    A[:,1] .= 0.0
    A[:,4] .= 0.0
    
    spmat = sparse.create_sparse_csc(A)
    
    Af = sparse.create_full(spmat)
    
    vec = rand(n_dim) # ones(n_dim)
    
    res = sparse.matrix_vector_prod(spmat, vec)
    
    res_theo = A * vec
    
    println( "$(norm(res - res_theo))" )

end

function test_matmult(spmat, vec)
    res = sparse.matrix_vector_prod(spmat, vec)
end

function benchmark_matmult()

    n_dim = 25000 # 25_000
    A = create_matrix(n_dim)
    spmat = sparse.create_sparse_csc(A)
    vec = rand(n_dim)


    b = @benchmark test_matmult($spmat, $vec)
    println("=== sparse matrix vec mult === ")
    show(
        stdout,
        MIME("text/plain"),
        b)
    println("")
    println("")

    b = @benchmark $A * $vec
    println("=== default full matrix vec mult === ")
    show(
        stdout,
        MIME("text/plain"),
        b)


    # res_sp = test_matmult(spmat, vec)
    # res_fu = A * vec;

    # println("$(norm(res_sp - res_fu))")

end



n_dim = 8
A = create_matrix(n_dim)
A[7, 6] = 3.14
A[8,7] = 2.6
spmat = sparse.create_sparse_csc(A)


(L, d, U) = sparse.matrix_split(spmat)

Lf = sparse.create_full(L)
Uf = sparse.create_full(U)
Df = diagm(d)

println(" $(norm( Lf + Uf + Df - A )) ")


# stest.L[8,6]



end # stest