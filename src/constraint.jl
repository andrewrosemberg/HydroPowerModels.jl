"""rainfall noises"""
function rainfall_noises(sp, data::Dict, _::Dict, t::Int)
    SDDP.parameterize(
        sp,
        collect(1:size(data["hydro"]["scenario_probabilities"], 2)),
        data["hydro"]["scenario_probabilities"][cidx(t, data["hydro"]["size_inflow"][1]),:],
    ) do ω
        # if isnothing(JuMP.MOI.get(sp,JuMP.MOI.VariablePrimalStart(), JuMP.all_variables(sp)[end]))
        #     JuMP.MOI.set.(sp,JuMP.MOI.VariablePrimalStart(), JuMP.all_variables(sp), NaN)
        # end
        nostart = findall(
            x -> isnothing(x),
            JuMP.MOI.get.(
                sp, JuMP.MOI.VariablePrimalStart(), JuMP.all_variables(sp)
            ),
        )
        for theta in nostart
            JuMP.MOI.set(
                sp,
                JuMP.MOI.VariablePrimalStart(),
                JuMP.all_variables(sp)[theta],
                sp.ext[:lower_bound],
            )
        end
        for i in 1:data["hydro"]["nHyd"]
            JuMP.fix(
                sp[:inflow][i],
                data["hydro"]["Hydrogenerators"][i]["inflow"][t, ω];
                force=true,
            )
        end
    end
    return nothing
end

"""creates hydro balance constraint"""
function constraint_hydro_balance(sp, data::Dict, params::Dict)
    k = 0.0036 # conversion factor from m3/s to hm3   
    @constraint(
        sp,
        hydro_balance[i=1:data["hydro"]["nHyd"]],
        sp[:reservoir][i].out ==
            sp[:reservoir][i].in +
        (sp[:inflow][i] - sp[:outflow][i]) * (k * params["stage_hours"]) - sp[:spill][i] +
        sum(
            sp[:spill][j] for
            j in data["hydro"]["Hydrogenerators"][i]["upstrem_hydros_spill"]
        ) +
        sum(
            sp[:outflow][j] for
            j in data["hydro"]["Hydrogenerators"][i]["upstrem_hydros_turn"]
        ) * (k * params["stage_hours"])
    )
    return nothing
end

"""creates energy constraints which bind the discharge with the active energy injected to the grid"""
function constraint_hydro_generation(sp, data::Dict, pm::AbstractPowerModel)
    @constraint(
        sp,
        turbine_energy[
            i=1:data["hydro"]["nHyd"];
            !isnothing(data["hydro"]["Hydrogenerators"][i]["index_grid"])
        ],
        PowerModels.var(pm, :pg)[data["hydro"]["Hydrogenerators"][i]["i_grid"]] *
        data["powersystem"]["baseMVA"] ==
            sp[:outflow][i] * data["hydro"]["Hydrogenerators"][i]["production_factor"]
    )
    return nothing
end

"""add deficit variables"""
function constraint_mod_deficit(sp, _::Dict, pm::AbstractPowerModel)
    for i in 1:length(PowerModels.sol(pm, 0, :bus))
        set_normalized_coefficient(
            PowerModels.sol(pm, 0, :bus)[i][:lam_kcl_r], sp[:deficit][i], -1
        )
    end
    return nothing
end

"""creates the constraint that imposes the violation for unilateral violation for outflow"""
function constraint_min_outflow_violation(sp, data::Dict)
    @constraint(
        sp,
        min_outflow_violation_bound[
            r=1:data["hydro"]["nHyd"]
        ],
        sp[:min_outflow_violation][r] >= (data["hydro"]["Hydrogenerators"][r]["min_turn"] - sp[:outflow][r])
    )
    return nothing
end

"""creates the constraint that imposes the violation for unilateral violation for volume"""
function constraint_min_volume_violation(sp, data::Dict)
    @constraint(
        sp,
        min_volume_violation_bound[
            r=1:data["hydro"]["nHyd"]
        ],
        sp[:min_volume_violation][r] >= (data["hydro"]["Hydrogenerators"][r]["min_turn"] - sp[:reservoir][r].out)
    )
    return nothing
end
