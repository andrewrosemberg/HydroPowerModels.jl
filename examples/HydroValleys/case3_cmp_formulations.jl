
intro_str = """

# Example Case 3 Comparing Formulations - Year Planning

author : Andrew Rosemberg \n
date : 21th Feb 2019 \n

## Introduction

This an example of the HydroPowerModels package for solving a simple stochastic case with the following specifications: \n
    - 3 Buses - 3 Lines - 2 Generators - 1 Reservoir and Hydrogenerator \n
    - 3 Scenarios - 12 Stages \n
    - DC,SOC and AC Formulations \n

Simulation's results will be shown in tables to facilitate comparison. Each formulation will have its own table where the columns will
be named according to the variables of the problem: \n
    - "[variable type]_[index]_[quantile]". \n
Variable types in this example:\n
    * "hpg": Hydro active power generation.\n
    * "pg": Termo active power generation.\n
    * "pf": Active power flow.\n
    * "va": Voltage angle.\n
    * "pg": Termo active power generation.\n
    * "volume": Reservoir volume.\n

"""
#' # Init Case

#' ## Importing package and optimizer

using Ipopt, GLPK
using HydroPowerModels

#' ## Load Case Specifications
testcases_dir = joinpath(dirname(dirname(dirname(@__FILE__))), "testcases")
data = HydroPowerModels.parse_folder(joinpath(testcases_dir, "case3"))

#' ## Results Dict
dcp_stats = Dict()

#' # Case DC

#' ## Parameters

params = create_param(;
    stages=12,
    model_constructor_grid=DCPPowerModel,
    post_method=PowerModels.build_opf,
    optimizer=GLPK.Optimizer,
)

#' ## Build Model
m = hydrothermaloperation(data, params);

#' ## Solve
HydroPowerModels.train(m; iteration_limit=60);

#' ## Simulation
using Random: Random
Random.seed!(1111)
results = HydroPowerModels.simulate(m, 100);

#' ## Results
dcp_stats["DC"] = flat_dict(HydroPowerModels.descriptivestatistics_results(results))

#' # Case SOC

#' ## Parameters

params = create_param(;
    stages=12,
    model_constructor_grid=SOCWRPowerModel,
    post_method=PowerModels.build_opf,
    optimizer=IpoptSolver(; tol=1e-6),
)

#' ## Build Model
m = hydrothermaloperation(data, params);

#' ## Solve
HydroPowerModels.train(m; iteration_limit=60);

#' ## Simulation
using Random: Random
Random.seed!(1111)
results = HydroPowerModels.simulate(m, 100);

#' ## Results
dcp_stats["SOC"] = flat_dict(HydroPowerModels.descriptivestatistics_results(results))

#' # Case AC

#' ## Parameters

params = create_param(;
    stages=12,
    model_constructor_grid=ACPPowerModel,
    post_method=PowerModels.build_opf,
    optimizer=IpoptSolver(; tol=1e-6),
)

#' ## Build Model
m = hydrothermaloperation(data, params);

#' ## Solve
HydroPowerModels.train(m; iteration_limit=60);

#' ## Simulation
using Random: Random
Random.seed!(1111)
results = HydroPowerModels.simulate(m, 100);

#' ## Results
dcp_stats["AC"] = flat_dict(HydroPowerModels.descriptivestatistics_results(results))

#' # Export to compare Results
using Latexify
using DataFrames
using Base.Markdown

str_ac = html(
    latexify(DataFrame(signif_dict(dcp_stats["AC"], 2)); env=:mdtable, latex=false)
);
str_soc = html(
    latexify(DataFrame(signif_dict(dcp_stats["SOC"], 2)); env=:mdtable, latex=false)
);
str_dc = html(
    latexify(DataFrame(signif_dict(dcp_stats["DC"], 2)); env=:mdtable, latex=false)
);

results_str = """

  ## Results 

  """

final_str =
    intro_str *
    results_str *
    "### Table AC \n\n```@raw html\n\n" *
    str_ac *
    " \n\n```\n\n### Table DC \n\n```@raw html\n\n" *
    str_dc *
    " \n\n```\n\n### Table SOC \n\n```@raw html\n\n" *
    str_soc *
    " \n\n```";

# write to file
docs_scr_dir = joinpath(dirname(dirname(dirname(@__FILE__))), "docs/src/examples")
write(joinpath(docs_scr_dir, "case3_cmp_formulations.md"), final_str)
