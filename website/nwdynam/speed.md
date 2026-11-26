---
title: "Speed"
parent: "nwdynam (DyNAM)"
nav_order: 8
description: "Run times of nwdynam 1.11.2 against R's goldfish 1.6.12 on 30 choice and rate models of simulated event logs."
permalink: /nwdynam/speed/
---

# Speed compared with goldfish
{: .no_toc }

1. TOC
{:toc}

## Benchmark

Choice and rate models on simulated event logs of 200 to 20,000 events among 20 to 100 actors, in five sets of
effects:

- **D1**: choice model: inertia, reciprocity, indegree.
- **D2**: as D1, plus same group.
- **D3**: choice model: inertia, transitivity.
- **D4**: rate model with intercept: indegree, outdegree.
- **D5**: as D4, plus an actor covariate.

goldfish has several estimation engines. The main comparison is with its compiled engine `default_c`; its third
engine, `gather_compute`, took about the same time. The `default` engine is shown for context.

| Case | nwdynam (s) | goldfish `default_c` (s) | goldfish `default` (s) | `default_c` / nwdynam | `default` / nwdynam |
|---|---:|---:|---:|---:|---:|
| D1, 200 events, 20 actors | 0.0070 | 0.266 | 0.487 | 38.0 | 69.6 |
| D1, 1,000 events, 30 actors | 0.015 | 1.30 | 2.46 | 87.0 | 164 |
| D1, 5,000 events, 20 actors | 0.026 | 6.47 | 12.4 | 249 | 476 |
| D1, 5,000 events, 50 actors | 0.032 | 6.59 | 14.6 | 206 | 456 |
| D1, 5,000 events, 100 actors | 0.056 | 6.73 | 23.3 | 120 | 416 |
| D1, 20,000 events, 100 actors | 0.201 | 26.9 | 102 | 134 | 509 |
| D2, 200 events, 20 actors | 0.0090 | 0.263 | 0.500 | 29.2 | 55.6 |
| D2, 1,000 events, 30 actors | 0.018 | 1.29 | 2.54 | 71.4 | 141 |
| D2, 5,000 events, 20 actors | 0.027 | 6.38 | 12.9 | 236 | 476 |
| D2, 5,000 events, 50 actors | 0.042 | 6.51 | 15.7 | 155 | 373 |
| D2, 5,000 events, 100 actors | 0.062 | 6.72 | 27.2 | 108 | 439 |
| D2, 20,000 events, 100 actors | 0.222 | 27.0 | 121 | 122 | 545 |
| D3, 200 events, 20 actors | 0.0070 | 0.196 | 0.380 | 28.0 | 54.3 |
| D3, 1,000 events, 30 actors | 0.015 | 0.960 | 1.92 | 64.0 | 128 |
| D3, 5,000 events, 20 actors | 0.021 | 4.77 | 9.81 | 227 | 467 |
| D3, 5,000 events, 50 actors | 0.029 | 4.89 | 11.3 | 169 | 391 |
| D3, 5,000 events, 100 actors | 0.051 | 5.09 | 16.5 | 99.8 | 323 |
| D3, 20,000 events, 100 actors | 0.130 | 20.1 | 72.9 | 155 | 561 |
| D4, 200 events, 20 actors | 0.0090 | 0.201 | 0.365 | 22.3 | 40.6 |
| D4, 1,000 events, 30 actors | 0.018 | 0.985 | 2.06 | 54.7 | 114 |
| D4, 5,000 events, 20 actors | 0.025 | 4.84 | 9.43 | 194 | 377 |
| D4, 5,000 events, 50 actors | 0.039 | 5.08 | 16.7 | 130 | 428 |
| D4, 5,000 events, 100 actors | 0.053 | 5.46 | 35.6 | 103 | 671 |
| D4, 20,000 events, 100 actors \* | 0.180 | 24.6 | 358 | 137 | 1991 |
| D5, 200 events, 20 actors | 0.010 | 0.204 | 0.385 | 20.4 | 38.5 |
| D5, 1,000 events, 30 actors | 0.019 | 0.990 | 2.39 | 52.1 | 126 |
| D5, 5,000 events, 20 actors | 0.029 | 4.86 | 9.88 | 168 | 341 |
| D5, 5,000 events, 50 actors | 0.041 | 5.10 | 17.9 | 124 | 436 |
| D5, 5,000 events, 100 actors | 0.064 | 5.57 | 41.3 | 87.1 | 645 |
| D5, 20,000 events, 100 actors | 0.210 | 22.1 | 161 | 105 | 765 |
{: .compact-table }

\* goldfish did not converge in this case (0 of 3 fits), so do not rely on its ratio.

`nwdynam` was faster in all 30 cases: 20 to 249 times against `default_c` (114 in the median) and 38 to 1,991 times against
the `default` engine (403 in the median). In the 29 cases in which goldfish converged, the medians are 108 and 391,
the ranges 20 to 249 and 38 to 765, and the estimates of the two programs are the same to the printed precision.
`nwdynam` reports no convergence criterion; all its fits ended without an error.

## What the ratios do not show

- **Very small fits** take a few milliseconds in `nwdynam`, close to the 1 millisecond resolution of the timer. Their
  individual ratios are imprecise.
- **Preprocessing.** goldfish spends most of the time of a `default_c` fit on preparing the statistics of every event.
  Each timing is one whole call for one fit; reusing that preparation for several fits was not tested.
- **Not measured:** coordination models, effects through other networks, windows, composition change, time-varying
  covariates, two-mode networks and the `estat` commands.
- These are measurements on one computer with one thread. Another computer, several threads, another linear
algebra library or other settings can change the ratios. A ratio of times is also not a ratio for the same piece of
work: the programs do not always do the same amount of it.

## Where the speed comes from

The compiled plug-in of `nwdynam` computes the likelihood, its gradient and the exact Hessian, so a fit needs only a
few evaluations, and it has no separate preprocessing step. goldfish has C++ engines too. How much each point
contributes was not measured.

## How we measured

- **Date and machine.** 26 November 2026, one desktop computer: Intel Core i7-12700K (8 performance and 4 efficiency
  cores), 125 GB of memory, Ubuntu 22.04.
- **One thread.** Every fit was pinned to one core, and every program was limited to one thread. Stata was
  StataNow 19.5 MP. Up to three benchmarks ran at once, each on its own physical core.
- **Versions.** `nwcommands` 3.39.0, `nwdynam` 1.11.2; R 4.6.0 with its reference BLAS, goldfish 1.6.12.
- **What is timed.** Each fit ran in its own process after an untimed warm-up fit in the same process, which loads
  the code and the compiled library. The timer covers the estimation call only, not loading the data.
- **Repeats.** The two programs ran in turn. The tables show medians over up to five fits per case (fewer for fits over 60 seconds), with different seeds. A fit had a
  limit of 600 seconds.
- **Same data and model.** Both programs read the same data and fit the same model with their default control settings.
- **Scripts and raw timings** of this run are not yet in the public repository.

The other model packages are compared with their R counterparts on the page [Speed compared with R](../../nwcommands/speed/).
