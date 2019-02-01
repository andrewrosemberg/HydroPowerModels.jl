using JSON

"Read hydro description json file"
function parse_file_hydro(file::String)
    return JSON.parse(String(read(file)))
end

"Read Hydrogenerators inflow csv file"
function read_inflow(file::String, nHyd::Int)
    allinflows = readcsv(file)
    nlin, ncol = size(allinflows)
    nCen = Int(floor(ncol/nHyd))
    vector_inflows = Array{Array{Float64,2}}(nHyd)
    for i = 1:nHyd
        vector_inflows[i] = allinflows[1:nlin,(i-1)*nCen+1:i*nCen]
    end
    return vector_inflows
end

"Read hydro case folder"
function parse_folder(folder::String)
    foldername = split(folder,r"/|//|\\")[end]
    data = Dict()
    data["powersystem"] = PowerModels.parse_file(folder*"/"*foldername*".m")
    data["hydro"] = parse_file_hydro(folder*"/"*foldername*"hydro.json")
    vector_inflows = read_inflow(folder*"/"*foldername*"inflows.csv",length(data["hydro"]["Hydrogenerators"]))
    for i = 1:length(data["hydro"]["Hydrogenerators"])
        data["hydro"]["Hydrogenerators"][i]["inflow"]= vector_inflows[i]
    end
    data["hydro"]["scenario_probabilities"] = readcsv(folder*"/"*foldername*"scenarioprobability.csv")
    return data
end

"Organize Parameters"
function set_param(;stages::Int = 1,model_constructor_grid = DCPPowerModel, post_method = PowerModels.post_opf,solver = ClpSolver())
    params = Dict()
    params["stages"] = 3
    params["model_constructor_grid"] = model_constructor_grid
    params["post_method"] = post_method
    params["solver"] = solver
    return params
end

"Build Solution"
function build_solution(m::SDDPModel)
    stages = size(m.stages,1)
    solution = Dict()
    solution["solution"]=Vector{Array}(stages)
    for s = 1:stages
        markovstates = size(m.stages[s].subproblems,1)
        solution["solution"][s] = Array{Dict}(markovstates)
        for i = 1:markovstates
            solution["solution"][s][i] = PowerModels.build_solution(m.stages[s].subproblems[i].ext[:pm],:Optimal,0.0,
                                                                    solution_builder = PowerModels.get_solution)
        end
    end
    return solution
end