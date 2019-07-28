using Documenter, Literate, HydroPowerModels

examples_dir = joinpath(dirname(dirname(@__FILE__)), "examples/HydroValleys")
docs_dir = dirname(@__FILE__)
testcases_dir = joinpath(dirname(dirname(@__FILE__)), "testcases")

plot_bool = true
function replace_paths(str)
    path = "~//build//andrewrosemberg//HydroPowerModels.jl//testcases"
    ex = "testcases"
    str = replace(str, "\"$(ex)\"" => path)
    
    return str
end

const EXAMPLES = Any["examples/cases.md"]
for file in ["case3.jl"]
    filename = joinpath(examples_dir, file)
    md_filename = replace(file, ".jl"=>".md")
    push!(EXAMPLES,md_filename)
    Literate.markdown(filename, joinpath(docs_dir, "src"); documenter=true, preprocess = replace_paths)
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