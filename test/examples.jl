const examples_dir = joinpath(dirname(dirname(@__FILE__)), "examples")

const Examples = Dict(
    "HydroValleys" => [
            "case3deterministic.jl"
        ]  

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