"creates outflow variables specified in data"
function variable_inflow(sp, data::Dict)
    @variables(sp, begin
            inflow[r=1:data["hydro"]["nHyd"]]      >= 0            
    end)
end

"creates outflow variables specified in data"
function variable_outflow(sp, data::Dict)
    @variables(sp, begin
            outflow[r=1:data["hydro"]["nHyd"]]      >= 0            
    end)
end

"creates spillage variables specified in data"
function variable_spillage(sp, data::Dict)
    @variables(sp, begin
        spill[r=1:data["hydro"]["nHyd"]]      >= 0            
    end)
end

"creates volume variables specified in data"
function variable_volume(sp, data::Dict)
    @state(sp, data["hydro"]["Hydrogenerators"][r]["min_volume"] <= reservoir[r=1:data["hydro"]["nHyd"]] <= data["hydro"]["Hydrogenerators"][r]["max_volume"], reservoir0 == data["hydro"]["Hydrogenerators"][r]["initial_volume"])
end