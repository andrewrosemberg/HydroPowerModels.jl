using JuMP, SDDP


#overload function: SDDPModel

function SDDPModelHydro(build!::Function;
    sense                = :Min,
    stages::Int          = 1,
    objective_bound      = nothing,
    markov_transition    = [ones(Float64, (1,1)) for t in 1:stages],
    risk_measure         = Expectation(),
    cut_oracle::SDDP.AbstractCutOracle = SDDP.DefaultCutOracle(),
    solver               = UnsetSolver(),
    value_function       = SDDP.DefaultValueFunction(cut_oracle),
    )
    if objective_bound == nothing
        error("You must specify the objective_bound keyword")
    end
    # check number of arguments to SDDPModel() do [args...] ...  model def ... end
    num_args = SDDP.n_args(build!)
    if num_args < 2
        error("""Too few arguments in
            SDDPModel() do args...
            end""")
    elseif num_args > 3
        error("""Too many arguments
            SDDPModel() do args...
            end""")
    end

    # New SDDPModel
    m = SDDP.newSDDPModel(sense, SDDP.getel(SDDP.AbstractValueFunction, value_function, 1, 1), build!)

    for t in 1:stages
        markov_transition_matrix = SDDP.getel(Array{Float64, 2}, markov_transition, t)
        # check that
        if num_args == 2 && size(markov_transition_matrix, 2) > 1
            error("""Because you specified a noise tree in the SDDPModel constructor, you need to use the

                SDDPModel() do sp, stage, markov_state
                    ... model definition ...
                end

            syntax.""")
        end
        stage = SDDP.Stage(t,markov_transition_matrix)
        for i in 1:size(markov_transition_matrix, 2)
            mod = SDDP.Subproblem(
                finalstage     = (t == stages),
                stage          = t,
                markov_state   = i,
                sense          = SDDP.optimisationsense(sense),
                bound          = float(SDDP.getel(Real, objective_bound, t, i)),
                risk_measure   = SDDP.getel(SDDP.AbstractRiskMeasure, risk_measure, t, i),
                value_function = deepcopy(SDDP.getel(SDDP.AbstractValueFunction, value_function, t, i))
            )
            
            # dispatch to correct function
            # maybe we should do this with tuples
            if num_args == 3
                build!(mod, t, i)
            else
                build!(mod, t)
            end

            setsolver(mod, SDDP.getel(JuMP.MathProgBase.AbstractMathProgSolver, solver, t, i))

            # # Uniform noise probability for now
            if length(SDDP.ext(mod).noises) != length(SDDP.ext(mod).noiseprobability)
                SDDP.setnoiseprobability!(mod, ones(length(SDDP.ext(mod).noises)) / length(SDDP.ext(mod).noises))
            end
            push!(stage.subproblems, mod)
        end
        push!(m.stages, stage)
    end
    m
end