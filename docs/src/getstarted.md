## Getting started

Once PowerModels, SDDP and a solver (like GLPK or Ipopt) are installed, and a case data folder (e.g. "case3") has been acquired, an Hydrothermal Multistage Steady-State Power Network Optimization can be executed.

First import the necessary packages:

```julia
using HydroPowerModels
using Ipopt, GLPK
```

Load Case by passing the respective folder:


```julia
data = HydroPowerModels.parse_folder("case3_folderpath")
```

Set Parameters to run, for example, an DC Economic Hydrothermal Dispatch:

```julia
params = create_param( stages = 12, 
                    model_constructor_grid  = DCPPowerModel,
                    post_method             = PowerModels.build_opf,
                    optimizer               = GLPK.Optimizer
);
```

Build the Model and execute the SDDP method:

```julia
m = hydrothermaloperation(data, params)

HydroPowerModels.train(m;iteration_limit = 60);
```

Simulate 100 Instances of the problem:

```julia
results = HydroPowerModels.simulate(m, 100);
```

## Getting Results

The simulate command in HydroPowerModels returns a detailed execution data in the form of a dictionary.

For example, the algorithm's runtime and original case data can be accessed with:

```julia
results[:solve_time]
results[:data]
```

Simulation results are found in the simulations array inside the dictionary, which every element is an array containing information of all stages. For example, information about the 10th simulation, as objective value and sampled noise of the first stage, may be accessed with:

```julia
results[:simulations][10][1][:objective]
results[:simulations][10][1][:noise_term]
```

The ```:powersystem``` field contains detailed information about the grid solution returned by the PowerModels package, like generation and bus informations (inside the subitem "solution") and status ("OPTIMAL", "INFEASIBLE",...) of the solution execution. For example, the status of the solution execution and the active generation of the 2th generator on the jth stage and ith simulation can be inspect by:

```julia
results[:simulations][1][2][:powersystem]["termination_status"]

results[:simulations][i][j][:powersystem]["solution"]["gen"]["2"]["pg"]
```

Reservoirs menagement information, like outflow and spillage, are found inside the ```:reservoirs``` field:

```julia
results[:simulations][i][j][:reservoirs][:outflow]

results[:simulations][i][j][:reservoirs][:spill]
```

## Plotting Results

In order to plot the results returned by the simulate function, you may choose from a variety of methods.

The function ’plotresults()’ receives a results dictionary and generates the most common plots for a hydrothermal dispatch: 

```julia
HydroPowerModels.plotresults(results)
```

Otherwise, it helps to organize values of a variable for all simulations and stages into a matrix and then plot using the  'plotscenarios'. The 'plotscenarios' function indicates the median and the following quantiles: [5%, 15%, 25%, 75%, 85%, 95%]. For example, to plot the values of the active generation of the 1st generator:

```julia
baseMVA =  [results[:simulations][i][j][:powersystem]["solution"]["baseMVA"] for i=1:100, j=1:12]'

scen_gen = [results[:simulations][i][j][:powersystem]["solution"]["gen"]["$gen"]["pg"] for i=1:100, j=1:12]'.*baseMVA

HydroPowerModels.plotscenarios(scen_gen, title  = "Thermal Generation 1",
                ylabel = "MW",
                xlabel = "Stages",
                bottom_margin = 10mm,
                right_margin = 10mm,
                left_margin = 10mm                
                )
```

For those familiar with other plot functions may use them with no big dificulty.