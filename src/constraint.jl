"rainfall noises"
function rainfall_noises(sp, data::Dict, t::Int)
    for i in 1:data["hydro"]["nHyd"]
        SDDP.parameterize(sp, data["hydro"]["Hydrogenerators"][i]["inflow"][t,:], data["hydro"]["scenario_probabilities"][cidx(t,data["hydro"]["size_inflow"][1]),:]) do ω
            JuMP.fix(sp[:inflow][i], ω; force=true)
        end        
    end
end

"creates hydro balance constraint"
function constraint_hydro_balance(sp, data::Dict)    
    for i in 1:data["hydro"]["nHyd"]
        @constraints(sp, begin
            hydro_balance[i=1:data["hydro"]["nHyd"]], sp[:reservoir][i].out == sp[:reservoir][i].in + sp[:inflow][i] - sp[:outflow][i] - sp[:spill][i] + sum(sp[:outflow][j] + sp[:spill][j] for j in data["hydro"]["Hydrogenerators"][i]["upstrem_hydros"])
        end)
    end
end

"creates energy constraints which bind the discharge with the active energy injected to the grid"
function constraint_hydro_generation(sp, data::Dict, pm::GenericPowerModel)
    @constraints(sp, begin
        turbine_energy[i=1:data["hydro"]["nHyd"]], var(pm, 0, 1, :pg)[data["hydro"]["Hydrogenerators"][i]["index_grid"]]*data["powersystem"]["baseMVA"] == sp[:outflow][i]*data["hydro"]["Hydrogenerators"][i]["production_factor"]
    end)
end