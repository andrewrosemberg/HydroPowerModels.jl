"""rainfall noises"""
function rainfall_noises(sp, data::Dict, t::Int)    
        SDDP.parameterize(sp, collect(1:size(data["hydro"]["scenario_probabilities"],2)), data["hydro"]["scenario_probabilities"][cidx(t,data["hydro"]["size_inflow"][1]),:]) do ω
            for i in 1:data["hydro"]["nHyd"]
                JuMP.fix(sp[:inflow][i], data["hydro"]["Hydrogenerators"][i]["inflow"][t,ω]; force=true)
            end        
        end
    return nothing
end

"""creates hydro balance constraint"""
function constraint_hydro_balance(sp, data::Dict, params::Dict)    
    @constraint(sp, hydro_balance[i=1:data["hydro"]["nHyd"]],   sp[:reservoir][i].out == sp[:reservoir][i].in + (sp[:inflow][i] - sp[:outflow][i])*(0.0036*params["stage_hours"]) - sp[:spill][i] + 
                                                    sum(sp[:spill][j] for j in data["hydro"]["Hydrogenerators"][i]["upstrem_hydros_spill"]) +
                                                    sum(sp[:outflow][j] for j in data["hydro"]["Hydrogenerators"][i]["upstrem_hydros_turn"])*(0.0036*params["stage_hours"])
    )
    return nothing
end

"""creates energy constraints which bind the discharge with the active energy injected to the grid"""
function constraint_hydro_generation(sp, data::Dict, pm::GenericPowerModel)
    @constraint(sp, turbine_energy[i=1:data["hydro"]["nHyd"]; data["hydro"]["Hydrogenerators"][i]["index_grid"] != nothing], var(pm, 0, 1, :pg)[data["hydro"]["Hydrogenerators"][i]["i_grid"]]*data["powersystem"]["baseMVA"] == sp[:outflow][i]*data["hydro"]["Hydrogenerators"][i]["production_factor"]
    )
    return nothing
end

"""add deficit variables"""
function constraint_mod_deficit(sp, data::Dict, pm::GenericPowerModel)
    for i=1:length(con(pm, 0, 1, :kcl_p))
        set_coefficient(con(pm, 0, 1, :kcl_p)[i], sp[:deficit][i], -1)
    end
end