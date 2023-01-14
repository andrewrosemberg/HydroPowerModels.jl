"""set objective"""
function set_objective(sp, data::Dict)
    @stageobjective(sp, sum(values(sp.ext[:cost])))
end

"""add generators cost to cost dict"""
function add_gen_cost(sp, data::Dict)
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
