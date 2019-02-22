# HydroPowerModels.jl
A Julia/JuMP package for Hydrothermal Multistage Steady-State Power Network Optimization solved by Stochastic Dual Dynamic Programming (SDDP).

 **Documentation** | **Build Status** | **Coverage** |
|:-----------------:|:-----------------:|:-----------------:|
|[![][docs-latest-img]][docs-latest-url] | [![Build Status][build-img]][build-url] | [![Codecov branch][codecov-img]][codecov-url] |

[build-img]: https://travis-ci.com/andrewrosemberg/HydroPowerModels.jl.svg?branch=master
[build-url]: https://travis-ci.com/andrewrosemberg/HydroPowerModels.jl

[codecov-img]: https://codecov.io/gh/andrewrosemberg/HydroPowerModels.jl/coverage.svg?branch=master
[codecov-url]: https://codecov.io/gh/andrewrosemberg/HydroPowerModels.jl?branch=master

[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-latest-url]: https://andrewrosemberg.github.io/HydroPowerModels.jl/latest/

[![DOI](https://zenodo.org/badge/166077703.svg)](https://zenodo.org/badge/latestdoi/166077703)

**If you are struggling to figure out how to use something, raise a Github issue!**

**Network Data Formats**
* Matpower ".m" files
* PTI ".raw" files (PSS(R)E v33 specfication)

**Resevoir Data Formats**
* JSON ".json" files

**Problem Specifications and Network Formulations**
* Problem Specifications and Network Formulations are handled by [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl).

**Solution Method**
* Solution method is handled by [SDDP.jl](https://github.com/odow/SDDP.jl).
