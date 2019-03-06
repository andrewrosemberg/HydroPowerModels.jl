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
    "text": "If you want to use the parallel features of HydroPowerModels.jl, you should start Julia with some worker processes (julia -p N), or add by running julia> addprocs(N) in a running Julia session.Once PowerModels, SDDP and a solver (like Clp or Ipopt) are installed, and a case data folder (e.g. \"case3\") has been acquired, an Hydrothermal Multistage Steady-State Power Network Optimization can be executed.First import the necessary packages:using HydroPowerModels\nusing Ipopt, ClpLoad Case by passing the respective folder:data = HydroPowerModels.parse_folder(\"case3_folderpath\")Set Parameters to run, for example, an DC Economic Hydrothermal Dispatch:params = set_param( \n    stages = 3, \n    model_constructor_grid  = DCPPowerModel,\n    post_method             = PowerModels.post_opf,\n    solver                  = ClpSolver())Build the Model and execute the SDDP method:m = hydrothermaloperation(data, params)\n\nstatus = solve(m, iteration_limit = 60)Simulate 100 Instances of the problem:results = simulate_model(m, 100)"
},

{
    "location": "getstarted.html#Getting-Results-1",
    "page": "Manual",
    "title": "Getting Results",
    "category": "section",
    "text": "The simulate_model command in HydroPowerModels returns a detailed execution data in the form of a dictionary.For example, the algorithm\'s runtime and original case data can be accessed with:results[\"solve_time\"]\nresults[\"data\"]Simulation results are found in the simulations array inside the dictionary. For example, information about the 10th simulation, as objective value and sampled noise, may be accessed with:results[\"simulations\"][10]\nresults[\"simulations\"][10][\"objective\"]\nresults[\"simulations\"][10][\"noise\"]The \"solution\" field contains detailed information about the grid solution returned by the PowerModels package, like generation and bus informations, as well as reservoirs menagement information, like outflow and spillage. For example, the active generation of the 2th generator and the outflow of the 1st reservoir on the second stage and first markov state can be inspect by:results[\"simulations\"][1][\"solution\"][2][1][\"gen\"][\"2\"][\"pg\"]\n\nresults[\"simulations\"][1][\"solution\"][2][1][\"reservoirs\"][\"1\"][\"outflow\"]"
},

{
    "location": "getstarted.html#Plotting-Results-1",
    "page": "Manual",
    "title": "Plotting Results",
    "category": "section",
    "text": "In order to plot the results returned by the simulate_model function, you may choose from a variety of methods.The function ’plotresults()’ receives a results dictionary and generates the most common plots for a hydrothermal dispatch: plotresults(results)Otherwise, it helps to organize values of a variable for all simulations and stages into a matrix and then plot using the  \'plotscenarios\'. The \'plotscenarios\' function indicates the median and the following quantiles: [5%, 15%, 25%, 75%, 85%, 95%]. For example, to plot the values of the active generation of the 1st generator:baseMVA =  [results[\"simulations\"][i][\"solution\"][j][\"baseMVA\"] for i=1:100, j=1:12]\'\n\nscen_gen = [results[\"simulations\"][i][\"solution\"][j][\"gen\"][\"$gen\"][\"pg\"] for i=1:100, j=1:12]\'.*baseMVA\n\nplotscenarios(scen_gen, title  = \"Termo Generation 1\",\n                ylabel = \"MWh\",\n                xlabel = \"Stages\",\n                bottom_margin = 10mm,\n                right_margin = 10mm,\n                left_margin = 10mm                \n                )For those familiar with the plot functions from SDDP.jl, they may also be used here. For example, to plot the active generation from the 3rd generator and the volume of the 1st reservoir for all stages and simulations:plt = SDDP.newplot()\n\nSDDP.addplot!(plt,\n    1:100, 1:params[\"stages\"],\n    (i, t)->results[\"simulations\"][i][\"solution\"][t][\"gen\"][\"3\"][\"pg\"]*results[\"simulations\"][i][\"solution\"][t][\"baseMVA\"],\n    title  = \"Hydro Generation\",\n    ylabel = \"MWh\"\n)\n\nSDDP.addplot!(plt,\n    1:100, 1:params[\"stages\"],\n    (i, t)->results[\"simulations\"][i][\"solution\"][t][\"reservoirs\"][\"1\"][\"volume\"],\n    title  = \"volume\",\n    ylabel = \"L\"\n)\nSDDP.show(plt)"
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

{
    "location": "examples/case3_cmp_formulations.html#",
    "page": "Case 3 - Comparing Formulations",
    "title": "Case 3 - Comparing Formulations",
    "category": "page",
    "text": ""
},

{
    "location": "examples/case3_cmp_formulations.html#Example-Case-3-Comparing-Formulations-Year-Planning-1",
    "page": "Case 3 - Comparing Formulations",
    "title": "Example Case 3 Comparing Formulations - Year Planning",
    "category": "section",
    "text": "author : Andrew Rosemberg date : 21th Feb 2019 "
},

{
    "location": "examples/case3_cmp_formulations.html#Introduction-1",
    "page": "Case 3 - Comparing Formulations",
    "title": "Introduction",
    "category": "section",
    "text": "This an example of the HydroPowerModels package for solving a simple stochastic case with the following specifications: - 3 Buses - 3 Lines - 2 Generators - 1 Reservoir and Hydrogenerator \n\n- 3 Scenarios - 12 Stages \n\n- DC,SOC and AC FormulationsSimulation\'s results will be shown in tables to facilitate comparison. Each formulation will have its own table where the columns will be named according to the variables of the problem: - \"[variable type]_[index]_[quantile]\".Variable types in this example:* \"hpg\": Hydro active power generation.\n\n* \"pg\": Termo active power generation.\n\n* \"pf\": Active power flow.\n\n* \"va\": Voltage angle.\n\n* \"pg\": Termo active power generation.\n\n* \"volume\": Reservoir volume."
},

{
    "location": "examples/case3_cmp_formulations.html#Results-1",
    "page": "Case 3 - Comparing Formulations",
    "title": "Results",
    "category": "section",
    "text": ""
},

{
    "location": "examples/case3_cmp_formulations.html#Table-AC-1",
    "page": "Case 3 - Comparing Formulations",
    "title": "Table AC",
    "category": "section",
    "text": "\n<table><tr><th>hpg_1_25.0&#37;</th><th>hpg_1_50.0&#37;</th><th>hpg_1_75.0&#37;</th><th>pf_1_25.0&#37;</th><th>pf_1_50.0&#37;</th><th>pf_1_75.0&#37;</th><th>pf_2_25.0&#37;</th><th>pf_2_50.0&#37;</th><th>pf_2_75.0&#37;</th><th>pf_3_25.0&#37;</th><th>pf_3_50.0&#37;</th><th>pf_3_75.0&#37;</th><th>pg_1_25.0&#37;</th><th>pg_1_50.0&#37;</th><th>pg_1_75.0&#37;</th><th>pg_2_25.0&#37;</th><th>pg_2_50.0&#37;</th><th>pg_2_75.0&#37;</th><th>va_1_25.0&#37;</th><th>va_1_50.0&#37;</th><th>va_1_75.0&#37;</th><th>va_2_25.0&#37;</th><th>va_2_50.0&#37;</th><th>va_2_75.0&#37;</th><th>va_3_25.0&#37;</th><th>va_3_50.0&#37;</th><th>va_3_75.0&#37;</th><th>volume_1_25.0&#37;</th><th>volume_1_50.0&#37;</th><th>volume_1_75.0&#37;</th></tr><tr><td>42.0</td><td>42.0</td><td>65.0</td><td>39.0</td><td>39.0</td><td>46.0</td><td>-62.0</td><td>-62.0</td><td>-55.0</td><td>3.1</td><td>3.1</td><td>19.0</td><td>37.0</td><td>60.0</td><td>60.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-2.8999999999999997e-35</td><td>0.0</td><td>3.5999999999999997e-35</td><td>-0.16</td><td>-0.026</td><td>-0.026</td><td>-0.41</td><td>-0.41</td><td>-0.4</td><td>88.0</td><td>88.0</td><td>100.0</td></tr><tr><td>42.0</td><td>43.0</td><td>52.0</td><td>39.0</td><td>39.0</td><td>42.0</td><td>-62.0</td><td>-62.0</td><td>-59.0</td><td>3.1</td><td>3.9</td><td>9.6</td><td>51.0</td><td>59.0</td><td>60.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-1.9999999999999997e-31</td><td>0.0</td><td>5.7e-32</td><td>-0.083</td><td>-0.033</td><td>-0.026</td><td>-0.41</td><td>-0.41</td><td>-0.4</td><td>80.0</td><td>110.0</td><td>120.0</td></tr><tr><td>42.0</td><td>42.0</td><td>48.0</td><td>39.0</td><td>39.0</td><td>41.0</td><td>-62.0</td><td>-62.0</td><td>-60.0</td><td>3.1</td><td>3.1</td><td>7.5</td><td>54.0</td><td>60.0</td><td>60.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-1.5e-31</td><td>0.0</td><td>6.6e-35</td><td>-0.065</td><td>-0.026</td><td>-0.026</td><td>-0.41</td><td>-0.41</td><td>-0.39</td><td>97.0</td><td>120.0</td><td>140.0</td></tr><tr><td>42.0</td><td>45.0</td><td>51.0</td><td>39.0</td><td>40.0</td><td>42.0</td><td>-62.0</td><td>-61.0</td><td>-59.0</td><td>3.1</td><td>5.4</td><td>9.0</td><td>51.0</td><td>57.0</td><td>60.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-3.3999999999999997e-31</td><td>0.0</td><td>3.1999999999999997e-31</td><td>-0.079</td><td>-0.047</td><td>-0.026</td><td>-0.41</td><td>-0.4</td><td>-0.39</td><td>100.0</td><td>120.0</td><td>130.0</td></tr><tr><td>42.0</td><td>45.0</td><td>51.0</td><td>39.0</td><td>40.0</td><td>42.0</td><td>-62.0</td><td>-61.0</td><td>-59.0</td><td>3.1</td><td>5.0</td><td>9.5</td><td>51.0</td><td>57.0</td><td>60.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-3.0e-33</td><td>0.0</td><td>3.7e-32</td><td>-0.082</td><td>-0.043</td><td>-0.026</td><td>-0.41</td><td>-0.4</td><td>-0.39</td><td>93.0</td><td>110.0</td><td>120.0</td></tr><tr><td>42.0</td><td>47.0</td><td>53.0</td><td>39.0</td><td>40.0</td><td>42.0</td><td>-62.0</td><td>-61.0</td><td>-59.0</td><td>3.1</td><td>6.2</td><td>11.0</td><td>49.0</td><td>56.0</td><td>60.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-1.8e-32</td><td>0.0</td><td>1.6999999999999999e-35</td><td>-0.094</td><td>-0.055</td><td>-0.026</td><td>-0.41</td><td>-0.39</td><td>-0.39</td><td>76.0</td><td>89.0</td><td>95.0</td></tr><tr><td>42.0</td><td>47.0</td><td>53.0</td><td>39.0</td><td>40.0</td><td>42.0</td><td>-62.0</td><td>-61.0</td><td>-59.0</td><td>3.1</td><td>6.2</td><td>10.0</td><td>49.0</td><td>56.0</td><td>60.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-2.6000000000000003e-32</td><td>0.0</td><td>5.5e-34</td><td>-0.089</td><td>-0.054</td><td>-0.026</td><td>-0.41</td><td>-0.4</td><td>-0.39</td><td>53.0</td><td>61.0</td><td>67.0</td></tr><tr><td>42.0</td><td>50.0</td><td>58.0</td><td>39.0</td><td>41.0</td><td>44.0</td><td>-62.0</td><td>-60.0</td><td>-57.0</td><td>3.1</td><td>8.7</td><td>14.0</td><td>44.0</td><td>52.0</td><td>60.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-4.7e-36</td><td>0.0</td><td>2.8e-36</td><td>-0.12</td><td>-0.076</td><td>-0.026</td><td>-0.41</td><td>-0.4</td><td>-0.39</td><td>33.0</td><td>40.0</td><td>40.0</td></tr><tr><td>42.0</td><td>59.0</td><td>68.0</td><td>39.0</td><td>44.0</td><td>48.0</td><td>-62.0</td><td>-57.0</td><td>-54.0</td><td>3.1</td><td>15.0</td><td>21.0</td><td>34.0</td><td>43.0</td><td>60.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-1.2e-36</td><td>0.0</td><td>7.100000000000001e-36</td><td>-0.19</td><td>-0.13</td><td>-0.026</td><td>-0.45</td><td>-0.41</td><td>-0.39</td><td>17.0</td><td>20.0</td><td>29.0</td></tr><tr><td>42.0</td><td>58.0</td><td>71.0</td><td>39.0</td><td>44.0</td><td>49.0</td><td>-62.0</td><td>-57.0</td><td>-53.0</td><td>3.1</td><td>14.0</td><td>22.0</td><td>31.0</td><td>44.0</td><td>60.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-3.3e-39</td><td>0.0</td><td>3.9e-35</td><td>-0.23</td><td>-0.12</td><td>-0.026</td><td>-0.51</td><td>-0.41</td><td>-0.39</td><td>12.0</td><td>12.0</td><td>12.0</td></tr><tr><td>56.0</td><td>68.0</td><td>74.0</td><td>43.0</td><td>48.0</td><td>51.0</td><td>-58.0</td><td>-54.0</td><td>-51.0</td><td>13.0</td><td>21.0</td><td>23.0</td><td>29.0</td><td>34.0</td><td>46.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-3.7000000000000003e-34</td><td>0.0</td><td>1.9e-33</td><td>-0.29</td><td>-0.19</td><td>-0.11</td><td>-0.59</td><td>-0.45</td><td>-0.41</td><td>4.0</td><td>4.0</td><td>28.0</td></tr><tr><td>63.0</td><td>74.0</td><td>74.0</td><td>46.0</td><td>51.0</td><td>51.0</td><td>-56.0</td><td>-51.0</td><td>-51.0</td><td>18.0</td><td>23.0</td><td>23.0</td><td>29.0</td><td>29.0</td><td>39.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-5.7e-33</td><td>0.0</td><td>1.5e-33</td><td>-0.29</td><td>-0.29</td><td>-0.15</td><td>-0.59</td><td>-0.59</td><td>-0.4</td><td>4.5e-7</td><td>3.3e-5</td><td>16.0</td></tr></table>\n \n"
},

{
    "location": "examples/case3_cmp_formulations.html#Table-DC-1",
    "page": "Case 3 - Comparing Formulations",
    "title": "Table DC",
    "category": "section",
    "text": "\n<table><tr><th>hpg_1_25.0&#37;</th><th>hpg_1_50.0&#37;</th><th>hpg_1_75.0&#37;</th><th>pf_1_25.0&#37;</th><th>pf_1_50.0&#37;</th><th>pf_1_75.0&#37;</th><th>pf_2_25.0&#37;</th><th>pf_2_50.0&#37;</th><th>pf_2_75.0&#37;</th><th>pf_3_25.0&#37;</th><th>pf_3_50.0&#37;</th><th>pf_3_75.0&#37;</th><th>pg_1_25.0&#37;</th><th>pg_1_50.0&#37;</th><th>pg_1_75.0&#37;</th><th>pg_2_25.0&#37;</th><th>pg_2_50.0&#37;</th><th>pg_2_75.0&#37;</th><th>va_1_25.0&#37;</th><th>va_1_50.0&#37;</th><th>va_1_75.0&#37;</th><th>va_2_25.0&#37;</th><th>va_2_50.0&#37;</th><th>va_2_75.0&#37;</th><th>va_3_25.0&#37;</th><th>va_3_50.0&#37;</th><th>va_3_75.0&#37;</th><th>volume_1_25.0&#37;</th><th>volume_1_50.0&#37;</th><th>volume_1_75.0&#37;</th></tr><tr><td>38.0</td><td>38.0</td><td>65.0</td><td>35.0</td><td>35.0</td><td>46.0</td><td>-65.0</td><td>-65.0</td><td>-54.0</td><td>2.6</td><td>2.6</td><td>19.0</td><td>35.0</td><td>62.0</td><td>62.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-0.19</td><td>-0.026</td><td>-0.026</td><td>-0.46</td><td>-0.35</td><td>-0.35</td><td>92.0</td><td>92.0</td><td>100.0</td></tr><tr><td>38.0</td><td>38.0</td><td>40.0</td><td>35.0</td><td>35.0</td><td>36.0</td><td>-65.0</td><td>-65.0</td><td>-64.0</td><td>2.6</td><td>2.6</td><td>4.0</td><td>60.0</td><td>62.0</td><td>62.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-0.04</td><td>-0.026</td><td>-0.026</td><td>-0.36</td><td>-0.35</td><td>-0.35</td><td>90.0</td><td>120.0</td><td>130.0</td></tr><tr><td>38.0</td><td>38.0</td><td>45.0</td><td>35.0</td><td>35.0</td><td>38.0</td><td>-65.0</td><td>-65.0</td><td>-62.0</td><td>2.6</td><td>2.6</td><td>7.0</td><td>55.0</td><td>62.0</td><td>62.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-0.07</td><td>-0.026</td><td>-0.026</td><td>-0.38</td><td>-0.35</td><td>-0.35</td><td>110.0</td><td>130.0</td><td>150.0</td></tr><tr><td>38.0</td><td>38.0</td><td>52.0</td><td>35.0</td><td>35.0</td><td>41.0</td><td>-65.0</td><td>-65.0</td><td>-59.0</td><td>2.6</td><td>2.6</td><td>11.0</td><td>48.0</td><td>62.0</td><td>62.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-0.11</td><td>-0.026</td><td>-0.026</td><td>-0.41</td><td>-0.35</td><td>-0.35</td><td>120.0</td><td>130.0</td><td>150.0</td></tr><tr><td>38.0</td><td>47.0</td><td>62.0</td><td>35.0</td><td>39.0</td><td>45.0</td><td>-65.0</td><td>-61.0</td><td>-55.0</td><td>2.6</td><td>8.3</td><td>17.0</td><td>38.0</td><td>53.0</td><td>62.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-0.17</td><td>-0.083</td><td>-0.026</td><td>-0.45</td><td>-0.39</td><td>-0.35</td><td>110.0</td><td>110.0</td><td>130.0</td></tr><tr><td>41.0</td><td>53.0</td><td>68.0</td><td>36.0</td><td>41.0</td><td>47.0</td><td>-64.0</td><td>-59.0</td><td>-53.0</td><td>4.6</td><td>12.0</td><td>21.0</td><td>32.0</td><td>47.0</td><td>59.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-0.21</td><td>-0.12</td><td>-0.046</td><td>-0.47</td><td>-0.41</td><td>-0.37</td><td>85.0</td><td>85.0</td><td>85.0</td></tr><tr><td>38.0</td><td>48.0</td><td>58.0</td><td>35.0</td><td>39.0</td><td>43.0</td><td>-65.0</td><td>-61.0</td><td>-57.0</td><td>2.6</td><td>8.6</td><td>15.0</td><td>42.0</td><td>52.0</td><td>62.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-0.15</td><td>-0.086</td><td>-0.026</td><td>-0.43</td><td>-0.39</td><td>-0.35</td><td>58.0</td><td>58.0</td><td>58.0</td></tr><tr><td>38.0</td><td>53.0</td><td>68.0</td><td>35.0</td><td>41.0</td><td>47.0</td><td>-65.0</td><td>-59.0</td><td>-53.0</td><td>2.6</td><td>12.0</td><td>21.0</td><td>32.0</td><td>47.0</td><td>62.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-0.21</td><td>-0.12</td><td>-0.026</td><td>-0.47</td><td>-0.41</td><td>-0.35</td><td>35.0</td><td>35.0</td><td>35.0</td></tr><tr><td>38.0</td><td>55.0</td><td>75.0</td><td>35.0</td><td>42.0</td><td>50.0</td><td>-65.0</td><td>-58.0</td><td>-50.0</td><td>2.6</td><td>13.0</td><td>25.0</td><td>25.0</td><td>45.0</td><td>62.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-0.25</td><td>-0.13</td><td>-0.026</td><td>-0.5</td><td>-0.42</td><td>-0.35</td><td>17.0</td><td>20.0</td><td>20.0</td></tr><tr><td>38.0</td><td>62.0</td><td>75.0</td><td>35.0</td><td>45.0</td><td>50.0</td><td>-65.0</td><td>-55.0</td><td>-50.0</td><td>2.6</td><td>17.0</td><td>25.0</td><td>25.0</td><td>38.0</td><td>62.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-0.25</td><td>-0.17</td><td>-0.026</td><td>-0.5</td><td>-0.45</td><td>-0.35</td><td>7.5</td><td>7.6</td><td>17.0</td></tr><tr><td>61.0</td><td>65.0</td><td>75.0</td><td>44.0</td><td>46.0</td><td>50.0</td><td>-56.0</td><td>-54.0</td><td>-50.0</td><td>17.0</td><td>19.0</td><td>25.0</td><td>25.0</td><td>35.0</td><td>39.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-0.25</td><td>-0.19</td><td>-0.17</td><td>-0.5</td><td>-0.46</td><td>-0.45</td><td>2.6</td><td>2.6</td><td>23.0</td></tr><tr><td>58.0</td><td>73.0</td><td>75.0</td><td>43.0</td><td>49.0</td><td>50.0</td><td>-57.0</td><td>-51.0</td><td>-50.0</td><td>15.0</td><td>24.0</td><td>25.0</td><td>25.0</td><td>27.0</td><td>42.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>-0.25</td><td>-0.24</td><td>-0.15</td><td>-0.5</td><td>-0.49</td><td>-0.43</td><td>0.0</td><td>0.0</td><td>30.0</td></tr></table>\n \n"
},

{
    "location": "examples/case3_cmp_formulations.html#Table-SOC-1",
    "page": "Case 3 - Comparing Formulations",
    "title": "Table SOC",
    "category": "section",
    "text": "\n<table><tr><th>hpg_1_25.0&#37;</th><th>hpg_1_50.0&#37;</th><th>hpg_1_75.0&#37;</th><th>pf_1_25.0&#37;</th><th>pf_1_50.0&#37;</th><th>pf_1_75.0&#37;</th><th>pf_2_25.0&#37;</th><th>pf_2_50.0&#37;</th><th>pf_2_75.0&#37;</th><th>pf_3_25.0&#37;</th><th>pf_3_50.0&#37;</th><th>pf_3_75.0&#37;</th><th>pg_1_25.0&#37;</th><th>pg_1_50.0&#37;</th><th>pg_1_75.0&#37;</th><th>pg_2_25.0&#37;</th><th>pg_2_50.0&#37;</th><th>pg_2_75.0&#37;</th><th>volume_1_25.0&#37;</th><th>volume_1_50.0&#37;</th><th>volume_1_75.0&#37;</th></tr><tr><td>53.0</td><td>53.0</td><td>65.0</td><td>47.0</td><td>47.0</td><td>47.0</td><td>-54.0</td><td>-54.0</td><td>-54.0</td><td>6.3</td><td>6.3</td><td>18.0</td><td>37.0</td><td>49.0</td><td>49.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>77.0</td><td>77.0</td><td>110.0</td></tr><tr><td>47.0</td><td>52.0</td><td>60.0</td><td>47.0</td><td>47.0</td><td>47.0</td><td>-54.0</td><td>-54.0</td><td>-54.0</td><td>0.47</td><td>5.3</td><td>13.0</td><td>42.0</td><td>50.0</td><td>54.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>65.0</td><td>95.0</td><td>120.0</td></tr><tr><td>48.0</td><td>52.0</td><td>56.0</td><td>47.0</td><td>47.0</td><td>47.0</td><td>-54.0</td><td>-54.0</td><td>-54.0</td><td>0.68</td><td>5.2</td><td>9.5</td><td>45.0</td><td>50.0</td><td>54.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>77.0</td><td>99.0</td><td>120.0</td></tr><tr><td>48.0</td><td>52.0</td><td>56.0</td><td>47.0</td><td>47.0</td><td>47.0</td><td>-54.0</td><td>-54.0</td><td>-54.0</td><td>0.82</td><td>5.0</td><td>9.3</td><td>46.0</td><td>50.0</td><td>54.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>79.0</td><td>97.0</td><td>110.0</td></tr><tr><td>47.0</td><td>51.0</td><td>56.0</td><td>47.0</td><td>47.0</td><td>47.0</td><td>-54.0</td><td>-54.0</td><td>-54.0</td><td>0.41</td><td>4.2</td><td>8.6</td><td>46.0</td><td>51.0</td><td>54.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>68.0</td><td>81.0</td><td>97.0</td></tr><tr><td>47.0</td><td>50.0</td><td>56.0</td><td>47.0</td><td>47.0</td><td>47.0</td><td>-54.0</td><td>-54.0</td><td>-54.0</td><td>0.051</td><td>3.4</td><td>8.9</td><td>46.0</td><td>52.0</td><td>55.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>49.0</td><td>61.0</td><td>74.0</td></tr><tr><td>45.0</td><td>51.0</td><td>55.0</td><td>47.0</td><td>47.0</td><td>47.0</td><td>-54.0</td><td>-54.0</td><td>-54.0</td><td>-2.3</td><td>4.2</td><td>7.7</td><td>47.0</td><td>51.0</td><td>57.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>23.0</td><td>32.0</td><td>37.0</td></tr><tr><td>42.0</td><td>51.0</td><td>58.0</td><td>47.0</td><td>47.0</td><td>47.0</td><td>-54.0</td><td>-54.0</td><td>-54.0</td><td>-5.2</td><td>3.6</td><td>11.0</td><td>43.0</td><td>51.0</td><td>60.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>8.9</td><td>9.7</td><td>14.0</td></tr><tr><td>34.0</td><td>50.0</td><td>65.0</td><td>46.0</td><td>47.0</td><td>47.0</td><td>-55.0</td><td>-54.0</td><td>-54.0</td><td>-13.0</td><td>2.7</td><td>18.0</td><td>37.0</td><td>52.0</td><td>68.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>3.4e-5</td><td>0.00021</td><td>4.4</td></tr><tr><td>30.0</td><td>50.0</td><td>75.0</td><td>46.0</td><td>47.0</td><td>56.0</td><td>-55.0</td><td>-54.0</td><td>-46.0</td><td>-16.0</td><td>3.0</td><td>19.0</td><td>27.0</td><td>52.0</td><td>72.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>2.7e-6</td><td>2.8e-6</td><td>4.3e-6</td></tr><tr><td>60.0</td><td>60.0</td><td>80.0</td><td>47.0</td><td>47.0</td><td>61.0</td><td>-54.0</td><td>-54.0</td><td>-41.0</td><td>13.0</td><td>13.0</td><td>19.0</td><td>23.0</td><td>42.0</td><td>42.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>1.5e-6</td><td>1.5e-6</td><td>10.0</td></tr><tr><td>45.0</td><td>70.0</td><td>80.0</td><td>47.0</td><td>51.0</td><td>61.0</td><td>-54.0</td><td>-50.0</td><td>-41.0</td><td>-2.0</td><td>19.0</td><td>19.0</td><td>23.0</td><td>32.0</td><td>57.0</td><td>0.0</td><td>0.0</td><td>0.0</td><td>4.4e-7</td><td>4.6e-7</td><td>12.0</td></tr></table>\n \n"
},

]}
