
mutable struct OdeResult
    t::Stack{Float64}
    q::MatrixStack{Float64}

    function OdeResult(x::Vector, start_size::Int = 16)
        L = length(x)
        t = datastructs.Stack{Float64}(start_size);
        q = datastructs.MatrixStack{Float64}(L, start_size);
        
        return new(t, q)
    end
end

function n_dim(ode_res::OdeResult)
    return size(ode_res.q.data, 1)
end

function Base.length(ode_res::OdeResult)
    return Base.length(ode_res.t)
end

function init_ode_result(x)
    return OdeResult(x)
end

function Base.push!(ode_res::OdeResult, t, q)
    push!(ode_res.t, t)
    push!(ode_res.q, q)
end

function time(ode_res::OdeResult)
    v = view(ode_res.t.data, 1:ode_res.t.ptr)
    return v
end

function variables(ode_res::OdeResult)
    v = view(ode_res.q.data, 1:size(ode_res.q.data, 1), 1:ode_res.t.ptr)
    return v
end

function shrink_to_fit!(ode_res::OdeResult)
    datastructs.shrink_to_fit!(ode_res.t)
    datastructs.shrink_to_fit!(ode_res.q)
    return ode_res
end


struct VariableIndex
    name::Symbol
    index::Int
end


function plot(ode_res::OdeResult; max_var = 5)

    n_vars = n_dim(ode_res)
    n_max_var = min(max_var, n_vars)

    figh = PyPlot.figure()
    ax1 = PyPlot.subplot(n_max_var, 1, 1)
    PyPlot.plot( ode_res.t.data, ode_res.q.data[1, :] )
    PyPlot.grid()

    for ii = 2:n_max_var
        PyPlot.subplot(n_max_var, 1, ii, sharex = ax1)
        PyPlot.plot( ode_res.t.data, ode_res.q.data[ii, :] )
        PyPlot.grid()
    end

    return figh

end