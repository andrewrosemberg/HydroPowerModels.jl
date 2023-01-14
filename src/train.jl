"""
    train(hydromodel::HydroPowerModel;kwargs...) 

Train future cost function using SDDP.

Keyword arguments (same as SDDP.train):
<https://github.com/odow/SDDP.jl/blob/0490bea2c46787e1d4d63a5491ea0106c7fe70cf/src/algorithm.jl#L780-L827>

"""
function train(hydromodel::HydroPowerModel; kwargs...)
    return SDDP.train(hydromodel.policygraph; kwargs...)
end
