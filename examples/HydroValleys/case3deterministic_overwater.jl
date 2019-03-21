using Clp
using HydroPowerModels

########################################
#       Load Case
########################################
testcases_dir = joinpath(dirname(dirname(dirname(@__FILE__))), "testcases")
data = HydroPowerModels.parse_folder(joinpath(testcases_dir,"case3deterministic_overwater"))

########################################
#       Set Parameters
########################################
# model_constructor_grid may be for example: ACPPowerModel or DCPPowerModel
# optimizer may be for example: IpoptSolver(tol=1e-6) or Clp.Optimizer
params = set_param( stages = 3, 
                    model_constructor_grid  = DCPPowerModel,
                    post_method             = PowerModels.post_opf,
                    optimizer                  = Clp.Optimizer)

########################################
#       Build Model
########################################
m = hydrothermaloperation(data, params)

########################################
#       Solve
########################################
status = solve(m, iteration_limit = 60)

########################################
#       Simulation
########################################
results = simulate_model(m, 1)

########################################
#       Test
########################################
# objective
@test isapprox(results["simulations"][1]["objective"],1504.17, atol=1e-2)

# solution grid
@test results["simulations"][1]["solution"][1]["gen"]["4"]["pg"] == 0
@test isapprox(results["simulations"][1]["solution"][1]["gen"]["2"]["pg"],0, atol=1e-2)
@test isapprox(results["simulations"][1]["solution"][1]["gen"]["3"]["pg"],0.74, atol=1e-2)
@test isapprox(results["simulations"][1]["solution"][1]["gen"]["1"]["pg"],0.25, atol=1e-2)

# solution reservoirs
@test isapprox(results["simulations"][1]["solution"][1]["reservoirs"]["1"]["spill"],325.07, atol=1e-2)
