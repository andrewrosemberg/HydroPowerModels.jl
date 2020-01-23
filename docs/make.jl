using Documenter, Literate, HydroPowerModels

examples_dir = joinpath(dirname(dirname(@__FILE__)), "examples/HydroValleys")
docs_dir = dirname(@__FILE__)
testcases_dir = joinpath(dirname(dirname(@__FILE__)), "testcases")

plot_bool = true

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
        "Case data" => "inputfiles.md",
        "Examples"  => "examples/cases.md",
        "Reference" => "apireference.md"
    ]
)

include("make_examples.jl")

deploydocs(
    repo   = "github.com/andrewrosemberg/HydroPowerModels.jl.git",
)