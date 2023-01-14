using GLPK

@testset "hydrovalleymodel" begin
    @testset "Test kwargs" begin
        params = create_param(;
            stages=3,
            model_constructor_grid=DCPPowerModel,
            post_method=PowerModels.build_opf,
            optimizer=GLPK.Optimizer,
        )
        # no hydro data
        @test_throws Exception hydrovalleymodel(Dict("powersystem" => Dict()), params)
    end
end
