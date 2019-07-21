# Review of @frapac

The paper is overall well-writen, and to my opinion fully meet
the standart required for the JuliaCon. I would accept the preprint
for publication, once some minor comments are adressed.


## Generic comments

- I think some references are missing in the article. Some of them are pointed
  out in the Github review. When dealing with Stochastic Programming and
  Dynamic Programming, the works of Bellman [1] and Bertsekas [2] have to be quoted.
  Refering to the book of Shapiro, Dentcheva and Ruczinsky [3] would also
  be appreciated.

- Speaking of Shapiro, was the package tested on the seminal use-case presented
  by Shapiro in [4] ? This use-case is often used as a reference to assess the
  performance of the SDDP algorithm, and it would seem relevant to add it
  in the `examples` folder (or at least a proxy model of it as the data may
  be closed-source).

- More generally, I think the package `HydroPowerModels` is a good place to
  write benchmarks for SDDP libraries. Is there any plan about it?

- Speaking of benchmarks, do the authors write the specifications of the
  files specifying the underlying models (as the `json` files in the `testcases` folder)?
  I remember having some discussions with Oscar Dowson on specifying
  stochastic programming models in MathOptFormat (see e.g. [5]). Is there
  some plan to import directly the optimization models from such formats?

- The `examples` folder stores interesting examples, relevant to the application.
  It would be interesting to write a script comparing the performance of
  the different OPF relaxations on the `case3` use-case, in a deterministic
  setting. I would also appreciate to minimize the dependency to Weave (for
  instance by removing the reference to `WEAVE_ARGS` in the scripts).

- The case-study given in the article is interesting. I think adding some
  results detailing the convergence of SDDP would be relevant (e.g.
  what is the final gap between the lower and the upper bounds at the
  end of the optimization?). Also, I would state explicitly which stopping
  criterion (stalling, max iterations or statistical stopping tests) is being
  used when calling `SDDP.jl`.

- Is it possible to add the case-study described in the paper in the
  package? I would be interested to run it locally.

- I think it could be relevant to write a conclusion stating the future
  development roadmap of `HydroPowerModels.jl`.


## Technical comments

In the next, I will refer to OPF-SP as the stochastic programming model
implementing the OPF physical equations.

- In my opinion, the authors must emphasize that SDDP is guarantee
  to converge only if the optimization model is convex (ref [6]).

- The convergence of SDDP in the non-convex case is not guaranteed. The authors
  should emphasized that when dealing with polar equations in OPF-SP,
  SDDP acts only as a heuristic. It would be interesting to have a discussion
  on the quality of the cuts computed in this case.

- Dealing with non-linear subproblems in SDDP implies to use non-linear (NLP)
  optimization solvers (as Ipopt or Knitro). However, on the contrary to
  Gurobi or other classical solvers, these solvers do not support modifying
  the optimization problem inplace (for instance when adding linear cuts to
  the model). `Ipopt.jl` rebuilds a new optimization
  model from scratch each time `MOI.optimize!` is being called, and `Knitro.jl`
  does not support the modification of constraints after the resolving (even
  if that won't require too much works to add this functionnality to the
  code of Knitro). When using NLP solvers in SDDP, I am wondering how much the
  performance deteriorate comparing to classical solvers as Xpress, CPLEX
  or Gurobi?

- A great enhancement of the package would be to split the model used
  in the **optimization** pass (when calling SDDP.jl) from the model used
  in the **simulation** pass. Personally, I see SDDP only as a tool to
  compute the value functions (by approximating them with linear cuts).
  The optimization pass requires certain hypotheses to hold (as the convexity
  of the underlying optimization model, or some assumption about the uncertainties)
  that do not hold necessarily in simulation.
  An interesting use-case would be to do the following:
  * Compute the value functions on a convex relaxation of the OPF-SP model with SDDP.
  * Test these value functions in assessment, by using the original
    non-linear version of the OPF-SP problem.

- The same holds for inflow data. Most of the time, the optimizer used
  a set of inflow scenarios to fit some probability laws (with discrete support).
  However, the choice of the modeling is up to the optimizer (e.g. how many
  points to use in the discrete supports).
  I think the authors should put more emphasis on this assessment part in the
  paper.

- In this perspective, I think it could be relevant to implement a code that
  fit the probability laws directly from the inflow/demands scenarios.
  That would ease the importation of other models in the package. Furthermore,
  it would be interesting to model the inflows as a Markov-chain
  (which is currently supported in `SDDP.jl`, as far as I remember).


## References

[1] Bellman, Richard. "Dynamic programming." Science 153.3731 (1966): 34-37.

[2] Bertsekas, Dimitri P., et al. Dynamic programming and optimal control. Vol. 1. No. 2. Belmont, MA: Athena scientific, 1995.

[3] Shapiro, Alexander, Darinka Dentcheva, and Andrzej Ruszczyński. Lectures on stochastic programming: modeling and theory. Society for Industrial and Applied Mathematics, 2009.

[4] Shapiro, Alexander, et al. "Report for technical cooperation between Georgia Institute of Technology and ONS-Operador Nacional do Sistema Elétrico." (2011).

[5] https://github.com/odow/MathOptFormat.jl/pull/51

[6] Girardeau, Pierre, Vincent Leclere, and Andrew B. Philpott. "On the convergence of decomposition methods for multistage stochastic convex programs." Mathematics of Operations Research 40.1 (2014): 130-145.
