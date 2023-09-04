#################################################
# Parser to PowerModels Dict
# Ref: http://www.pserc.cornell.edu/matpower/manual.pdf
#################################################

function gen_dict(;
    name=nothing,
    ncost=2, # Number of terms to interpolate in cost funcion
    qc1max=0, # Maximum reactive power output at PC1 (MVAr)
    pg=0, # Active Generation (Not Used by PowerModels,but expected) 
    model=2, # Cost model, 1 = piecewise linear, 2 = polynomial
    shutdown=0, # Shutdown Cost
    startup=0, # Startup Cost
    qc2max=0, # Maximum reactive power output at PC2 (MVAr)
    ramp_agc=0,
    qg=0,  # Reactive Generation (Not Used by PowerModels,but expected) 
    gen_bus=2, # Bus Of Generator
    pmax=1, # Maximum Real Power Generation (u.u) (Will be multi by mbase)
    ramp_10=0,
    vg=1, # Voltage magnitude setpoint (p.u.)
    mbase=100, # Total MVA base of machine
    pc2=0, # Upper real power output of PQ capability curve (MW)
    index=1, # Index
    cost=[     # Cost terms
        2000,
        0,
    ],
    qmax=999, # Maximun Reacitive
    gen_status=1, # Status Generator (On 1, OFF 0)
    qmin=-999, # Minimum Reactive
    qc1min=0, # Minimum reactive power output at PC1 (MVAr)
    qc2min=0, # Minimum reactive power output at PC2 (MVAr)
    pc1=0, # Lower real power output of PQ capability curve (MW)
    ramp_q=0,
    ramp_30=0,
    pmin=0, # Minimum Real Power Generation (u.u) (Will be multi by mbase)
    apf=0, #[not] Area participation factor
)
    gen = Dict(
        "ncost" => ncost,
        "qc1max" => qc1max,
        "pg" => pg,
        "model" => model,
        "shutdown" => shutdown,
        "startup" => startup,
        "qc2max" => qc2max,
        "ramp_agc" => ramp_agc,
        "qg" => qg,
        "gen_bus" => gen_bus,
        "pmax" => pmax,
        "ramp_10" => ramp_10,
        "vg" => vg,
        "mbase" => mbase,
        "pc2" => pc2,
        "index" => index,
        "cost" => cost,
        "qmax" => qmax,
        "gen_status" => gen_status,
        "qmin" => qmin,
        "qc1min" => qc1min,
        "qc2min" => qc2min,
        "pc1" => pc1,
        "ramp_q" => ramp_q,
        "ramp_30" => ramp_30,
        "pmin" => pmin,
        "apf" => apf,
    )

    if !isnothing(name)
        gen["name"] = name
    end
    return gen
end

function branch_dict(;
    name=nothing,
    br_r=0.065, # Resistance (p.u.)
    rate_a=1, #  MVA rating A (long term rating), set to 0 for unlimited
    shift=0, #  Transformer phase shift angle (degrees), positive ⇒ delay
    br_x=1, #  Reactance (p.u.)
    g_to=0,
    g_fr=0,
    b_fr=0.225,
    f_bus=1, # “from” bus number
    br_status=1, # Initial branch status, 1 = in-service, 0 = out-of-service
    t_bus=3, # “to” bus number
    b_to=0.225,
    index=1, # Index
    angmin=-1.0472, # minimum angle difference, θf − θt (rad)
    angmax=1.0472, # maximum angle difference, θf − θt (rad)
    transformer=false, # Bool to indicate if it is transformer
    tap=1,
) #  transformer off nominal turns ratio
    branch = Dict{String,Any}(
        "br_r" => br_r,
        "rate_a" => rate_a,
        "shift" => shift,
        "br_x" => br_x,
        "g_to" => g_to,
        "g_fr" => g_fr,
        "b_fr" => b_fr,
        "f_bus" => f_bus,
        "br_status" => br_status,
        "t_bus" => t_bus,
        "b_to" => b_to,
        "index" => index,
        "angmin" => angmin,
        "angmax" => angmax,
        "transformer" => transformer,
        "tap" => tap,
    )

    if !isnothing(name)
        branch["name"] = name
    end
    return branch
end

function bus_dict(;
    name=nothing,
    zone=1, #  loss zone (positive integer)
    bus_i=1, # bus number (positive integer)
    bus_type=1,  # bus type (1 = PQ, 2 = PV, 3 = ref, 4 = isolated)
    vmax=1.1, # maximum voltage magnitude (p.u.)
    area=1, # area number (positive integer)
    vmin=0.9, # minimum voltage magnitude (p.u.)
    index=1, # index
    va=0, # voltage angle (degrees)
    vm=1, # voltage magnitude (p.u.)
    base_kv=0,
) # base voltage (kV)
    bus = Dict{String,Any}(
        "zone" => zone,
        "bus_i" => bus_i,
        "bus_type" => bus_type,
        "vmax" => vmax,
        "area" => area,
        "vmin" => vmin,
        "index" => index,
        "va" => va,
        "vm" => vm,
        "base_kv" => base_kv,
    )
    if !isnothing(name)
        bus["name"] = name
    end
    return bus
end

function load_dict(;
    load_bus=1, # bus where load is present
    status=1, # status (ON: 1, OFF:0)
    pd=1, # reactive power demand
    qd=0.12 * pd, # real power demand
    index=1,
) # index
    return lod = Dict{String,Any}(
        "load_bus" => load_bus, "status" => status, "qd" => qd, "pd" => pd, "index" => index
    )
end

function _powermodels_dict_(;
    bus::Dict{String,Dict{String,Any}}=Dict{String,Dict{String,Any}}(),
    source_type::String="matpower",
    name="CaseX",
    cost_deficit=1000,
    dcline::Dict{String,Any}=Dict{String,Any}(),
    source_version::Dict{String,Any}=Dict(
        "major" => 2, "minor" => 0, "patch" => 0, "prerelease" => [], "build" => []
    ),
    gen::Dict{String,Dict{String,Any}}=Dict{String,Dict{String,Any}}(),
    branch::Dict{String,Dict{String,Any}}=Dict{String,Dict{String,Any}}(),
    storage::Dict{String,Dict{String,Any}}=Dict{String,Dict{String,Any}}(),
    baseMVA::Float64=100.0,
    per_unit::Bool=true,
    shunt::Dict{String,Dict{String,Any}}=Dict{String,Dict{String,Any}}(),
    load::Dict{String,Dict{String,Any}}=Dict{String,Dict{String,Any}}(),
)
    pm = Dict(
        "name" => name,
        "cost_deficit" => cost_deficit,
        "bus" => bus,
        "source_type" => source_type,
        "dcline" => dcline,
        "source_version" => source_version,
        "gen" => gen,
        "branch" => branch,
        "storage" => storage,
        "baseMVA" => baseMVA,
        "per_unit" => per_unit,
        "shunt" => shunt,
        "load" => load,
    )
    return pm
end

function powermodels_dict(;
    bus::Array{Dict{String,Any}}=Array{Dict{String,Any}}(undef, 0),
    source_type::String="matpower",
    name="CaseX",
    cost_deficit=1000,
    dcline::Dict{String,Any}=Dict{String,Any}(),
    source_version::Dict{String,Any}=Dict(
        "major" => 2, "minor" => 0, "patch" => 0, "prerelease" => [], "build" => []
    ),
    gen::Array{Dict{String,Any}}=Array{Dict{String,Any}}(undef, 0),
    branch::Array{Dict{String,Any}}=Array{Dict{String,Any}}(undef, 0),
    storage::Array{Dict{String,Any}}=Array{Dict{String,Any}}(undef, 0),
    baseMVA::Float64=100.0,
    per_unit::Bool=true,
    shunt::Array{Dict{String,Any}}=Array{Dict{String,Any}}(undef, 0),
    load::Array{Dict{String,Any}}=Array{Dict{String,Any}}(undef, 0),
)
    return pm = _powermodels_dict_(;
        bus=Dict(Pair.(string.(collect(1:size(bus, 1))), bus)),
        source_type=source_type,
        name=name,
        cost_deficit=cost_deficit,
        dcline=dcline,
        source_version=source_version,
        gen=Dict(Pair.(string.(collect(1:size(gen, 1))), gen)),
        branch=Dict(Pair.(string.(collect(1:size(branch, 1))), branch)),
        storage=Dict(Pair.(string.(collect(1:size(storage, 1))), storage)),
        baseMVA=baseMVA,
        per_unit=per_unit,
        shunt=Dict(Pair.(string.(collect(1:size(shunt, 1))), shunt)),
        load=Dict(Pair.(string.(collect(1:size(load, 1))), load)),
    )
end
