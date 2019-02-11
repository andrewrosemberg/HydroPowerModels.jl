# HydroPowerModels.jl Documentation

```
CurrentModule = HydroPowerModels
```

## Overview
HydroPowerModels.jl is a Julia/JuMP package for Hydrothermal Multistage Steady-State Power Network Optimization solved by Stochastic Dual Dynamic Programming (SDDP). 

Problem Specifications and Network Formulations are handled by [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl). 

Solution method is handled by [SDDP.jl](https://github.com/odow/SDDP.jl).

## Installation

Dependencies to this package include the packages PowerModels and SDDP. Therefore you should first install as follows:

```julia
Pkg.add("PowerModels")
Pkg.clone("https://github.com/odow/SDDP.jl.git")
```

The current package is unregistered so you will need to `Pkg.clone` it as follows:

```julia
Pkg.clone("https://github.com/andrewrosemberg/HydroPowerModels.jl.git")
```
