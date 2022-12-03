
struct RotationMatrix{T}
    m::Matrix{T}
end
function RotationMatrix(phi::T) where {T}
    c = cos(phi)
    s = sin(phi)

    m = Matrix{Float64}(undef, 2, 2)
    m[1,1] = c
    m[2,2] = c
    m[1,2] = -s
    m[2,1] = s
    
    return RotationMatrix(m)
end

function rotation_matrix(phi)
    # R * v -> v_rotated_by_phi
    c = cos(phi)
    s = sin(phi)

    R = [c -s; s c]
    return R
end

function Base.getindex(rot_mat::RotationMatrix, index)
    return rot_mat.m[index]
end

function Base.getindex(rot_mat::RotationMatrix, index...)
    return rot_mat.m[index...]
end


function rotate(rot_mat, p::T) where {T <: AbstractPoint}
    x = rot_mat[1,1] * p.x + rot_mat[1,2] * p.y
    y = rot_mat[2,1] * p.x + rot_mat[2,2] * p.y
    return T(x, y)
end

function rotate(rot_mat, p::T) where {T <: AbstractArray}
    x = rot_mat[1,1] * p[1] + rot_mat[1,2] * p[1]
    y = rot_mat[2,1] * p[1] + rot_mat[2,2] * p[1]
    return [x, y]
end
