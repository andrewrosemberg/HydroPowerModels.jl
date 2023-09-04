using Pkg
Pkg.activate(".")
using CSV
include("./parser/julia103/powermodels_dict.jl")
include("./parser/julia103/hydro_dict.jl")

#Params
case = "brasil_4"
case_dir = dirname(@__FILE__)

# Load case data
hydro_pre = CSV.read(joinpath(case_dir, "hydro.csv"))
lines = CSV.read(joinpath(case_dir, "trans.csv"))
thermal_gen = CSV.read(joinpath(case_dir, "thermal.csv"))
demand = CSV.read(joinpath(case_dir, "demand.csv"))

#------------------------------------------------------------
# Parse Data to PowerModels JSON
#------------------------------------------------------------
# prepocess
busName = unique(vcat(lines[:f], lines[:t]))
gen2bus = [findall(x -> x == i, busName)[1] for i in thermal_gen[:bus]]
lines[:f] = [findall(x -> x == i, busName)[1] for i in lines[:f]]
lines[:t] = [findall(x -> x == i, busName)[1] for i in lines[:t]]
demand[:Tr] = fill(0, size(demand, 1))
bus2load = [demand[1, Symbol(bus)] for bus in busName]
# Create Dicts
gen_array = [
    gen_dict(;
        gen_bus=gen2bus[idx],
        pmax=thermal_gen[:max][idx] / 100,
        index=idx,
        cost=[thermal_gen[:cost][idx] * 100, 0],
    ) for idx in 1:size(thermal_gen, 1)
]

bus_array = [
    bus_dict(;
        name=busName[idx], bus_i=idx, bus_type=if idx == 1
            3
        elseif idx in unique(gen2bus)
            2
        else
            1
        end, index=idx
    ) for idx in 1:size(busName, 1)
]

branch_array = [
    branch_dict(;
        br_r=lines[:r][idx],
        rate_a=lines[Symbol(" max")][idx] / 100,
        f_bus=lines[:f][idx],
        t_bus=lines[:t][idx],
        index=idx,
    ) for idx in 1:size(lines, 1)
]

lod_array = [
    load_dict(; load_bus=idx, pd=bus2load[idx] / 100, index=idx) for
    idx in 1:size(bus2load, 1)
]

#------------------------------------------------------------
# Parse Data to Hidro JSON
#------------------------------------------------------------
hydroarray = [
    hydrogenerator_dict(;
        index=idx,
        index_grid=idx + size(thermal_gen, 1),
        max_volume=hydro_pre[:Max_store][idx] * 0.0036,
        min_volume=0,
        max_turn=hydro_pre[:Max_discharge][idx],
        min_turn=0,
        initial_volume=hydro_pre[:Init_store][idx] * 0.0036,
        production_factor=1,
        spill_cost=0,
        minimal_outflow_violation_cost=0,
        minimal_volume_violation_cost=0,
        downstream_turn=Int64[],
        downstream_spill=Int64[],
    ) for idx in 1:size(hydro_pre, 1)
]

# Create Dicts gen
hydrogen_array = [
    gen_dict(;
        gen_bus=[findall(x -> x == i, busName)[1] for i in hydro_pre[:bus]][idx],
        pmax=hydro_pre[:Max_discharge][idx] / 100,
        index=idx + size(thermal_gen, 1),
        cost=[0],
    ) for idx in 1:size(hydro_pre, 1)
]

#------------------------------------------------------------
# Final dicts
#------------------------------------------------------------

# Final Dict PowerModels
pm = powermodels_dict(;
    name=case,
    cost_deficit=2300,
    gen=[gen_array; hydrogen_array],
    bus=bus_array,
    branch=branch_array,
    load=lod_array,
)

# Final Dict Hydro
hm = hydro_dict(; hydrogenarray=hydroarray)

#------------------------------------------------------------
# Save Files
#------------------------------------------------------------

using JSON
pathcase_out = case_dir

open(joinpath(pathcase_out, "PowerModels.json"), "w") do f
    JSON.print(f, pm)
end

open(joinpath(pathcase_out, "hydro.json"), "w") do f
    JSON.print(f, hm)
end
