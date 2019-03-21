using Clp

@testset "Variables" begin
    @testset "@variable" begin
        sp = Model()
        data = Dict("hydro" => Dict("nHyd" => 4))     
        # inflow            
        HydroPowerModels.variable_inflow(sp, data)
        @test size(sp[:inflow],1) == 4
        # spillage
        HydroPowerModels.variable_spillage(sp, data)
        @test size(sp[:spill],1) == 4
        # outflow
        HydroPowerModels.variable_outflow(sp, data)
        @test size(sp[:outflow],1) == 4
    end

    @testset "@state" begin
        sp = Model()
        data = Dict("hydro" => Dict("nHyd" => 1,
        "Hydrogenerators" => [Dict("min_volume" => 0, "max_volume" => 200, "initial_volume" => 100)]))
         
        m = SDDPModel(
            sense   = :Min,
            stages  = 1,
            optimizer = Clp.Optimizer,
            objective_bound = 0.0
                                    ) do sp,t
            HydroPowerModels.variable_volume(sp, data)
        end
        # state variable volume
        @test JuMP.getlowerbound(m.stages[1].subproblems[1][:reservoir].out[1]) == 0.0
        @test JuMP.getupperbound(m.stages[1].subproblems[1][:reservoir].out[1]) == 200

        # initial value of state variable volume
        JuMP.solve(m.stages[1].subproblems[1])
        @test JuMP.getvalue(m.stages[1].subproblems[1][:reservoir].in[1]) == 100
    end

end