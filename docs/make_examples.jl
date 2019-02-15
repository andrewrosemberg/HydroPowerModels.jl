using Weave

plot_bool = true

examples_dir = joinpath(dirname(dirname(@__FILE__)), "examples/HydroValleys")
docs_dir = dirname(@__FILE__)
weave(joinpath(examples_dir,"case3.jl"), out_path =joinpath(docs_dir,"build/examples"), doctype = "md2html")