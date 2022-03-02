

include("../../../../std/util/src/util_module.jl")

module dtest
using ..util
using ..distributions
using PyPlot
PyPlot.pygui(true)



function test_uniform()

    
    distr = distributions.UniformDistribution(2.0, 3.0)

    n = 1000
    rnb = distributions.random(distr, n)
    # show(rnb) 

    (cdf_x, cdf_y) = distributions.emp_cdf(rnb)
    
    PyPlot.figure()
    PyPlot.grid()
    PyPlot.plot(cdf_x, cdf_y, marker = :o)

    
end


function test_normal()

    
    distr = distributions.NormalDistribution(2.0, 3.0)

    n = 10000
    rnb = distributions.random(distr, n)
    # show(rnb) 

    (cdf_x, cdf_y) = distributions.emp_cdf(rnb)
    
    PyPlot.figure()
    PyPlot.grid()
    PyPlot.plot(cdf_x, cdf_y, marker = :o)

    
end


function test_cauchy()

    
    distr = distributions.CauchyDistribution(2.0, 3.0)

    n = 10000
    rnb = distributions.random(distr, n)
    # show(rnb) 

    (cdf_x, cdf_y) = distributions.emp_cdf(rnb)
    
    PyPlot.figure()
    PyPlot.grid()
    PyPlot.plot(cdf_x, cdf_y, marker = :o)
    
end


function test_pdf_uniform()

    gauss_distr = distributions.NormalDistribution(0.0, 1.0)
    cauchy_distr = distributions.CauchyDistribution(0.0, 1.0)

    x = collect( -3.0:0.1:3.0 )
    yc = distributions.pdf(cauchy_distr, x)
    yg = distributions.pdf(gauss_distr, x)
    

    PyPlot.figure()
    PyPlot.grid()
    PyPlot.plot(x, yc)
    PyPlot.plot(x, yg)

end


function test_histo()

    gauss_distr = distributions.NormalDistribution(0.0, 2.0)
    n_rand = 10000
    rnb = distributions.random(gauss_distr, n_rand)

    edges = [0.0, 1.0, 1.1, 1.2, 1.5, 2.0]
    # (bin_edges, freq, bin_idx) = distributions.histogram(rnb, edges)
    (bin_edges, freq) = distributions.histogram(rnb, 50)

    println( " The sum of freqs: $(sum(freq)) " )

    x_mids = 0.5 * (bin_edges[1:end-1] + bin_edges[2:end])


    x_min = gauss_distr.mu - 5 * gauss_distr.sigma
    x_max = gauss_distr.mu + 5 * gauss_distr.sigma

    pdf_x = collect( range(x_min, x_max, 100) )
    pdf_y = distributions.pdf(gauss_distr, pdf_x)

    
    # PyPlot.figure()
    # PyPlot.plot(pdf_x, pdf_y)

    # PyPlot.figure()
    # PyPlot.plot(x_mids, freq, marker = :o)

    widths = diff(bin_edges)
    PyPlot.figure()
    PyPlot.bar(bin_edges[1:end-1], freq, align=:edge, width = widths) # 


end





function test_rejection_sampling()

    gauss_distr = distributions.NormalDistribution(0.0, 1.0)
    gauss_distr2 = distributions.NormalDistribution(5.0, 2.0)
    
    pdf_fcn(x) = 0.5*(
        1 * distributions.pdf(gauss_distr2, x) + 
        distributions.pdf(distributions.NormalDistribution(3.0, 1.0), x) )

    x_min = -4.0
    x_max = 8.0

    n_rand = 10000
    rnb = distributions.rejection_sampling_1d(pdf_fcn, x_min, x_max, n_rand)
    # rnb = distributions.random(gauss_distr2, n_rand)
    (cdf_x, cdf_y) = distributions.emp_cdf(rnb)



    # rnb_g = distributions.random(gauss_distr, n_rand)
    # (cdf_x_g, cdf_y_g) = distributions.emp_cdf(rnb_g)

    n_discr = 100
    x_vec = collect( range(x_min, x_max, n_discr) )
    y_vec = pdf_fcn.(x_vec)


    # n_bin = max( 10, convert(Int, ceil(sqrt( n_rand ))) )

    sigma = distributions.std(rnb)
    h = distributions.bin_size_scott(sigma, n_rand)

    n_bin = convert(Int, ceil( (x_max - x_min) / h ))

    (bin_edges, freq) = distributions.histogram(rnb, n_bin)
    x_mids = 0.5 .* (bin_edges[1:end-1] .+ bin_edges[2:end])
    pdf_freq = 1 / (bin_edges[2] - bin_edges[1]) * freq[2:end-1] ./ n_rand


    PyPlot.figure()
    PyPlot.grid()
    PyPlot.plot(x_vec, y_vec)

    # PyPlot.plot(cdf_x_g, cdf_y_g)
    PyPlot.plot(cdf_x, cdf_y)
    PyPlot.plot( x_mids, pdf_freq )
    

end


function test_multi_gauss()

    mu = [1.0, 3.0]
    sigma = [0.5 0.8; 0.8 3.0]
    multi_normal = distributions.MultiNormalDistribution(mu, sigma)
    
    x_vec = collect( range(-5., 5, 150) )
    y_vec = collect( range(-5., 11, 150) )
    
    (X, Y) = util.mesh_grid(x_vec, y_vec)

    Lx = length(x_vec)
    Ly = length(y_vec)
    
    pdf_s = zeros( Lx, Ly )
    for ii = 1:Lx
        for jj = 1:Ly
            pdf_s[ii, jj] = distributions.pdf( multi_normal, (x_vec[ii], y_vec[jj]) )
        end
    end

    
    PyPlot.figure()
    PyPlot.grid()
    # PyPlot.surf(X, Y, pdf_s, alpha = 0.7)
    PyPlot.contour(X, Y, pdf_s, levels = [1e-4, 0.001, 0.01, 0.025, 0.05,  0.1, 0.125, 0.16, 0.17])

end


function test_multi_gauss_random()


    mu = [1.0, 3.0]
    sigma = [0.5 0.8; 0.8 3.0]
    multi_normal = distributions.MultiNormalDistribution(mu, sigma)


    n_rand = 1000
    rnb = distributions.random(multi_normal, n_rand)

    n_bin_x = 29
    n_bin_y = 29
    
    (x_bin_edges, y_bin_edges, freq) = distributions.histogram_2d(rnb, n_bin_x, n_bin_y)

    # show(x_bin_edges)
    # show(y_bin_edges)
    # show(freq)
    (X_bin, Y_bin) = util.mesh_grid(x_bin_edges[1:end-1], y_bin_edges[1:end-1])


    x_vec = collect( range(-5., 5, 150) )
    y_vec = collect( range(-5., 11, 150) )
    
    (X, Y) = util.mesh_grid(x_vec, y_vec)

    Lx = length(x_vec)
    Ly = length(y_vec)
    
    pdf_s = zeros( Lx, Ly )
    for ii = 1:Lx
        for jj = 1:Ly
            pdf_s[ii, jj] = distributions.pdf( multi_normal, (x_vec[ii], y_vec[jj]) )
        end
    end

    
    PyPlot.figure()
    PyPlot.grid()
    PyPlot.contour(X, Y, pdf_s, levels = [1e-4, 0.001, 0.01, 0.025, 0.05,  0.1, 0.125, 0.16, 0.17])
    PyPlot.plot( rnb[1, :], rnb[2, :], linestyle = :none, marker = :., markersize = 10 )



    width = x_bin_edges[2] - x_bin_edges[1]
    depth = y_bin_edges[2] - y_bin_edges[1]
    height = freq[:]


    xxx = X_bin[:]
    yyy = Y_bin[:]
    zzz = similar(xxx) .* 0

    PyPlot.bar3d( xxx, yyy, zzz, width, depth, height)
        
end




function test_rejection_sampling_2d()

    multi_gauss = distributions.MultiNormalDistribution( [1.0, 3.0], [0.5 0.0; 0.0 1.0] )
    pdf_fcn(x) = distributions.pdf(multi_gauss, x)


    factor = 5.0
    x_min = multi_gauss.mu[1] - factor * multi_gauss.sigma[1,1]
    x_max = multi_gauss.mu[1] + factor * multi_gauss.sigma[1,1]
    
    y_min = multi_gauss.mu[2] - factor * multi_gauss.sigma[2,2]
    y_max = multi_gauss.mu[2] + factor * multi_gauss.sigma[2,2]


    
    x_vec = collect( range(x_min, x_max, 50) )
    y_vec = collect( range(y_min, y_max, 50) )
    (X, Y) = util.mesh_grid(x_vec, y_vec)

    Lx = length(x_vec)
    Ly = length(y_vec)
    
    pdf_s = zeros( Lx, Ly )
    for ii = 1:Lx
        for jj = 1:Ly
            pdf_s[ii, jj] = distributions.pdf( multi_gauss, (x_vec[ii], y_vec[jj]) )
        end
    end

    n_rand = 100

    (x_rnb, y_rnb) = distributions.rejection_sampling_2d(pdf_fcn, x_min, x_max, y_min, y_max, n_rand)


    PyPlot.figure()
    PyPlot.contour(X, Y, pdf_s, levels = [1e-4, 0.001, 0.01, 0.025, 0.05,  0.1, 0.125, 0.16, 0.17])
    PyPlot.plot( x_rnb, y_rnb , linestyle = :none, marker = :., markersize = 10)
    

end



end # dtest

