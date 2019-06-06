
#' ---
#' title : Example Case 3 - Year Planning
#' author : Andrew Rosemberg
#' date : 20th Feb 2019
#' ---

#' # Introduction

#' This an example of the HydroPowerModels package for solving a simple stochastic case with the following specifications:
#'    - 3 Buses
#'    - 3 Lines
#'    - 2 Generators
#'    - 1 Reservoir and Hydrogenerator
#'    - 3 Scenarios
#'    - 12 Stages
#'    - SOC Formulation

#' # Case

#' ## Importing package and optimizer
using SCS
using HydroPowerModels

#' ## Initialization
#+ results =  "hidden"
if !@isdefined plot_bool
    plot_bool = true
end
using Random
seed = 1221

#' ## Load Case Specifications

#' Data
data = HydroPowerModels.parse_folder(joinpath(WEAVE_ARGS[:testcases_dir],"case3"));

#' Plot power grid graph
if plot_bool == true
    Random.seed!(seed)
    plot_grid(alldata[1],node_label=false)
end

#' Parameters
params = create_param(  stages = 12, 
                        model_constructor_grid  = SOCWRConicPowerModel,
                        post_method             = PowerModels.post_opf,
                        optimizer               = with_optimizer(SCS.Optimizer))

#' ## Build Model
#+ results =  "hidden"
m = hydrothermaloperation(alldata, params);

#' ## Train
#+ results =  "hidden"
start_time = time()
HydroPowerModels.train(m,iteration_limit = 100,stopping_rules= [SDDP.Statistical(num_replications = 20,iteration_period=20)]);
end_time = time() - start_time

#' Termination Status and solve time (s)
(SDDP.termination_status(m.policygraph), end_time)

#' Bounds
plot_bound(m)

#' ## Simulation
import Random
Random.seed!(seed)
results = HydroPowerModels.simulate(m, 100);
results

#' ## Testing Results
#' Bound
using Test
@test isapprox(sum(s[:stage_objective] for s in results[:simulations][1]), 9400.0, atol=1)

#' ## Plot Aggregated Results
if plot_bool == true
    plot_aggregated_results(results)
end

#' # Annex 1: Case Summary
if plot_bool == true
    PowerModels.print_summary(data["powersystem"])
end

#' # Annex 2: Plot Results
if plot_bool == true
    plotresults(results)
end
