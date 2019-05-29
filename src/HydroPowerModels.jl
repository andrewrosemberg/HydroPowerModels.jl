module HydroPowerModels

using JuMP, Clp, PowerModels, SDDP
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
include("visualize_data.jl")
include("objective.jl")

export  hydrothermaloperation, parse_folder, create_param,
        plotresults, plotscenarios, set_active_demand!, flat_dict,
        descriptivestatistics_results, signif_dict, plot_grid, plot_hydro_grid,
        plot_grid_dispatched, plot_aggregated_results, plot_bound

Reexport.@reexport using PowerModels, SDDP

"""
data is a dict with all information of the problem. 

param is a dict containing solution parameters.
"""
function hydrothermaloperation(alldata::Array{Dict{Any,Any}}, params::Dict)
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
    policygraph = SDDP.LinearPolicyGraph(
                    sense       = :Min,
                    stages      = params["stages"],
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
            pm = PowerModels.build_generic_model(data["powersystem"], params["model_constructor_grid_forward"], 
                params["post_method"], jump_model=sp, setting = params["setting"])
        else
            pm = PowerModels.build_generic_model(data["powersystem"], params["model_constructor_grid_backward"], 
                params["post_method"], jump_model=sp, setting = params["setting"])
        end
        
        # create reference to variables
        createvarrefs!(sp,pm)

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
        # JuMP.MathOptInterface.set.(sp,JuMP.MathOptInterface.VariablePrimalStart(), sp[:deficit], 0)
        # JuMP.MathOptInterface.set.(sp,JuMP.MathOptInterface.VariablePrimalStart(), sp[:inflow], 0)
        # JuMP.MathOptInterface.set.(sp,JuMP.MathOptInterface.VariablePrimalStart(), sp[:outflow], 0)
        # JuMP.MathOptInterface.set.(sp,JuMP.MathOptInterface.VariablePrimalStart(), sp[:spill], 0)
        # for r in sp[:reservoir]
        #     JuMP.MathOptInterface.set.(sp,JuMP.MathOptInterface.VariablePrimalStart(), r.in, 0) 
        # end
        # for r in sp[:reservoir]
        #     JuMP.MathOptInterface.set.(sp,JuMP.MathOptInterface.VariablePrimalStart(), r.out, 0) 
        # end

    end

    # save data
    m = HydroPowerModel(policygraph,alldata,params)

    return m
end

end
