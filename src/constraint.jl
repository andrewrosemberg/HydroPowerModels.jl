"rainfall noises"
function rainfall_noises(sp, data::Dict, t::Int)
    for i in 1:data["hydro"]["nHyd"]
        if t > 1 # in future stages random inflows
            @rhsnoise(sp, rainfall = data["hydro"]["Hydrogenerators"][i]["inflow"],
            rainfall == sp[:inflow][i])
        
        else # in the first stage deterministic inflow
            @rhsnoise(sp, rainfall = [data["hydro"]["Hydrogenerators"][i]["inflow"][2]],
            rainfall == sp[:inflow][i])
        end
    end
end

"creates hydro balance constraint"
function constraint_hydro_balance(sp, data::Dict)
    for i in 1:data["hydro"]["nHyd"]
        @constraints(sp, begin
            hydro_balance[i=1:data["hydro"]["nHyd"]], sp[:reservoir][i] - (sp[:reservoir0][i] - sp[:outflow][i] - sp[:spill][i]) == sp[:inflow][i]
        end)
    end
end

"creates energy balance constraint"
function constraint_hydro_generation(sp, data::Dict, pm::GenericPowerModel)
    @constraints(sp, begin
        turbine_energy[i=1:data["hydro"]["nHyd"]], var(pm, 0, 1, :pg)[data["hydro"]["Hydrogenerators"][i]["index"]] == sp[:outflow][i]*data["hydro"]["Hydrogenerators"][i]["production_factor"]
    end)
end