using Documenter, Literate, HydroPowerModels

examples_dir = joinpath(dirname(dirname(@__FILE__)), "examples/HydroValleys")
docs_dir = dirname(@__FILE__)
testcases_dir = joinpath(dirname(dirname(@__FILE__)), "testcases")

const EXAMPLES = Any[   "Cases"=>"examples/cases.md"]
for file in ["case3.jl"]
    filename = joinpath(examples_dir, file)
    md_filename = replace(file, ".jl"=>".md")
    push!(EXAMPLES, "examples/HydroValleys/$(md_filename)")
    Literate.markdown(filename, dirname(filename); documenter=true)
end

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
        "Examples"  => EXAMPLES,
        "Reference" => "apireference.md"
    ]
)

include("make_examples.jl")

deploydocs(
    repo   = "github.com/andrewrosemberg/HydroPowerModels.jl.git",
)