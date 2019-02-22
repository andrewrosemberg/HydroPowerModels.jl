
intro_str = """

# Example Case 3 Comparing Formulations - Year Planning

author : Andrew Rosemberg \n
date : 21th Feb 2019 \n

## Introduction

This an example of the HydroPowerModels package for solving a simple stochastic case with the following specifications: \n
    - 3 Buses \n
    - 3 Lines \n
    - 2 Generators \n
    - 1 Reservoir and Hydrogenerator \n
    - 3 Scenarios \n
    - 12 Stages \n
    - DC,SOC and AC Formulations \n

"""
#' # Init Case

#' ## Importing package and solver

using Ipopt,Clp
using HydroPowerModels

#' ## Load Case Specifications
testcases_dir = joinpath(dirname(dirname(dirname(@__FILE__))), "testcases")
data = HydroPowerModels.parse_folder(joinpath(testcases_dir,"case3"))

#' ## Results Dict
dcp_stats = Dict()

#' # Case DC

#' ## Parameters

params = set_param( stages = 12, 
                    model_constructor_grid  = DCPPowerModel,
                    post_method             = PowerModels.post_opf,
                    solver                  = ClpSolver())

#' ## Build Model
m = hydrothermaloperation(data, params);

#' ## Solve
status = solve(m, iteration_limit = 60);

#' ## Simulation
srand(1111)
results = simulate_model(m, 100);

#' ## Results
dcp_stats["DC"] = flat_dict(HydroPowerModels.descriptivestatistics_results(results))

#' # Case SOC

#' ## Parameters

params = set_param( stages = 12, 
                    model_constructor_grid  = SOCWRPowerModel,
                    post_method             = PowerModels.post_opf,
                    solver                  = IpoptSolver(tol=1e-6))

#' ## Build Model
m = hydrothermaloperation(data, params);

#' ## Solve
status = solve(m, iteration_limit = 60);

#' ## Simulation
srand(1111)
results = simulate_model(m, 100);

#' ## Results
dcp_stats["SOC"] = flat_dict(HydroPowerModels.descriptivestatistics_results(results))

#' # Case AC

#' ## Parameters

params = set_param( stages = 12, 
                    model_constructor_grid  = ACPPowerModel,
                    post_method             = PowerModels.post_opf,
                    solver                  = IpoptSolver(tol=1e-6))

#' ## Build Model
m = hydrothermaloperation(data, params);

#' ## Solve
status = solve(m, iteration_limit = 60);

#' ## Simulation
srand(1111)
results = simulate_model(m, 100);

#' ## Results
dcp_stats["AC"] = flat_dict(HydroPowerModels.descriptivestatistics_results(results))

#' # Export to compare Results
using Latexify
using DataFrames
using Base.Markdown

str_ac = html(latexify(DataFrame(signif_dict(dcp_stats["AC"],2)),env=:mdtable,latex=false));
str_soc = html(latexify(DataFrame(signif_dict(dcp_stats["SOC"],2)),env=:mdtable,latex=false));
str_dc = html(latexify(DataFrame(signif_dict(dcp_stats["DC"],2)),env=:mdtable,latex=false));

results_str="""

## Results 

"""

final_str = intro_str*results_str*"### Table AC \n\n```@raw html\n\n"*str_ac*" \n\n```\n\n### Table DC \n\n```@raw html\n\n"*str_dc*" \n\n```\n\n### Table SOC \n\n```@raw html\n\n"*str_soc*" \n\n```";

# write to file
docs_scr_dir = joinpath(dirname(dirname(dirname(@__FILE__))), "docs/src/examples")
write(joinpath(docs_scr_dir,"case3_cmp_formulations.md"), final_str)