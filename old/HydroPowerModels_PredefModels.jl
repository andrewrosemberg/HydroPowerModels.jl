using JuMP, PowerModels, SDDP, Gurobi
include("./matpower_parser.jl")

using Plots
plotly()

plot(collect(0:10),collect(0:10))

#link para o sistema observe que apenas as barras [1, 2, 7, 13, 15, 16, 18, 21, 22, 23] tem geradores
# e que as barras [11, 12, 27, 21, 22, 23 24] não tem carga
#http://orbit.dtu.dk/files/120568114/An_Updated_Version_of_the_IEEE_RTS_24Bus_System_for_Electricty_Market_an....pdf 
case = PowerModels.parse_file("./testcases/testcases_hydro/case3.m")

using Ipopt, SCS

########################################
#       PowerModels
########################################
#? Change case
index_hydro = 1
case["gen"]["$index_hydro"]["cost"] = [0.,0.,0.]
case["gen"]["$index_hydro"]["startup"] = 0.
#? Extract Powermodel and Jump model
pm = PowerModels.build_generic_model(case, ACPPowerModel, PowerModels.post_opf);
m_pm = pm.model
print(m_pm)
getobjective(m_pm)
case["load"]["3"]

m_pm.obj
#? run no hydro
opf_pm = run_opf(case, DCPPowerModel, IpoptSolver(tol=1e-6))
opf_pm["solution"]["gen"]["1"]

# m.linconstr[1]
# m.linearterms
# JuMP.conDict
# JuMP.getconstraint(m,:kcl)
# @variable(m, lowerbound = 0,upperbound =1, objective = 0, inconstraints = [m.linconstr[1]], coefficients = [1.0])
# m[:kcl_p]

########################################
#       SDDP
########################################
# Parameters
T = 3 # number of stages
nGen = length(collect(keys(case["gen"]))) - 1 # number of generators
index_gen = setdiff(map(x->parse(Int64,x),collect(keys(case["gen"]))),index_hydro)

#definemodel
pms = [PowerModels.build_generic_model(case, ACPPowerModel, PowerModels.post_opf) for t=1:T];

m = SDDPModel(
                  sense = :Min,
                 stages = T,
                 predefined_subproblems = [[pms[t].model] for t=1:T],
                 solver = IpoptSolver(tol=1e-6),#GurobiSolver(Presolve=0,OutputFlag=0), #ClpSolver(),
        objective_bound = 0.0
                                        ) do sp,t

    @state(sp, 0 <= outgoing_volume <= 200, incoming_volume == 200)
    @variables(sp, begin
        thermal_generation[i=1:nGen]        
        hydro_generation   >= 0
        hydro_spill        >= 0
    end)

    if t > 1 # in future stages random inflows
        @rhsnoise(sp, inflow = [0.0, 50, 100], #inflow_hist[:,t],
        outgoing_volume - (incoming_volume - hydro_generation - hydro_spill) == inflow)

        # setnoiseprobability!(sp, [1/6, 1/3, 0.5]) # wet climate state 
        #setnoiseprobability!(sp, [3/6, 2/6, 1/6]) # dry climate state
    
    else # in the first stage deterministic inflow
        @rhsnoise(sp, inflow = [50.0],
        outgoing_volume - (incoming_volume - hydro_generation - hydro_spill) == inflow)
    end


    # # Powermodels compatibility
    @constraint(sp,pms[t].var[:nw][0][:cnd][1][:pg][index_hydro] == hydro_generation)

    for i = 1:nGen
        @constraint(sp,pms[t].var[:nw][0][:cnd][1][:pg][index_gen[i]] == thermal_generation[i])
    end
    
    # Stage objective
    @stageobjective(sp, sp.obj) #getobjective(sp))
end

status = solve(m, iteration_limit = 40)

SDDP.plotvaluefunction(m, 2,1, 0.0:200.0; label1="Volume")

simulation_result = simulate(m,
    100,
    [:outgoing_volume, :thermal_generation, :hydro_generation, :hydro_spill]
)

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

# # Plot results
# plt = SDDP.newplot()

# for g in 1:length(data["powersystem"]["gen"])
#     SDDP.addplot!(plt,
#         1:100, 1:params["stages"],
#         (i, t)->simulation_result[i][Symbol("0_1_pg")][t][g]*100,
#         title  = "Thermal Generation $g",
#         ylabel = "MWh",
#         ymin=0,
#         ymax=100
#     )
# end
# SDDP.addplot!(plt,
#     1:100, 1:params["stages"],
#     (i, t)->simulation_result[i][:outflow][t][1],
#     title  = "Outflow",
#     ylabel = "L"
# )
# SDDP.addplot!(plt,
#     1:100, 1:params["stages"],
#     (i, t)->simulation_result[i][:reservoir][t][1],
#     title  = "reservoir",
#     ylabel = "L"
# )
# SDDP.addplot!(plt,
#     1:100, 1:params["stages"],
#     (i, t)->data["hydro"]["Hydrogenerators"][1]["inflow"][simulation_result[i][:noise][t]]+50*Int(t==1),
#     title  = "Inflows",
#     ylabel = "MWh"
# )
# SDDP.show(plt)

# using Plots
# plotly()
# plot(collect(0:10),collect(0:10))

# plot(
#     SDDP.publicationplot(simulation_result, (data) -> [data[:reservoir][t][1] for t=1:params["stages"]], title="Reservoir"),
#     SDDP.publicationplot(simulation_result, (data) -> [data[Symbol("0_1_pg")][t][1]*100 for t=1:params["stages"]], title="Thermal Generation 1", ylabel = "MWh",ylim=[0,100]),
#     SDDP.publicationplot(simulation_result, (data) -> [data[Symbol("0_1_pg")][t][2]*100 for t=1:params["stages"]], title="Thermal Generation 2", ylabel = "MWh",ylim=[0,100]),
#     SDDP.publicationplot(simulation_result, (data) -> [data[Symbol("0_1_pg")][t][4]*100 for t=1:params["stages"]], title="Thermal Generation 4", ylabel = "MWh",ylim=[0,100]),
#     SDDP.publicationplot(simulation_result, (data) -> [data[Symbol("0_1_pg")][t][3]*100 for t=1:params["stages"]], title="Hydro Generation 1", ylabel = "MWh",ylim=[0,100]),
#     SDDP.publicationplot(simulation_result, (data) -> [data[:outflow][t][1] for t=1:params["stages"]], title="Outflow"),
#     SDDP.publicationplot(simulation_result, (data) -> [data[:spill][t][1] for t=1:params["stages"]], title="Hydro Spill"),
#     SDDP.publicationplot(simulation_result, (datasddp) -> [data["hydro"]["Hydrogenerators"][1]["inflow"][datasddp[:noise][t]]+50*Int(t==1) for t=1:params["stages"]],title  = "Inflows"),
#     layout        = (4,2),
#     size          = (1500, 800),
#     titlefont     = Plots.font("times", 14),
#     guidefont     = Plots.font("times", 14),
#     tickfont      = Plots.font("times", 14),
#     bottom_margin = 9.5Plots.mm,
#     left_margin   = 5Plots.mm,
#     xlabel        = "Stage\n",
#     xticks        = collect(1:params["stages"])
# )

