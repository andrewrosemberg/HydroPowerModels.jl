function hydrogenerator_dict(;
    index=1,
    index_grid=1,
    name=nothing,
    max_volume=100,
    min_volume=0,
    max_turn=100,
    min_turn=0,
    initial_volume=0.0,
    production_factor=1.0,
    spill_cost=0.0,
    downstream_turn=[],
    downstream_spill=[],
)
    hydrogen = Dict(
        "index" => index,
        "index_grid" => index_grid,
        "max_volume" => max_volume,
        "min_volume" => min_volume,
        "max_turn" => max_turn,
        "min_turn" => min_turn,
        "initial_volume" => initial_volume,
        "production_factor" => production_factor,
        "spill_cost" => spill_cost,
        "downstream_turn" => downstream_turn,
        "downstream_spill" => downstream_spill,
    )
    if name != nothing
        hydrogen["name"] = name
    end
    return hydrogen
end

function hydro_dict(; hydrogenarray=[])
    return hydro_dict = Dict("Hydrogenerators" => hydrogenarray)
end
