using HydroPowerModels, Test
using JuMP, PowerModels, SDDP

plot_bool = false

testcases_dir = joinpath(dirname(dirname(@__FILE__)), "testcases")
WEAVE_ARGS = Dict(:testcases_dir => testcases_dir)

include("hydrovalleymodel.jl")
include("IO.jl")
include("variables.jl")
include("examples.jl")
