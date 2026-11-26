---
title: "Speed"
parent: "nwdynam (DyNAM)"
nav_order: 8
description: "Run times of nwdynam 1.8.0 against R's goldfish on the same data and models: choice, rate with intercept, and the largest fits."
permalink: /nwdynam/speed/
---

# Speed compared with goldfish
{: .no_toc }

1. TOC
{:toc}

## Benchmark

Choice and rate sub-models of a dynamic network actor model on simulated event logs of 200 to 20,000 events among 20 to
100 actors. Four effect sets: C1 the default choice effects (`inertia recip indeg`); C2 adds `same(group)`; C3 is
`inertia trans`; R1i is the rate sub-model with `intercept` (and the default effects `indeg outdeg`); R2i adds `ego(x)`.
Every fit of nwdynam runs in the compiled plug-in. goldfish has three engines; `default_c` and `gather_compute` took the
same time, and `default` was 1.8 to 15 times slower, so the table shows `default_c` and `default`. The last column
gives the time of goldfish divided by the time of nwdynam, as "`default_c` / `default`".

| Cell | nwdynam 1.8.0 (s) | goldfish `default_c` (s) | goldfish `default` (s) | ratio `default_c` / `default` |
|---|---:|---:|---:|---:|
| C1, 200 events, 20 actors | 0.038 | 0.256 | 0.463 | 7 / 12 |
| C1, 1000 events, 30 actors | 0.043 | 1.254 | 2.343 | 29 / 54 |
| C1, 5000 events, 20 actors | 0.058 | 6.205 | 11.8 | 107 / 203 |
| C1, 5000 events, 50 actors | 0.063 | 6.332 | 14.0 | 101 / 222 |
| C1, 5000 events, 100 actors | 0.080 | 6.516 | 22.8 | 81 / 285 |
| C1, 20000 events, 100 actors | 0.236 | 26.2 | 101.4 | 111 / 430 |
| C2, 5000 events, 50 actors | 0.083 | 6.361 | 15.2 | 77 / 184 |
| C2, 5000 events, 100 actors | 0.089 | 6.565 | 26.2 | 74 / 295 |
| C3, 5000 events, 50 actors | 0.072 | 4.757 | 11.0 | 66 / 153 |
| C3, 5000 events, 100 actors | 0.076 | 4.936 | 16.2 | 65 / 213 |
| C3, 20000 events, 100 actors | 0.166 | 19.8 | 71.0 | 119 / 427 |
| R1i, 5000 events, 50 actors | 0.070 | 5.009 | 16.5 | 72 / 236 |
| R1i, 5000 events, 100 actors | 0.089 | 5.405 | 35.0 | 61 / 393 |
| R1i, 20000 events, 100 actors | 0.217 | 24.3 | 355.3 | 112 / 1637 |
| R2i, 5000 events, 50 actors | 0.084 | 5.038 | 17.7 | 60 / 210 |
| R2i, 5000 events, 100 actors | 0.089 | 5.505 | 41.3 | 62 / 464 |

nwdynam was faster than goldfish in every cell: 7 to 119 times against `default_c` and 12 to 1,637 times against the
default engine. The gain grows with the number of events (goldfish's time is dominated by preprocessing that grows with
the events) and is smallest in the small cells. The largest fit timed, 20,000 events among 100 actors in the rate model with
intercept, took 0.22 seconds in nwdynam and 24 seconds (`default_c`) or 355 seconds (`default`) in goldfish. Estimates
agree with goldfish to a relative difference of at most 6e-7 in every cell, the log likelihood to round-off.

## Where the speed comes from

- **Compiled likelihood, gradient and Hessian.** The plug-in computes the likelihood, the gradient and the exact Hessian of all effects, and
  the optimizer takes Newton steps with it; a fit needs a handful of evaluations.
- **goldfish spends its time in preprocessing.** For `default_c` and `gather_compute`, almost the whole call is the
  step that computes the statistics of each event for each possible receiver. nwdynam has no separate step. The
  comparison is of whole calls for one fit. Whether goldfish can reuse the preprocessing across several fits was not tested.
- **Version 1.5.1 fixed slow cells.** In version 1.5.0 four cells of the table took 1.8 to 5.5 seconds because the
  optimizer of Mata backed up for many evaluations; since 1.5.1 a damped Newton loop is used, and all cells take under 0.25 seconds.

## What was not measured

The effects added in version 1.8.0 (effects through other networks, windows, composition change, time-varying
covariates, two-mode networks) and the `estat` commands were not benchmarked; fits that do not use them are as fast as in version 1.5.1 (within noise
in all 16 cells above). The coordination sub-model was not compared with goldfish in this benchmark. goldfish times were measured once, with version 1.5.0 of nwdynam; they were not repeated.

## How we measured

- **Machine.** Intel Core i7-12700K (20 logical CPUs), 125 GB RAM, Ubuntu 22.04.4 LTS (kernel 6.5.0), one server with no other load (load average about 1). Stata is StataNow 19.5 MP (limited to 8 processors by the licence), R 4.6.0.
- **Dates.** nwdynam 1.5.0 and goldfish 1.6.12: 15 and 16 November 2026; nwdynam 1.5.1: 16 November 2026; nwdynam 1.8.0 (the times in the table): 16 November 2026. The times of goldfish were not repeated for the later runs; the times of nwdynam were measured on their own, so the two programs were not timed in turn for versions 1.5.1 and 1.8.0.
- **Data and scripts.** Simulated event logs from the generator scripts; scripts, data and one row per fit in the [bench folder](https://github.com/thomas-u-grund/nwcommands/tree/main/bench).
- **One fit per process.** Each fit runs in its own Stata or R process after an untimed warm-up fit, so the first call (loading libraries) is not in the time. The timer covers the estimation command (for the R packages, the estimation call including its preprocessing). Loading the data is not timed.
- **Medians.** Up to 7 repeats with a different seed for each repeat in both programs (5, 3 or 1 in the largest cells of the R packages); the tables show medians.
- **Same data, same model, defaults.** Both programs get the same data and the same specification with their default control settings. Neither side is tuned.
- **Time limit.** Each fit has a limit of 600 seconds. A fit that reaches it is reported as a time-out, not dropped.

The other model packages are compared with their R counterparts on the page [Speed compared with R](../../nwcommands/speed/).
