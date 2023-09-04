"""creates outflow variables specified in data"""
function variable_inflow(sp, data::Dict)
    @variables(
        sp,
        begin
            inflow[r=1:data["hydro"]["nHyd"]]
        end
    )
end

"""creates outflow variables specified in data"""
function variable_outflow(sp, data::Dict)
    @variables(
        sp,
        begin
            0 <=
            outflow[r=1:data["hydro"]["nHyd"]] <=
            data["hydro"]["Hydrogenerators"][r]["max_turn"]
        end
    )
end

"""creates the minimal outflow violation variables specified in data"""
function variable_min_outflow_violation(sp, data::Dict)
    @variables(
        sp,
        begin
            min_outflow_violation[r=1:data["hydro"]["nHyd"]] >= 0 
        end
    )
end

"""creates spillage variables specified in data"""
function variable_spillage(sp, data::Dict)
    @variables(
        sp,
        begin
            spill[r=1:data["hydro"]["nHyd"]] >= 0
        end
    )
end

"""creates volume variables specified in data"""
function variable_volume(sp, data::Dict)
    @variable(
        sp,
        0 <=
            reservoir[r=1:data["hydro"]["nHyd"]] <=
            data["hydro"]["Hydrogenerators"][r]["max_volume"],
        SDDP.State,
        initial_value = data["hydro"]["Hydrogenerators"][r]["initial_volume"]
    )
end

"""creates the minimal volume violation variables specified in data"""
function variable_min_volume_violation(sp, data::Dict)
    @variables(
        sp,
        begin
            min_volume_violation[r=1:data["hydro"]["nHyd"]] >= 0
        end
    )
end

"""creates deficit variables"""
function variable_deficit(sp, _::Dict, pm::AbstractPowerModel)
    PowerModels.var(pm)[:deficit] = @variable(
        sp, deficit[i in collect(1:length(PowerModels.sol(pm, 0, :bus)))] >= 0
    )
    return sol_component_value(
        pm, 0, :bus, :deficit, ids(pm, 0, :bus), PowerModels.var(pm)[:deficit]
    )
end

"""creates dict of cost variables"""
function variable_cost(sp, _::Dict)
    cost = Dict()
    return sp.ext[:cost] = cost
end
