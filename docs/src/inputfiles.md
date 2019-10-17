# Input Files

HydroPowerModels.jl uses case description files to specify cases. The following subsections intend to give a brief description of those files.

## Network Description: "PowerModels.json" 

Network description follows the standards of [PowerModels.jl](https://lanl-ansi.github.io/PowerModels.jl/stable/network-data/), but some extra information is required. Thus, we use a JSON file containing the information required by PowerModels.jl, with the [MATPOWER notation](https://matpower.org/docs/MATPOWER-manual-6.0b1.pdf), and introduced some keys to add the extra information we required (as the "cost of deficit").

This following is an example of a Network Description file:

```
{
  "bus": {
    "1": {
      "zone": 1, # [not] loss zone (positive integer).
      "bus_i": 1, # bus number (positive integer).
      "bus_type": 3, # bus type (1 = PQ, 2 = PV, 3 = ref, 4 = isolated).
      "vmax": 1.1, # maximum voltage magnitude (p.u.).
      "area": 1, # area number (positive integer).
      "vmin": 0.9, # minimum voltage magnitude (p.u.).
      "index": 1, # index
      "va": 0, # voltage angle (degrees)
      "vm": 1, # voltage magnitude (p.u.)
      "base_kv": 0 ## base voltage (kV)
    }#
  },
  "source_type": "matpower", # source file type which generated this json. (if exists)
  "name": "case3", # case name
  "dcline": {}, # [not] DC lines description
  "source_version": { # source file version (if exists)
    "major": 2,
    "minor": 0,
    "patch": 0,
    "prerelease": [],
    "build": []
  },
  "gen": {
    "1": {
      "ncost": 2, # Number of terms to interpolate in cost funcion.  
      "qc1max": 0, # Maximum reactive power output at PC1 (MVAr).
      "pg": 0, # Active Generation (Not Used by PowerModels,but expected).
      "model": 2, # Cost model, 1 = piecewise linear, 2 = polynomial.
      "shutdown": 0, # Shutdown Cost.
      "startup": 0, # Startup Cost.
      "qc2max": 0, # Maximum reactive power output at PC2 (MVAr).
      "ramp_agc": 0, # [not]
      "qg": 0, # Reactive Generation (Not Used by PowerModels,but expected).
      "gen_bus": 2, # Bus Of Generator
      "pmax": 1, # Maximum Real Power Generation (u.u) (Will be multi by mbase).
      "ramp_10": 0, # [not]
      "vg": 1, # Voltage magnitude setpoint (p.u.).
      "mbase": 100, # (MVA) Total MVA base of machine.
      "pc2": 0, # Upper real power output of PQ capability curve (MW).
      "index": 1, # Index
      "cost": [ # (dol/(MW/MVA)) Cost terms
        18, # linear factor.
        0 # intercept.
      ],
      "qmax": 100, # Maximun Reacitive Power Generation
      "gen_status": 1, # Status Generator (On 1, OFF 0).
      "qmin": -100, # Minimum Reactive Power Generation
      "qc1min": 0, # Minimum reactive power output at PC1 (MVAr).
      "qc2min": 0, # Minimum reactive power output at PC2 (MVAr).
      "pc1": 0, # Lower real power output of PQ capability curve (MW).
      "ramp_q": 0, # [not]
      "ramp_30": 0, # [not]
      "pmin": 0, # Minimum Real Power Generation (u.u) (Will be multi by mbase).
      "apf": 0 # [not] Area participation factor.
    }
  },
  "branch": {
    "1": {
      "br_r": 0.065, # Resistance (p.u.).
      "rate_a": 1, #  MVA rating A (long term rating), set to 0 for unlimited.
      "shift": 0, #  Transformer phase shift angle (degrees), positive ⇒ delay.
      "br_x": 1, #  Reactance (p.u.).
      "g_to": 0, # [not]
      "g_fr": 0, # [not]
      "b_fr": 0.225,
      "f_bus": 1, # “from” bus number.
      "br_status": 1, # Initial branch status, 1 = in-service, 0 = out-of-service.
      "t_bus": 3, # “to” bus number.
      "b_to": 0.225,
      "index": 1, # Index.
      "angmin": -1.0472, # minimum angle difference, θf − θt (rad).
      "angmax": 1.0472, # maximum angle difference, θf − θt (rad).
      "transformer": false, # Bool to indicate if it is transformer.
      "tap": 1 #  transformer off nominal turns ratio.
    }
  },
  "storage": {}, # [not] storages descriptions
  "baseMVA": 100,
  "per_unit": true,
  "shunt": {}, # [not]
  "switch": {}, # [not]
  "cost_deficit": 1000, # cost of deficit in (dol/MW)
  "load": {
    "1": {
      "load_bus": 3, # load's bus number.
      "status": 1, # Initial load status, 1 = in-service, 0 = out-of-service.
      "qd": 0, # reactive power demand.
      "pd": 1, # (MW) real power demand.
      "index": 1 # index.
    }
  }
}

```
## Hydro Generators Description: "hydro.json" 

This is an example of a Hydro Description file:

```
{
    "Hydrogenerators":[
        {   
            "index": 1, # Index of Hydrogenerators.
            "index_grid": 3, # Index of generator in network.
            "name": "", # Name.
            "max_volume":10, # (Hm3) Maximun Volume of Reservoir.
            "min_volume":0, # (Hm3) Minimun Volume of Reservoir.
            "max_turn": 100 # (m3/s) Maximun Outflow of Reservoir.
            "min_turn": 0 # (m3/s) Minimun Outflow of Reservoir.
            "initial_volume":0, # (Hm3) Initial Volume of Reservoir.
            "production_factor":1, # (MW/ (m3/s)) Production Factor.
            "spill_cost":0, # (dol/Hm3) Cost of Spillage.
            "downstream_turn": [], # Hydro Generators downstream of turn.
            "downstream_spill": [] # Hydro Generators downstream of spillage.
        }
    ]
}

```

## Inflows: "inflows.csv" 

Inflows are expected in (m3/s) in a csv file representing a matrix, where rows are the stages and columns are the scenarious.