"calculate number of hydrogenerators"
function countgenerators!(data::Dict)
    data["hydro"]["nHyd"] = size(data["hydro"]["Hydrogenerators"],1)
end

"compoute upstream_hydro"
function upstream_hydro!(data::Dict)
    for i in 1:data["hydro"]["nHyd"]
        data["hydro"]["Hydrogenerators"][i]["upstrem_hydros"] = []
    end
    for i in 1:data["hydro"]["nHyd"]
        for j in data["hydro"]["Hydrogenerators"][i]["dowstream_turn"]
            if (j > data["hydro"]["nHyd"] || j <= 0)
                error("Incoherent dowstream_turn list")
            end
            data["hydro"]["Hydrogenerators"][j]["upstrem_hydros"] = append!(data["hydro"]["Hydrogenerators"][j]["upstrem_hydros"],j)
        end
        for j in data["hydro"]["Hydrogenerators"][i]["dowstream_spill"]
            if (j > data["hydro"]["nHyd"] || j <= 0)
                error("Incoherent dowstream_spill list")
            end
            data["hydro"]["Hydrogenerators"][j]["upstrem_hydros"] = append!(data["hydro"]["Hydrogenerators"][j]["upstrem_hydros"],j)
        end
    end
end

"create ref for anonimous variables on model"
function createvarrefs(sp::JuMP.Model,pm::GenericPowerModel)
    for listvarref in values(var(pm,pm.cnw,pm.ccnd))
        if typeof(listvarref) == Dict{Any,Any}
            for variableref in values(listvarref)
                if typeof(variableref) == JuMP.Variable
                    sp[Symbol(getname(variableref))] = variableref
                end
            end
        else
            sp[Symbol(getname(listvarref))] = listvarref
        end
    end
end

"count available inflow data"
function countavailableinflow!(data::Dict)
    data["hydro"]["size_inflow"] = size(data["hydro"]["Hydrogenerators"][1]["inflow"])
end

"circular index"
function cidx(i::Int,n::Int)
    mod(i,n)==0 ? n : mod(i,n)
end

"hydrogenerators indexes"
function idx_hydro(data::Dict)
    [hydro["index_grid"] for hydro in data["hydro"]["Hydrogenerators"]]
end