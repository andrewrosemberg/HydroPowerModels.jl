using JuMP, PowerModels, SDDP
using Ipopt, SCS
using JSON
include("./src/HydroPowerModels.jl")
using HydroPowerModels

########################################
#       Load Case
########################################
#link para o sistema observe que apenas as barras [1, 2, 7, 13, 15, 16, 18, 21, 22, 23] tem geradores
# e que as barras [11, 12, 27, 21, 22, 23 24] não tem carga
#http://orbit.dtu.dk/files/120568114/An_Updated_Version_of_the_IEEE_RTS_24Bus_System_for_Electricty_Market_an....pdf 
data = Dict()
data["powersystem"]= PowerModels.parse_file("./testcases/testcases_hydro/case3.m")
data["hydro"]=JSON.parse(String(read("./testcases/testcases_hydro/case3hydro.json")))
data["hydro"]["Hydrogenerators"][1]["inflow"]= [0.0, 50, 100]

params = Dict()
params["stages"] = 3
params["model_constructor_grid"] = ACPPowerModel
params["post_method"] = PowerModels.post_opf
params["solver"] = IpoptSolver(tol=1e-6)

########################################
#       Build Model
########################################
m = hydrovalleymodel(data, params)

########################################
#       Solve
########################################
status = solve(m, iteration_limit = 60)

# Plot value function
SDDP.plotvaluefunction(m, 2,1, 0.0:200.0; label1="Volume")

########################################
#       Simulation
########################################

simulation_result = simulate(m,
    100,
    [:outgoing_volume, :thermal_generation, :hydro_generation, :hydro_spill]
)

# Plot results
inflows = [0.0, 50.0, 100.0]
plt = SDDP.newplot()
thgen = [3,5,8]
for g in thgen
    SDDP.addplot!(plt,
        1:100, 1:T,
        (i, t)->simulation_result[i][:thermal_generation][t][g],
        title  = "Thermal Generation $g",
        ylabel = "MWh"
    )
end
SDDP.addplot!(plt,
    1:100, 1:T,
    (i, t)->inflows[simulation_result[i][:noise][t]]+50*Int(t==1),
    title  = "Inflows",
    ylabel = "MWh"
)
SDDP.show(plt)

plot(
    SDDP.publicationplot(simulation_result, :outgoing_volume, title="Volume"),
    #SDDP.publicationplot(simulation_result, (data) -> [data[:thermal_generation][t][1] for t=1:T], title="Thermal Generation 1", ylabel = "MWh")    ,
    SDDP.publicationplot(simulation_result, (data) -> [data[:thermal_generation][t][2] for t=1:T], title="Thermal Generation 2", ylabel = "MWh"),
    SDDP.publicationplot(simulation_result, :hydro_generation, title="Hydro Generation"),
    SDDP.publicationplot(simulation_result, :hydro_spill, title="Hydro Spill"),
    SDDP.publicationplot(simulation_result, (data) -> [inflows[data[:noise][t]]+50*Int(t==1) for t=1:T],title  = "Inflows"),
    layout        = (5,1),
    size          = (1500, 800),
    titlefont     = Plots.font("times", 14),
    guidefont     = Plots.font("times", 14),
    tickfont      = Plots.font("times", 14),
    bottom_margin = 9.5Plots.mm,
    left_margin   = 5Plots.mm,
    xlabel        = "Stage\n",
    xticks        = collect(1:T)
)

t1 = ones(100,3)
for i = 1:100, t = 1:T
    t1[i,t] = simulation_result[i][:thermal_generation][t][1]
end

[[simulation_result[i][:thermal_generation][1] for t=1:T] for i = 1:100]
