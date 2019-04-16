"""train future cost function using SDDP"""
function train(hydromodel::HydroPowerModel;kwargs...)
    SDDP.train(hydromodel.policygraph; kwargs...)
end