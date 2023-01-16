using Plots, Plots.PlotMeasures
import Fontconfig, Cairo
# import Reel, Compose
using LightGraphs, GraphPlot
using Random

"""
    plotscenarios(scen::Array{Float64,2}; savepath::String ="",
        save::Bool = false, fileformat::String = "png", kwargs...)

Plots a set of scenarios.

Parameters:
-   scen        : Scenarios matrix (Stages x Scenarious).
-   quants      : Lower Quantiles to plot (their simmetric will be taken into account)
-   save        : Bool to indicate if figure is to be saved.
-   savepath    : Path save figure.
-   fileformat  : Figure file format.
-   kwargs      : Aditional keyword arguments for plot function.
"""
function plotscenarios(scen::Array{Float64,2}; quants=collect(0.05:0.1:0.25),
        savepath::String ="",
        save::Bool = false, fileformat::String = "png", kwargs...)

    med_scen = Statistics.median(scen;dims=2)
    nstag,nscen = size(scen)

    # plot if all scenarious are equal

    if prod(isapprox.(med_scen-quantile_scen(scen,0.0), 0.0, atol=1e-1))
        p1 = plot(round.(med_scen,digits =5),
            color = "Steel Blue", 
            xticks = (collect(1:Int(floor(nstag/4)):nstag), [string(i) for  i in collect(1:Int(floor(nstag/4)):nstag)]),
            label = "Max and Min";
            kwargs...)

        if save
            savefig(p1, savepath*"$fileformat")
            return nothing
        end
        return p1 
    end

    # plot
    p1 = plot(med_scen, ribbon=(med_scen-quantile_scen(scen,0.0),quantile_scen(scen,1.0)-med_scen),
                color = "gray", 
                xticks = (collect(1:Int(floor(nstag/4)):nstag), [string(i) for  i in collect(1:Int(floor(nstag/4)):nstag)]),
                label = "Median";
                kwargs...)
    for q in quants
        plot!(p1, med_scen, ribbon=(med_scen-quantile_scen(scen,q),quantile_scen(scen,1-q)-med_scen), 
                            color = "gray", label = "")
    end
    plot!(p1, maximum(scen; dims=2), label = "Max and Min", color = "Steel Blue")
    plot!(p1, minimum(scen; dims=2), label = "", color = "Steel Blue")
    plot!(p1, mean(scen; dims=2), label = "Mean", color = "Black")
    if save
        savefig(p1, savepath*"$fileformat")
        return nothing
    end

    return p1    
end

"""
    HydroPowerModels.plotresults(results::Dict;nc::Int = 3)

Common Plots.

Parameters:
-   results        : Simulations output.
-   nc             : Number of figures per line.

"""
function plotresults(results::Dict;nc::Int = 3)
    plt_total = Array{Plots.Plot}(undef,10000)
    nplots = 0
    nsim = length(results[:simulations])
    nstages = length(results[:simulations][1])

    # Thermal Generation
    ngen = length(results[:data][1]["powersystem"]["gen"])
    idxhyd = idx_hydro(results[:data][1])
    idxgen = setdiff(collect(1:ngen),idxhyd)
    baseMVA =  [results[:simulations][i][j][:powersystem]["solution"]["baseMVA"] for i=1:nsim, j=1:nstages]'
    scen_gen = [[results[:simulations][i][j][:powersystem]["solution"]["gen"]["$gen"]["pg"] for i=1:nsim, j=1:nstages]'.*baseMVA for gen =1:ngen]

    plt =   [plotscenarios(scen_gen[gen], title  = "Thermal Generation $gen",
                ylabel = "MW",
                xlabel = "Stages",
                bottom_margin = 10mm,
                right_margin = 10mm,
                left_margin = 10mm                
                )
            for gen in idxgen
    ]
    plt_total[nplots+1:nplots+length(plt)] = plt
    nplots +=length(plt) 

    # Thermal Reactive Generation
    if results[:params]["model_constructor_grid_forward"] == PowerModels.ACPPowerModel
        scen_qgen = [[results[:simulations][i][j][:powersystem]["solution"]["gen"]["$gen"]["qg"] for i=1:nsim, j=1:results[:params]["stages"]]'.*baseMVA for gen =1:ngen]
        plt =   [plotscenarios(scen_qgen[gen], title  = "Thermal Reactive Generation $gen",
                ylabel = "MW",
                xlabel = "Stages",
                bottom_margin = 10mm,
                right_margin = 10mm,
                left_margin = 10mm                
                )
            for gen in idxgen
        ]
        plt_total[nplots+1:nplots+length(plt)] = plt
        nplots +=length(plt) 
    end

    # circuit MVA
    baseMVA = results[:data][1]["powersystem"]["baseMVA"]

    # Branch flow

    nbrc = length(results[:data][1]["powersystem"]["branch"])
    idxbrc = collect(1:nbrc)
    scen_branch = [[results[:simulations][i][j][:powersystem]["solution"]["branch"]["$brc"]["pf"] for i=1:nsim, j=1:nstages]'.*baseMVA for brc =1:nbrc]

    plt =   [plotscenarios(scen_branch[brc], title  = "Branch Flow $brc",
                ylabel = "MW",
                xlabel = "Stages",
                bottom_margin = 10mm,
                right_margin = 10mm,
                left_margin = 10mm                
                )
            for brc in idxbrc
    ]
    plt_total[nplots+1:nplots+length(plt)] = plt
    nplots +=length(plt) 

    # Branch Reactive flow

    if results[:params]["model_constructor_grid_forward"] == PowerModels.ACPPowerModel
        scen_branch_qf = [[results[:simulations][i][j][:powersystem]["solution"]["branch"]["$brc"]["qf"] for i=1:nsim, j=1:results[:params]["stages"]]'.*baseMVA for brc =1:nbrc]
        plt =   [plotscenarios(scen_branch_qf[brc], title  = "Branch Reactive Flow $brc",
                ylabel = "MW",
                xlabel = "Stages",
                bottom_margin = 10mm,
                right_margin = 10mm,
                left_margin = 10mm                
                )
            for brc in idxbrc
        ]
        plt_total[nplots+1:nplots+length(plt)] = plt
        nplots +=length(plt) 
    end

    # Voltage angle
    try    
        nbus = length(results[:data][1]["powersystem"]["bus"])
        idxbus = collect(1:nbus)
        scen_va = convert(Array{Array{Float64,2},1},[[results[:simulations][i][j][:powersystem]["solution"]["bus"]["$bus"]["va"] for i=1:nsim, j=1:nstages]' for bus =1:nbus])

        plt =   [plotscenarios(scen_va[bus], title  = "Voltage angle $bus",
                    ylabel = "Radians",
                    xlabel = "Stages",
                    bottom_margin = 10mm,
                    right_margin = 10mm,
                    left_margin = 10mm               
                    )
                for bus in idxbus
        ]
        plt_total[nplots+1:nplots+length(plt)] = plt
        nplots +=length(plt) 
    catch
    end

    # Nodal price
    try
    nbus = length(results[:data][1]["powersystem"]["bus"])
    idxbus = collect(1:nbus)
    scen_pld = convert(Array{Array{Float64,2},1},[[-results[:simulations][i][j][:powersystem]["solution"]["bus"]["$bus"]["lam_kcl_r"] for i=1:nsim, j=1:nstages]' for bus =1:nbus])/baseMVA

    plt =   [plotscenarios(scen_pld[bus], title  = "Nodal price bus $bus",
                ylabel = "\$/MW",
                xlabel = "Stages",
                bottom_margin = 10mm,
                right_margin = 10mm,
                left_margin = 10mm               
                )
            for bus in idxbus
    ]
    plt_total[nplots+1:nplots+length(plt)] = plt
    nplots +=length(plt) 
    catch
    end
    # Deficit
    try
    nbus = length(results[:data][1]["powersystem"]["bus"])
    idxbus = collect(1:nbus)
    scen_def = convert(Array{Array{Float64,2},1},[[results[:simulations][i][j][:powersystem]["solution"]["bus"]["$bus"]["deficit"] for i=1:nsim, j=1:nstages]' for bus =1:nbus])

    plt =   [plotscenarios(scen_def[bus].*baseMVA, title  = "Deficit bus $bus",
                ylabel = "MW",
                xlabel = "Stages",
                bottom_margin = 10mm,
                right_margin = 10mm,
                left_margin = 10mm               
                )
            for bus in idxbus
    ]
    plt_total[nplots+1:nplots+length(plt)] = plt
    nplots +=length(plt)
    catch
    end

    # Hydro Generation
    nHyd = results[:data][1]["hydro"]["nHyd"]
    
    plt =   [   plotscenarios(scen_gen[gen], title  = "Hydro Generation $gen",
                    ylabel = "MW",
                    xlabel = "Stages",
                    bottom_margin = 10mm,
                    right_margin = 10mm,
                    left_margin = 10mm               
                    )
                for gen in idxhyd
    ]
    plt_total[nplots+1:nplots+length(plt)] = plt
    nplots +=length(plt) 

    # Reservoir Outflow
    scen_turn = convert(Array{Array{Float64,2},1},[[results[:simulations][i][j][:reservoirs][:outflow][res] for i=1:nsim, j=1:nstages]' for res = 1:results[:data][1]["hydro"]["nHyd"]])
    plt =   [   plotscenarios(scen_turn[res], title  = "Reservoir Outflow $res",
                    ylabel = "m³/s",
                    xlabel = "Stages",
                    bottom_margin = 10mm,
                    right_margin = 10mm,
                    left_margin = 10mm               
                    )  
                for res = 1:nHyd
    ]
    plt_total[nplots+1:nplots+length(plt)] = plt
    nplots +=length(plt) 

    # Hydro Spill    
    scen_spill = convert(Array{Array{Float64,2},1},[[results[:simulations][i][j][:reservoirs][:spill][res] for i=1:nsim, j=1:nstages]' for res = 1:results[:data][1]["hydro"]["nHyd"]])

    plt =   [   plotscenarios(scen_spill[res], title  = "Hydro Spill $res",
                    ylabel = "Hm³",
                    xlabel = "Stages",
                    bottom_margin = 10mm,
                    right_margin = 10mm,
                    left_margin = 10mm               
                    )  
                for res = 1:nHyd
    ]    
    plt_total[nplots+1:nplots+length(plt)] = plt
    nplots +=length(plt) 

    # Reservoir Volume
    scen_voume = convert(Array{Array{Float64,2},1},[[results[:simulations][i][j][:reservoirs][:reservoir][res].out for i=1:nsim, j=1:nstages]' for res = 1:results[:data][1]["hydro"]["nHyd"]])


    plt =   [   plotscenarios(scen_voume[res], title  = "Volume Reservoir $res",
                    ylabel = "Hm³",
                    xlabel = "Stages",
                    bottom_margin = 10mm,
                    right_margin = 10mm,
                    left_margin = 10mm               
                    )  
                for res = 1:nHyd
    ]    
    plt_total[nplots+1:nplots+length(plt)] = plt
    nplots +=length(plt) 

    # Inflows
    scen_inflows = convert(Array{Array{Float64,2},1},[[results[:data][1]["hydro"]["Hydrogenerators"][res]["inflow"][cidx(j,results[:data][1]["hydro"]["size_inflow"][1]),results[:simulations][i][j][:noise_term]] for i=1:nsim, j=1:nstages]' for res = 1:results[:data][1]["hydro"]["nHyd"]])

    plt =   [   plotscenarios(scen_inflows[res], title  = "Inflows Reservoir $res",
                    ylabel = "m³/s",
                    xlabel = "Stages",
                    bottom_margin = 10mm,
                    right_margin = 10mm,
                    left_margin = 10mm               
                    )  
                for res = 1:nHyd
    ]    
    plt_total[nplots+1:nplots+length(plt)] = plt
    nplots +=length(plt) 
    if mod(nplots,nc) > 0 && floor(Int,nplots/nc) > 0
        l = @layout [ Plots.grid(floor(Int,nplots/nc),nc);  Plots.grid(1,mod(nplots,nc))]
        nlines = floor(Int,nplots/nc)+1
        l.heights = Plots.grid(2,1,heights=[floor(Int,nplots/nc)/nlines;1/nlines]).heights
    elseif floor(Int,nplots/nc) > 0
        l = @layout Plots.grid(floor(Int,nplots/nc),nc)
        nlines = floor(Int,nplots/nc)
        l.heights = Plots.grid(nlines,1,heights=[1/nlines for n = 1:nlines]).heights
    else
        l = @layout Plots.grid(1,mod(nplots,nc))
        nlines = 1
        l.heights = Plots.grid(1,1,heights=[1]).heights
    end    

    return plot(plt_total[1:nplots]...,layout=l,size = (nc*400,400*ceil(Int,nplots/nc)),legend=false)
end

"""Common descriptive statistics"""
function descriptivestatistics_results(results::Dict;nitem::Int = 3,quants::Array{Float64}=[0.25;0.5;0.75])

    dcp_stats = Dict()
    
    nsim = length(results[:simulations])
    nstages = length(results[:simulations][1][1][:powersystem]["solution"])

    # Thermal Generation first nitem gen

    dcp_stats["pg"] = Dict()

    ngen = length(results[:data][1]["powersystem"]["gen"])
    idxhyd = idx_hydro(results[:data][1])
    idxgen = setdiff(collect(1:min(ngen,nitem)),idxhyd)
    baseMVA =  [results[:simulations][i][j][:powersystem]["solution"]["baseMVA"] for i=1:nsim, j=1:nstages]'
    scen_gen = [[results[:simulations][i][j][:powersystem]["solution"]["gen"]["$gen"]["pg"] for i=1:nsim, j=1:nstages]'.*baseMVA for gen =1:ngen]
    
    for i = 1:size(idxgen,1)
        gen = idxgen[i]
        dcp_stats["pg"]["$i"] = quantile_scen(scen_gen[gen], quants, output_dict=true)
    end

    # Branch flow first nitem brc

    dcp_stats["pf"] = Dict()

    nbrc = length(results[:data][1]["powersystem"]["branch"])
    idxbrc = collect(1:min(nbrc,nitem))
    scen_branch = [[results[:simulations][i][j][:powersystem]["solution"]["branch"]["$brc"]["pf"] for i=1:nsim, j=1:nstages]'.*baseMVA for brc =1:nbrc]

    for i = 1:size(idxbrc,1)
        brc = idxbrc[i]
        dcp_stats["pf"]["$i"] = quantile_scen(scen_branch[brc], quants, output_dict=true)
    end

    # Voltage angle first nitem bus
    
    if results[:params]["model_constructor_grid"] != PowerModels.AbstractPowerModel{PowerModels.SOCWRForm}

        dcp_stats["va"] = Dict()

        nbus = length(results[:data][1]["powersystem"]["bus"])
        idxbus = collect(1:min(nbus,nitem))
        scen_va = convert(Array{Array{Float64,2},1},[[results[:simulations][i][j][:powersystem]["solution"]["bus"]["$bus"]["va"] for i=1:nsim, j=1:nstages]' for bus =1:nbus])

        for i = 1:size(idxbus,1)
            bus = idxbus[i]
            dcp_stats["va"]["$i"] = quantile_scen(scen_va[bus], quants, output_dict=true)
        end
    
    end
    # Hydro Generation first nitem Hydro

    dcp_stats["hpg"] = Dict()

    for i = 1:size(idxhyd[1:min(results[:data][1]["hydro"]["nHyd"],nitem)],1)
        gen = idxhyd[1:min(results[:data][1]["hydro"]["nHyd"],nitem)][i]
        dcp_stats["hpg"]["$i"] = quantile_scen(scen_gen[gen], quants, output_dict=true)
    end

    # Reservoir Volume first nitem Hydro

    dcp_stats["volume"] = Dict()

    scen_voume = convert(Array{Array{Float64,2},1},[[results[:simulations][i][j][:reservoirs][:reservoir][res].out for i=1:nsim, j=1:nstages]' for res = 1:results[:data][1]["hydro"]["nHyd"]])

    for res = 1:min(results[:data][1]["hydro"]["nHyd"],nitem)
        dcp_stats["volume"]["$res"] = quantile_scen(scen_voume[res], quants, output_dict=true)
    end

    return dcp_stats
end

"""
    HydroPowerModels.plot_grid(data::Dict;path=nothing,size_fig = [15cm, 15cm],node_label=false,nodelabeldist=4.5)

Plot Grid installed Power.

Paremeters:
-   data         : HydroPowerModel single stage data.
-   path         : Path to save grid plot.
-   size_fig     : Size figure.
-   node_label   : Plot nodel label on grid.
-   nodelabeldist: Nodel label distance from node.
"""
function plot_grid(data::Dict;path=nothing,size_fig = [15cm, 15cm],node_label=false,nodelabeldist=4.5)

    gatherusefulinfo!(data)

    nbus = length(data["powersystem"]["bus"])

    nNodes = nbus

    g = Graph(nbus)

    for brc in values(data["powersystem"]["branch"])
        add_edge!(g, brc["f_bus"], brc["t_bus"])
    end

    # nodes gen
    thermal_nodes = fill(0.0,nbus)
    hydro_nodes = fill(0.0,nbus)

    idxhyd = idx_hydro(data)

    for i in 1:length(data["powersystem"]["gen"])
        bus_i = data["powersystem"]["gen"]["$i"]["gen_bus"]
        if i in idxhyd
            hydro_nodes[bus_i] += data["powersystem"]["gen"]["$i"]["pmax"]*data["powersystem"]["gen"]["$i"]["mbase"]
        else
            thermal_nodes[bus_i] += data["powersystem"]["gen"]["$i"]["pmax"]*data["powersystem"]["gen"]["$i"]["mbase"]
        end
    end

    # nodes loads
    load_nodes = fill(0.0,nbus)

    for i in 1:length(data["powersystem"]["load"])
        bus_i = data["powersystem"]["load"]["$i"]["load_bus"]
        load_nodes[bus_i] += data["powersystem"]["load"]["$i"]["pd"]*data["powersystem"]["baseMVA"]
    end

    # number of nodes
    num_nodes = nbus+ sum(load_nodes .> 0)+sum(hydro_nodes .> 0)+sum(thermal_nodes .> 0)
    
    # node size
    nodesize = fill(0.0,num_nodes)

    # nodes membership (3: Hydro, 2: Thermal)
    membership = fill(1,num_nodes)

    # node label
    if node_label
        nodelabel = [1:nbus;fill("",sum(hydro_nodes .> 0));fill("",sum(thermal_nodes .> 0));fill("",sum(load_nodes .> 0))]
    else
        nodelabel = nothing
    end
    # create nodes
    for bus_i in 1:length(data["powersystem"]["bus"])
        if hydro_nodes[bus_i] > 0
            add_vertex!(g)
            nNodes +=1
            add_edge!(g, nNodes, bus_i)
            membership[nNodes] = 3
            nodesize[nNodes] = log(hydro_nodes[bus_i])
        end

        if thermal_nodes[bus_i] > 0
            add_vertex!(g)
            nNodes +=1
            add_edge!(g, nNodes, bus_i)
            membership[nNodes] = 2
            nodesize[nNodes] = log(thermal_nodes[bus_i])
        end

        if load_nodes[bus_i] > 0
            add_vertex!(g)
            nNodes +=1
            add_edge!(g, nNodes, bus_i)
            membership[nNodes] = 4
            nodesize[nNodes] = log(load_nodes[bus_i])
        end

    end

    for n in 1:num_nodes
        nodesize[n] = nodesize[n] == 0 ? unique(sort(nodesize))[2] : nodesize[n]
    end
    
    nodecolor = ["black", "red", "blue", "orange"]

    # membership color
    nodefillc = nodecolor[Int64.(membership)]

    if path != nothing
        draw(PDF(path, size_fig...), gplot(g, nodefillc=nodefillc, nodesize=nodesize, nodelabel=nodelabel,nodelabeldist=nodelabeldist))
    else
        gplot(g, nodefillc=nodefillc, nodesize=nodesize, nodelabel=nodelabel,nodelabeldist=nodelabeldist)
    end
end

""" Plot Hydro Grid installed volume"""
function plot_hydro_grid(data::Dict;path=nothing,size_fig = [12cm, 12cm],node_label=false,nodelabeldist=8.5)

    gatherusefulinfo!(data)

    nHyd = data["hydro"]["nHyd"]

    nNodes = nHyd

    g = DiGraph(nNodes)

    # nodes bus
    node2bus = []

    # hydro_size
    hydro_size = fill(0.0,nHyd)

    for i=1:nHyd
        hydro = data["hydro"]["Hydrogenerators"][i]
        hydro_size[i] = hydro["max_volume"]

        for hyd in hydro["downstream_turn"]
            j = findall(x->x["index"]==hyd,data["hydro"]["Hydrogenerators"])
            if !isempty(j)
                add_edge!(g, i, j[1])
            end
        end
        for hyd in hydro["downstream_spill"]
            j = findall(x->x["index"]==hyd,data["hydro"]["Hydrogenerators"])
            if !isempty(j)
                add_edge!(g, i, j[1])
            end
        end
        
        if hydro["index_grid"] != nothing 
            bus_i = data["powersystem"]["gen"]["$(hydro["i_grid"])"]["gen_bus"]
            node = findall(x->x==bus_i,node2bus)
            if isempty(node)
                append!(node2bus,bus_i)
                add_vertex!(g)
                nNodes +=1
                node = [size(node2bus,1)]
            end
            add_edge!(g, i, Int64(nHyd+node[1]))
        end
    end

    # node size
    nodesize = fill(maximum(log.(hydro_size.*1000,1.002))*0.5,nNodes)
    
    nodesize[1:nHyd] = log.(hydro_size.*1000,1.002)
    nodecolor = ["black", "blue"]

    # membership color
    membership = fill(1,nNodes)
    membership[1:nHyd] .= 2
    nodefillc = nodecolor[membership]

    # node label
    if node_label
        nodelabel = [fill("",nHyd);node2bus]
    else
        nodelabel = nothing
    end

    if path != nothing
        draw(PDF(path, size_fig...), gplot(g, nodefillc=nodefillc, nodesize=nodesize, nodelabel=nodelabel,nodelabeldist=nodelabeldist, arrowlengthfrac=0.005))    
    else
        gplot(g, nodefillc=nodefillc, nodesize=nodesize, nodelabel=nodelabel,nodelabeldist=nodelabeldist, arrowlengthfrac=0.005)
    end
end

# """ Plot Grid Stage Dispatched Power"""
# function plot_grid_dispatched_stage(results::Dict,t::Int;quant::Float64=0.5,size_fig = [15cm, 15cm],node_label=false,nodelabeldist=4.5)

#     data = results[:data][1]

#     nbus = length(data["powersystem"]["bus"])

#     nNodes = nbus

#     g = Graph(nbus)

#     for brc in values(data["powersystem"]["branch"])
#         add_edge!(g, brc["f_bus"], brc["t_bus"])
#     end

#     # nodes gen
#     thermal_nodes = fill(0.0,nbus)
#     hydro_nodes = fill(0.0,nbus)

#     idxhyd = idx_hydro(data)

#     for i in 1:length(data["powersystem"]["gen"])
#         bus_i = data["powersystem"]["gen"]["$i"]["gen_bus"]
#         if i in idxhyd
#             hydro_nodes[bus_i] += Statistics.quantile([results[:simulations][s][t][:powersystem]["solution"]["gen"]["$i"]["pg"] for s in 1:length(results[:simulations])], quant)*data["powersystem"]["gen"]["$i"]["mbase"]
#         else
#             thermal_nodes[bus_i] += Statistics.quantile([results[:simulations][s][t][:powersystem]["solution"]["gen"]["$i"]["pg"] for s in 1:length(results[:simulations])], quant)*data["powersystem"]["gen"]["$i"]["mbase"]
#         end
#     end

#     # nodes loads
#     load_nodes = fill(0.0,nbus)

#     for i in 1:length(data["powersystem"]["load"])
#         bus_i = data["powersystem"]["load"]["$i"]["load_bus"]
#         load_nodes[bus_i] += data["powersystem"]["load"]["$i"]["pd"]*data["powersystem"]["baseMVA"]
#     end

#     # number of nodes
#     num_nodes = nbus+ sum(load_nodes .> 0)+sum(hydro_nodes .> 0)+sum(thermal_nodes .> 0)
    
#     # node size
#     nodesize = fill(0.1,num_nodes)

#     # nodes membership (3: Hydro, 2: Thermal)
#     membership = fill(1,num_nodes)

#     # node label
#     if node_label
#         nodelabel = [1:nbus;fill("",sum(hydro_nodes .> 0));fill("",sum(thermal_nodes .> 0));fill("",sum(load_nodes .> 0))]
#     else
#         nodelabel = nothing
#     end
#     # create nodes
#     for bus_i in 1:length(data["powersystem"]["bus"])
#         if hydro_nodes[bus_i] > 0
#             add_vertex!(g)
#             nNodes +=1
#             add_edge!(g, nNodes, bus_i)
#             membership[nNodes] = 3
#             nodesize[nNodes] = log(hydro_nodes[bus_i])
#         end

#         if thermal_nodes[bus_i] > 0
#             add_vertex!(g)
#             nNodes +=1
#             add_edge!(g, nNodes, bus_i)
#             membership[nNodes] = 2
#             nodesize[nNodes] = log(thermal_nodes[bus_i])
#         end

#         if load_nodes[bus_i] > 0
#             add_vertex!(g)
#             nNodes +=1
#             add_edge!(g, nNodes, bus_i)
#             membership[nNodes] = 4
#             nodesize[nNodes] = log(load_nodes[bus_i])
#         end

#     end

#     for n in 1:num_nodes
#         nodesize[n] = nodesize[n] == 0 ? unique(sort(nodesize))[2] : nodesize[n]
#     end
    
#     nodecolor = ["black", "red", "blue", "orange"]

#     # membership color
#     nodefillc = nodecolor[Int64.(membership)]


#     gplot(g, nodefillc=nodefillc, nodesize=nodesize, nodelabel=nodelabel,nodelabeldist=nodelabeldist)
# end

# """ Plot Grid Dispatched Power"""
# function plot_grid_dispatched(results::Dict;seed=1111,quant::Float64=0.5,size_fig = [15cm, 15cm],node_label=false,nodelabeldist=4.5)
#     duration=length(results[:simulations][1])
#     roll(fps=1, duration=duration) do t, dt
#         Random.seed!(seed)
#         plot_grid_dispatched_stage(results,Int64(t+1);quant=quant,size_fig = size_fig,node_label=node_label,nodelabeldist=nodelabeldist)
#     end
# end

"""
    HydroPowerModels.plot_aggregated_results(results::Dict;nc::Int=3)

Plot Aggregated Results. Figures are of aggregated quantities, but the methods used to aggregate were chosen in order to help analysis. For example: The final nodal price is an average of nodal prices weighted by the contribution of local loads to the total demand; Reservoir volume was grouped weighted by the amount of energy that could be produced by the stored water (as was the inflow of water). 

Paremeter:
-   results: Simulation results.

"""
function plot_aggregated_results(results::Dict;nc::Int=3)
    plt_total = Array{Plots.Plot}(undef,20)
    nplots = 0
    nsim = length(results[:simulations])
    nstages = length(results[:simulations][1])

    # Thermal Generation
    ngen = length(results[:data][1]["powersystem"]["gen"])
    idxhyd = idx_hydro(results[:data][1])
    idxgen = setdiff(collect(1:ngen),idxhyd)
    baseMVA =  [results[:simulations][i][j][:powersystem]["solution"]["baseMVA"] for i=1:nsim, j=1:nstages]'
    scen_gen_all = [[results[:simulations][i][j][:powersystem]["solution"]["gen"]["$gen"]["pg"] for i=1:nsim, j=1:nstages]'.*baseMVA for gen =1:ngen]
    
    scen_gen = deepcopy(scen_gen_all[idxgen[1]])
    scen_gen .=0
    for gen in idxgen
        scen_gen = scen_gen .+ scen_gen_all[gen]
    end
    plt = plotscenarios(scen_gen, title  = "Thermal Generation",
                ylabel = "MW",
                xlabel = "Stages",
                bottom_margin = 10mm,
                right_margin = 10mm,
                left_margin = 10mm                
                )
    plt_total[nplots+1] = plt
    nplots += 1

    # circuit MVA
    baseMVA = results[:data][1]["powersystem"]["baseMVA"]

    # nodes loads
    nbus = length(results[:data][1]["powersystem"]["bus"])
    load_nodes = fill(0.0,nstages,nbus)
    for t in 1:nstages
        data = results[:data][min(t,length(results[:data]))]
        for i in 1:length(data["powersystem"]["load"])
            bus_i = data["powersystem"]["load"]["$i"]["load_bus"]
            load_nodes[t,bus_i] += data["powersystem"]["load"]["$i"]["pd"]*data["powersystem"]["baseMVA"]
        end
    end

    # Nodal price
    idxbus = collect(1:nbus)
    try
    scen_pld_all = convert(Array{Array{Float64,2},1},[[-results[:simulations][i][j][:powersystem]["solution"]["bus"]["$bus"]["lam_kcl_r"] for i=1:nsim, j=1:nstages]' for bus =1:nbus])/baseMVA
    
    scen_pld = deepcopy(scen_pld_all[idxbus[1]])
    scen_pld .=0
    for bus in idxbus
        scen_pld = scen_pld .+ scen_pld_all[bus].*hcat(fill(load_nodes[:,bus],nsim)...)
    end
    for t=1:nstages
        scen_pld[t,:] /= sum(load_nodes[t,bus] for bus in idxbus)
    end
    plt = plotscenarios(scen_pld, title  = "Load Weighted Average Nodal price ",
                ylabel = "\$/MW",
                xlabel = "Stages",
                bottom_margin = 10mm,
                right_margin = 10mm,
                left_margin = 10mm               
                )
    plt_total[nplots+1] = plt
    nplots += 1
    catch
    end
    # Deficit
    try
    scen_def_all = convert(Array{Array{Float64,2},1},[[results[:simulations][i][j][:powersystem]["solution"]["bus"]["$bus"]["deficit"] for i=1:nsim, j=1:nstages]' for bus =1:nbus])
    scen_def = deepcopy(scen_def_all[idxbus[1]])
    scen_def .=0
    for bus in idxbus
        scen_def = scen_def .+ scen_def_all[bus]
    end
    plt = plotscenarios(scen_def.*baseMVA, title  = "Deficit",
                ylabel = "MW",
                xlabel = "Stages",
                bottom_margin = 10mm,
                right_margin = 10mm,
                left_margin = 10mm               
                )
    plt_total[nplots+1] = plt
    nplots += 1
    catch
    end

    # Hydro Generation
    scen_gen = deepcopy(scen_gen_all[idxhyd[1]])
    scen_gen .=0
    for gen in idxhyd
        scen_gen = scen_gen .+ scen_gen_all[gen]
    end
    plt = plotscenarios(scen_gen, title  = "Hydro Generation",
                ylabel = "MW",
                xlabel = "Stages",
                bottom_margin = 10mm,
                right_margin = 10mm,
                left_margin = 10mm                
                )
    plt_total[nplots+1] = plt
    nplots += 1

    # Reservoir Outflow
    nHyd = results[:data][1]["hydro"]["nHyd"] 
    scen_turn_all = convert(Array{Array{Float64,2},1},[[results[:simulations][i][j][:reservoirs][:outflow][res] for i=1:nsim, j=1:nstages]' for res = 1:results[:data][1]["hydro"]["nHyd"]])
    
    scen_turn = deepcopy(scen_turn_all[1])
    scen_turn .=0
    for res = 1:nHyd
        scen_turn = scen_turn .+ scen_turn_all[res]
    end

    plt = plotscenarios(scen_turn, title  = "Reservoir Outflow",
                    ylabel = "m³/s",
                    xlabel = "Stages",
                    bottom_margin = 10mm,
                    right_margin = 10mm,
                    left_margin = 10mm               
                    )
    plt_total[nplots+1] = plt
    nplots += 1

    # Reservoir Spill
    scen_spill_all = convert(Array{Array{Float64,2},1},[[results[:simulations][i][j][:reservoirs][:spill][res] for i=1:nsim, j=1:nstages]' for res = 1:results[:data][1]["hydro"]["nHyd"]])./(0.0036*results[:params]["stage_hours"])
    
    scen_spill = deepcopy(scen_spill_all[1])
    scen_spill .=0
    for res = 1:nHyd
        scen_spill = scen_spill .+ scen_spill_all[res]
    end

    plt = plotscenarios(scen_spill, title  = "Reservoir Spill",
                    ylabel = "m³/s",
                    xlabel = "Stages",
                    bottom_margin = 10mm,
                    right_margin = 10mm,
                    left_margin = 10mm               
                    )
    plt_total[nplots+1] = plt
    nplots += 1  

    # Reservoir Volume

    water_energy!(results[:data][1])

    scen_voume_all = convert(Array{Array{Float64,2},1},[[results[:simulations][i][j][:reservoirs][:reservoir][res].out for i=1:nsim, j=1:nstages]' for res = 1:results[:data][1]["hydro"]["nHyd"]])
    
    scen_voume = deepcopy(scen_voume_all[1])
    scen_voume .=0
    for res = 1:nHyd
        scen_voume = scen_voume .+ (scen_voume_all[res].*results[:data][1]["hydro"]["Hydrogenerators"][res]["water_energy"])./(0.0036*results[:params]["stage_hours"])
    end

    plt = plotscenarios(scen_voume, title  = "Volume Reservoir",
                    ylabel = "MW",
                    xlabel = "Stages",
                    bottom_margin = 10mm,
                    right_margin = 10mm,
                    left_margin = 10mm               
                    )
    plt_total[nplots+1] = plt
    nplots += 1  

    # Inflows

    scen_inflows_all = convert(Array{Array{Float64,2},1},[[results[:data][1]["hydro"]["Hydrogenerators"][res]["inflow"][cidx(j,results[:data][1]["hydro"]["size_inflow"][1]),results[:simulations][i][j][:noise_term]] for i=1:nsim, j=1:nstages]' for res = 1:results[:data][1]["hydro"]["nHyd"]])
    
    scen_inflows = deepcopy(scen_inflows_all[1])
    scen_inflows .=0
    for res = 1:nHyd
        scen_inflows = scen_inflows .+ (scen_inflows_all[res].*results[:data][1]["hydro"]["Hydrogenerators"][res]["water_energy"])
    end

    plt = plotscenarios(scen_inflows, title  = "Inflows",
                    ylabel = "MW",
                    xlabel = "Stages",
                    bottom_margin = 10mm,
                    right_margin = 10mm,
                    left_margin = 10mm               
                    )
    plt_total[nplots+1] = plt
    nplots += 1

    if mod(nplots,nc) > 0 && floor(Int,nplots/nc) > 0
        l = @layout [ Plots.grid(floor(Int,nplots/nc),nc);  Plots.grid(1,mod(nplots,nc))]
        nlines = floor(Int,nplots/nc)+1
        l.heights = Plots.grid(2,1,heights=[floor(Int,nplots/nc)/nlines;1/nlines]).heights
    elseif floor(Int,nplots/nc) > 0
        l = @layout Plots.grid(floor(Int,nplots/nc),nc)
        nlines = floor(Int,nplots/nc)
        l.heights = Plots.grid(nlines,1,heights=[1/nlines for n = 1:nlines]).heights
    else
        l = @layout Plots.grid(1,mod(nplots,nc))
        nlines = 1
        l.heights = Plots.grid(1,1,heights=[1]).heights
    end

     return plot(plt_total[1:nplots]...,layout=l,size = (4*400, 500*ceil(Int,nplots/nc)),legend=false)
end

"""
    HydroPowerModels.plot_bound(m)

Plots the SDDP outer bound per iteration.
"""
function plot_bound(m)
    niter = length(m.policygraph.most_recent_training_results.log)
    val = round.([m.policygraph.most_recent_training_results.log[iter].bound for iter in 1:niter],digits =5)

    xticks = unique!([collect(1:Int(floor(niter/4)):niter);niter])
    plot(val,
        xticks = (xticks, [string(i) for  i in xticks]),
        label = "Bound",
        title = "Bound x iterations",
        bottom_margin = 10mm,
        right_margin = 10mm,
        left_margin = 10mm
        )
end