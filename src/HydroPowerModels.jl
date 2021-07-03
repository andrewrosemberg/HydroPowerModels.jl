module HydroPowerModels

using JuMP, PowerModels, SDDP
import Reexport

mutable struct HydroPowerModel
    policygraph::SDDP.PolicyGraph
    alldata::Array{Dict{Any,Any}}
    params::Dict
end

include("variable.jl")
include("constraint.jl")
include("utilities.jl")
include("IO.jl")
include("simulate.jl")
include("train.jl")
# include("visualization/visualize_data.jl")
include("objective.jl")
include("build_model.jl")

export  hydrothermaloperation, create_param,
        set_active_demand!, flat_dict, signif_dict

Reexport.@reexport using PowerModels, SDDP

"""
    hydrothermaloperation(alldata::Array{Dict{Any,Any}}, params::Dict)

Create a hydrothermal power operation model containing the policygraph the system data and the planning parameters.

Required parameters are:
-   alldata is a vector of dicts with information of the problem's stages. 
-   param is a dict containing solution parameters.
"""
function hydrothermaloperation(alldata::Array{Dict{Any,Any}}, params::Dict; build_model::Function=HydroPowerModels.build_opf_powermodels, discount_factor::Float64=1.0)
    # verbose
    if !params["verbose"]
        PowerModels.silence()
    end

    # if set silence the solver
    # related to https://github.com/JuliaOpt/JuMP.jl/pull/1921
    if !params["verbose"]
        try
            MOI.set(JuMP.backend(Model(params["optimizer"])), MOI.Silent(), true)
        catch
            @info "Silent() attribute not implemented by the optimizer."
        end
    end

    # Model Definition
    # graph definition
    graph = SDDP.LinearGraph(0)
    SDDP.add_node(graph, 1)
    SDDP.add_edge(graph, 0 => 1, 1.0)
    for t in 2:params["stages"]
        SDDP.add_node(graph, t)
        SDDP.add_edge(graph, t-1 => t, discount_factor)
    end
    policygraph = SDDP.PolicyGraph(graph,
                    sense       = :Min,
                    optimizer   = params["optimizer"],
                    optimizer_forward = params["optimizer_forward"],
                    optimizer_backward = params["optimizer_backward"],
                    lower_bound = 0.0,
                    direct_mode = false
                                            ) do sp, t, isforward
        
        # if set silence the solver
        # related to https://github.com/JuliaOpt/JuMP.jl/pull/1921
        if !params["verbose"]
            try
                MOI.set(JuMP.backend(sp), MOI.Silent(), true)
            catch
                #@info "Silent() attribute not implemented by the optimizer."
            end
        end
        # Extract current data
        data = alldata[min(t,size(alldata,1))]
        
        # gather useful information from data
        gatherusefulinfo!(data)

        # build eletric grid model using PowerModels

        if isforward
            pm = PowerModels.build_model(data["powersystem"], params["model_constructor_grid_forward"], 
                params["post_method"], jump_model=sp, setting = params["setting"])
        else
            pm = PowerModels.build_model(data["powersystem"], params["model_constructor_grid_backward"], 
               params["post_method"], jump_model=sp, setting = params["setting"])
        end
        sp.ext[:isforward] = isforward
        
        # create reference to variables
        createvarrefs!(sp,pm)

        # save AbstractPowerModel and Data
        sp.ext[:pm] = pm
        sp.ext[:data] = data

        # save lower_bound
        sp.ext[:lower_bound] = 0.0

        # resevoir variables
        variable_volume(sp, data)
        
        # outflow and spillage variables
        variable_outflow(sp, data)
        variable_spillage(sp, data)

        # hydro balance
        variable_inflow(sp, data)
        rainfall_noises(sp, data, params, cidx(t,data["hydro"]["size_inflow"][1]))
        constraint_hydro_balance(sp, data, params)

        # hydro_generation
        constraint_hydro_generation(sp, data, pm)

        # deficit
        variable_deficit(sp, data, pm)
        constraint_mod_deficit(sp, data, pm)

        # costs stage
        variable_cost(sp, data)
        add_gen_cost(sp, data)
        add_spill_cost(sp, data)
        add_deficit_cost(sp, data)
        
        # Stage objective
        set_objective(sp, data)

        # # variable primal start
        # JuMP.MathOptInterface.set.(sp,JuMP.MathOptInterface.VariablePrimalStart(), JuMP.all_variables(sp), NaN)
        JuMP.MathOptInterface.set.(sp,JuMP.MathOptInterface.VariablePrimalStart(), sp[:deficit], 0.0)
        JuMP.MathOptInterface.set.(sp,JuMP.MathOptInterface.VariablePrimalStart(), sp[:inflow], 0.0)
        JuMP.MathOptInterface.set.(sp,JuMP.MathOptInterface.VariablePrimalStart(), sp[:outflow], 0.0)
        JuMP.MathOptInterface.set.(sp,JuMP.MathOptInterface.VariablePrimalStart(), sp[:spill], 0.0)
        for r in sp[:reservoir]
            JuMP.MathOptInterface.set.(sp,JuMP.MathOptInterface.VariablePrimalStart(), r.in, 0.0) 
        end
        for r in sp[:reservoir]
            JuMP.MathOptInterface.set.(sp,JuMP.MathOptInterface.VariablePrimalStart(), r.out, 0.0) 
        end

    end

    # save data
    m = HydroPowerModel(policygraph,alldata,params)

    return m
end

end
