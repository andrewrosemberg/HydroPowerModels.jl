#module HydroPowerModels

using JuMP, PowerModels, SDDP

using Ipopt, SCS

"""
data é seu dicionario com todos os dados do problem que vc carregou
pode por exemplo incluir o dicionario do power models dentro de ele
então antes de chamar essa funcao aqui vc tem uma outra funcao que
processa os dados no formato json e escreve teu dicionário

param pode ser um conjunto de parametro de solucao....
podem ter outros dados de entrada...
"""
#function hydrovalleymodel(data::Dict, params::Dict)
########################################
#       Parameters
########################################
# Hydro Parameters
nHyd = size(data["hydro"]["Hydrogenerators"],1)
index_hydro = Array{Int64}(nHyd)
max_volume = Array{Float64}(nHyd)
initial_volume = Array{Float64}(nHyd)
production_factor = Array{Float64}(nHyd)
for i=1:nHyd
    index_hydro[i] = data["hydro"]["Hydrogenerators"][i]["index"]
    max_volume[i] = data["hydro"]["Hydrogenerators"][i]["max_volume"]
    initial_volume[i] = data["hydro"]["Hydrogenerators"][i]["initial_volume"]
    production_factor[i] = data["hydro"]["Hydrogenerators"][i]["production_factor"]
end
# Problem Parameters
T = data["hydro"]["number_of_stages"] # number of stages

########################################
#       Init
########################################
nGen = length(collect(keys(data["powersystem"]["gen"]))) - nHyd # number of generators
index_gen = setdiff(map(x->parse(Int64,x),collect(keys(data["powersystem"]["gen"]))),index_hydro)

########################################
#       Model Definition
########################################

m = SDDPModel(
                  sense = :Min,
                 stages = T,
                 solver = IpoptSolver(tol=1e-6),#GurobiSolver(Presolve=0,OutputFlag=0), #ClpSolver(),
        objective_bound = 0.0
                                        ) do sp,t

    pm = PowerModels.build_generic_model(data["powersystem"], ACPPowerModel, PowerModels.post_opf,jump_model=sp)

    @state(sp, 0 <= outgoing_volume <= max_volume, incoming_volume == initial_volume)
    @variables(sp, begin
        thermal_generation[i=1:nGen]        
        hydro_generation[i=1:nHyd]   >= 0
        hydro_turb[i=1:nHyd]         >= 0
        hydro_spill[i=1:nHyd]        >= 0
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

    @constraint(sp, hydro_turb*production_factor == hydro_generation)

    # # Powermodels compatibility
    @constraint(sp,pm.var[:nw][0][:cnd][1][:pg][index_hydro] == hydro_generation)

    for i = 1:nGen
        @constraint(sp,pm.var[:nw][0][:cnd][1][:pg][index_gen[i]] == thermal_generation[i])
    end
    
    # Stage objective
    @stageobjective(sp, sp.obj) #getobjective(sp))
end


########################################
#       Solve
########################################

# solve
status = solve(m, iteration_limit = 60)

#end
#end