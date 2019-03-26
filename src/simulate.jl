
# This file includes modified source code from https://github.com/odow/SDDP.jl
# as at d90faae19c90f1fa03636ebe1cee92b083c355c2

#  Copyright 2017, Oscar Dowson and contributors
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at http://mozilla.org/MPL/2.0/.
#############################################################################

function simulate_model(m::SDDP.PolicyGraph{T}, N::Int; asynchronous::Bool = true) where {T}
    solution = Dict()
    solution["simulations"] = Array{Dict}(undef,N)
    tic()
    if asynchronous
        wp = CachingPool(workers())
        let m = m
            solution["simulations"] .= pmap(wp, (i) -> randomsimulation(m), 1:N)
        end
    else
        solution["simulations"] .= map(i -> randomsimulation(m), 1:N)
    end
    solution["solve_time"] = toc()
    solution["params"] = m.ext[:params]
    solution["machine"] = Dict(
        "cpu" => Sys.cpu_info()[1].model,
        "memory" => string(Sys.total_memory()/2^30, " Gb")
    )

    # add original data dict
    solution["data"] = m.ext[:alldata]
    
    return solution
end

function randomsimulation(m::SDDP.PolicyGraph{T}) where {T}
    store = SDDP.newsolutionstore(Symbol[])
    obj = SDDP.forwardpass!(m, SDDP.Settings(),store)
    store[:objective] = obj
    solution = Dict()
    for (key,value) in  store
        solution[string(key)] = value
    end
    solution = build_solution_single_simulation(m,solution = solution)
    return solution
end
