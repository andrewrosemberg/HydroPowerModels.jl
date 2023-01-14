
# This file includes modified source code from https://github.com/odow/SDDP.jl
# as at d90faae19c90f1fa03636ebe1cee92b083c355c2

#  Copyright 2017, Oscar Dowson and contributors
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at http://mozilla.org/MPL/2.0/.
#############################################################################

"""simulate function"""
function simulate(
    hydromodel::HydroPowerModel,
    number_replications::Int=1;
    sampling_scheme=SDDP.InSampleMonteCarlo(;
        max_depth=hydromodel.params["stages"], terminate_on_dummy_leaf=false
    ),
    kwargs...,
)
    solution = Dict{Symbol,Any}()

    start_time = time()
    solution[:simulations] = SDDP.simulate(
        hydromodel.policygraph,
        number_replications;
        sampling_scheme=sampling_scheme,
        custom_recorders=Dict{Symbol,Function}(
            :powersystem => build_sol_powermodels,
            :reservoirs => build_sol_reservoirs,
            :objective => objective_value,
        ),
    )
    solution[:solve_time] = end_time = time() - start_time

    solution[:params] = hydromodel.params
    solution[:machine] = Dict(
        :cpu => Sys.cpu_info()[1].model, :memory => string(Sys.total_memory() / 2^30, " Gb")
    )

    # add original data dict
    solution[:data] = hydromodel.alldata

    return solution
end

"""PowerModels solution build"""
function build_sol_powermodels(sp::JuMP.Model)
    solve_time = 0.0
    try
        solve_time = MOI.get(sp, MOI.SolveTimeSec())
    catch
        solve_time = 0.0
    end
    status = JuMP.termination_status(sp)
    return built_sol = PowerModels._IM.build_result(
        sp.ext[:pm], solve_time; solution_processors=[get_solution]
    )
end

"""Reservoir solution build"""
function build_sol_reservoirs(sp::JuMP.Model)
    store = Dict{Symbol,Any}(
        :reservoir => JuMP.value.(sp[:reservoir]),
        :outflow => JuMP.value.(sp[:outflow]),
        :spill => JuMP.value.(sp[:spill]),
    )
    return store
end

""
function get_solution(pm::AbstractPowerModel, sol::Dict{String,<:Any})
    # PowerModels.solution_opf!(pm, sol)
    # add_kcl_deficit(sol, pm)
end

""
function add_kcl_deficit(sol, pm::AbstractPowerModel)
    return PowerModels.add_setpoint!(
        sol, pm, "bus", "deficit", :deficit; status_name="bus_type", inactive_status_value=4
    )
end
