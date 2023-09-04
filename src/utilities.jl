using Statistics

"""calculate number of hydrogenerators"""
function countgenerators!(data::Dict)
    return data["hydro"]["nHyd"] = size(data["hydro"]["Hydrogenerators"], 1)
end

"""compoute upstream_hydro"""
function upstream_hydro!(data::Dict)
    for i in 1:data["hydro"]["nHyd"]
        data["hydro"]["Hydrogenerators"][i]["upstrem_hydros_turn"] = []
        data["hydro"]["Hydrogenerators"][i]["upstrem_hydros_spill"] = []
    end
    for i in 1:data["hydro"]["nHyd"]
        for idx in data["hydro"]["Hydrogenerators"][i]["downstream_turn"]
            j = findall(x -> x["index"] == idx, data["hydro"]["Hydrogenerators"])
            if length(j) != 1
                error("Incoherent downstream_turn list")
            end
            j = j[1]
            data["hydro"]["Hydrogenerators"][j]["upstrem_hydros_turn"] = append!(
                data["hydro"]["Hydrogenerators"][j]["upstrem_hydros_turn"], i
            )
        end
        for idx in data["hydro"]["Hydrogenerators"][i]["downstream_spill"]
            j = findall(x -> x["index"] == idx, data["hydro"]["Hydrogenerators"])
            if length(j) != 1
                error("Incoherent downstream_spill list")
            end
            j = j[1]
            data["hydro"]["Hydrogenerators"][j]["upstrem_hydros_spill"] = append!(
                data["hydro"]["Hydrogenerators"][j]["upstrem_hydros_spill"], i
            )
        end
    end
    for i in 1:data["hydro"]["nHyd"]
        unique!(data["hydro"]["Hydrogenerators"][i]["upstrem_hydros_turn"])
        unique!(data["hydro"]["Hydrogenerators"][i]["upstrem_hydros_spill"])
    end
    return nothing
end

"""create ref for anonimous variables on model"""
function createvarrefs!(sp::JuMP.Model, pm::AbstractPowerModel)
    for listvarref in values(PowerModels.var(pm))
        for variableref in values(listvarref)
            if typeof(variableref) == JuMP.VariableRef
                sp[Symbol(name(variableref))] = variableref
            end
        end
    end
end

"""count available inflow data"""
function countavailableinflow!(data::Dict)
    return data["hydro"]["size_inflow"] = size(
        data["hydro"]["Hydrogenerators"][1]["inflow"]
    )
end

"""circular index"""
function cidx(i::Int, n::Int)
    return mod(i, n) == 0 ? n : mod(i, n)
end

"""hydrogenerators indexes"""
function idx_hydro(data::Dict)
    return [
        hydro["i_grid"] for
        hydro in data["hydro"]["Hydrogenerators"] if !isnothing(hydro["index_grid"])
    ]
end

"""find vector index of hydrogenerators on grid"""
function index2i!(data::Dict)
    for i in 1:data["hydro"]["nHyd"]
        if !isnothing(data["hydro"]["Hydrogenerators"][i]["index_grid"])
            i_grid = findall(
                x -> x["index"] == data["hydro"]["Hydrogenerators"][i]["index_grid"],
                data["powersystem"]["gen"],
            )
            if length(i_grid) != 1
                error(
                    "Generator of hydro with index $(data["hydro"]["Hydrogenerators"][i]["index"]) not identifiable",
                )
            end
            data["hydro"]["Hydrogenerators"][i]["i_grid"] = parse(Int64, i_grid[1])
        end
    end
    return nothing
end

"""gather useful information from data"""
function gatherusefulinfo!(data::Dict)
    # calculate number of hydrogenerators
    countgenerators!(data)

    # compoute upstream_hydro
    upstream_hydro!(data)

    # count available inflow data
    countavailableinflow!(data)

    # find index hydrogen
    index2i!(data)

    # add zeroed loads on buses w no loads for deficit coherence
    add_loads!(data)

    return nothing
end

"""Quantile Scenarios"""
function quantile_scen(scen::Array{Float64,2}, quant::Float64)
    return quantile_scen(scen, [quant])[:, 1]
end

"""Quantile Scenarios"""
function quantile_scen(
    scen::Array{Float64,2}, quants::Array{Float64}; output_dict::Bool=false
)
    quantiles = [
        Statistics.quantile(scen[i, :], quant) for i in 1:size(scen, 1), quant in quants
    ]
    if output_dict
        output = Dict()
        for col in 1:length(quants)
            quant = quants[col]
            output["$(quant*100)%"] = quantiles[:, col]
        end
        return output
    end

    return quantiles
end

"""Multilayer Dict to Onelayer Dict"""
function flat_dict(mlt_dict::Dict{Any,Any})
    if typeof(collect(values(mlt_dict))[1]) != Dict{Any,Any}
        return mlt_dict
    end

    one_dict = Dict()
    kws = collect(keys(mlt_dict))

    recursion_ret = [flat_dict(i) for i in values(mlt_dict)]
    for i in 1:size(recursion_ret, 1)
        item = recursion_ret[i]
        for (ikw, val) in item
            one_dict[kws[i] * "_" * ikw] = val
        end
    end

    return one_dict
end

"""truncate values dict"""
function signif_dict(one_dict::Dict, digts::Integer)
    for kw in keys(one_dict)
        if typeof(one_dict[kw]) <: AbstractFloat
            one_dict[kw] = round.(one_dict[kw], digits=digts)
        end
    end
    return one_dict
end

"""add zeroed loads on buses w no loads for deficit coherence"""
function add_loads!(data::Dict)
    locked_buses = unique([
        load["load_bus"] for load in values(data["powersystem"]["load"])
    ])
    free_buses = setdiff(collect(1:length(data["powersystem"]["bus"])), locked_buses)

    load_idx = length(data["powersystem"]["load"]) + 1
    for bus in free_buses
        data["powersystem"]["load"]["$load_idx"] = load_dict(;
            load_bus=bus, pd=0, index=load_idx
        )
        load_idx += 1
    end
end

""" creates a load dictionary """
function load_dict(;
    load_bus=1, # bus where load is present
    status=1, # status (ON: 1, OFF:0)
    pd=1, # reactive power demand
    qd=0.12 * pd, # real power demand
    index=1,
) # index
    return lod = Dict(
        "load_bus" => load_bus, "status" => status, "qd" => qd, "pd" => pd, "index" => index
    )
end

""" water value """
function water_energy!(data::Dict)
    countgenerators!(data)
    for i in 1:data["hydro"]["nHyd"]
        if !haskey(data["hydro"]["Hydrogenerators"][i], "water_energy")
            water_energy_res!(data, i)
        end
    end
    return nothing
end

""" water value """
function water_energy_res!(data::Dict, res::Int)
    data["hydro"]["Hydrogenerators"][res]["water_energy"] = 0.0
    water_val_turn = data["hydro"]["Hydrogenerators"][res]["production_factor"]
    for idx in data["hydro"]["Hydrogenerators"][res]["downstream_turn"]
        j = findall(x -> x["index"] == idx, data["hydro"]["Hydrogenerators"])
        if length(j) != 1
            error("Incoherent downstream_turn list")
        end
        j = j[1]
        water_val_turn += water_energy_res!(data, j)
    end
    water_val_spill = 0.0
    for idx in data["hydro"]["Hydrogenerators"][res]["downstream_spill"]
        j = findall(x -> x["index"] == idx, data["hydro"]["Hydrogenerators"])
        if length(j) != 1
            error("Incoherent downstream_spill list")
        end
        j = j[1]
        water_val_spill += water_energy_res!(data, j)
    end

    data["hydro"]["Hydrogenerators"][res]["water_energy"] +=
        water_val_turn >= water_val_spill ? water_val_turn : water_val_spill

    return data["hydro"]["Hydrogenerators"][res]["water_energy"]
end
