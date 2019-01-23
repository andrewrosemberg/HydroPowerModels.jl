using JuMP, PowerModels, SDDP
using Plots
plotly()
plot(collect(0:10),collect(0:10))

using Ipopt, SCS

########################################
#       Load Case
########################################

#link para o sistema observe que apenas as barras [1, 2, 7, 13, 15, 16, 18, 21, 22, 23] tem geradores
# e que as barras [11, 12, 27, 21, 22, 23 24] não tem carga
#http://orbit.dtu.dk/files/120568114/An_Updated_Version_of_the_IEEE_RTS_24Bus_System_for_Electricty_Market_an....pdf 
case = PowerModels.parse_file("./testcases/testcases_hydro/case3.m")

case_hydro = JSON.parse(String(read("./testcases/testcases_hydro/case3hydro.json")))

########################################
#       Parameters
########################################
# Hydro Parameters
index_hydro = case_hydro["Hydrogenerators"][1]["index"]
max_volume = case_hydro["Hydrogenerators"][1]["max_volume"]
initial_volume = case_hydro["Hydrogenerators"][1]["initial_volume"]
production_factor = case_hydro["Hydrogenerators"][1]["production_factor"]

# Problem Parameters
T = 3 # number of stages

########################################
#       Init
########################################

nGen = length(collect(keys(case["gen"]))) - 1 # number of generators
index_gen = setdiff(map(x->parse(Int64,x),collect(keys(case["gen"]))),index_hydro)

########################################
#       Model Definition
########################################

m = SDDPModel(
                  sense = :Min,
                 stages = T,
                 solver = IpoptSolver(tol=1e-6),#GurobiSolver(Presolve=0,OutputFlag=0), #ClpSolver(),
        objective_bound = 0.0
                                        ) do sp,t

    pm = PowerModels.build_generic_model(case, ACPPowerModel, PowerModels.post_opf,jump_model=sp)

    @state(sp, 0 <= outgoing_volume <= max_volume, incoming_volume == initial_volume)
    @variables(sp, begin
        thermal_generation[i=1:nGen]        
        hydro_generation   >= 0
        hydro_turb         >= 0
        hydro_spill        >= 0
    end)

    if t > 1 # in future stages random inflows
        @rhsnoise(sp, inflow = [0.0, 50, 100], #inflow_hist[:,t],
        outgoing_volume - (incoming_volume - hydro_turb - hydro_spill) == inflow)

        # setnoiseprobability!(sp, [1/6, 1/3, 0.5]) # wet climate state 
        #setnoiseprobability!(sp, [3/6, 2/6, 1/6]) # dry climate state
    
    else # in the first stage deterministic inflow
        @rhsnoise(sp, inflow = [50.0],
        outgoing_volume - (incoming_volume - hydro_turb - hydro_spill) == inflow)
    end

    @constraint(sp,hydro_turb*production_factor == hydro_generation)

    # # Powermodels compatibility
    @constraint(sp,pm.var[:nw][0][:cnd][1][:pg][index_hydro] == hydro_generation)

    for i = 1:nGen
        @constraint(sp,pm.var[:nw][0][:cnd][1][:pg][index_gen[i]] == thermal_generation[i])
    end
    
    # Stage objective
    @stageobjective(sp, sp.obj) #getobjective(sp))
end

print(m.stages[1].subproblems[1])

########################################
#       Solve
########################################
# solve
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
