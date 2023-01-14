using Weave

plot_bool = true

examples_dir = joinpath(dirname(dirname(@__FILE__)), "examples/HydroValleys")
docs_dir = dirname(@__FILE__)
testcases_dir = joinpath(dirname(dirname(@__FILE__)), "testcases")

weave(
    joinpath(examples_dir, "case3.jl");
    out_path=joinpath(docs_dir, "build/examples"),
    doctype="md2html",
    args=Dict(:testcases_dir => testcases_dir),
)
weave(
    joinpath(examples_dir, "case3_5years.jl");
    out_path=joinpath(docs_dir, "build/examples"),
    doctype="md2html",
    args=Dict(:testcases_dir => testcases_dir),
)
weave(
    joinpath(examples_dir, "case3_ac.jl");
    out_path=joinpath(docs_dir, "build/examples"),
    doctype="md2html",
    args=Dict(:testcases_dir => testcases_dir),
)
weave(
    joinpath(examples_dir, "case3_soc.jl");
    out_path=joinpath(docs_dir, "build/examples"),
    doctype="md2html",
    args=Dict(:testcases_dir => testcases_dir),
)
