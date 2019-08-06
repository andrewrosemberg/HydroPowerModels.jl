"""
    build_opf_powermodels((sp::JuMP.Model, data::Dict, params::Dict)

Network grid model builder.

Required parameters are:
-   sp is a JuMP model.
-   data is a dict with information of the subproblem. 
-   param is a dict containing solution parameters.
"""
function build_opf_powermodels(sp::JuMP.Model, data::Dict, params::Dict)
    return PowerModels.build_model(data["powersystem"], params["model_constructor_grid"], 
            params["post_method"], jump_model=sp, setting = params["setting"])
end