module HydroPowerModels

using JuMP, Clp, PowerModels, SDDP
import Reexport

include("variable.jl")
include("constraint.jl")
include("utilities.jl")
include("IO.jl")
include("simulate.jl")

export  hydrothermaloperation, parse_folder, set_param, simulate_model,
        plotresults, plotscenarios, set_active_demand, flat_dict,
        descriptivestatistics_results, signif_dict

Reexport.@reexport using PowerModels, SDDP

"""
data is a dict with all information of the problem. 

param is a dict containing solution parameters.
"""
function hydrothermaloperation(alldata::Array{Dict{Any,Any}}, params::Dict)

    # Model Definition
    m = SDDP.LinearPolicyGraph(
                    sense   = :Min,
                    stages  = params["stages"],
                    optimizer  = with_optimizer(params["optimizer"]),
                    lower_bound = 0.0,
                    direct_mode=false
                                            ) do sp,t
        
        # Extract current data
        data = alldata[min(t,size(alldata,1))]
        # calculate number of hydrogenerators
        countgenerators!(data)
        
        # compoute upstream_hydro
        upstream_hydro!(data)

        # count available inflow data
        countavailableinflow!(data)

        # build eletric grid model using PowerModels                                   
        pm = PowerModels.build_generic_model(data["powersystem"], params["model_constructor_grid"], 
            params["post_method"], jump_model=sp, setting = params["setting"])
        
        # create reference to variables
        createvarrefs(sp,pm)

        # save GenericPowerModel and Data
        sp.ext[:pm] = pm
        sp.ext[:data] = data

        # resevoir variables
        variable_volume(sp, data)
        
        # outflow and spillage variables
        variable_outflow(sp, data)
        variable_spillage(sp, data)

        # hydro balance
        variable_inflow(sp, data)
        rainfall_noises(sp, data, cidx(t,data["hydro"]["size_inflow"][1]))
        constraint_hydro_balance(sp, data)

        # hydro_generation
        constraint_hydro_generation(sp, data, pm)
        
        # Stage objective
        @stageobjective(sp, objective_function(sp) + sum(data["hydro"]["Hydrogenerators"][i]["spill_cost"]*sp[:spill][i] for i=1:data["hydro"]["nHyd"]))
    end

    # save data
    m.ext[:alldata] = alldata
    m.ext[:params] = params

    return m
end

end
