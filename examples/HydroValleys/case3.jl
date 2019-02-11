using JuMP, PowerModels, SDDP
using Ipopt, SCS, Clp
using HydroPowerModels

########################################
#       Load Case
########################################
data = HydroPowerModels.parse_folder("./testcases/testcases_hydro/case3")

# model_constructor_grid may be for example: ACPPowerModel or DCPPowerModel
# solver may be for example: IpoptSolver(tol=1e-6) or ClpSolver()
params = set_param( stages = 3, 
                    model_constructor_grid  = DCPPowerModel,
                    post_method             = PowerModels.post_opf,
                    solver                  = ClpSolver())

########################################
#       Build Model
########################################
m = hydrovalleymodel(data, params)

########################################
#       Solve
########################################
status = solve(m, iteration_limit = 60)

########################################
#       Simulation
########################################

results = simulate_model(m, 100)
