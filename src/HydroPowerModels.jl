module HydroPowerModels

using JuMP, PowerModels, SDDP
using Ipopt, SCS

include("variable.jl")
include("constraint.jl")

export hydrovalleymodel

"""
data is a dict with all information of the problem. 

param is a dict containing solution parameters.
"""
function hydrovalleymodel(data::Dict, params::Dict)
    # calculate number of generators
    data["hydro"]["nHyd"] = size(data["hydro"]["Hydrogenerators"],1)    

    # Model Definition
    m = SDDPModel(
                    sense   = :Min,
                    stages  = params["stages"],
                    solver  = params["solver"],
            objective_bound = 0.0
                                            ) do sp,t

        # build eletric grid model using PowerModels                                   
        pm = PowerModels.build_generic_model(data["powersystem"], params["model_constructor_grid"], params["post_method"], jump_model=sp)

        # resevoir variables
        variable_volume(sp, data)
        
        # outflow and spillage variables
        variable_outflow(sp, data)
        variable_spillage(sp, data)

        # hydro balance
        variable_inflow(sp, data)
        rainfall_noises(sp, data, t)
        constraint_hydro_balance(sp, data)

        # hydro_generation
        constraint_hydro_generation(sp, data, pm)
        
        # Stage objective
        @stageobjective(sp, sp.obj)
    end

    return m
end

end
