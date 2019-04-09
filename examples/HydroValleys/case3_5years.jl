
#' ---
#' title : Example Case 3 - 5 Years Planning
#' author : Andrew Rosemberg
#' date : 17th Feb 2019
#' ---

#' # Introduction

#' This an example of the HydroPowerModels package for solving a simple stochastic case with the following specifications:
#'    - 3 Buses
#'    - 3 Lines
#'    - 2 Generators
#'    - 1 Reservoir and Hydrogenerator
#'    - 3 Scenarios
#'    - 60 Stages

#' # Case

#' ## Importing package and optimizer

using Clp
using HydroPowerModels

#' ## Load Case Specifications
data = HydroPowerModels.parse_folder(joinpath(WEAVE_ARGS[:testcases_dir],"case3"))

params = set_param( stages = 12*5, 
                    model_constructor_grid  = DCPPowerModel,
                    post_method             = PowerModels.post_opf,
                    optimizer                  = Clp.Optimizer)

#' ## Build Model
m = hydrothermaloperation(data, params);

#' ## Solve
status = SDDP.train(m.policygraph; iteration_limit = 100, cut_deletion_minimum=1000000);

#' ## Simulation
import Random
Random.seed!(1111);
results = HydroPowerModels.simulate(m, 100);

#' ## Testing Results
#' Objective
using Test
@test isapprox(sum(s[:stage_objective] for s in results[:simulations][1]), 54601.39, atol=1)

#' Solution
@test results[:simulations][1][50][:powersystem]["solution"]["gen"]["4"]["pg"] == 0
@test isapprox(results[:simulations][1][50][:powersystem]["solution"]["gen"]["2"]["pg"],0.0, atol=1e-2)
@test isapprox(results[:simulations][1][50][:powersystem]["solution"]["gen"]["3"]["pg"],0.74, atol=1e-2)
@test isapprox(results[:simulations][1][50][:powersystem]["solution"]["gen"]["1"]["pg"],0.25, atol=1e-2)

#' ## Plotting Results

if !@isdefined plot_bool
    plot_bool = true
end

if plot_bool == true
    plotresults(results)
end