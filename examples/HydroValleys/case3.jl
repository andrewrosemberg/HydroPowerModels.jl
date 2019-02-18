
#' ---
#' title : Example Case 3 - Year Planning
#' author : Andrew Rosemberg
#' date : 15th Feb 2019
#' ---

#' # Introduction

#' This an example of the HydroPowerModels package for solving a simple stochastic case with the following specifications:
#'    - 3 Buses
#'    - 3 Lines
#'    - 2 Generators
#'    - 1 Reservoir and Hydrogenerator
#'    - 3 Scenarios
#'    - 12 Stages

#' # Case

#' ## Importing package and solver

using Clp
using HydroPowerModels

#' ## Load Case Specifications
data = HydroPowerModels.parse_folder(joinpath(WEAVE_ARGS[:testcases_dir],"case3"))

params = set_param( stages = 12, 
                    model_constructor_grid  = DCPPowerModel,
                    post_method             = PowerModels.post_opf,
                    solver                  = ClpSolver())

#' ## Build Model
m = hydrothermaloperation(data, params)

#' ## Solve
status = solve(m, iteration_limit = 60)

#' ## Simulation
srand(1111)
results = simulate_model(m, 100)

#' ## Testing Results
#' Objective
using Base.Test
@test isapprox(results["simulations"][1]["objective"], 12400.00, atol=1e-2)

#' Solution
@test results["simulations"][1]["solution"][1]["gen"]["4"]["pg"] == 0
@test isapprox(results["simulations"][1]["solution"][1]["gen"]["2"]["pg"],0.0, atol=1e-2)
@test isapprox(results["simulations"][1]["solution"][1]["gen"]["3"]["pg"],0.65, atol=1e-2)
@test isapprox(results["simulations"][1]["solution"][1]["gen"]["1"]["pg"],0.34, atol=1e-2)

#' ## Plotting Results

#' Termo Generation

if !isdefined(:plot_bool)
    plot_bool = true
end

if plot_bool == true
    using Plots
    using Plots.PlotMeasures

    baseMVA =  [results["simulations"][i]["solution"][j]["baseMVA"] for i=1:100, j=1:params["stages"]]'

    scen_gen = [[results["simulations"][i]["solution"][j]["gen"]["$gen"]["pg"] for i=1:100, j=1:params["stages"]]'.*baseMVA for gen =1:3]

    plt =   [plot(median(scen_gen[gen],2), title  = "Termo Generation $gen",
                ylabel = "MWh",
                xlabel = "Stages",
                ribbon=(median(scen_gen[gen],2)-map(i->quantile(scen_gen[gen][i,:],0.05), 1:params["stages"]),map(i->quantile(scen_gen[gen][i,:],0.95), 1:params["stages"])-median(scen_gen[gen],2)),     
                xticks = (collect(1:Int(floor(params["stages"]/4)):params["stages"]), [string(i) for  i in collect(1:Int(floor(params["stages"]/4)):params["stages"])]),
                bottom_margin = 10mm,
                right_margin = 10mm
                )
            for gen =1:2
    ]
    plot(plt...,legend=false)
end

#' Branch flow

if plot_bool == true
    scen_branch = [[results["simulations"][i]["solution"][j]["branch"]["$brc"]["pf"] for i=1:100, j=1:params["stages"]]'.*baseMVA for brc =1:3]

    plt =   [plot(median(scen_branch[brc],2), title  = "Branch Flow $brc",
                ylabel = "MWh",
                xlabel = "Stages",
                ribbon=(median(scen_branch[brc],2)-map(i->quantile(scen_branch[brc][i,:],0.05), 1:params["stages"]),map(i->quantile(scen_branch[brc][i,:],0.95), 1:params["stages"])-median(scen_branch[brc],2)) ,     
                xticks = (collect(1:Int(floor(params["stages"]/4)):params["stages"]), [string(i) for  i in collect(1:Int(floor(params["stages"]/4)):params["stages"])]),
                bottom_margin = 10mm,
                right_margin = 10mm
                )
            for brc =1:3
    ]
    plot(plt...,legend=false)
end

#' Voltage angle

if plot_bool == true
    scen_va = [[results["simulations"][i]["solution"][j]["bus"]["$bus"]["va"] for i=1:100, j=1:params["stages"]]' for bus =1:3]

    plt =   [plot(median(scen_va[bus],2), title  = "Voltage angle $bus",
                ylabel = "Radians",
                xlabel = "Stages",
                ribbon=(median(scen_va[bus],2)-map(i->quantile(scen_va[bus][i,:],0.05), 1:params["stages"]),map(i->quantile(scen_va[bus][i,:],0.95), 1:params["stages"])-median(scen_va[bus],2)) ,     
                xticks = (collect(1:Int(floor(params["stages"]/4)):params["stages"]), [string(i) for  i in collect(1:Int(floor(params["stages"]/4)):params["stages"])]),
                bottom_margin = 10mm,
                right_margin = 10mm
                )
            for bus =1:3
    ]
    plot(plt...,legend=false)
end

#' Hydro Generation and Reservoir Volume

if plot_bool == true

    scen_voume = [results["simulations"][i]["solution"][j]["reservoirs"]["1"]["volume"] for i=1:100, j=1:params["stages"]]'

    plt =   [plot(median(scen_gen[3],2), title  = "Hydro Generation",
                ylabel = "MWh",
                xlabel = "Stages",
                ribbon=(median(scen_gen[3],2)-map(i->quantile(scen_gen[3][i,:],0.05), 1:params["stages"]),map(i->quantile(scen_gen[3][i,:],0.95), 1:params["stages"])-median(scen_gen[3],2)),     
                xticks = (collect(1:Int(floor(params["stages"]/4)):params["stages"]), [string(i) for  i in collect(1:Int(floor(params["stages"]/4)):params["stages"])]),
                bottom_margin = 10mm,
                right_margin = 10mm
                );
            plot(mean(scen_voume,2), title  = "Volume Reservoir",
                ylabel = "m³",
                xlabel = "Stages",
                ribbon=(median(scen_voume,2)-map(i->quantile(scen_voume[i,:],0.05), 1:params["stages"]),map(i->quantile(scen_voume[i,:],0.95), 1:params["stages"])-median(scen_voume,2)),     
                xticks = (collect(1:Int(floor(params["stages"]/4)):params["stages"]), [string(i) for  i in collect(1:Int(floor(params["stages"]/4)):params["stages"])]),
                bottom_margin = 10mm,
                right_margin = 10mm
                )    
            
    ]
    plot(plt...,legend=false)
end
