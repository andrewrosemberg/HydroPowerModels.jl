
using RecipesBase
using RecipesBase: grid, @layout

include(joinpath(@__DIR__, "sddp_publication_plot.jl"))

"""
    HydroPowerModels.plot_aggregated_results(results::Dict;nc::Int=3)

Plot Aggregated Results. Figures are of aggregated quantities, but the methods used to aggregate were chosen in order to help analysis. For example: The final nodal price is an average of nodal prices weighted by the contribution of local loads to the total demand; Reservoir volume was grouped weighted by the amount of energy that could be produced by the stored water (as was the inflow of water). 

Paremeter:
-   results: Simulation results.

"""
function plot_aggregated_results(results::Dict;nc::Int=3)
    plt_total = Array{Any}(undef,20)
    nplots = 0

    # Thermal Generation
    idxhyd = idx_hydro(results[:data][1])
    plt = HydroPowerModels.publication_plot(results[:simulations], title = "Thermal Generation", 
        xlabel = "Stage", ylabel = "MW",
    ) do data
        baseMVA =  data[:powersystem]["solution"]["baseMVA"]
        return sum(val["pg"] * baseMVA for (gen,val) in data[:powersystem]["solution"]["gen"] if !(gen in string.(idxhyd)))
    end

    plt_total[nplots+1] = plt
    nplots += 1

    # Nodal price
    nbus = length(results[:data][1]["powersystem"]["bus"])
    try
    plt = HydroPowerModels.publication_plot(results[:simulations], title = "Load Weighted Average Nodal price", 
        xlabel = "Stage", ylabel = "\$/MW",
    ) do sim_results, t
        baseMVA = sim_results[:powersystem]["solution"]["baseMVA"]
        data = results[:data][min(t,length(results[:data]))]
        load_nodes = fill(0.0, nbus)
        for i in 1:length(data["powersystem"]["load"])
            bus_i = data["powersystem"]["load"]["$i"]["load_bus"]
            load_nodes[bus_i] += data["powersystem"]["load"]["$i"]["pd"] * data["powersystem"]["baseMVA"]
        end
    
        return sum(
            -val["lam_kcl_r"] * load_nodes[parse(Int,bus)] for (bus,val) in sim_results[:powersystem]["solution"]["bus"]
        ) / (sum(load_nodes) * baseMVA)
    end
    plt_total[nplots+1] = plt
    nplots += 1
    catch
    end
    # Deficit
    try
     plt = HydroPowerModels.publication_plot(results[:simulations], title = "Deficit", 
        xlabel = "Stage", ylabel = "MW",
    ) do data
        baseMVA =  data[:powersystem]["solution"]["baseMVA"]
        return sum(val["deficit"] * baseMVA for (bus,val) in data[:powersystem]["solution"]["bus"])
    end
    plt_total[nplots+1] = plt
    nplots += 1
    catch
    end

    # Hydro Generation
    plt = HydroPowerModels.publication_plot(results[:simulations], title = "Hydro Generation", 
        xlabel = "Stage", ylabel = "MW",
    ) do data
        baseMVA =  data[:powersystem]["solution"]["baseMVA"]
        return sum(val["pg"] * baseMVA for (gen,val) in data[:powersystem]["solution"]["gen"] if (gen in string.(idxhyd)))
    end
    plt_total[nplots+1] = plt
    nplots += 1

    # Reservoir Outflow
    plt = HydroPowerModels.publication_plot(results[:simulations], title = "Reservoir Outflow", 
        xlabel = "Stage", ylabel = "m³/s",
    ) do data
        return sum(data[:reservoirs][:outflow])
    end
    plt_total[nplots+1] = plt
    nplots += 1

    # Reservoir Spill
    plt = HydroPowerModels.publication_plot(results[:simulations], title = "Reservoir Spill", 
        xlabel = "Stage", ylabel = "m³/s",
    ) do data
        return sum(data[:reservoirs][:spill])
    end
    plt_total[nplots+1] = plt
    nplots += 1  

    # Reservoir Volume
    water_energy!(results[:data][1])

    plt = HydroPowerModels.publication_plot(results[:simulations], title = "Volume Reservoir", 
        xlabel = "Stage", ylabel = "MW",
    ) do data
        return sum(val.out * results[:data][1]["hydro"]["Hydrogenerators"][res]["water_energy"] for (res,val) in enumerate(data[:reservoirs][:reservoir])) / (0.0036 * results[:params]["stage_hours"])
    end
    plt_total[nplots+1] = plt
    nplots += 1  

    # Inflows
    plt = HydroPowerModels.publication_plot(results[:simulations], title = "Inflows", 
        xlabel = "Stage", ylabel = "MW",
    ) do data, t
        return sum(
            results[:data][1]["hydro"]["Hydrogenerators"][res]["inflow"][cidx(t,results[:data][1]["hydro"]["size_inflow"][1]),data[:noise_term]] * 
            results[:data][1]["hydro"]["Hydrogenerators"][res]["water_energy"] for 
            (res,val) in enumerate(data[:reservoirs][:reservoir])
        )
    end
    plt_total[nplots+1] = plt
    nplots += 1

    if mod(nplots,nc) > 0 && floor(Int,nplots/nc) > 0
        nlines = floor(Int,nplots/nc)+1
        heights_aux = [floor(Int,nplots/nc)/nlines;1/nlines]
        l = @layout [grid(floor(Int,nplots/nc),nc);  grid(1,mod(nplots,nc))]
        l[1].attr[:height] = heights_aux[1]
    elseif floor(Int,nplots/nc) > 0
        l = @layout grid(floor(Int,nplots/nc),nc)
    else
        l = @layout grid(1,mod(nplots,nc))
    end

     return RecipesBase.plot(plt_total[1:nplots]...,layout=l,size = (4 * 400, 500 * ceil(Int,nplots/nc)),legend=false)
end
