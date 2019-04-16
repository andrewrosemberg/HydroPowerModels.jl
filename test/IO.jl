using Clp

@testset "IO" begin
    @testset "Input parameters" begin
        optimizer = Clp.Optimizer
        params = create_param( stages                  = 3, 
                            model_constructor_grid  = DCPPowerModel,
                            post_method             = PowerModels.post_opf,
                            optimizer                  = optimizer)
        # no hydro data
        @test params["stages"] == 3
        @test params["post_method"] == PowerModels.post_opf
        @test params["optimizer"] == optimizer
        @test params["model_constructor_grid"] == DCPPowerModel

    end
end