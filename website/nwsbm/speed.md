---
title: "Speed"
parent: "nwsbm (block models)"
nav_order: 8
description: "Run times of nwsbm 1.1.0 against R's sbm and blockmodels, including the case in which R is faster."
permalink: /nwsbm/speed/
---

# Speed compared with sbm and blockmodels
{: .no_toc }

1. TOC
{:toc}

## Benchmark

Bernoulli block models on four simulated undirected networks with three planted blocks, up to ten blocks, the number
chosen by the ICL. R used its reference linear algebra library (BLAS).

| Network | sbm (s) | blockmodels (s) | nwsbm (s) | sbm / nwsbm | blockmodels / nwsbm | blocks chosen |
|---|---:|---:|---:|---:|---:|---:|
| 50 actors | 0.113 | 0.113 | 0.035 | 3.2 | 3.2 | 3 |
| 100 actors | 0.366 | 0.362 | 0.111 | 3.3 | 3.3 | 3 |
| 200 actors | 0.713 | 0.720 | 0.261 | 2.7 | 2.8 | 3 |
| 300 actors | 1.87 | 1.87 | 0.441 | 4.2 | 4.2 | 3 |
{: .compact-table }

With R's reference BLAS, `nwsbm` was faster than `sbm` on all four networks (2.7 to 4.2 times, 3.3 in the median) and
than `blockmodels` (2.8 to 4.2 times, 3.2 in the median). All three programs chose the same partition, with the same
ICL.

## When it is not faster

**With Intel's MKL library in place of the reference BLAS, R was faster.** This was tried only on the network of 200
actors: `sbm` took 0.22 s and `blockmodels` 0.21 s, against 0.26 s for `nwsbm` (R's time divided by that of `nwsbm`:
about 0.8). The R times with MKL come from an earlier run with the same versions of R and the two packages; the
`nwsbm` time is from the run above. R users with an optimized linear algebra library should not expect the ratios of
the table.

## What the ratios do not show

- **Not the same work.** The programs differ in how many starting solutions they try. In an earlier count, `nwsbm`
  made more optimization runs than the R packages and needed less time for each.
- **Only these models** were timed: no two-mode, valued, degree-corrected or covariate models.
- These are measurements on one computer with one thread. Another computer, several threads, another linear
algebra library or other settings can change the ratios. A ratio of times is also not a ratio for the same piece of
work: the programs do not always do the same amount of it.

## How we measured

- **Date and machine.** 26 November 2026, one desktop computer: Intel Core i7-12700K (8 performance and 4 efficiency
  cores), 125 GB of memory, Ubuntu 22.04.
- **One thread.** Every fit was pinned to one core, and every program was limited to one thread. Stata was
  StataNow 19.5 MP. Up to three benchmarks ran at once, each on its own physical core.
- **Versions.** `nwcommands` 3.39.0, `nwsbm` 1.1.0; R 4.6.0 with its reference BLAS, `sbm` 1.0.0, `blockmodels` 1.2.1.
- **What is timed.** Each fit ran in its own process after an untimed warm-up fit in the same process, which loads
  the code and the compiled library. The timer covers the estimation call only, not loading the data.
- **Repeats.** The two programs ran in turn. The tables show medians over up to five fits per network, with different seeds. A fit had a
  limit of 600 seconds.
- **Same data and model.** Both programs read the same data and fit the same model with their default control settings.
- **Scripts and raw timings** of this run are not yet in the public repository.

The other model packages are compared with their R counterparts on the page [Speed compared with R](../../nwcommands/speed/).
