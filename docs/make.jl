
using Documenter, HydroPowerModels

makedocs(
    modules = [HydroPowerModels],
    doctest  = false,
    clean    = true,
    format   = :html,
    sitename = "HydroPowerModels.jl",
    authors = "Andrew Rosemberg",
    pages = [
        "Home" => "index.md",
        "getstarted.md"
    ]
)

deploydocs(
    repo   = "github.com/andrewrosemberg/HydroPowerModels.jl.git",
    target = "build",
    osname = "linux",
    julia  = "0.6",
    deps   = nothing,
    make   = nothing,
)