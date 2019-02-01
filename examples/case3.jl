using JuMP, PowerModels, SDDP
using Ipopt, SCS, Clp

include("./src/HydroPowerModels.jl")
using HydroPowerModels

########################################
#       Load Case
########################################
data = HydroPowerModels.parse_folder("./testcases/testcases_hydro/case3")

# model_constructor_grid may be for example: ACPPowerModel or DCPPowerModel
# solver may be for example: IpoptSolver(tol=1e-6) or ClpSolver()
params = set_param( stages = 3, 
                    model_constructor_grid = DCPPowerModel,
                    post_method = PowerModels.post_opf,
                    solver = ClpSolver())

########################################
#       Build Model
########################################
m = hydrovalleymodel(data, params)

########################################
#       Solve
########################################
status = solve(m, iteration_limit = 60)

results = run_opf(data["powersystem"], DCPPowerModel, ClpSolver())

# Plot value function
SDDP.plotvaluefunction(m, 2,1, 0.0:200.0; label1="Volume")

########################################
#       Simulation
########################################

simulation_result = simulate(m,
    100,
    [:outflow, :spill,:reservoir, Symbol("0_1_pg")]
)

results = HydroPowerModels.build_solution(m)

simulation_result[100][:objective]
simulation_result[100][:stageobjective]

# Plot results
plt = SDDP.newplot()

for g in 1:length(data["powersystem"]["gen"])
    SDDP.addplot!(plt,
        1:100, 1:params["stages"],
        (i, t)->simulation_result[i][Symbol("0_1_pg")][t][g]*100,
        title  = "Thermal Generation $g",
        ylabel = "MWh",
        ymin=0,
        ymax=100
    )
end
SDDP.addplot!(plt,
    1:100, 1:params["stages"],
    (i, t)->simulation_result[i][:outflow][t][1],
    title  = "Outflow",
    ylabel = "L"
)
SDDP.addplot!(plt,
    1:100, 1:params["stages"],
    (i, t)->simulation_result[i][:reservoir][t][1],
    title  = "reservoir",
    ylabel = "L"
)
SDDP.addplot!(plt,
    1:100, 1:params["stages"],
    (i, t)->data["hydro"]["Hydrogenerators"][1]["inflow"][simulation_result[i][:noise][t]]+50*Int(t==1),
    title  = "Inflows",
    ylabel = "MWh"
)
SDDP.show(plt)

using Plots
plotly()
plot(collect(0:10),collect(0:10))

plot(
    SDDP.publicationplot(simulation_result, (data) -> [data[:reservoir][t][1] for t=1:params["stages"]], title="Reservoir"),
    SDDP.publicationplot(simulation_result, (data) -> [data[Symbol("0_1_pg")][t][1]*100 for t=1:params["stages"]], title="Thermal Generation 1", ylabel = "MWh",ylim=[0,100]),
    SDDP.publicationplot(simulation_result, (data) -> [data[Symbol("0_1_pg")][t][2]*100 for t=1:params["stages"]], title="Thermal Generation 2", ylabel = "MWh",ylim=[0,100]),
    SDDP.publicationplot(simulation_result, (data) -> [data[Symbol("0_1_pg")][t][4]*100 for t=1:params["stages"]], title="Thermal Generation 4", ylabel = "MWh",ylim=[0,100]),
    SDDP.publicationplot(simulation_result, (data) -> [data[Symbol("0_1_pg")][t][3]*100 for t=1:params["stages"]], title="Hydro Generation 1", ylabel = "MWh",ylim=[0,100]),
    SDDP.publicationplot(simulation_result, (data) -> [data[:outflow][t][1] for t=1:params["stages"]], title="Outflow"),
    SDDP.publicationplot(simulation_result, (data) -> [data[:spill][t][1] for t=1:params["stages"]], title="Hydro Spill"),
    SDDP.publicationplot(simulation_result, (datasddp) -> [data["hydro"]["Hydrogenerators"][1]["inflow"][datasddp[:noise][t]]+50*Int(t==1) for t=1:params["stages"]],title  = "Inflows"),
    layout        = (4,2),
    size          = (1500, 800),
    titlefont     = Plots.font("times", 14),
    guidefont     = Plots.font("times", 14),
    tickfont      = Plots.font("times", 14),
    bottom_margin = 9.5Plots.mm,
    left_margin   = 5Plots.mm,
    xlabel        = "Stage\n",
    xticks        = collect(1:params["stages"])
)
