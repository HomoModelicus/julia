
module neuro
using Random

include("activation_functions.jl")
include("sample_container.jl")
include("error_measure.jl")
include("training_options.jl")
include("tools.jl")

# =========================================================================== #
# Neural Network
# =========================================================================== #


struct NeuralNetwork{ErrorFunction}
    n_neurons_per_layers::Vector{Int}
    activation_function::Vector{AbstractActivationFunction}
    error_function::ErrorFunction
    weight_matrices::WeightMatrix{Float64}
    biases::Bias{Float64}
    
    function NeuralNetwork{ErrorFunction}(
        n_neurons_per_layers::Vector{Int},
        activation_function,
        error_function::ErrorFunction = LeastSquaresErrorFunction()
        ) where     { ErrorFunction <: AbstractErrorFunction}

        weight_matrices = WeightMatrix(n_neurons_per_layers)
        biases          = Bias(n_neurons_per_layers)

        return new(
            n_neurons_per_layers,
            activation_function,
            error_function,
            weight_matrices,
            biases)
    end
end

function NeuralNetwork(
    n_neurons_per_layers::Vector{Int},
    activation_function,
    error_function::ErrorFunction = LeastSquaresErrorFunction()
    ) where {ErrorFunction <: AbstractErrorFunction}

    return NeuralNetwork{ErrorFunction}(
        n_neurons_per_layers,
        activation_function,
        error_function)
end

function copy_in_bias!(nn::NeuralNetwork, b_vec, index::Int)
    for kk = 1:length(nn.biases.array[index])
        nn.biases.array[index][kk] = b_vec[kk]
    end
end

function copy_in_weight_matrix!(nn::NeuralNetwork, weight_mat, index::Int)
    for kk = 1:length(nn.weight_matrices.array[index])
        nn.weight_matrices.array[index][kk] = weight_mat[kk]
    end
end

function n_layers(nn::NeuralNetwork)
    return length(nn.n_neurons_per_layers)
end


function fw_prop(nn::NeuralNetwork, x_input)
    N_layers = n_layers(nn)
    y        = x_input
    for layer = 1:(N_layers-1)
        W = nn.weight_matrices.array[layer]
        # u = W * y
        # x = u + nn.biases.array[layer]
        # y = nn.activation_function[layer].(x)
        y = nn.activation_function[layer].( W * y + nn.biases.array[layer] )
    end

    return y
end

function fw_prop(nn::NeuralNetwork, x_input, x_vec)
    N_layers = n_layers(nn)
    y        = x_input
    for layer = 1:(N_layers-1)
        W = nn.weight_matrices.array[layer]
        u = W * y
        x_vec.array[layer] = u + nn.biases.array[layer]
        y = nn.activation_function[layer].(x_vec.array[layer])
    end

    return y
end


function bw_prop(nn::NeuralNetwork, x_vec, delta_e)
    N_layers = n_layers(nn)
    dy = delta_e
    for layer = N_layers:-1:2
        act_fcn = nn.activation_function[layer-1]
        
        Ldy = length(dy)
        ds  = zeros(Ldy)
        for ii = 1:Ldy
            ds[ii] = differentiate(act_fcn, x_vec.array[layer-1][ii])
        end
        dx = dy .* ds
        W  = nn.weight_matrices.array[layer-1]
        dy = W' * dx
    end
    return dy
end

function train2!(nn::NeuralNetwork, sample_container::SC, options::TrainingOptions) where {SC <: AbstractSampleContainer}

    # generals
    N_layers  = n_layers(nn)
    N_samples = n_samples(sample_container)

    # create indices
    sample_indices = collect(1:N_samples)

    # pre allocate containers
    x_vec        = IntermediateVectorResult(nn.n_neurons_per_layers)
    y_vec        = IntermediateVectorResult(nn.n_neurons_per_layers)
    delta_x      = IntermediateVectorResult(nn.n_neurons_per_layers)
    delta_y      = IntermediateVectorResult(nn.n_neurons_per_layers)
    delta_bias   = IntermediateVectorResult(nn.n_neurons_per_layers)
    dactifcn     = IntermediateVectorResult(nn.n_neurons_per_layers)
    delta_w_mat  = WeightMatrix(nn.n_neurons_per_layers)
    delta_e      = zeros(nn.n_neurons_per_layers[end])


    iter = 0
    for outer iter = 1:options.max_iter

        # shuffle the indices
        shuffle!(sample_indices)

        for bb = 1:options.batch_size

            # select the sample index
            sample_index = sample_indices[bb]

            # forward propagate and save the inputs
            (x_meas, y_meas) = get_sample(sample_container, sample_index)

            y = x_meas
            layer = 0
            for outer layer = 1:(N_layers-1)
                W = nn.weight_matrices.array[layer]
                x_vec.array[layer] = W * y + nn.biases.array[layer]
                y_vec.array[layer] = nn.activation_function[layer].(x_vec.array[layer])
                y                  = y_vec.array[layer]
            end

            # evaluate the derivative of the error function
            y_out = y_vec.array[layer]
            gradient!(nn.error_function, y_meas, y_out, delta_e)

            # backward propagate the errors and update the deltas
            delta_y.array[layer] = delta_e
            for layer = (N_layers-1):-1:1
                act_fcn = nn.activation_function[layer]
                
                Ldy = length(x_vec.array[layer])
                for ii = 1:Ldy
                    dactifcn.array[layer][ii] = differentiate(act_fcn, x_vec.array[layer][ii])
                end
                delta_x.array[layer] = delta_y.array[layer] .* dactifcn.array[layer]
                W  = nn.weight_matrices.array[layer]
                if layer >= 2
                    delta_y.array[layer-1] = W' * delta_x.array[layer]
                end
            end

            for layer = 1:N_layers-1
                delta_bias.array[layer]  += delta_x.array[layer]
            end
            delta_w_mat.array[1] += delta_x.array[1] * x_meas'
            for layer = 2:N_layers-1
                delta_w_mat.array[layer] += delta_x.array[layer] * y_vec.array[layer-1]'
            end

        end # batch

        for layer = 1:N_layers-1
            # max norm 
            # options.max_norm
            # n = norm()
            nn.biases.array[layer]          -= options.learning_rate .* delta_bias.array[layer]
            nn.weight_matrices.array[layer] -= options.learning_rate .* delta_w_mat.array[layer]
        end

        zeros!(delta_bias)
        zeros!(delta_w_mat)
        
        
    end # iter

    return nn
end


# function evaluate_container(nn::NeuralNetwork, cv_cont::MatrixVectorSampleContainer)
function evaluate_container(nn::NeuralNetwork, cv_cont)

    N_layers  = n_layers(nn)
    N_samples = n_samples(cv_cont)
    # N_dim     = n_dim(cv_cont)
    y_out     = zeros(nn.n_neurons_per_layers[end], N_samples)

    for kk = 1:N_samples
        (xm, ym) = get_sample(cv_cont, kk)
        y = xm
        for layer = 1:(N_layers-1)
            W = nn.weight_matrices.array[layer]
            y = nn.activation_function[layer].(W * y .+ nn.biases.array[layer])
        end
        y_out[:, kk] = y
    end
    
    return y_out
end


# function evaluate_performance(nn::NeuralNetwork, cv_cont::MatrixVectorSampleContainer)
function evaluate_performance(nn::NeuralNetwork, cv_cont)

    N_layers  = n_layers(nn)
    N_samples = n_samples(cv_cont)
    y_out     = zeros(N_samples)

    for kk = 1:N_samples
        (xm, ym) = get_sample(cv_cont, kk)
        y = xm
        for layer = 1:(N_layers-1)
            W = nn.weight_matrices.array[layer]
            y = nn.activation_function[layer].(W * y .+ nn.biases.array[layer])
        end
        # p = nn.error_function(ym, y[1:nn.n_neurons_per_layers[end]])
        p = nn.error_function(ym, y)
        y_out[kk] = p
    end
    
    return y_out
end



#=
function train!(nn::NeuralNetwork, sample_container::SC, options::TrainingOptions) where {SC <: AbstractSampleContainer}

    # generals
    N_layers  = n_layers(nn)
    N_samples = n_samples(sample_container)

    # create indices
    sample_indices = collect(1:N_samples)

    # pre allocate containers
    x_vec        = IntermediateVectorResult(nn.n_neurons_per_layers)
    y_vec        = IntermediateVectorResult(nn.n_neurons_per_layers)
    delta_x      = IntermediateVectorResult(nn.n_neurons_per_layers)
    delta_y      = IntermediateVectorResult(nn.n_neurons_per_layers)
    delta_bias   = IntermediateVectorResult(nn.n_neurons_per_layers)
    dactifcn     = IntermediateVectorResult(nn.n_neurons_per_layers)
    delta_w_mat  = WeightMatrix(nn.n_neurons_per_layers)
    delta_e      = zeros(nn.n_neurons_per_layers[end])
    
    iter = 0
    for outer iter = 1:options.max_iter

        # shuffle the indices
        shuffle!(sample_indices)

        for bb = 1:options.batch_size

            # select the sample index
            sample_index = sample_indices[bb]

            # forward propagate and save the inputs
            (x_meas, y_meas) = get_sample(sample_container, sample_index)

            y = x_meas
            for layer = 1:(N_layers-2)
                W                    = nn.weight_matrices.array[layer]
                x_vec.array[layer]   = W * y
                x_vec.array[layer] .+= nn.biases.array[layer]
                y_vec.array[layer]   = nn.activation_function.(x_vec.array[layer])
                y                    = y_vec.array[layer]
            end

            # output layer
            layer                = N_layers-1
            W                    = nn.weight_matrices.array[layer]
            x_vec.array[layer]   = W * y_vec.array[layer-1]
            x_vec.array[layer] .+= nn.biases.array[layer]
            y_vec.array[layer]   = nn.output_activation_function.(x_vec.array[layer])

            # evaluate the derivative of the error function
            y_out = y_vec.array[layer]
            gradient!(nn.error_function, y_meas, y_out, delta_e)
            
            # backward propagate the errors and update the deltas
            delta_y.array[layer] = delta_e

            # output layer
            for ii = 1:nn.n_neurons_per_layers[end]
                dactifcn.array[layer][ii] = differentiate(nn.output_activation_function, x_vec.array[layer][ii])
            end
            delta_x.array[layer]      = delta_y.array[layer] .* dactifcn.array[end]
            
            for layer = (N_layers-1):-1:2
                W                      = nn.weight_matrices.array[layer]
                delta_y.array[layer-1] = W' * delta_x.array[layer]
                for ii = 1:nn.n_neurons_per_layers[layer-1]
                    dactifcn.array[layer-1][ii] = differentiate(nn.activation_function, x_vec.array[layer-1][ii])
                end
                delta_x.array[layer-1]    = delta_y.array[layer-1] .* dactifcn.array[layer-1]
                delta_bias.array[layer]  .+= delta_x.array[layer]

                delta_w_mat.array[layer] .+= delta_x.array[layer] * y_vec.array[layer-1]'
            end
            delta_bias.array[1]  .+= delta_x.array[1]
            delta_w_mat.array[1] .+= delta_x.array[1] * x_meas'

        end

        # update the weights
        # b <- b - alpha * delta_x
        # W <- W - alpha * delta_W
        for layer = 1:N_layers-1
            bias        = nn.biases.array[layer]
            bias       .-= 1/options.batch_size .* options.learning_rate .* delta_bias.array[layer]
            weight_mat  = nn.weight_matrices.array[layer]
            weight_mat .-= 1/options.batch_size .* options.learning_rate .* delta_w_mat.array[layer]
        end

        # here could be the performance evaluated

    end

    return (nn, iter)
end
=#

#=
function evaluate(nn::NeuralNetwork, x_input)
    N_layers = n_layers(nn)
    y        = x_input
    for layer = 1:(N_layers-2)
        W = nn.weight_matrices.array[layer]
        y = nn.activation_function.(W * y .+ nn.biases.array[layer])
    end
    # output layer
    layer = N_layers-1
    W     = nn.weight_matrices.array[layer]
    y     = nn.output_activation_function.(W * y .+ nn.biases.array[layer])
    return y
end
=#


end # module