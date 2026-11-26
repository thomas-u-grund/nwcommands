---
title: "Speed compared with R"
parent: "Packages and reference"
nav_order: 3
description: "Run times of the Stata model packages against ergm, RSiena, goldfish, latentnet, sbm, blockmodels and relevent, with the cases where R is faster and what the ratios do not show."
permalink: /nwcommands/speed/
---

# Speed compared with R
{: .no_toc }

This page compares the run time of the model packages with the R packages for the same models. It says where the Stata
packages were faster, where they were not, and what a ratio of times does not show. Times depend on the model, the
data and the machine. Treat the tables as examples, not as promises.

1. TOC
{:toc}

## Summary

The table gives the time of the R program divided by the time of the Stata command: above 1 means that Stata was
faster. A *case* is one model on one data set. All but the `nwrem` row were measured on 26 November 2026 on one Linux
computer with one thread.

| Comparison | Cases | Median | Range | Agreement of the results |
|---|---:|---:|---:|---|
| [nwergm 1.16.1 and ergm 4.12.0](../../nwergm/speed/), default settings | 8 | 3.5 | 3.3 to 5.6 | within 0.07 standard errors |
| [nwsaom 1.9.2 and RSiena 1.6.14](../../nwsaom/speed/) | 27 | 3.9 | 2.0 to 14.3 | within 0.09 standard errors |
| [nwdynam 1.11.2 and goldfish 1.6.12](../../nwdynam/speed/), compiled engine | 30 | 114 | 20 to 249 | same estimates in 29 cases |
| nwdynam and goldfish, default engine | 30 | 403 | 38 to 1,991 | same estimates in 29 cases |
| [nwlsm 1.0.6 and latentnet 2.12.0](../../nwlsm/speed/) | 3 | 4.7 | 3.6 to 5.0 | similar effective sample size per draw |
| [nwsbm 1.1.0 and sbm 1.0.0](../../nwsbm/speed/), reference BLAS | 4 | 3.3 | 2.7 to 4.2 | same partition and ICL |
| nwsbm and blockmodels 1.2.1, reference BLAS | 4 | 3.2 | 2.8 to 4.2 | same partition and ICL |
| nwsbm and sbm, R with the MKL library | 1 | **0.8: R faster** | | same partition and ICL |

| Earlier measurement (16 November 2026, another run) | Result |
|---|---|
| [nwrem 1.4.0 and relevent 1.2-1](../../nwrem/speed/) | all cases that both finished: 22 to 3,560 times with a Hessian in relevent, 16 to 2,208 times without; estimates within 0.01 standard errors |

In the cases in which every fit converged, the medians are about the same (3.8 for nwsaom; 108 and 391 for the two
engines of goldfish). The largest ratio against goldfish's default engine, 1,991, belongs to a case in which goldfish
did not converge; without it the largest is 765. `nwalaam` has not been compared.

### What a ratio does not show

- **Not the same work.** The programs do not always do the same amount of work, for example in the number of
  simulation steps or optimization runs of a fit. On the Lazega network `nwergm` made about 1.16 times as many Monte
  Carlo proposals as `ergm` (counted with `nwergm` 1.16.0).
- **One computer, one thread.** Several threads, another computer or other settings can change the ratios.
- **The library behind R matters.** With Intel's MKL, tried on one network, R's block model packages were faster than
  `nwsbm`. The R times for that test come from an earlier run of the same R versions.
- **Parts of a fit can differ.** In an earlier profile, `ergm` was faster at the maximum pseudolikelihood step alone.
- **Millisecond fits** are close to the resolution of the timer; do not read their ratios as precise.

### Where the advantage comes from

None of the R packages is slow R code: ergm's and latentnet's samplers are C, RSiena's simulation and the block model
code of sbm and blockmodels are C++, goldfish has C++ estimation engines and relevent has compiled code. A difference
in time is therefore not one between compiled and interpreted code. The Stata packages run their inner loops in a
compiled plug-in written in C, with Mata driving the rest. The plug-ins update the statistics from each single change
instead of recomputing them, store networks as lists of ties where possible and, in several packages, can use threads.
These are descriptions of the design, not measurements: how much each point contributes was not separated.

---

## The packages one by one

The tables, the cases and their limits are on the speed page of each package:

- [nwergm and ergm](../../nwergm/speed/)
- [nwsaom and RSiena](../../nwsaom/speed/)
- [nwdynam and goldfish](../../nwdynam/speed/)
- [nwrem and relevent](../../nwrem/speed/) (earlier measurement)
- [nwlsm and latentnet](../../nwlsm/speed/)
- [nwsbm, sbm and blockmodels](../../nwsbm/speed/)

---

## How we measured

- **Date and machine.** 26 November 2026, one desktop computer: Intel Core i7-12700K (8 performance and 4 efficiency
  cores), 125 GB of memory, Ubuntu 22.04.
- **One thread.** Every fit was pinned to one core, and every program was limited to one thread. Stata was
  StataNow 19.5 MP. Up to three benchmarks ran at once, each on its own physical core.
- **Versions.** `nwcommands` 3.39.0, `nwergm` 1.16.1, `nwsaom` 1.9.2, `nwdynam` 1.11.2, `nwlsm` 1.0.6, `nwsbm` 1.1.0; R 4.6.0 with its reference BLAS, `ergm` 4.12.0, RSiena 1.6.14, goldfish 1.6.12, `latentnet` 2.12.0, `sbm` 1.0.0, `blockmodels` 1.2.1.
- **What is timed.** Each fit ran in its own process after an untimed warm-up fit in the same process, which loads
  the code and the compiled library. The timer covers the estimation call only, not loading the data.
- **Repeats.** The two programs ran in turn. The tables show medians over up to five fits per case, seven for the ERGMs (fewer for fits over 60 seconds), with different seeds. A fit had a
  limit of 600 seconds.
- **Same data and model.** Both programs read the same data and fit the same model with their default control settings.
- **Scripts and raw timings** of this run are not yet in the public repository.

The `nwrem` comparison, its scripts and raw timings, and earlier measurements of the other packages are described on
the [nwrem speed page](../../nwrem/speed/) and in the
[bench folder](https://github.com/thomas-u-grund/nwcommands/tree/main/bench) of the repository.

Last updated 26 November 2026.
