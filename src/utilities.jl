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