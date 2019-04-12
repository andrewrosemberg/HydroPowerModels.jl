
#' ---
#' title : Example Case 3 AC - Year Planning
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
#'    - AC Formulation

#' # Case

#' ## Importing package and optimizer

using Ipopt
using HydroPowerModels

#' ## Load Case Specifications
data = HydroPowerModels.parse_folder(joinpath(WEAVE_ARGS[:testcases_dir],"case3"))

params = create_param( stages = 12, 
                    model_constructor_grid  = ACPPowerModel,
                    post_method             = PowerModels.post_opf,
                    optimizer               = Ipopt.Optimizer)

#' ## Build Model
m = hydrothermaloperation(data, params)

#' ## Solve
import Random
Random.seed!(1111)
status = SDDP.train(m.policygraph; iteration_limit = 100);

#' ## Simulation
results = HydroPowerModels.simulate(m, 100);
results

#' ## Results
#' Objective
results[:simulations][1][1][:objective]

#' ## Plotting Results

#' Active

if !@isdefined plot_bool
    plot_bool = true
end

if plot_bool == true
    plotresults(results)
end