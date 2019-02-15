using Weave

examples_dir = joinpath(dirname(dirname(@__FILE__)), "examples/HydroValleys")
weave(joinpath(examples_dir,"case3.jl"), out_path = "build/examples", doctype = "md2html")