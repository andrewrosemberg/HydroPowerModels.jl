using GLPK

@testset "Variables" begin
    @testset "@variable" begin
        sp = Model()
        data = Dict(
            "hydro" => Dict(
                "nHyd" => 4, "Hydrogenerators" => [Dict("max_turn" => 200) for r in 1:4]
            ),
        )

        # inflow            
        HydroPowerModels.variable_inflow(sp, data)
        @test size(sp[:inflow], 1) == 4
        # spillage
        HydroPowerModels.variable_spillage(sp, data)
        @test size(sp[:spill], 1) == 4
        # outflow
        HydroPowerModels.variable_outflow(sp, data)
        @test size(sp[:outflow], 1) == 4
    end

    @testset "@state" begin
        sp = Model()
        data = Dict(
            "hydro" => Dict(
                "nHyd" => 1,
                "Hydrogenerators" => [
                    Dict("min_volume" => 0, "max_volume" => 200, "initial_volume" => 100),
                ],
            ),
        )

        m = SDDP.LinearPolicyGraph(;
            sense=:Min,
            stages=1,
            optimizer=GLPK.Optimizer,
            lower_bound=0.0,
            direct_mode=false,
        ) do sp, t
            HydroPowerModels.variable_volume(sp, data)
            @stageobjective(sp, 0)
        end
        SDDP.train(m; iteration_limit=60)
        # state variable volume
        @test JuMP.lower_bound(m[1].subproblem[:reservoir][1].out) == 0.0
        @test JuMP.upper_bound(m[1].subproblem[:reservoir][1].out) == 200

        # initial value of state variable volume
        JuMP.optimize!(m[1].subproblem)
        @test JuMP.value(m[1].subproblem[:reservoir][1].in) == 100
    end
end
