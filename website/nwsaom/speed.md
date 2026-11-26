---
title: "Speed"
parent: "nwsaom (SAOM)"
nav_order: 8
description: "Run times of nwsaom 1.9.2 against R's RSiena 1.6.14 on 27 models with the same data, and what the ratios do not show."
permalink: /nwsaom/speed/
---

# Speed compared with RSiena
{: .no_toc }

1. TOC
{:toc}

## Benchmark

27 models: directed and undirected networks of 50 pupils (the Glasgow data of RSiena), co-evolution with behaviour,
networks of 100 to 500 actors built from copies of those data, two-mode networks and several networks at once.
One thread for both programs (RSiena without `useCluster`, `nwsaom` with `cores(1)`).

| Model | RSiena (s) | nwsaom (s) | RSiena / nwsaom | converged RSiena | converged nwsaom | largest difference (SE) |
|---|---:|---:|---:|---:|---:|---:|
| S1: outdegree, reciprocity | 1.43 | 0.367 | 3.9 | 5/5 | 5/5 | 0.06 |
| S2: S1 and gwesp | 3.24 | 0.909 | 3.6 | 5/5 | 5/5 | 0.02 |
| S3: S2 and same smoking | 3.98 | 1.02 | 3.9 | 5/5 | 5/5 | 0.07 |
| S4: S2, in-degree popularity, activity | 5.10 | 1.54 | 3.3 | 5/5 | 5/5 | 0.09 |
| S5: S2, alcohol ego, alter, similarity | 6.03 | 1.62 | 3.7 | 5/5 | 5/5 | 0.05 |
| S6: S2, unconditional estimation | 4.17 | 1.12 | 3.7 | 5/5 | 5/5 | 0.04 |
| S7: undirected: degree | 0.625 | 0.131 | 4.8 | 5/5 | 5/5 | 0.02 |
| S8: undirected: degree, joint change | 1.63 | 0.114 | 14.3 | 5/5 | 5/5 | 0.06 |
| S9: co-evolution, friendship and alcohol | 8.25 | 1.94 | 4.2 | 5/5 | 5/5 | 0.03 |
| S10: co-evolution, friendship and smoking | 9.37 | 2.02 | 4.6 | 5/5 | 4/5 | 0.04 |
| S11: as S9 for 2 waves | 3.23 | 0.737 | 4.4 | 5/5 | 5/5 | 0.04 |
| S12: 100 pupils: outdegree, reciprocity, gwesp | 12.3 | 3.22 | 3.8 | 5/5 | 5/5 | 0.05 |
| S13: 200 pupils: outdegree, reciprocity, gwesp | 51.7 | 12.1 | 4.3 | 5/5 | 5/5 | 0.04 |
| S14: 500 pupils: outdegree, reciprocity, gwesp | 348 | 83.2 | 4.2 | 5/5 | 5/5 | 0.05 |
| S15: 200 pupils with alcohol co-evolution | 114 | 20.7 | 5.5 | 5/5 | 5/5 | 0.07 |
| S16: network effects with covariates | 9.40 | 2.59 | 3.6 | 5/5 | 5/5 | 0.06 |
| S17: S16 with alcohol co-evolution | 13.4 | 3.17 | 4.2 | 4/5 | 5/5 | 0.05 |
| S18: undirected: degree, gwesp, covariates | 1.40 | 0.382 | 3.7 | 5/5 | 5/5 | 0.01 |
| S19: S16 with 200 pupils | 161 | 30.9 | 5.2 | 4/5 | 5/5 | 0.07 |
| S20: S17 with 200 pupils | 190 | 33.9 | 5.6 | 4/5 | 4/5 | 0.08 |
| S21: two-mode, 4-cycles, unconditional | 5.16 | 1.21 | 4.3 | 1/5 | 5/5 | 0.09 |
| S22: two-mode, more structural effects | 1.09 | 0.539 | 2.0 | 5/5 | 5/5 | 0.04 |
| S23: two networks, cross effect | 7.34 | 2.71 | 2.7 | 5/5 | 4/5 | 0.02 |
| S24: S23 with smoking behaviour | 15.1 | 2.41 | 6.3 | 4/5 | 5/5 | 0.04 |
| S25: S24 with cross effects | 21.5 | 5.55 | 3.9 | 4/5 | 5/5 | 0.03 |
| S26: two undirected networks, cross effect | 5.94 | 2.15 | 2.8 | 5/5 | 5/5 | 0.05 |
| S27: gwesp, reciprocity, covariate-triad | 8.53 | 2.97 | 2.9 | 5/5 | 5/5 | 0.05 |
{: .compact-table }

`nwsaom` was faster on all 27 models: 2.0 to 14.3 times, 3.9 in the median. In the 19 models in which every fit of
both programs converged, the median is 3.8. The largest ratio is for the undirected model with joint tie changes
(S8). The mean estimates of the two programs differ by at most 0.09 RSiena standard errors.

A fit converged when its overall maximum convergence ratio was below 0.25, RSiena's criterion. The times include all
fits. Read the ratio with care where convergence differs: on the first two-mode model (S21), **RSiena converged in
only 1 of 5 fits** and `nwsaom` in 5 of 5.

## More than one core

*An earlier measurement, not repeated for the new run: `nwsaom` 1.5.7 against RSiena 1.6.14 on an Apple M5 Pro
laptop, 9 November 2026. Its model names differ from those of the table above.*

Both programs can use several cores (nwsaom with `cores()`, RSiena with `useCluster` and several R processes).
Median seconds per fit over 3 seeds; nwsaom threads and RSiena processes:

| Model | nwsaom 1 | nwsaom 2 | nwsaom 5 | nwsaom 10 | RSiena 1 | RSiena 5 | RSiena 10 |
|---|---:|---:|---:|---:|---:|---:|---:|
| R1 (50 actors) | 1.34 | 1.11 | 0.96 | 0.92 | 4.74 | 3.53 | 3.97 |
| R4 (200 actors) | 22.0 | 18.1 | 15.4 | 14.7 | 89.5 | 34.4 | 29.7 |
| R5 (200 actors) | 23.6 | 14.0 | 11.7 | 10.9 | 111 | 46.0 | 49.1 |
{: .compact-table }

Ten threads are 1.5 (R1 and R4) and 2.2 (R5) times as fast as one thread, and 5.2 to 10.2 times as fast as one
RSiena process. Against the best RSiena setting, nwsaom with ten threads is 3.8 (R1), 2.0 (R4) and 4.2 (R5) times
as fast. The gain from threads is less than proportional because the second phase of the estimation, where each
step needs the previous estimate, cannot be split over threads. The estimates of nwsaom are identical for every
number of threads.

## What the ratios do not show

- **Several cores.** The earlier measurement above shows that the lead can be smaller when both programs use several
  cores on larger networks.
- These are measurements on one computer with one thread. Another computer, several threads, another linear
algebra library or other settings can change the ratios. A ratio of times is also not a ratio for the same piece of
work: the programs do not always do the same amount of it.

## Where the speed comes from

Both programs run the same algorithm with RSiena's default settings (the same phases, update rules and convergence
criterion) and make a similar number of simulation steps; RSiena's simulation is C++. The difference lies in how a
simulation is carried out: `nwsaom` runs the simulations of the first and third phases in batches inside its
plug-in, passes once over all of an actor's options for each effect, computes quantities that several effects share
only once, and can spread the simulations over threads with the same result for any number of threads. How much each
point contributes was not measured.

## How we measured

- **Date and machine.** 26 November 2026, one desktop computer: Intel Core i7-12700K (8 performance and 4 efficiency
  cores), 125 GB of memory, Ubuntu 22.04.
- **One thread.** Every fit was pinned to one core, and every program was limited to one thread. Stata was
  StataNow 19.5 MP. Up to three benchmarks ran at once, each on its own physical core.
- **Versions.** `nwcommands` 3.39.0, `nwsaom` 1.9.2; R 4.6.0 with its reference BLAS, RSiena 1.6.14.
- **What is timed.** Each fit ran in its own process after an untimed warm-up fit in the same process, which loads
  the code and the compiled library. The timer covers the estimation call only, not loading the data.
- **Repeats.** The two programs ran in turn. The tables show medians over up to five fits per model (fewer for fits over 60 seconds), with different seeds. A fit had a
  limit of 600 seconds.
- **Same data and model.** Both programs read the same data and fit the same model with their default control settings.
- **Scripts and raw timings** of this run are not yet in the public repository.

The other model packages are compared with their R counterparts on the page [Speed compared with R](../../nwcommands/speed/).
