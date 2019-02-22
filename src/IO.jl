using JSON
using Plots
using Plots.PlotMeasures

"Read hydro description json file"
function parse_file_json(file::String)
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
function parse_folder(folder::String; stages::Int = 1)        
    data = Dict()
    try
        data["powersystem"] = parse_file_json(folder*"/"*"PowerModels.json")
        data["powersystem"]["source_version"] = VersionNumber(data["powersystem"]["source_version"]["major"],data["powersystem"]["source_version"]["minor"],data["powersystem"]["source_version"]["patch"],Tuple{}(data["powersystem"]["source_version"]["prerelease"]),Tuple{}(data["powersystem"]["source_version"]["build"]))
    catch
        data["powersystem"] = PowerModels.parse_file(folder*"/"*"PowerModels.m")
    end
    data["hydro"] = parse_file_json(folder*"/"*"hydro.json")
    vector_inflows = read_inflow(folder*"/"*"inflows.csv",length(data["hydro"]["Hydrogenerators"]))
    for i = 1:length(data["hydro"]["Hydrogenerators"])
        data["hydro"]["Hydrogenerators"][i]["inflow"]= vector_inflows[i]
    end
    data["hydro"]["scenario_probabilities"] = readcsv(folder*"/"*"scenarioprobability.csv")
    return [data for i=1:stages]
end

"set active demand"
function set_active_demand(alldata::Array{Dict{Any,Any}}, demand::Array{Float64,2})
    for t = 1:size(alldata,1)
        data = alldata[t]
        for load = 1:length(data["powersystem"]["load"])
            bus = data["powersystem"]["load"]["$load"]["load_bus"]
            data["powersystem"]["load"]["$load"]["pd"] = demand[t,bus]
        end
    end
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
        for r =1:m.ext[:alldata][1]["hydro"]["nHyd"]
            solution["solution"][s]["reservoirs"]["$r"] = Dict()
            solution["solution"][s]["reservoirs"]["$r"]["spill"] = getvalue(m.stages[s].subproblems[i][:spill])[r]
            solution["solution"][s]["reservoirs"]["$r"]["outflow"] = getvalue(m.stages[s].subproblems[i][:outflow])[r]
            solution["solution"][s]["reservoirs"]["$r"]["volume"] = getvalue(m.stages[s].subproblems[i][:reservoir])[r]
        end        
    end
    return solution
end

"""Quantile Scenarios"""
function quantile_scen(scen::Array{Float64,2},quant::Float64)
    return [quantile(scen[i, :], quant) for i = 1:size(scen, 1)]
end

"""Quantile Scenarios"""
function quantile_scen(scen::Array{Float64,2},quants::Array{Float64};output_dict::Bool=false)
    if output_dict
        output = Dict()
        for quant in quants 
            output["$(quant*100)%"] = [quantile(scen[i, :], quant) for i = 1:size(scen, 1)]
        end
        return output
    else
        return [quantile(scen[i, :], quant) for i = 1:size(scen, 1),quant in quants]
    end
    
end

"""Plots a set o scenarios"""
function plotscenarios(scen::Array{Float64,2}; savepath::String ="",
        save::Bool = false, fileformat::String = "png", kwargs...)

    med_scen = median(scen,2)
    nscen = size(scen,1)

    # plot
    p1 = plot(med_scen, ribbon=(med_scen-quantile_scen(scen,0.0),quantile_scen(scen,1.0)-med_scen),
                color = "gray", 
                xticks = (collect(1:Int(floor(nscen/4)):nscen), [string(i) for  i in collect(1:Int(floor(nscen/4)):nscen)]),
                label = "Median";
                kwargs...)
    for q=0.05:0.1:0.25
        plot!(p1, med_scen, ribbon=(med_scen-quantile_scen(scen,q),quantile_scen(scen,1-q)-med_scen), color = "gray", label = "")
    end
    plot!(p1, maximum(scen, 2), label = "Max and Min", color = "Steel Blue")
    plot!(p1, minimum(scen, 2), label = "", color = "Steel Blue")
    if save
        savefig(p1, savepath*"$fileformat")
        return nothing
    else
        return p1
    end
end

"""Common Plots"""
function plotresults(results::Dict;nplts::Int = 3)

    plt_total = Array{Plots.Plot}(10)
    nplots = 0
    nsim = length(results["simulations"])
    nstages = length(results["simulations"][1]["solution"])

    # Termo Generation first 3 gen

    idxhyd = idx_hydro(results["data"][1])
    idxgen = setdiff(collect(1:min(length(results["data"][1]["powersystem"]["gen"]),nplts)),idxhyd)
    baseMVA =  [results["simulations"][i]["solution"][j]["baseMVA"] for i=1:nsim, j=1:nstages]'
    scen_gen = [[results["simulations"][i]["solution"][j]["gen"]["$gen"]["pg"] for i=1:nsim, j=1:nstages]'.*baseMVA for gen =1:3]

    plt =   [plotscenarios(scen_gen[gen], title  = "Termo Generation $gen",
                ylabel = "MWh",
                xlabel = "Stages",
                bottom_margin = 10mm,
                right_margin = 10mm,
                left_margin = 10mm                
                )
            for gen in idxgen
    ]
    plt_total[nplots+1] = plot(plt...,layout=(1,size(plt,1)))
    nplots += 1

    # Branch flow first 3 brc

    idxbrc = collect(1:min(length(results["data"][1]["powersystem"]["branch"]),nplts))
    scen_branch = [[results["simulations"][i]["solution"][j]["branch"]["$brc"]["pf"] for i=1:nsim, j=1:nstages]'.*baseMVA for brc =1:3]

    plt =   [plotscenarios(scen_branch[brc], title  = "Branch Flow $brc",
                ylabel = "MWh",
                xlabel = "Stages",
                bottom_margin = 10mm,
                right_margin = 10mm,
                left_margin = 10mm                
                )
            for brc in idxbrc
    ]
    plt_total[nplots+1] = plot(plt...,layout=(1,size(plt,1)))
    nplots += 1

    # Voltage angle first 3 bus
    
    if results["params"]["model_constructor_grid"] != PowerModels.GenericPowerModel{PowerModels.SOCWRForm}
        idxbus = collect(1:min(length(results["data"][1]["powersystem"]["bus"]),nplts))
        scen_va = [[results["simulations"][i]["solution"][j]["bus"]["$bus"]["va"] for i=1:nsim, j=1:nstages]' for bus =1:3]

        plt =   [plotscenarios(scen_va[bus], title  = "Voltage angle $bus",
                    ylabel = "Radians",
                    xlabel = "Stages",
                    bottom_margin = 10mm,
                    right_margin = 10mm,
                    left_margin = 10mm               
                    )
                for bus in idxbus
        ]
        plt_total[nplots+1] = plot(plt...,layout=(1,size(plt,1)))
        nplots += 1
    
    end
    # Hydro Generation and Reservoir Volume first 3 Hydro

    scen_voume = [[results["simulations"][i]["solution"][j]["reservoirs"]["$res"]["volume"] for i=1:nsim, j=1:nstages]' for res = 1:min(results["data"][1]["hydro"]["nHyd"],3)]

    plt =   [   [plotscenarios(scen_gen[gen], title  = "Hydro Generation $gen",
                    ylabel = "MWh",
                    xlabel = "Stages",
                    bottom_margin = 10mm,
                    right_margin = 10mm,
                    left_margin = 10mm               
                    )
                for gen in idxhyd[1:min(results["data"][1]["hydro"]["nHyd"],nplts)]]
                ;
                [plotscenarios(scen_voume[res], title  = "Volume Reservoir $res",
                    ylabel = "m³",
                    xlabel = "Stages",
                    bottom_margin = 10mm,
                    right_margin = 10mm,
                    left_margin = 10mm               
                    )  
                for res = 1:min(results["data"][1]["hydro"]["nHyd"],nplts)]
    ]
    plt_total[nplots+1] = plot(plt...,layout=(1,size(plt,1)))
    nplots += 1

    return plot(plt_total[1:nplots]...,layout=(nplots,1),size = (nplts*400, 500*nplots),legend=false)
end

"""Common descriptive statistics"""
function descriptivestatistics_results(results::Dict;nitem::Int = 3,quants::Array{Float64}=[0.25;0.5;0.75])

    dcp_stats = Dict()
    
    nsim = length(results["simulations"])
    nstages = length(results["simulations"][1]["solution"])

    # Termo Generation first nitem gen

    dcp_stats["pg"] = Dict()

    idxhyd = idx_hydro(results["data"][1])
    idxgen = setdiff(collect(1:min(length(results["data"][1]["powersystem"]["gen"]),nitem)),idxhyd)
    baseMVA =  [results["simulations"][i]["solution"][j]["baseMVA"] for i=1:nsim, j=1:nstages]'
    scen_gen = [[results["simulations"][i]["solution"][j]["gen"]["$gen"]["pg"] for i=1:nsim, j=1:nstages]'.*baseMVA for gen =1:3]
    
    for i = 1:size(idxgen,1)
        gen = idxgen[i]
        dcp_stats["pg"]["$i"] = quantile_scen(scen_gen[gen], quants, output_dict=true)
    end

    # Branch flow first nitem brc

    dcp_stats["pf"] = Dict()

    idxbrc = collect(1:min(length(results["data"][1]["powersystem"]["branch"]),nitem))
    scen_branch = [[results["simulations"][i]["solution"][j]["branch"]["$brc"]["pf"] for i=1:nsim, j=1:nstages]'.*baseMVA for brc =1:3]

    for i = 1:size(idxbrc,1)
        brc = idxbrc[i]
        dcp_stats["pf"]["$i"] = quantile_scen(scen_branch[brc], quants, output_dict=true)
    end

    # Voltage angle first nitem bus
    
    if results["params"]["model_constructor_grid"] != PowerModels.GenericPowerModel{PowerModels.SOCWRForm}

        dcp_stats["va"] = Dict()

        idxbus = collect(1:min(length(results["data"][1]["powersystem"]["bus"]),nitem))
        scen_va = [[results["simulations"][i]["solution"][j]["bus"]["$bus"]["va"] for i=1:nsim, j=1:nstages]' for bus =1:3]

        for i = 1:size(idxbus,1)
            bus = idxbus[i]
            dcp_stats["va"]["$i"] = quantile_scen(scen_va[bus], quants, output_dict=true)
        end
    
    end
    # Hydro Generation first nitem Hydro

    dcp_stats["hpg"] = Dict()

    for i = 1:size(idxhyd[1:min(results["data"][1]["hydro"]["nHyd"],nitem)],1)
        gen = idxhyd[1:min(results["data"][1]["hydro"]["nHyd"],nitem)][i]
        dcp_stats["hpg"]["$i"] = quantile_scen(scen_gen[gen], quants, output_dict=true)
    end

    # Reservoir Volume first nitem Hydro

    dcp_stats["volume"] = Dict()

    scen_voume = [[results["simulations"][i]["solution"][j]["reservoirs"]["$res"]["volume"] for i=1:nsim, j=1:nstages]' for res = 1:min(results["data"][1]["hydro"]["nHyd"],3)]

    for res = 1:min(results["data"][1]["hydro"]["nHyd"],nitem)
        dcp_stats["volume"]["$res"] = quantile_scen(scen_voume[res], quants, output_dict=true)
    end

    return dcp_stats
end

"""Multilayer Dict to Onelayer Dict"""
function flat_dict(mlt_dict::Dict{Any,Any})
    if typeof(collect(values(mlt_dict))[1]) != Dict{Any,Any}
        return mlt_dict
    end
    
    one_dict = Dict()
    kws = collect(keys(mlt_dict))

    recursion_ret = [flat_dict(i) for i in values(mlt_dict)]
    for i = 1:size(recursion_ret,1)
        item = recursion_ret[i]
        for (ikw,val) in item
            one_dict[kws[i]*"_"*ikw] = val
        end
    end

    return one_dict

end

"""truncate values dict"""
function signif_dict(one_dict::Dict, digits::Integer)
    for kw in keys(one_dict)
        one_dict[kw] = signif.(one_dict[kw],digits)
    end
    return one_dict
end