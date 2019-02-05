using Clp

@testset "IO" begin
    @testset "Input parameters" begin
        solver = ClpSolver()
        params = set_param( stages                  = 3, 
                            model_constructor_grid  = DCPPowerModel,
                            post_method             = PowerModels.post_opf,
                            solver                  = solver)
        # no hydro data
        @test params["stages"] == 3
        @test params["post_method"] == PowerModels.post_opf
        @test params["solver"] == solver
        @test params["model_constructor_grid"] == DCPPowerModel

    end
end