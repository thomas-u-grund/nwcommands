---
title: "nwsaom and RSiena"
parent: "nwsaom (SAOM)"
nav_order: 8
permalink: /nwsaom/rsiena/
description: "What nwsaom shares with RSiena, what it lacks, how it was compared, and a translation table from RSiena functions to nwsaom commands."
---

# nwsaom and RSiena

`nwsaom` follows the Siena project closely and exists because of it. The stochastic actor-oriented
model is due to Tom Snijders. RSiena (Ripley, Snijders, Boda, Voros, Preciado and many contributors)
is the reference implementation, and multiSiena (Snijders, Koskinen, Ripley) supplies the Bayesian
estimator that `nwsaom bayes` follows. `nwsaom` is not affiliated with or endorsed by the Siena
project, and errors in `nwsaom` are the author's. If you can use R, RSiena remains the reference
and the more complete program.

## What is the same

- **The model and the effects.** The effect library follows RSiena's table of effects. In the effects table of
  RSiena 1.6.6 (`getEffects()` over twelve data configurations) 1,121 rows are planned for `nwsaom`;
  1,058 of them (94%) are implemented, and every implemented effect was compared with `siena07`.
  The effects that RSiena 1.6.7 to 1.6.14 added or changed (for example WXZX and the two-mode
  toU) are implemented and compared with RSiena 1.6.14 but are not part of these counts; the counts
  change with RSiena releases.
- **The algorithm and the defaults.** Method of moments by Robbins-Monro stochastic approximation in
  three phases, conditional estimation for one network, the same starting values, the same convergence
  rule (all t-ratios below 0.1, overall maximum ratio below 0.25), centered covariates.
- **The output.** Coefficients, rates and convergence statistics as in RSiena; the option `detail`
  prints RSiena's names of the effects.
- **The postestimation tools:** goodness of fit, score tests, time-heterogeneity test, relative importance.

## What differs

Not implemented in `nwsaom`:

- the generalised method of moments estimator;
- the settings model;
- a hierarchical Bayesian analysis of several groups, and the joint estimation of one model in several groups
  (groups fitted separately can be combined with `nwsaom meta`, the counterpart of `siena08`);
- the continuous (stochastic differential equation) behavior;
- inside `nwsaom multinet`: composition change, missing ties, `estat gof`, `estat importance` and `estat simulate`.

Maximum likelihood and Bayesian estimation do not cover non-directed or two-mode networks, several networks,
missing data or composition change. Only binary ties are supported. A few implementation details differ
and are disclosed in the help: for example `estat gof` simulates fresh networks at the estimates instead
of reusing those stored during the fit.

## How the estimates were compared

For each implemented effect the observed statistic was compared with the one `siena07` computes, and the
estimates were compared over at least two seeds; for a few effects, where the estimates are degenerate in
both programs, only the statistic could be compared. The comparisons were made with RSiena 1.6.14 (see `nwsaom version`).
Because both programs estimate by simulation, results agree within simulation noise, not to the last digit.
The manual (PDF) gives the validation in detail.

## Speed

`nwsaom` runs its simulations in a compiled, multithreaded plugin and evaluates the change statistics of an
actor in batches. In the benchmark reported in the manual, on a single thread, `nwsaom` was faster than RSiena
on every model; further threads come on top. The numbers are in the manual and are not repeated here.

## Translation table

| RSiena | nwsaom |
|---|---|
| `sienaNet`, `sienaDataCreate` | `nwset` for the networks; waves and covariates are named in the `nwsaom` options |
| `print01Report` | `nwsaom describe, waves(...)` |
| `coCovar`, `varCovar` | variables in the dataset; `tvcov()` for changing covariates |
| `getEffects`, `includeEffects` | effect options of `nwsaom` (`outdegree`, `reciprocity`, `transtrip`, `gwesp()`, `egox()`, `altx()`, `samex()`, `simx()`, ...); `detail` shows RSiena's names |
| `includeInteraction` | `interact()` |
| effect type `endow`, `creation` | `endow()`, `creation()` |
| `includeEffects(fix, test)`, `score.Test` | `fix()` and `estat score` |
| `sienaAlgorithmCreate` (`n1`, `n3`, `seed`, `firstg`, `cond`, `maxlike`, cores) | `k0()`, `k3()`, `seed()`, `firstg()`, `unconditional`, `ml`, `cores()` |
| `siena07` | `nwsaom` |
| `siena07` with `simOnly = TRUE` | `nwsaom simulate`, `estat simulate` |
| `sienaGOF`, `plot.sienaGOF` | `estat gof` |
| `sienaTimeTest` | `estat timetest` |
| `sienaRI` | `estat importance` |
| `siena08` | `nwsaom meta` |
| `sienaCompositionChange` | `present()`, `joinat()`, `leaveat()` |
| missing data in `sienaDataCreate` | `missnet()`, `missbeh()` |
| `multi_siena` / `sienaBayes` | `nwsaom bayes` (one directed network, with or without one behavior) |
| several dependent networks | `nwsaom multinet` |
| `netmediate` (MEMS) | `estat mems` |

RSiena has renamed several of its functions in recent versions (for example `siena` for `siena07`,
`test_gof` for `sienaGOF`); the older names are used above.

## About the software

The software was developed with Claude Code (Anthropic), an AI coding assistant, working under the author's
direction; its correctness rests on numerical comparison with RSiena.

## References

Snijders, T.A.B. (2001). The statistical evaluation of social network dynamics. *Sociological Methodology* 31.
Ripley, R.M., Snijders, T.A.B., Boda, Z., Voros, A., Preciado, P. Manual for RSiena.
Lospinoso, J., Snijders, T.A.B. (2019). Goodness of fit for stochastic actor-oriented models. *Methodological Innovations* 12(3).
