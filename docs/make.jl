
using Documenter, HydroPowerModels

makedocs(
    modules = [HydroPowerModels],
    doctest  = false,
    clean    = true,
    format   = :html,
    sitename = "HydroPowerModels.jl",
    authors = "Andrew Rosemberg",
    pages = [
        "Home"      => "index.md",
        "Manual"    => "getstarted.md",
        "Examples"  => Any[ "Case 3"=>"examples/case3.md",
                            "Case 3 - 5 Years"=>"examples/case3_5years.md",
                            "Case 3 - Comparing Formulations"=>"examples/case3_cmp_formulations.md",
        ]
    ]
)

include("make_examples.jl")

deploydocs(
    repo   = "github.com/andrewrosemberg/HydroPowerModels.jl.git",
    julia = "0.6.4" ,
    target = "build",
    osname = "linux",
    make   = nothing
)