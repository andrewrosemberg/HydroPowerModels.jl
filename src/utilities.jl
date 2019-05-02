import Statistics

"""calculate number of hydrogenerators"""
function countgenerators!(data::Dict)
    data["hydro"]["nHyd"] = size(data["hydro"]["Hydrogenerators"],1)
end

"""compoute upstream_hydro"""
function upstream_hydro!(data::Dict)
    for i in 1:data["hydro"]["nHyd"]
        data["hydro"]["Hydrogenerators"][i]["upstrem_hydros_turn"] = []
        data["hydro"]["Hydrogenerators"][i]["upstrem_hydros_spill"] = []
    end
    for i in 1:data["hydro"]["nHyd"]
        for idx in data["hydro"]["Hydrogenerators"][i]["downstream_turn"]
            j = findall(x->x["index"]==idx,data["hydro"]["Hydrogenerators"])
            if length(j)!=1
                error("Incoherent downstream_turn list")
            end
            j = j[1]
            data["hydro"]["Hydrogenerators"][j]["upstrem_hydros_turn"] = append!(data["hydro"]["Hydrogenerators"][j]["upstrem_hydros_turn"],i)
        end
        for idx in data["hydro"]["Hydrogenerators"][i]["downstream_spill"]
            j = findall(x->x["index"]==idx,data["hydro"]["Hydrogenerators"])
            if length(j)!=1
                error("Incoherent downstream_spill list")
            end
            j = j[1]
            data["hydro"]["Hydrogenerators"][j]["upstrem_hydros_spill"] = append!(data["hydro"]["Hydrogenerators"][j]["upstrem_hydros_spill"],i)
        end        
    end
    for i in 1:data["hydro"]["nHyd"]
        unique!(data["hydro"]["Hydrogenerators"][i]["upstrem_hydros_turn"])
        unique!(data["hydro"]["Hydrogenerators"][i]["upstrem_hydros_spill"])
    end
    return nothing
end

"""create ref for anonimous variables on model"""
function createvarrefs!(sp::JuMP.Model,pm::GenericPowerModel)
    for listvarref in values(var(pm,pm.cnw,pm.ccnd))
        for variableref in values(listvarref)
            if typeof(variableref) == JuMP.VariableRef
                sp[Symbol(name(variableref))] = variableref
            end
        end
    end
end

"""count available inflow data"""
function countavailableinflow!(data::Dict)
    data["hydro"]["size_inflow"] = size(data["hydro"]["Hydrogenerators"][1]["inflow"])
end

"""circular index"""
function cidx(i::Int,n::Int)
    mod(i,n)==0 ? n : mod(i,n)
end

"""hydrogenerators indexes"""
function idx_hydro(data::Dict)
    [hydro["i_grid"] for hydro in data["hydro"]["Hydrogenerators"] if hydro["index_grid"] != nothing]
end

"""find vector index of hydrogenerators on grid"""
function index2i!(data::Dict)
    for i=1:data["hydro"]["nHyd"]
        if data["hydro"]["Hydrogenerators"][i]["index_grid"] != nothing
            i_grid = findall(x->x["index"] == data["hydro"]["Hydrogenerators"][i]["index_grid"],data["powersystem"]["gen"])
            if length(i_grid) != 1
                error("Generator of hydro with index $(data["hydro"]["Hydrogenerators"][i]["index"]) not identifiable")
            end
            data["hydro"]["Hydrogenerators"][i]["i_grid"] = parse(Int64,i_grid[1])
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

    return nothing
end

"""Quantile Scenarios"""
function quantile_scen(scen::Array{Float64,2},quant::Float64)
    return quantile_scen(scen,[quant])[:,1]
end

"""Quantile Scenarios"""
function quantile_scen(scen::Array{Float64,2},quants::Array{Float64};output_dict::Bool=false)
    quantiles = [Statistics.quantile(scen[i, :], quant) for i = 1:size(scen, 1),quant in quants]
    if output_dict
        output = Dict()
        for col = 1:length(quants)
            output["$(quant*100)%"] = quantiles[:,col]
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
    for i = 1:size(recursion_ret,1)
        item = recursion_ret[i]
        for (ikw,val) in item
            one_dict[kws[i]*"_"*ikw] = val
        end
    end

    return one_dict

end

"""truncate values dict"""
function signif_dict(one_dict::Dict, digits::Integer)
    for kw in keys(one_dict)
        one_dict[kw] = signif.(one_dict[kw],digits)
    end
    return one_dict
end