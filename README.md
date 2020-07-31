# HydroPowerModels.jl
A Julia/JuMP package for Hydrothermal Multistage Steady-State Power Network Optimization solved by Stochastic Dual Dynamic Programming (SDDP).

| **DOI** |**Documentation** | **Build Status** | **Coverage** | **Paper** |
|:-----------------:|:-----------------:|:-----------------:|:-----------------:|:-----------------:|
|[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.3842130.svg)](https://doi.org/10.5281/zenodo.3842130)|[![][docs-latest-img]][docs-latest-url] | [![Build Status][build-img]][build-url] | [![Codecov branch][codecov-img]][codecov-url] | [![status][paper-img]][paper-url] |

[build-img]: https://travis-ci.com/andrewrosemberg/HydroPowerModels.jl.svg?branch=master
[build-url]: https://travis-ci.com/andrewrosemberg/HydroPowerModels.jl

[codecov-img]: https://codecov.io/gh/andrewrosemberg/HydroPowerModels.jl/coverage.svg?branch=master
[codecov-url]: https://codecov.io/gh/andrewrosemberg/HydroPowerModels.jl?branch=master

[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-latest-url]: https://andrewrosemberg.github.io/HydroPowerModels.jl/latest/

[paper-img]: https://proceedings.juliacon.org/papers/10.21105/jcon.00035/status.svg
[paper-url]: https://proceedings.juliacon.org/papers/10.21105/jcon.00035#

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
* JuliaCon 2020 [video](https://www.youtube.com/watch?v=xUpX-k0oZmo) [abstract](https://live.juliacon.org/talk/ETWX8X)

**Publications**
* [Preprint Julia Proceedings](https://www.researchgate.net/publication/342068899_HydroPowerModelsjl_A_JuliaJuMP_Package_for_Hydrothermal_Economic_Dispatch_Optimization?_sg=-ns1NVJAEH4f6vC2lhCZjqMnPbu5huqHa4hzO5rvHR7xCiNYqldptqVgUfSzqvVcKV3Mboud9o2q9JPQTCMqI9Jz6HBS7P-M40JJ_0Tv.mH0MO_FCD6hy__nKGpOGByuZG6rHMHcdJkukrG_1m-hzggFXnx8rmQFSj8YlzCkKu1k5awQi8JafY0fpiGspIw)
* [Master Thesis](https://www.researchgate.net/publication/342751537_A_Framework_for_Assessing_the_Impacts_of_Network_Formulations_in_the_Operation_of_Hydrothermal_Power_Systems)

**Citing HydroPowerModels.jl**

If you use HydroPowerModels.jl, we ask that you please cite the following:
```
@article{Rosemberg2020,
  doi = {10.21105/jcon.00035},
  url = {https://doi.org/10.21105/jcon.00035},
  year = {2020},
  publisher = {The Open Journal},
  volume = {1},
  number = {1},
  pages = {35},
  author = {Andrew W. Rosemberg and Alexandre Street and Joaquim D. Garcia and Thuener Silva and \\ Davi M. Valladão and Oscar Dowson},
  title = {HydroPowerModels.jl: A Julia/JuMP Package for Hydrothermal Economic Dispatch Optimization},
  journal = {Proceedings of the JuliaCon Conferences}
}
```
