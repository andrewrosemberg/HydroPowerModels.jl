"""
Read hydro description json file.
"""
function parse_file_json(file::String)
    return JSON.parse(String(read(file)))
end

"""Read Hydrogenerators inflow csv file"""
function read_inflow(file::String, nHyd::Int)
    allinflows = CSV.read(file, Tables.matrix; header=false)
    nlin, ncol = size(allinflows)
    nCen = Int(floor(ncol / nHyd))
    vector_inflows = Array{Array{Float64,2}}(undef, nHyd)
    for i in 1:nHyd
        vector_inflows[i] = allinflows[1:nlin, ((i - 1) * nCen + 1):(i * nCen)]
    end
    return vector_inflows, nCen
end

"""
    HydroPowerModels.parse_folder(folder::String; stages::Int = 1,digts::Int=7)

Read hydrothermal case folder.

Parameters:
-   folder  : Path to case folder.
-   stages  : Number of stages.
-   digts   : Number of digits to take into acoint from case description files.
"""
function parse_folder(folder::String; stages::Int=1, digts::Int=7)
    data = Dict()
    try
        data["powersystem"] = parse_file_json(joinpath(folder, "PowerModels.json"))
        if typeof(data["powersystem"]["source_version"]) <: AbstractDict
            data["powersystem"]["source_version"] = VersionNumber(
                data["powersystem"]["source_version"]["major"],
                data["powersystem"]["source_version"]["minor"],
                data["powersystem"]["source_version"]["patch"],
                Tuple{}(data["powersystem"]["source_version"]["prerelease"]),
                Tuple{}(data["powersystem"]["source_version"]["build"]),
            )
        end
    catch
        data["powersystem"] = PowerModels.parse_file(joinpath(folder, "PowerModels.m"))
    end
    data["hydro"] = parse_file_json(joinpath(folder, "hydro.json"))
    for i in 1:length(data["hydro"]["Hydrogenerators"])
        data["hydro"]["Hydrogenerators"][i] = signif_dict(
            data["hydro"]["Hydrogenerators"][i], digts
        )
    end
    vector_inflows, nCen = read_inflow(
        joinpath(folder, "inflows.csv"), length(data["hydro"]["Hydrogenerators"])
    )
    for i in 1:length(data["hydro"]["Hydrogenerators"])
        data["hydro"]["Hydrogenerators"][i]["inflow"] = vector_inflows[i]
    end
    try
        data["hydro"]["scenario_probabilities"] = convert(
            Matrix{Float64},
            CSV.read(joinpath(folder, "scenarioprobability.csv"); header=false),
        )
    catch
        data["hydro"]["scenario_probabilities"] =
            ones(size(vector_inflows[1], 1), nCen) ./ nCen
    end
    return [deepcopy(data) for _ in 1:stages]
end

"""set active demand"""
function set_active_demand!(alldata::Array{Dict{Any,Any}}, demand::Array{Float64,2})
    for t in 1:size(alldata, 1)
        data = alldata[t]
        for load in 1:length(data["powersystem"]["load"])
            bus = data["powersystem"]["load"]["$load"]["load_bus"]
            data["powersystem"]["load"]["$load"]["pd"] = demand[t, bus]
        end
    end
    return nothing
end

"""
    create_param(;stages::Int = 1,
        model_constructor_grid = DCPPowerModel,
        model_constructor_grid_backward = model_constructor_grid,
        model_constructor_grid_forward = model_constructor_grid_backward,
        post_method = PowerModels.build_opf,
        optimizer = GLPK.Optimizer,
        optimizer_backward = optimizer,
        optimizer_forward = optimizer_backward,
        setting = Dict("output" => Dict("branch_flows" => true,"duals" => true)),
        verbose = false,
        stage_hours = 1)

Create Parameters Dictionary.

Keywords are:
-   stages::Int             : Number of stages.
-   model_constructor_grid  : Network formulation (Types from <https://github.com/lanl-ansi/PowerModels.jl>).
-   optimizer               : Optimizer factory (<http://www.juliaopt.org/JuMP.jl/v0.19.0/solvers/>).
-   setting                 : PowerModels settings (<https://github.com/lanl-ansi/PowerModels.jl/blob/e28644bf85232a5322adeeb847c0d18b7ff4f235/src/core/base.jl#L6-L34>)) .
-   verbose                 : Boolean to indicate information prints.
-   stage_hours             : Number of hours in each stage.
"""
function create_param(;
    stages::Int=1,
    model_constructor_grid=DCPPowerModel,
    model_constructor_grid_backward=model_constructor_grid,
    model_constructor_grid_forward=model_constructor_grid_backward,
    post_method=PowerModels.build_opf,
    optimizer=GLPK.Optimizer,
    optimizer_backward=optimizer,
    optimizer_forward=optimizer_backward,
    setting=Dict("output" => Dict("branch_flows" => true, "duals" => true)),
    verbose=false,
    stage_hours=1,
    discount_factor::Float64=1.0,
)
    params = Dict()
    params["stages"] = stages
    params["stage_hours"] = stage_hours
    params["discount_factor"] = discount_factor
    params["model_constructor_grid"] = model_constructor_grid
    params["model_constructor_grid_backward"] = model_constructor_grid_backward
    params["model_constructor_grid_forward"] = model_constructor_grid_forward
    params["post_method"] = post_method
    params["optimizer"] = optimizer
    params["optimizer_backward"] = optimizer_backward
    params["optimizer_forward"] = optimizer_forward
    params["verbose"] = verbose
    params["setting"] = setting
    return params
end
