using Clp

@testset "hydrovalleymodel" begin
    @testset "Test kwargs" begin
        params = set_param( stages                  = 3, 
                            model_constructor_grid  = DCPPowerModel,
                            post_method             = PowerModels.post_opf,
                            optimizer                  = Clp.Optimizer)
        # no hydro data
        @test_throws Exception hydrovalleymodel(Dict("powersystem" => Dict()), params)

    end
end