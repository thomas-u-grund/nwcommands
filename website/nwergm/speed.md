---
title: "Speed"
parent: "nwergm (ERGM)"
nav_order: 8
description: "Run times of nwergm 1.16.1 against R's ergm 4.12.0 on the same data and models, where nwergm is faster, where it is not, and what the ratios do not show."
permalink: /nwergm/speed/
---

# Speed compared with ergm
{: .no_toc }

1. TOC
{:toc}

## Benchmark

Eight models: six simulated networks of 30 to 1,000 nodes and two real ones (the advice network of the 71 lawyers of
Lazega's law firm and the Faux Mesa High friendship network). Estimation is by Monte Carlo maximum likelihood with
default settings in both programs. The column *without log likelihood* gives the ratio when the evaluation of the
log likelihood is switched off in both programs.

| Model | ergm (s) | nwergm (s) | ergm / nwergm | without log likelihood | largest difference (SE) |
|---|---:|---:|---:|---:|---:|
| E1 30 nodes, directed: edges, mutual | 0.269 | 0.048 | 5.6 | 2.8 | 0.06 |
| E2 100 nodes, directed: edges, mutual, nodematch | 0.418 | 0.128 | 3.3 | 2.1 | 0.03 |
| E3 100 nodes, undirected: edges, gwesp | 0.444 | 0.131 | 3.4 | 2.8 | 0.05 |
| E4 500 nodes, undirected: edges, nodematch, gwesp | 3.93 | 1.16 | 3.4 | 3.2 | 0.07 |
| E5 1,000 nodes, directed: edges, mutual, nodematch | 11.1 | 2.67 | 4.2 | 3.1 | 0.03 |
| E6 1,000 nodes, sparse, undirected: edges, gwesp, gwnsp | 9.60 | 2.95 | 3.3 | 4.1 | 0.05 |
| E7 Lazega advice, 71 lawyers, directed: seven terms | 12.5 | 3.51 | 3.6 | 3.5 | 0.06 |
| E8 Faux Mesa High, 205 students: edges, two nodematch, gwesp(0.25) | 5.61 | 1.16 | 4.8 | 5.1 | 0.01 |
{: .compact-table }

With default settings, `nwergm` was faster on all eight models: 3.3 to 5.6 times, 3.5 in the median. Without
the evaluation of the log likelihood the ratios were 2.1 to 5.1. All fits of both programs converged (seven of
seven for every model). The mean estimates of the two programs differ by at most 0.07 standard errors, no more than
two sets of fits of the same program differ (up to 0.09), because both estimate by simulation.

## What the ratios do not show

- **Not the same number of steps.** The two programs adapt the sampling during a fit, so they do not make the same
  number of Metropolis-Hastings proposals. In a count made with `nwergm` 1.16.0, not repeated for this run, `nwergm`
  made 0.44 to 1.2 times as many proposals as `ergm` over the eight models (fewer on five of them), and about 1.16
  times as many on the Lazega network.
- **The pseudolikelihood alone.** In an earlier profile with `nwergm` 1.16.0, not repeated for this run, the maximum
  pseudolikelihood fit by itself was *faster in `ergm`* on every model, by a factor of 1.4 to 7. In `nwergm` the time
  goes into building the data in Mata, not into the estimation step.
- **Models with one coefficient per node and a dyad-dependent term** are slow in both programs: every iteration
  draws at least 32 networks per coefficient.
- **Without the compiled plug-in**, or with the option that forces the Mata sampler, `nwergm` is far slower than R.
- These are measurements on one computer with one thread. Another computer, several threads, another linear
algebra library or other settings can change the ratios. A ratio of times is also not a ratio for the same piece of
work: the programs do not always do the same amount of it.

## Where the speed comes from

The Metropolis-Hastings sampler, the change statistics, the observed statistics, the design matrix of the
pseudolikelihood and the Newton steps of curved pseudolikelihood fits run in a plug-in written in C; ergm's sampler
is C as well. The plug-in keeps the network as a bit matrix, updates the statistics of a proposed change from the
neighborhoods of the two nodes, and keeps a cache of shared-partner counts, as ergm does. How much each of these
contributes was not measured.

## How we measured

- **Date and machine.** 26 November 2026, one desktop computer: Intel Core i7-12700K (8 performance and 4 efficiency
  cores), 125 GB of memory, Ubuntu 22.04.
- **One thread.** Every fit was pinned to one core, and every program was limited to one thread. Stata was
  StataNow 19.5 MP. Up to three benchmarks ran at once, each on its own physical core.
- **Versions.** `nwcommands` 3.39.0, `nwergm` 1.16.1; R 4.6.0 with its reference BLAS, `ergm` 4.12.0.
- **What is timed.** Each fit ran in its own process after an untimed warm-up fit in the same process, which loads
  the code and the compiled library. The timer covers the estimation call only, not loading the data.
- **Repeats.** The two programs ran in turn. The tables show medians over seven fits per model, with different seeds. A fit had a
  limit of 600 seconds.
- **Same data and model.** Both programs read the same data and fit the same model with their default control settings.
- **Scripts and raw timings** of this run are not yet in the public repository.

The other model packages are compared with their R counterparts on the page [Speed compared with R](../../nwcommands/speed/).
