
mutable struct OdeStat
    rejected_steps::Int
	current_rejected_steps::Int
	longest_rejected_streak::Int
    accepted_steps::Int
    iter::Int

    function OdeStat()
        rejected_steps          = 0
        current_rejected_steps  = 0
        longest_rejected_streak = 0
        accepted_steps          = 0
        iter                    = 0

        return new(
            rejected_steps,
            current_rejected_steps, 
            longest_rejected_streak,
            accepted_steps,
            iter)
    end
end

function increase_rejected!(ode_stat::OdeStat)
    ode_stat.rejected_steps         += 1
    ode_stat.current_rejected_steps += 1
    ode_stat.iter                   += 1
end

function increase_accepted!(ode_stat::OdeStat)
    ode_stat.accepted_steps += 1
    ode_stat.iter           += 1
end

function reset_rejected!(ode_stat::OdeStat)
    t = max( ode_stat.current_rejected_steps, ode_stat.longest_rejected_streak )
    ode_stat.longest_rejected_streak = t
    ode_stat.current_rejected_steps  = 0
end

function Base.show(io::IO, ode_stat::OdeStat)
    println("Ode Statistics with properties:")
    println("         rejected_steps: $(ode_stat.rejected_steps)")
    println(" current_rejected_steps: $(ode_stat.current_rejected_steps)")
    println("longest_rejected_streak: $(ode_stat.longest_rejected_streak)")
    println("         accepted_steps: $(ode_stat.accepted_steps)")
    println("                   iter: $(ode_stat.iter)")
    println("")
end
