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
using GLPK
using HydroPowerModels

#' ## Initialization
#'+ results =  "hidden"
if !@isdefined plot_bool
    plot_bool = true
end
using Random
seed = 1221

#' ## Load Case Specifications

#' Data
alldata = HydroPowerModels.parse_folder(joinpath(WEAVE_ARGS[:testcases_dir], "case3"));

#' Plot power grid graph
if plot_bool == true
    Random.seed!(seed)
    HydroPowerModels.plot_grid(alldata[1]; has_nodelabel=false)
end

#' Parameters
params = create_param(;
    stages=12,
    model_constructor_grid=DCPPowerModel,
    post_method=PowerModels.build_opf,
    optimizer=GLPK.Optimizer,
);

#' ## Build Model
#'+ results =  "hidden"
m = hydrothermaloperation(alldata, params);

#' ## Train
#'+ results =  "hidden"
Random.seed!(seed)
start_time = time()
HydroPowerModels.train(
    m;
    iteration_limit=100,
    stopping_rules=[SDDP.Statistical(; num_replications=20, iteration_period=20)],
);
end_time = time() - start_time

#' Termination Status and solve time (s)
(SDDP.termination_status(m.policygraph), end_time)

#' Bounds
if plot_bool == true
    HydroPowerModels.plot_bound(m)
end

#' ## Simulation
using Random: Random
Random.seed!(seed)
results = HydroPowerModels.simulate(m, 100);
results

#' ## Testing Results
using Test
#' Bound
@test SDDP.calculate_bound(m.policygraph) >= 1.1e4
#' Number of Simulations
@test length(results[:simulations]) == 100

#' ## Plot Aggregated Results
if plot_bool == true
    HydroPowerModels.plot_aggregated_results(results)
end

#' # Annex 1: Case Summary
if plot_bool == true
    PowerModels.print_summary(alldata[1]["powersystem"])
end

#' # Annex 2: Plot Results
if plot_bool == true
    HydroPowerModels.plotresults(results)
end
