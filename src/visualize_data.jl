using Plots, Plots.PlotMeasures
import Cairo, Fontconfig
using LightGraphs, GraphPlot, Compose

"""Plots a set o scenarios"""
function plotscenarios(scen::Array{Float64,2}; savepath::String ="",
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
    for q=0.05:0.1:0.25
        plot!(p1, med_scen, ribbon=(med_scen-quantile_scen(scen,q),quantile_scen(scen,1-q)-med_scen), 
                            color = "gray", label = "")
    end
    plot!(p1, maximum(scen; dims=2), label = "Max and Min", color = "Steel Blue")
    plot!(p1, minimum(scen; dims=2), label = "", color = "Steel Blue")
    if save
        savefig(p1, savepath*"$fileformat")
        return nothing
    end

    return p1    
end

"""Common Plots"""
function plotresults(results::Dict;nplts::Int = 3)

    plt_total = Array{Plots.Plot}(undef,10)
    nplots = 0
    nsim = length(results[:simulations])
    nstages = length(results[:simulations][1])

    # Thermal Generation

    ngen = length(results[:data][1]["powersystem"]["gen"])
    idxhyd = idx_hydro(results[:data][1])
    idxgen = setdiff(collect(1:min(ngen,nplts)),idxhyd)
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
    plt_total[nplots+1] = plot(plt...,layout=(1,size(plt,1)))
    nplots += 1

    # Thermal Reactive Generation

    if results[:params]["model_constructor_grid"] == PowerModels.ACPPowerModel
        scen_qgen = [[results[:simulations][i][j][:powersystem]["solution"]["gen"]["$gen"]["qg"] for i=1:100, j=1:results[:params]["stages"]]'.*baseMVA for gen =1:ngen]

        plt =   [plotscenarios(scen_qgen[gen], title  = "Thermal Reactive Generation $gen",
                ylabel = "MW",
                xlabel = "Stages",
                bottom_margin = 10mm,
                right_margin = 10mm,
                left_margin = 10mm                
                )
            for gen in idxgen
        ]
        plt_total[nplots+1] = plot(plt...,layout=(1,size(plt,1)))
        nplots += 1
    end
    # Branch flow

    nbrc = length(results[:data][1]["powersystem"]["branch"])
    idxbrc = collect(1:min(nbrc,nplts))
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
    plt_total[nplots+1] = plot(plt...,layout=(1,size(plt,1)))
    nplots += 1

    # Branch Reactive flow

    if results[:params]["model_constructor_grid"] == PowerModels.ACPPowerModel
        scen_branch_qf = [[results[:simulations][i][j][:powersystem]["solution"]["branch"]["$brc"]["qf"] for i=1:100, j=1:results[:params]["stages"]]'.*baseMVA for brc =1:nbrc]

        plt =   [plotscenarios(scen_branch_qf[brc], title  = "Branch Reactive Flow $brc",
                ylabel = "MW",
                xlabel = "Stages",
                bottom_margin = 10mm,
                right_margin = 10mm,
                left_margin = 10mm                
                )
            for brc in idxbrc
        ]
        plt_total[nplots+1] = plot(plt...,layout=(1,size(plt,1)))
        nplots += 1
    end

    # Voltage angle
    
    if results[:params]["model_constructor_grid"] != PowerModels.GenericPowerModel{PowerModels.SOCWRForm}
        nbus = length(results[:data][1]["powersystem"]["bus"])
        idxbus = collect(1:min(nbus,nplts))
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
        plt_total[nplots+1] = plot(plt...,layout=(1,size(plt,1)))
        nplots += 1
    
    end

    # Nodal price

    nbus = length(results[:data][1]["powersystem"]["bus"])
    idxbus = collect(1:min(nbus,nplts))
    scen_pld = convert(Array{Array{Float64,2},1},[[-results[:simulations][i][j][:powersystem]["solution"]["bus"]["$bus"]["lam_kcl_r"] for i=1:nsim, j=1:nstages]' for bus =1:nbus])

    plt =   [plotscenarios(scen_pld[bus], title  = "Nodal price bus $bus",
                ylabel = "Dollars/MW",
                xlabel = "Stages",
                bottom_margin = 10mm,
                right_margin = 10mm,
                left_margin = 10mm               
                )
            for bus in idxbus
    ]
    plt_total[nplots+1] = plot(plt...,layout=(1,size(plt,1)))
    nplots += 1

    # Hydro Generation
    
    plt =   [   plotscenarios(scen_gen[gen], title  = "Hydro Generation $gen",
                    ylabel = "MW",
                    xlabel = "Stages",
                    bottom_margin = 10mm,
                    right_margin = 10mm,
                    left_margin = 10mm               
                    )
                for gen in idxhyd[1:min(size(idxhyd,1),nplts)]
    ]
    plt_total[nplots+1] = plot(plt...,layout=(1,size(plt,1)))
    nplots += 1

    # Hydro Turn
    
    scen_turn = convert(Array{Array{Float64,2},1},[[results[:simulations][i][j][:reservoirs][:outflow][res] for i=1:nsim, j=1:nstages]' for res = 1:results[:data][1]["hydro"]["nHyd"]])
    
    plt =   [   plotscenarios(scen_turn[res], title  = "Hydro Turn $res",
                    ylabel = "m³",
                    xlabel = "Stages",
                    bottom_margin = 10mm,
                    right_margin = 10mm,
                    left_margin = 10mm               
                    )  
                for res = 1:min(results[:data][1]["hydro"]["nHyd"],nplts)
    ]
    plt_total[nplots+1] = plot(plt...,layout=(1,size(plt,1)))
    nplots += 1

    # Hydro Spill
    
    scen_spill = convert(Array{Array{Float64,2},1},[[results[:simulations][i][j][:reservoirs][:spill][res] for i=1:nsim, j=1:nstages]' for res = 1:results[:data][1]["hydro"]["nHyd"]])
    
    plt =   [   plotscenarios(scen_spill[res], title  = "Hydro Spill $res",
                    ylabel = "Hm³",
                    xlabel = "Stages",
                    bottom_margin = 10mm,
                    right_margin = 10mm,
                    left_margin = 10mm               
                    )  
                for res = 1:min(results[:data][1]["hydro"]["nHyd"],nplts)
    ]
    plt_total[nplots+1] = plot(plt...,layout=(1,size(plt,1)))
    nplots += 1    

    # Reservoir Volume

    scen_voume = convert(Array{Array{Float64,2},1},[[results[:simulations][i][j][:reservoirs][:reservoir][res].out for i=1:nsim, j=1:nstages]' for res = 1:results[:data][1]["hydro"]["nHyd"]])
    
    plt =   [   plotscenarios(scen_voume[res], title  = "Volume Reservoir $res",
                    ylabel = "Hm³",
                    xlabel = "Stages",
                    bottom_margin = 10mm,
                    right_margin = 10mm,
                    left_margin = 10mm               
                    )  
                for res = 1:min(results[:data][1]["hydro"]["nHyd"],nplts)
    ]
    
    plt_total[nplots+1] = plot(plt...,layout=(1,size(plt,1)))
    nplots += 1

    # Inflows

    scen_inflows = convert(Array{Array{Float64,2},1},[[results[:data][1]["hydro"]["Hydrogenerators"][res]["inflow"][j,results[:simulations][i][j][:noise_term]] for i=1:nsim, j=1:nstages]' for res = 1:results[:data][1]["hydro"]["nHyd"]])
    
    plt =   [   plotscenarios(scen_inflows[res], title  = "Inflows Reservoir $res",
                    ylabel = "m³",
                    xlabel = "Stages",
                    bottom_margin = 10mm,
                    right_margin = 10mm,
                    left_margin = 10mm               
                    )  
                for res = 1:min(results[:data][1]["hydro"]["nHyd"],nplts)
    ]
    
    plt_total[nplots+1] = plot(plt...,layout=(1,size(plt,1)))
    nplots += 1

    return plot(plt_total[1:nplots]...,layout=(nplots,1),size = (nplts*400, 500*nplots),legend=false)
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
    
    if results[:params]["model_constructor_grid"] != PowerModels.GenericPowerModel{PowerModels.SOCWRForm}

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

function plot_grid(data::Dict,path::String)

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

    # node size
    nodesize = fill(0.4,nbus+sum(load_nodes .> 0)+sum(hydro_nodes .> 0)+sum(thermal_nodes .> 0))

    # nodes membership (3: Hydro, 2: Thermal)
    membership = fill(1,nbus+sum(load_nodes .> 0)+sum(hydro_nodes .> 0)+sum(thermal_nodes .> 0))


    # create nodes
    for bus_i in 1:length(data["powersystem"]["bus"])
        if hydro_nodes[bus_i] > 0
            add_vertex!(g)
            nNodes +=1
            add_edge!(g, nNodes, bus_i)
            membership[nNodes] = 3
            nodesize[nNodes] = 1.005^hydro_nodes[bus_i]
        end

        if thermal_nodes[bus_i] > 0
            add_vertex!(g)
            nNodes +=1
            add_edge!(g, nNodes, bus_i)
            membership[nNodes] = 2
            nodesize[nNodes] = 1.005^hydro_nodes[bus_i]
        end

        if load_nodes[bus_i] > 0
            add_vertex!(g)
            nNodes +=1
            add_edge!(g, nNodes, bus_i)
            membership[nNodes] = 4
            nodesize[nNodes] = 1.005^hydro_nodes[bus_i]
        end

    end
    
    nodecolor = ["black", "red", "blue", "orange"]

    # membership color
    nodefillc = nodecolor[Int64.(membership)]

    draw(PDF(path, 15cm, 15cm), gplot(g, nodefillc=nodefillc, nodesize=nodesize))
end
