## Getting started

If you want to use the parallel features of HydroPowerModels.jl, you should start Julia with
some worker processes (`julia -p N`), or add by running `julia> addprocs(N)` in
a running Julia session.

Once PowerModels, SDDP and a solver (like Clp or Ipopt) are installed, and a case data folder (e.g. "case3") has been acquired, an Hydrothermal Multistage Steady-State Power Network Optimization can be executed.

First import the necessary packages:

```julia
using HydroPowerModels
using JuMP, PowerModels, SDDP
using Ipopt, Clp
```

Load Case by passing the respective folder:


```julia
data = HydroPowerModels.parse_folder("case3_folderpath")
```

Set Parameters to run, for example, an DC Economic Hydrothermal Dispatch:

```julia
params = set_param( 
    stages = 3, 
    model_constructor_grid  = DCPPowerModel,
    post_method             = PowerModels.post_opf,
    solver                  = ClpSolver())
```

Build and Model and execute the SDDP method:

```julia
m = hydrovalleymodel(data, params)

status = solve(m, iteration_limit = 60)
```

Simulate 100 Instances of the problem:

```julia
results = simulate_model(m, 100)
```

## Getting Results

The simulate_model command in HydroPowerModels returns a detailed execution data in the form of a dictionary.

For example, the algorithm's runtime and original case data can be accessed with:

```julia
result["solve_time"]
result["data"]
```

Simulation results are found in the simulations array inside the dictionary. For example, information about the 10th simulation, as objective value and sampled noise, may be accessed with:

```julia
result["simulation"][10]
result["simulation"][10]["objective"]
result["simulation"][10]["noise"]
```

The "solution" field contains detailed information about the grid solution returned by the PowerModels package, like generation and bus informations, as well as reservoirs menagement information, like outflow and spillage. For example, the active generation of the 2th generator and the outflow of the 1st reservoir on the second stage and first markov state can be inspect by:

```julia
results["simulations"][1]["solution"][2][1]["gen"]["2"]["pg"]

results["simulations"][1]["solution"][2][1]["reservoirs"]["1"]["outflow"]
```

## Plotting Results

In order to plot the results returned by the simulate_model function, you may choose from a variety of methods.

The getvalue function helps to organize values of a variable for all simulations and stages into a matrix:

```julia
get_multiperiod_value(results::Dict, path=[]::Array{Any,1}, matidx=Int[]::Array{Int,1})
```
Where path is the vector of keys in our results data structure to arrive at the variable of interest; matidx are the indexes in the path vector which correspond to the dimensions of the output matrix.

For example, the generation matrix from the 1st generator may be accessed with:

```julia
get_multiperiod_value(results,["simulations",1,"solution",1,"gen","1","pg"],[4,2])
```

For those familiar with the plot functions from SDDP.jl, they may also be used here. For example, to plot the active generation from the 3rd generator and the volume of the 1st reservoir for all stages and simulations:

```julia
plt = SDDP.newplot()

SDDP.addplot!(plt,
    1:100, 1:params["stages"],
    (i, t)->results["simulations"][i]["solution"][t]["gen"]["3"]["pg"]*results["simulations"][i]["solution"][t]["baseMVA"],
    title  = "Hydro Generation",
    ylabel = "MWh"
)

SDDP.addplot!(plt,
    1:100, 1:params["stages"],
    (i, t)->results["simulations"][i]["solution"][t]["reservoirs"]["1"]["volume"],
    title  = "volume",
    ylabel = "L"
)
SDDP.show(plt)
```