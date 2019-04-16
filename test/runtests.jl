using HydroPowerModels, Test
using JuMP, PowerModels, SDDP

plot_bool = false
WEAVE_ARGS = Dict(:testcases_dir => joinpath(dirname(dirname(@__FILE__)), "testcases"))

include("hydrovalleymodel.jl")
include("IO.jl")
include("variables.jl")
include("examples.jl")