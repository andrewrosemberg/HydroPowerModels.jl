using JSON
using CSV

"""Read hydro description json file"""
function parse_file_json(file::String)
    return JSON.parse(String(read(file)))
end

"""Read Hydrogenerators inflow csv file"""
function read_inflow(file::String, nHyd::Int)
    allinflows = CSV.read(file,header=false)
    nlin, ncol = size(allinflows)
    nCen = Int(floor(ncol/nHyd))
    vector_inflows = Array{Array{Float64,2}}(undef,nHyd)
    for i = 1:nHyd
        vector_inflows[i] = allinflows[1:nlin,(i-1)*nCen+1:i*nCen]
    end
    return vector_inflows, nCen
end

"""Read hydro case folder"""
function parse_folder(folder::String; stages::Int = 1,digts::Int=7)        
    data = Dict()
    try
        data["powersystem"] = parse_file_json(joinpath(folder,"PowerModels.json"))
        data["powersystem"]["source_version"] = VersionNumber(data["powersystem"]["source_version"]["major"],
                                                              data["powersystem"]["source_version"]["minor"],
                                                              data["powersystem"]["source_version"]["patch"],
                                                              Tuple{}(data["powersystem"]["source_version"]["prerelease"]),
                                                              Tuple{}(data["powersystem"]["source_version"]["build"]))
    catch
        data["powersystem"] = PowerModels.parse_file(joinpath(folder,"PowerModels.m"))
    end
    data["hydro"] = parse_file_json(joinpath(folder,"hydro.json"))
    for i = 1:length(data["hydro"]["Hydrogenerators"])
        data["hydro"]["Hydrogenerators"][i] = signif_dict(data["hydro"]["Hydrogenerators"][i],digts)
    end
    vector_inflows, nCen = read_inflow(joinpath(folder,"inflows.csv"),length(data["hydro"]["Hydrogenerators"]))
    for i = 1:length(data["hydro"]["Hydrogenerators"])
        data["hydro"]["Hydrogenerators"][i]["inflow"]= vector_inflows[i]
    end
    try
        data["hydro"]["scenario_probabilities"] = convert(Matrix{Float64},CSV.read(joinpath(folder,"scenarioprobability.csv"),header=false))
    catch
        data["hydro"]["scenario_probabilities"] = ones(size(vector_inflows[1],1),nCen)./nCen
    end
    return [deepcopy(data) for i=1:stages]
end

"""set active demand"""
function set_active_demand!(alldata::Array{Dict{Any,Any}}, demand::Array{Float64,2})
    for t = 1:size(alldata,1)
        data = alldata[t]
        for load = 1:length(data["powersystem"]["load"])
            bus = data["powersystem"]["load"]["$load"]["load_bus"]
            data["powersystem"]["load"]["$load"]["pd"] = demand[t,bus]
        end
    end
    return nothing
end

"""Create Parameters Dictionary"""
function create_param(;stages::Int = 1,
                    model_constructor_grid = DCPPowerModel, 
                    post_method = PowerModels.post_opf,
                    optimizer = with_optimizer(GLPK.Optimizer),
                    setting = Dict("output" => Dict("branch_flows" => true,"duals" => true)),
                    verbose = false,
                    stage_hours = 1)
    params = Dict()
    params["stages"] = stages
    params["stage_hours"] = stage_hours
    params["model_constructor_grid"] = model_constructor_grid
    params["post_method"] = post_method
    params["optimizer"] = optimizer
    params["verbose"] = verbose
    params["setting"] = setting
    return params
end