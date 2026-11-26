---
title: "Speed"
parent: "nwlsm (latent space)"
nav_order: 8
description: "Run times of nwlsm 1.0.6 against R's latentnet 2.12.0 on three simulated networks."
permalink: /nwlsm/speed/
---

# Speed compared with latentnet
{: .no_toc }

1. TOC
{:toc}

## Benchmark

Latent space models with two dimensions on three simulated undirected networks: 1,000 retained draws after a burn-in
of 2,000, keeping every tenth. ESS is the effective sample size of the log likelihood; the last three columns count
it per second, because a sampler is only fast if its draws carry information.

| Network | latentnet (s) | nwlsm (s) | latentnet / nwlsm | ESS per s, latentnet | ESS per s, nwlsm | nwlsm / latentnet |
|---|---:|---:|---:|---:|---:|---:|
| 50 actors | 4.16 | 0.840 | 5.0 | 69.2 | 277 | 4.0 |
| 100 actors | 16.4 | 3.53 | 4.7 | 26.1 | 123 | 4.7 |
| 200 actors | 51.5 | 14.2 | 3.6 | 13.1 | 41.2 | 3.1 |
{: .compact-table }

With one thread, `nwlsm` took 3.6 to 5.0 times less time than `latentnet` (4.7 in the median) and gave 3.1 to 4.7
times as many effective draws per second.

## Several threads

One chain on the network of 200 actors, in seconds: `latentnet` 50.2; `nwlsm` with 1 thread 14.1,
with 2 threads 12.9, with 4 threads 12.0 and with 8 threads 12.2. More threads help
one chain only a little: four take about 15% less time than one.

## What the ratios do not show

- **Fixed costs.** In an earlier analysis, a large part of the difference came from the time each program needs
  besides the sampling iterations. Per iteration, `nwlsm` was 1.6 to 2.5 times as fast, so the ratio of longer runs
  can be smaller.
- **Only these models** were timed: no random effects, clusters, valued networks or directed networks.
- These are measurements on one computer with one thread. Another computer, several threads, another linear
algebra library or other settings can change the ratios. A ratio of times is also not a ratio for the same piece of
work: the programs do not always do the same amount of it.

## How we measured

- **Date and machine.** 26 November 2026, one desktop computer: Intel Core i7-12700K (8 performance and 4 efficiency
  cores), 125 GB of memory, Ubuntu 22.04.
- **One thread.** Every fit was pinned to one core, and every program was limited to one thread (except in the study of several threads). Stata was
  StataNow 19.5 MP. Up to three benchmarks ran at once, each on its own physical core.
- **Versions.** `nwcommands` 3.39.0, `nwlsm` 1.0.6; R 4.6.0 with its reference BLAS, `latentnet` 2.12.0.
- **What is timed.** Each fit ran in its own process after an untimed warm-up fit in the same process, which loads
  the code and the compiled library. The timer covers the estimation call only, not loading the data.
- **Repeats.** The two programs ran in turn. The tables show medians over five fits per network, with different seeds. A fit had a
  limit of 600 seconds.
- **Same data and model.** Both programs read the same data and fit the same model with the same priors, burn-in and number of draws.
- **Scripts and raw timings** of this run are not yet in the public repository.

The other model packages are compared with their R counterparts on the page [Speed compared with R](../../nwcommands/speed/).
