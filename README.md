# HydroPowerModels.jl
A Julia/JuMP package for Hydrothermal Multistage Steady-State Power Network Optimization solved by Stochastic Dual Dynamic Programming (SDDP).

| **DOI** |**Documentation** | **Build Status** | **Coverage** | **Paper** |
|:-----------------:|:-----------------:|:-----------------:|:-----------------:|:-----------------:|
|[![DOI](https://zenodo.org/badge/166077703.svg)](https://zenodo.org/badge/latestdoi/166077703)|[![][docs-latest-img]][docs-latest-url] | [![Build Status][build-img]][build-url] | [![Codecov branch][codecov-img]][codecov-url] | [![status][paper-img]][paper-url] |

[build-img]: https://travis-ci.com/andrewrosemberg/HydroPowerModels.jl.svg?branch=master
[build-url]: https://travis-ci.com/andrewrosemberg/HydroPowerModels.jl

[codecov-img]: https://codecov.io/gh/andrewrosemberg/HydroPowerModels.jl/coverage.svg?branch=master
[codecov-url]: https://codecov.io/gh/andrewrosemberg/HydroPowerModels.jl?branch=master

[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-latest-url]: https://andrewrosemberg.github.io/HydroPowerModels.jl/latest/

[paper-img]: https://submissions.juliacon.org/papers/ad43bcbd43a6f904e60db8838c177520/status.svg
[paper-url]: https://submissions.juliacon.org/papers/ad43bcbd43a6f904e60db8838c177520

**If you are struggling to figure out how to use something, raise a Github issue!**

**Network Data Formats**
* PowerModels ".json" files

**Resevoir Data Formats**
* JSON ".json" files

**Problem Specifications and Network Formulations**
* Problem Specifications and Network Formulations are handled by [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl).

**Solution Method**
* Solution method is handled by [SDDP.jl](https://github.com/odow/SDDP.jl).

**Presentations**
* JuMP-Dev 2019 (Santiago, Chile) [video](https://youtu.be/H6LmhGJ2kc8)
* JuliaCon 2019 (Baltimore, United States) [video](https://www.youtube.com/watch?v=bnKX2uATrzA&t=41s)
* Julia Meeting Rio (Rio de Janeiro, Brasil) (Portuguese) [video](https://www.youtube.com/watch?v=lSdYwE_7B8k&list=PLTMduyIx3GGvMw9mgIBqZGA6rtpIKNL7B&index=5&t=0s) [pdf](https://jugrio.github.io/pdfs/HydroPowerModels.pdf)
