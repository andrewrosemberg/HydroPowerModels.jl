"""
    build_opf_powermodels((sp::JuMP.Model, data::Dict, params::Dict)

Network grid model builder.

Required parameters are:
-   sp is a JuMP model.
-   data is a dict with information of the subproblem. 
-   param is a dict containing solution parameters.
"""
function build_opf_powermodels(sp::JuMP.Model, data::Dict, params::Dict)
    return PowerModels.instantiate_model(
        data["powersystem"],
        params["model_constructor_grid"],
        params["post_method"];
        jump_model=sp,
        setting=params["setting"],
    )
end

"""
    build_graph(data::Dict, params::Dict)

Graph description.
"""
function build_graph(params::Dict)
    # graph definition
    graph = SDDP.LinearGraph(0)
    SDDP.add_node(graph, 1)
    SDDP.add_edge(graph, 0 => 1, 1.0)
    for t in 2:params["stages"]
        SDDP.add_node(graph, t)
        SDDP.add_edge(graph, t - 1 => t, params["discount_factor"])
    end
    return graph
end
