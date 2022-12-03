


module NumberTheo



function gcd(a::T, b::T) where {T <: Integer}
    a, b = (a < b) ? (b, a) : (a, b)
    while b != 0
        c = b
        d = mod(a, b)
        a = c
        b = d
    end
    return a
end

function lcm(a, b)
    (a, b) = (a < b) ? (a, b) : (b, a)
    d = gcd(b, a)
    return div(b, d) * a
end

function sieve_of_eratosthenes(n)
    a = trues(n)
    max_n = ceil(Int, sqrt(Float64(n)))

    for ii = 2:max_n
        if a[ii]
            jj = ii^2
            while jj <= n
                a[jj] = false
                jj += ii
            end
        end
    end
    a[1] = false # for 1
    pr = findall(a)
    return pr
end



end


#=
module ntest
using ..number

a = 30 # 2 * 3 * 5
b = 21 # 3 * 7

d = number.gcd(a, b) # 3
l = number.lcm(a, b) # 7 * 2 * 5 * 3


a = 28 # 2*2 * 7
b = 21 # 3 * 7

d = number.gcd(a, b) # 3
l = number.lcm(a, b) # 2 * 2 * 3 * 7


pr = number.sieve_of_eratosthenes(1000)


end
=#

