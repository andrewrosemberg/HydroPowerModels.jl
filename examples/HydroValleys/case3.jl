
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

#' ## Importing package and optimizer

using Clp
using HydroPowerModels

#' ## Load Case Specifications

#' data
data = HydroPowerModels.parse_folder(joinpath(WEAVE_ARGS[:testcases_dir],"case3"));
data[1]

#' parameters
params = set_param( stages = 12, 
                    model_constructor_grid  = DCPPowerModel,
                    post_method             = PowerModels.post_opf,
                    optimizer               = Clp.Optimizer);
params

#' ## Build Model
m = hydrothermaloperation(data, params);

#' ## Solve
status = SDDP.train(m.policygraph;iteration_limit = 100);
status

#' ## Simulation
import Random
Random.seed!(1111)
results = HydroPowerModels.simulate(m, 100);

#' ## Testing Results
#' Objective
using Test
@test isapprox(results[:simulations][1][1][:objective], 10496.09, atol=1)

#' Solution
@test results[:simulations][1][1][:powersystem]["solution"]["gen"]["4"]["pg"] == 0
@test isapprox(results[:simulations][1][1][:powersystem]["solution"]["gen"]["2"]["pg"],0.0, atol=1e-2)
@test isapprox(results[:simulations][1][1][:powersystem]["solution"]["gen"]["3"]["pg"],0.65, atol=1e-2)
@test isapprox(results[:simulations][1][1][:powersystem]["solution"]["gen"]["1"]["pg"],0.34, atol=1e-2)

#' ## Plotting Results

if !@isdefined plot_bool
    plot_bool = true
end

if plot_bool == true
    plotresults(results)
end
