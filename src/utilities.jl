"""calculate number of hydrogenerators"""
function countgenerators!(data::Dict)
    data["hydro"]["nHyd"] = size(data["hydro"]["Hydrogenerators"],1)
end

"""compoute upstream_hydro"""
function upstream_hydro!(data::Dict)
    for i in 1:data["hydro"]["nHyd"]
        data["hydro"]["Hydrogenerators"][i]["upstrem_hydros"] = []
    end
    for i in 1:data["hydro"]["nHyd"]
        for idx in data["hydro"]["Hydrogenerators"][i]["dowstream_turn"]
            j = findall(x->x["index"]==idx,data["hydro"]["Hydrogenerators"])
            if length(j)!=1
                error("Incoherent dowstream_turn list")
            end
            j = j[1]
            data["hydro"]["Hydrogenerators"][j]["upstrem_hydros"] = append!(data["hydro"]["Hydrogenerators"][j]["upstrem_hydros"],i)
        end
        for idx in data["hydro"]["Hydrogenerators"][i]["dowstream_spill"]
            j = findall(x->x["index"]==idx,data["hydro"]["Hydrogenerators"])
            if length(j)!=1
                error("Incoherent dowstream_spill list")
            end
            j = j[1]
            data["hydro"]["Hydrogenerators"][j]["upstrem_hydros"] = append!(data["hydro"]["Hydrogenerators"][j]["upstrem_hydros"],i)
        end        
    end
    for i in 1:data["hydro"]["nHyd"]
        unique!(data["hydro"]["Hydrogenerators"][i]["upstrem_hydros"])
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
    [hydro["index_grid"] for hydro in data["hydro"]["Hydrogenerators"]]
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