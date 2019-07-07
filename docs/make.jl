using Documenter, HydroPowerModels

makedocs(
    modules = [HydroPowerModels],
    doctest  = false,
    clean    = true,
    format   = Documenter.HTML(),
    sitename = "HydroPowerModels.jl",
    authors = "Andrew Rosemberg",
    pages = [
        "Home"      => "index.md",
        "Manual"    => "getstarted.md",
        "Examples"  => Any[ "Cases"=>"examples/cases.md",
                            "Case 3 - Comparing Formulations"=>"examples/case3_cmp_formulations.md",
        ]
    ]
)

include("make_examples.jl")

deploydocs(
    repo   = "github.com/andrewrosemberg/HydroPowerModels.jl.git",
)