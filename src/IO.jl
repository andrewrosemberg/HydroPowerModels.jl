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
    foldername = "" #split(folder,r"/|//|\\")[end]
    data = Dict()
    data["powersystem"] = PowerModels.parse_file(folder*"/"*foldername*"PowerModels.m")
    data["hydro"] = parse_file_hydro(folder*"/"*foldername*"hydro.json")
    vector_inflows = read_inflow(folder*"/"*foldername*"inflows.csv",length(data["hydro"]["Hydrogenerators"]))
    for i = 1:length(data["hydro"]["Hydrogenerators"])
        data["hydro"]["Hydrogenerators"][i]["inflow"]= vector_inflows[i]
    end
    data["hydro"]["scenario_probabilities"] = readcsv(folder*"/"*foldername*"scenarioprobability.csv")
    return data
end

"Organize Parameters"
function set_param(;stages::Int = 1,model_constructor_grid = DCPPowerModel, post_method = PowerModels.post_opf,solver = ClpSolver(),setting = Dict("output" => Dict("branch_flows" => true)))
    params = Dict()
    params["stages"] = stages
    params["model_constructor_grid"] = model_constructor_grid
    params["post_method"] = post_method
    params["solver"] = solver
    params["setting"] = setting
    return params
end

"Build Solution single simulation"
function build_solution_single_simulation(m::SDDPModel;solution = Dict())
    # add results    
    stages = size(m.stages,1) # count number of stages

    solution["solution"]= Dict()
    solution["solution"]=Array{Dict}(stages)
    for s = 1:stages
        i = solution["markov"][s]       
        built_sol = PowerModels.build_solution(m.stages[s].subproblems[i].ext[:pm],:Optimal,0.0,
        solution_builder = PowerModels.get_solution)
        solution["solution"][s] = built_sol["solution"]
        solution["solution"][s]["objective"] = built_sol["objective"]
        solution["solution"][s]["objective_lb"] = built_sol["objective_lb"]
        solution["solution"][s]["reservoirs"] = Dict()
        for r =1:m.ext[:data]["hydro"]["nHyd"]
            solution["solution"][s]["reservoirs"]["$r"] = Dict()
            solution["solution"][s]["reservoirs"]["$r"]["spill"] = getvalue(m.stages[s].subproblems[i][:spill])[r]
            solution["solution"][s]["reservoirs"]["$r"]["outflow"] = getvalue(m.stages[s].subproblems[i][:outflow])[r]
            solution["solution"][s]["reservoirs"]["$r"]["volume"] = getvalue(m.stages[s].subproblems[i][:reservoir])[r]
        end        
    end
    return solution
end

"Create matrix from dict"
function get_multiperiod_value(results::Dict, path=[]::Array{Any,1}, matidx=Int[]::Array{Int,1})
    codestr = Array{String}(size(path,1)+1)
    codestr[1] = "results"
    codestr[2:end] .= ["[path[$i]]" for i = 1:size(path,1)]
    if size(matidx,1)>0
        sizemat = Array{Int,1}(size(matidx,1))
        for idx = 1:size(matidx,1)
            sizemat[idx] = size(eval.(parse(*(codestr[1:matidx[idx]]...))))[1]
        end

        for idx = 1:size(matidx,1)
            codestr[matidx[idx]+1] = "[i$idx]"
        end

        codestr = *(codestr...)

        codestr = *(codestr,*("for ",["i$idx =1:$(sizemat[idx])," for idx = 1:size(matidx,1)]...)[1:end-1])
        codestr = "["*codestr*"]"
    else
        codestr = *(codestr...)
    end
    codestr = eval(parse(codestr))
    return codestr
end
