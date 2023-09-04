"""set objective"""
function set_objective(sp, _::Dict)
    @stageobjective(sp, sum(values(sp.ext[:cost])))
end

"""add generators cost to cost dict"""
function add_gen_cost(sp, _::Dict)
    return sp.ext[:cost][:gen_cost] = objective_function(sp)
end

"""add spillage cost to cost dict"""
function add_spill_cost(sp, data::Dict)
    return sp.ext[:cost][:spill_cost] = sum(
        data["hydro"]["Hydrogenerators"][i]["spill_cost"] * sp[:spill][i] for
        i in 1:data["hydro"]["nHyd"]
    )
end

"""add deficit cost to cost dict"""
function add_deficit_cost(sp, data::Dict)
    return sp.ext[:cost][:deficit_cost] =
        sum(sp[:deficit]) *
        data["powersystem"]["baseMVA"] *
        data["powersystem"]["cost_deficit"]
end

"""add minimal outflow violation cost to cost dict"""
function add_min_outflow_violation_cost(sp, data::Dict)
    return sp.ext[:cost][:min_outflow_violation_cost] =
        sum(data["hydro"]["Hydrogenerators"][i]["minimal_outflow_violation_cost"] * 
        sp[:min_outflow_violation][i] for i in 1:data["hydro"]["nHyd"])
end

"""add minimal volume violation cost to cost dict"""
function add_min_volume_violation_cost(sp, data::Dict)
    return sp.ext[:cost][:min_volume_violation_cost] =
        sum(data["hydro"]["Hydrogenerators"][i]["minimal_volume_violation_cost"] * 
        sp[:min_volume_violation][i] for i in 1:data["hydro"]["nHyd"])
end
