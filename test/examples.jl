const examples_dir = joinpath(dirname(dirname(@__FILE__)), "examples")

const Examples = Dict(
    "HydroValleys" => [
        "case3.jl",
        # "case3_soc.jl",
        "case3deterministic.jl",
        "case3deterministic_nowater.jl",
        "case3deterministic_overwater.jl",
    ],
)

@testset "Examples" begin
    for (key, examples) in Examples
        @testset "$(key)" begin
            for example in examples
                @testset "$example" begin
                    println("Running $(key):$(example)")
                    include(joinpath(examples_dir, key, example))
                end
            end
        end
    end
end
