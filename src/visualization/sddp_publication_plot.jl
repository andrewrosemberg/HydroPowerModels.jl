#  Copyright (c) 2017-23, Oscar Dowson and SDDP.jl contributors.
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at http://mozilla.org/MPL/2.0/.

################################################
# All functions are a copy from SDDP.jl apart from 
# a slightly modified `publication_data` that 
# calls `stage_function` passing which stage its in at each step in the loop.
################################################

function n_args(f::Function)
    @assert length(methods(f)) == 1
    return methods(f).mt.max_args-1
end


function publication_data(
    dataset::Vector{<:Vector{<:AbstractDict}},
    quantiles::Vector{Float64},
    stage_function::Function,
)
    max_stages = maximum(length.(dataset))
    output_array = fill(NaN, length(quantiles), max_stages)
    for stage in 1:max_stages
        stage_data = if n_args(stage_function) == 1
            stage_function.([data[stage] for data in dataset])
        else
            stage_function.([data[stage] for data in dataset], stage)
        end
        output_array[:, stage] .= Statistics.quantile(stage_data, quantiles)
    end
    return output_array
end

function publication_plot(
    data_function::Function,
    simulations::Vector{<:Vector{<:AbstractDict}};
    kwargs...,
)
    # An annoying over-load so that we can provide a consistent interface
    # instead of the Plots.jl generated `publicationplot`.
    return HydroPowerModels.publicationplot(simulations, data_function; kwargs...)
end

RecipesBase.@userplot PublicationPlot

RecipesBase.@recipe function f(
    publication_plot::PublicationPlot;
    quantile = [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0],
)
    dataset, stage_function = publication_plot.args
    size --> (500, 300)
    data_matrix = publication_data(dataset, sort(quantile), stage_function)
    for i in 1:floor(Int, size(data_matrix, 1) / 2)
        μ = 0.5 * (data_matrix[i, :] + data_matrix[end-i+1, :])
        r = data_matrix[end-i+1, :] - μ
        RecipesBase.@series begin
            x := 1:size(data_matrix, 2)
            ribbon := r
            y := μ
            fillalpha --> 0.2
            seriesalpha --> 0.0
            seriescolor --> "#00467F"
            label := ""
            ()
        end
    end
    if mod(size(data_matrix, 1), 2) == 1
        qi = ceil(Int, size(data_matrix, 1) / 2)
        RecipesBase.@series begin
            x := 1:size(data_matrix, 2)
            y := data_matrix[qi, :]
            seriescolor --> "#00467F"
            label := ""
            ()
        end
    end
end