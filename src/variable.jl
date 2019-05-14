"""creates outflow variables specified in data"""
function variable_inflow(sp, data::Dict)
    @variables(sp, begin
        inflow[r=1:data["hydro"]["nHyd"]]
    end)
end


# TODO: add data["hydro"]["Hydrogenerators"][r]["min_turn"] as penalized constraint
"""creates outflow variables specified in data"""
function variable_outflow(sp, data::Dict)
    @variables(sp, begin
        0 <= outflow[r=1:data["hydro"]["nHyd"]] <= data["hydro"]["Hydrogenerators"][r]["max_turn"]            
    end)
end

"""creates spillage variables specified in data"""
function variable_spillage(sp, data::Dict)
    @variables(sp, begin
        spill[r=1:data["hydro"]["nHyd"]]      >= 0            
    end)
end

"""creates volume variables specified in data"""
function variable_volume(sp, data::Dict)
    @variable(sp, data["hydro"]["Hydrogenerators"][r]["min_volume"] <= reservoir[r = 1:data["hydro"]["nHyd"]] <= data["hydro"]["Hydrogenerators"][r]["max_volume"], SDDP.State, initial_value = data["hydro"]["Hydrogenerators"][r]["initial_volume"])
end

"""creates deficit variables"""
function variable_deficit(sp, data::Dict, pm::GenericPowerModel)
    var(pm, 0, 1)[:deficit] = @variable(sp, deficit[i in collect(1:length(con(pm, 0, 1, :kcl_p)))] >= 0)
end

"""creates dict of cost variables"""
function variable_cost(sp, data::Dict)
    cost = Dict()
    sp.ext[:cost] = cost
end