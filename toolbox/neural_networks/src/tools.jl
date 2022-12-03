struct Bias{T}
    array::Vector{Vector{T}}
    function Bias{T}(bias_vec_of_vec::Vector{Vector{T}}) where {T}
        return new(copy(bias_vec_of_vec))
    end
end

function Bias(bias_vec_of_vec::Vector{Vector{T}}) where {T}
    return Bias{T}(bias_vec_of_vec)
end

function Bias(n_neuronns_per_layers::Vector{Int}, T = Float64)
    # for layers = 2..N_layers
    N_layers = length(n_neuronns_per_layers)
    bias_vec_of_vec = Vector{Vector{T}}(undef, N_layers-1)
    for ll = 1:N_layers-1
        tmp = randn(T, n_neuronns_per_layers[ll+1])
        bias_vec_of_vec[ll] = tmp
    end
    return Bias(bias_vec_of_vec)
end

function subarray(bias::Bias; layer = 1)
    return bias.array[layer]
end


struct WeightMatrix{T}
    # n_row = 1..n_neurons in the next layer
    # n_col = 1..n_neurons in the prev layer
    array::Vector{Matrix{T}}

    function WeightMatrix{T}(weightmat_vec::Vector{Matrix{T}}) where {T}
        return new(weightmat_vec)
    end
end

function WeightMatrix(weightmat_vec::Vector{Matrix{T}}) where {T}
    return WeightMatrix{T}(weightmat_vec)
end

function WeightMatrix(n_neuronns_per_layers::Vector{Int}, T = Float64)
    # for between layers = 1..N_layers
    N_layers   = length(n_neuronns_per_layers)
    weight_mat = Vector{Matrix{T}}(undef, N_layers-1)
    for ll = 1:N_layers-1
        n_prev         = n_neuronns_per_layers[ll]   # n_col
        n_next         = n_neuronns_per_layers[ll+1] # n_row
        tmp            = randn(T, n_next, n_prev)
        weight_mat[ll] = tmp
    end

    return WeightMatrix(weight_mat)
end

function submatrix(weight_mat::WeightMatrix; layer = 1)
    return weight_mat.array[layer]
end

function zeros!(weight_mat::WeightMatrix)
    L = length(weight_mat.array)
    for ii = 1:L
        v = weight_mat.array[ii]
        T = eltype(v)
        for jj in eachindex(v)
            v[jj] = zero(T)
        end
    end
end


struct IntermediateVectorResult{T}
    array::Vector{Vector{T}}
    function IntermediateVectorResult{T}(vec_of_vec::Vector{Vector{T}}) where {T}
        return new(copy(vec_of_vec))
    end
end

function IntermediateVectorResult(vec_of_vec::Vector{Vector{T}}) where {T}
    return IntermediateVectorResult{T}(vec_of_vec)
end

function IntermediateVectorResult(n_neuronns_per_layers::Vector{Int}, T = Float64)
    # for layers = 2..N_layers
    N_layers   = length(n_neuronns_per_layers)
    vec_of_vec = Vector{Vector{T}}(undef, N_layers-1)
    for ll = 1:N_layers-1
        # tmp            = Vector{T}(undef, n_neuronns_per_layers[ll+1])
        tmp            = zeros(T, n_neuronns_per_layers[ll+1])
        vec_of_vec[ll] = tmp
    end
    return IntermediateVectorResult(vec_of_vec)
end

function subarray(res::IntermediateVectorResult; layer = 1)
    return res.array[layer]
end

function zeros!(res::IntermediateVectorResult)
    L = length(res.array)
    for ii = 1:L
        v = res.array[ii]
        T = eltype(v)
        for jj in eachindex(v)
            v[jj] = zero(T)
        end
    end
end




struct PerformanceStat{T}
    perf::Vector{T}
    min::T
    max::T
    mean::T
    sigma::T
    function PerformanceStat{T}(perf::Vector{T}) where {T}
        min   = minimum(perf)
        max   = maximum(perf)
        s     = sum(perf)
        N     = length(perf)
        mean  = s / N
        v     = 1/(N-1) * sum( (perf .- mean).^2 )
        sigma = sqrt(v)
        return new(perf, min, max, mean, sigma)
    end
end

function PerformanceStat(perf::Vector{T}) where {T}
    return PerformanceStat{T}(perf)
end

function Base.show(io::IO, perfstat::PerformanceStat)
    println("Performance stat:")
    println("    - min:   $(perfstat.min)")
    println("    - mean:  $(perfstat.mean)")
    println("    - max:   $(perfstat.max)")
    println("    - sigma: $(perfstat.sigma)")
        
end

