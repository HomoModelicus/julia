




include("../src/neuro_module.jl")

module ntest
using ..neuro
using PyPlot
PyPlot.pygui(true)
using Random
Random.seed!(10)

function meshgrid(x, y)
    Lx = length(x)
    Ly = length(y)
    T = Float64
    
    xm = Matrix{T}(undef, Lx, Ly)
    ym = Matrix{T}(undef, Lx, Ly)
    
    for jj = 1:Ly
        xm[:, jj] = x
    end

    for ii = 1:Lx
        ym[ii, :] = y
    end

    return (xm, ym)
end

function true_fcn(x)
    # y = 0.5 * x[1] + 2.0 * x[2]
    a = 1.0
    b = 0.1
    y = (a - x[1])^2 + b * (x[2] - x[1]^2)^2
    return y
end

function true_fcn_v2(x)
    # y = 0.5 * x[1] + 2.0 * x[2]
    a = 1.0
    b = 0.1
    y1 = (a - x[1])^2 + b * (x[2] - x[1]^2)^2
    y2 = (a - x[1])^2
    return [y1, y2]
end


function create_sample_container()
    x1 = collect( range(-3.0, 4.0; length = 55) )
    x2 = collect( range(-2.0, 2.0; length = 85) )
    (xm, ym) = meshgrid(x1, x2)

    xv = vec(xm)
    yv = vec(ym)

    xx = [xv'; yv']
    yy = vec( mapslices(true_fcn, xx, dims = 1) )
    sample_cont = neuro.MatrixVectorSampleContainer(xx, yy)

    return sample_cont
end

function create_sample_container_v2()
    x1 = collect( range(-3.0, 4.0; length = 55) )
    x2 = collect( range(-2.0, 2.0; length = 55) )
    (xm, ym) = meshgrid(x1, x2)

    xv = vec(xm)
    yv = vec(ym)

    xx = [xv'; yv']
    yy = mapslices(true_fcn_v2, xx, dims = 1)
    sample_cont = neuro.MatrixMatrixSampleContainer(xx, yy)

    return sample_cont
end


#=
n_neurons_per_layers = [2, 30, 30, 1]
act_fcn              = [neuro.TanhActivationFunction(), neuro.TanhActivationFunction(), neuro.IdentityActivationFunction()]
=#

#=
n_neurons_per_layers = [2, 30, 30, 30, 1]
act_fcn              = [
    neuro.TanhActivationFunction(),
    neuro.TanhActivationFunction(),
    neuro.TanhActivationFunction(),
    neuro.IdentityActivationFunction()]
=#

#=
n_neurons_per_layers = [2, 30, 1]
act_fcn              = [
    neuro.TanhActivationFunction(),
    neuro.IdentityActivationFunction()]
=#


n_neurons_per_layers = [2, 10, 2]
act_fcn              = [
    neuro.TanhActivationFunction(),
    neuro.IdentityActivationFunction()]
    
nn                   = neuro.NeuralNetwork(n_neurons_per_layers, act_fcn)

#=
wm1 = ones(n_neurons_per_layers[2], n_neurons_per_layers[1])
wm2 = ones(n_neurons_per_layers[3], n_neurons_per_layers[2])

b1 = -ones(n_neurons_per_layers[2])
b2 = -ones(n_neurons_per_layers[3])

neuro.copy_in_bias!(nn, b1, 1)
neuro.copy_in_bias!(nn, b2, 2)

neuro.copy_in_weight_matrix!(nn, wm1, 1)
neuro.copy_in_weight_matrix!(nn, wm2, 2)
=#


sample_cont = create_sample_container_v2()

N_sample = length(sample_cont)
p_cv     = 0.8
N        = round(Int, p_cv * N_sample)
neuro.shuffle!(sample_cont)
(sample_cont_cut, cv_cont) = neuro.split(sample_cont, N)

training_options = neuro.TrainingOptions(
    learning_rate = 0.001,
    batch_size    = 30,
    max_iter      = 10_000)

# (nn, iter) = neuro.train!(nn, sample_cont, training_options)


nn = neuro.train2!(nn, sample_cont_cut, training_options)

# perf     = neuro.evaluate_performance(nn, cv_cont)
perf     = neuro.evaluate_performance(nn, sample_cont)
perfstat = neuro.PerformanceStat(perf)

# y_out = neuro.evaluate_container(nn, cv_cont)
y_out = neuro.evaluate_container(nn, sample_cont)


#=
PyPlot.figure()
PyPlot.surf(sample_cont.x[1,:], sample_cont.x[2,:], sample_cont.y, alpha = 0.5)
PyPlot.plot3D(cv_cont.x[1,:], cv_cont.x[2,:], y_out[1,:], marker = :., markersize = 10, linestyle = :none)
=#

PyPlot.figure()
PyPlot.surf(sample_cont.x[1,:], sample_cont.x[2,:], sample_cont.y[1,:], alpha = 0.5)
# PyPlot.plot3D(cv_cont.x[1,:], cv_cont.x[2,:], y_out[1,:], marker = :., markersize = 10, linestyle = :none)
PyPlot.plot3D(sample_cont.x[1,:], sample_cont.x[2,:], y_out[1,:], marker = :., markersize = 10, linestyle = :none)


PyPlot.figure()
PyPlot.surf(sample_cont.x[1,:], sample_cont.x[2,:], sample_cont.y[2,:], alpha = 0.5)
# PyPlot.plot3D(cv_cont.x[1,:], cv_cont.x[2,:], y_out[2,:], marker = :., markersize = 10, linestyle = :none)
PyPlot.plot3D(sample_cont.x[1,:], sample_cont.x[2,:], y_out[2,:], marker = :., markersize = 10, linestyle = :none)



end # module



