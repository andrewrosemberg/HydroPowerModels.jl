var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#HydroPowerModels.jl-Documentation-1",
    "page": "Home",
    "title": "HydroPowerModels.jl Documentation",
    "category": "section",
    "text": "CurrentModule = HydroPowerModels"
},

{
    "location": "index.html#Overview-1",
    "page": "Home",
    "title": "Overview",
    "category": "section",
    "text": "HydroPowerModels.jl is a Julia/JuMP package for Hydrothermal Multistage Steady-State Power Network Optimization solved by Stochastic Dual Dynamic Programming (SDDP). Problem Specifications and Network Formulations are handled by PowerModels.jl. Solution method is handled by SDDP.jl."
},

{
    "location": "index.html#Installation-1",
    "page": "Home",
    "title": "Installation",
    "category": "section",
    "text": "Dependencies to this package include the packages PowerModels and SDDP. Therefore you should first install as follows:Pkg.add(\"PowerModels\")\nPkg.clone(\"https://github.com/odow/SDDP.jl.git\")The current package is unregistered so you will need to Pkg.clone it as follows:Pkg.clone(\"https://github.com/andrewrosemberg/HydroPowerModels.jl.git\")"
},

{
    "location": "getstarted.html#",
    "page": "Manual",
    "title": "Manual",
    "category": "page",
    "text": ""
},

{
    "location": "getstarted.html#Getting-started-1",
    "page": "Manual",
    "title": "Getting started",
    "category": "section",
    "text": "If you want to use the parallel features of HydroPowerModels.jl, you should start Julia with some worker processes (julia -p N), or add by running julia> addprocs(N) in a running Julia session.Once PowerModels, SDDP and a solver (like Clp or Ipopt) are installed, and a case data folder (e.g. \"case3\") has been acquired, an Hydrothermal Multistage Steady-State Power Network Optimization can be executed.First import the necessary packages:using HydroPowerModels\nusing JuMP, PowerModels, SDDP\nusing Ipopt, ClpLoad Case by passing the respective folder:data = HydroPowerModels.parse_folder(\"case3_folderpath\")Set Parameters to run, for example, an DC Economic Hydrothermal Dispatch:params = set_param( \n    stages = 3, \n    model_constructor_grid  = DCPPowerModel,\n    post_method             = PowerModels.post_opf,\n    solver                  = ClpSolver())Build and Model and execute the SDDP method:m = hydrovalleymodel(data, params)\n\nstatus = solve(m, iteration_limit = 60)Simulate 100 Instances of the problem:results = simulate_model(m, 100)"
},

{
    "location": "getstarted.html#Getting-Results-1",
    "page": "Manual",
    "title": "Getting Results",
    "category": "section",
    "text": "The simulate_model command in HydroPowerModels returns a detailed execution data in the form of a dictionary.For example, the algorithm\'s runtime and original case data can be accessed with:result[\"solve_time\"]\nresult[\"data\"]Simulation results are found in the simulations array inside the dictionary. For example, information about the 10th simulation, as objective value and sampled noise, may be accessed with:result[\"simulation\"][10]\nresult[\"simulation\"][10][\"objective\"]\nresult[\"simulation\"][10][\"noise\"]The \"solution\" field contains detailed information about the grid solution returned by the PowerModels package, like generation and bus informations, as well as reservoirs menagement information, like outflow and spillage. For example, the active generation of the 2th generator and the outflow of the 1st reservoir on the second stage and first markov state can be inspect by:results[\"simulations\"][1][\"solution\"][2][1][\"gen\"][\"2\"][\"pg\"]\n\nresults[\"simulations\"][1][\"solution\"][2][1][\"reservoirs\"][\"1\"][\"outflow\"]"
},

{
    "location": "getstarted.html#Plotting-Results-1",
    "page": "Manual",
    "title": "Plotting Results",
    "category": "section",
    "text": "In order to plot the results returned by the simulate_model function, you may choose from a variety of methods.It helps to organize values of a variable for all simulations and stages into a matrix. For example, to plot the values of the active generation from the 1st to the 3rd generator:baseMVA =  [results[\"simulations\"][i][\"solution\"][j][\"baseMVA\"] for i=1:100, j=1:12]\'\n\nscen_gen = [[results[\"simulations\"][i][\"solution\"][j][\"gen\"][\"$gen\"][\"pg\"] for i=1:100, j=1:12]\'.*baseMVA for gen =1:3]Then just choose a plot function:plt =   [plot(median(scen_gen[gen],2), title  = \"Termo Generation $gen\",\n            ylabel = \"MWh\",\n            ribbon=(median(scen_gen[gen],2)-map(i->quantile(scen_gen[gen][i,:],0.05), 1:12),map(i->quantile(scen_gen[gen][i,:],0.95), 1:12)-median(scen_gen[gen],2))     \n            )\n        for gen =1:3\n]\nplot(plt...,legend=false)For those familiar with the plot functions from SDDP.jl, they may also be used here. For example, to plot the active generation from the 3rd generator and the volume of the 1st reservoir for all stages and simulations:plt = SDDP.newplot()\n\nSDDP.addplot!(plt,\n    1:100, 1:params[\"stages\"],\n    (i, t)->results[\"simulations\"][i][\"solution\"][t][\"gen\"][\"3\"][\"pg\"]*results[\"simulations\"][i][\"solution\"][t][\"baseMVA\"],\n    title  = \"Hydro Generation\",\n    ylabel = \"MWh\"\n)\n\nSDDP.addplot!(plt,\n    1:100, 1:params[\"stages\"],\n    (i, t)->results[\"simulations\"][i][\"solution\"][t][\"reservoirs\"][\"1\"][\"volume\"],\n    title  = \"volume\",\n    ylabel = \"L\"\n)\nSDDP.show(plt)"
},

{
    "location": "examples/case3.html#",
    "page": "Case 3",
    "title": "Case 3",
    "category": "page",
    "text": ""
},

{
    "location": "examples/case3_5years.html#",
    "page": "Case 3 - 5 Years",
    "title": "Case 3 - 5 Years",
    "category": "page",
    "text": ""
},

]}
