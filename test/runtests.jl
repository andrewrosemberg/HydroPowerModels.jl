using HydroPowerModels, Base.Test
using JuMP, PowerModels, SDDP

plot_bool = false

include("hydrovalleymodel.jl")
include("IO.jl")
include("variables.jl")
include("examples.jl")