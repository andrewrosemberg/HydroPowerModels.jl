"""rainfall noises"""
function rainfall_noises(sp, data::Dict, params::Dict, t::Int)    
        SDDP.parameterize(sp, collect(1:size(data["hydro"]["scenario_probabilities"],2)), data["hydro"]["scenario_probabilities"][cidx(t,data["hydro"]["size_inflow"][1]),:]) do ω
            # if JuMP.MathOptInterface.get(sp,JuMP.MathOptInterface.VariablePrimalStart(), JuMP.all_variables(sp)[end]) == nothing
            #     JuMP.MathOptInterface.set.(sp,JuMP.MathOptInterface.VariablePrimalStart(), JuMP.all_variables(sp), NaN)
            # end
            nostart = findall(x-> x == nothing, JuMP.MathOptInterface.get.(sp,JuMP.MathOptInterface.VariablePrimalStart(), JuMP.all_variables(sp)))
            for theta in nostart
                JuMP.MathOptInterface.set(sp,JuMP.MathOptInterface.VariablePrimalStart(), JuMP.all_variables(sp)[theta], sp.ext[:lower_bound])
            end
            for i in 1:data["hydro"]["nHyd"]
                JuMP.fix(sp[:inflow][i], data["hydro"]["Hydrogenerators"][i]["inflow"][t,ω]*(0.0036*params["stage_hours"]); force=true)
            end        
        end
    return nothing
end

"""creates hydro balance constraint"""
function constraint_hydro_balance(sp, data::Dict, params::Dict)    
    @constraint(sp, hydro_balance[i=1:data["hydro"]["nHyd"]],   sp[:reservoir][i].out == sp[:reservoir][i].in + sp[:inflow][i] - (sp[:outflow][i])*(0.0036*params["stage_hours"]) - sp[:spill][i] + 
                                                    sum(sp[:spill][j] for j in data["hydro"]["Hydrogenerators"][i]["upstrem_hydros_spill"]) +
                                                    sum(sp[:outflow][j] for j in data["hydro"]["Hydrogenerators"][i]["upstrem_hydros_turn"])*(0.0036*params["stage_hours"])
    )
    return nothing
end

"""creates energy constraints which bind the discharge with the active energy injected to the grid"""
function constraint_hydro_generation(sp, data::Dict, pm::AbstractPowerModel)
    @constraint(sp, turbine_energy[i=1:data["hydro"]["nHyd"]; data["hydro"]["Hydrogenerators"][i]["index_grid"] != nothing], PowerModels.var(pm, 0, 1, :pg)[data["hydro"]["Hydrogenerators"][i]["i_grid"]]*data["powersystem"]["baseMVA"] == sp[:outflow][i]*data["hydro"]["Hydrogenerators"][i]["production_factor"]
    )
    return nothing
end

"""add deficit variables"""
function constraint_mod_deficit(sp, data::Dict, pm::AbstractPowerModel)
    for i=1:length(PowerModels.con(pm, 0, 1, :kcl_p))
        set_coefficient(PowerModels.con(pm, 0, 1, :kcl_p)[i], sp[:deficit][i], -1)
    end
    for i=1:length(PowerModels.con(pm, 0, 1, :kcl_q))
        set_coefficient(PowerModels.con(pm, 0, 1, :kcl_q)[i], sp[:deficit_q][i], -1)
    end
end