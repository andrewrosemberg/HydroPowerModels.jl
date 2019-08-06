# HydroPowerModels.jl Documentation

```
CurrentModule = HydroPowerModels
```

## Overview
HydroPowerModels.jl is a Julia/JuMP package for Hydrothermal Multistage Steady-State Power Network Optimization solved by Stochastic Dual Dynamic Programming (SDDP). 

Problem Specifications and Network Formulations are handled by [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl). 

Solution method is handled by [SDDP.jl](https://github.com/odow/SDDP.jl).

## Installation

HydroPowerModels.jl relies on an unregistered package called SDDP, so you will need to add it as follows:

```julia
julia> ] add https://github.com/odow/SDDP.jl/#master 
```

The current package is unregistered so you will need to add it as follows:

```julia
julia> ] add https://github.com/andrewrosemberg/HydroPowerModels.jl.git 
```
