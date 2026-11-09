---
title: "Speed"
parent: "nwergm (ERGM)"
nav_order: 7.5
description: "Run times of nwergm against R's ergm on the same data and models, where nwergm is faster, where it is not, and why."
permalink: /nwergm/speed/
---

# Speed compared with ergm
{: .no_toc }

1. TOC
{:toc}

## Benchmark

Eight models of the nwergm article: networks of 30 to 1,000 nodes and two real networks (Lazega advice,
Faux Mesa High). Median of 7 fits per program, default settings. ergm and nwergm ran in turn for every model and
seed, on 9 November 2026, on a laptop with no other Stata or R job running (load average 1.8 to 3.4 before the
fits).

| Model | ergm 4.12.0 (s) | nwergm 1.5.2 (s) | ergm / nwergm |
|---|---:|---:|---:|
| B1 30 nodes, directed: edges, mutual | 0.19 | 0.066 | 2.9 |
| B2 100 nodes, directed: + nodematch | 0.30 | 0.14 | 2.1 |
| B3 100 nodes, undirected: edges, gwesp | 0.30 | 0.087 | 3.5 |
| B4 500 nodes, sparse, undirected: + nodematch, gwesp | 2.8 | 0.68 | 4.0 |
| B5 1,000 nodes, directed: edges, mutual, nodematch | 7.8 | 2.3 | 3.4 |
| B6 1,000 nodes, sparse, undirected: edges, gwesp, gwnsp | 6.6 | 1.7 | 3.8 |
| Lazega advice, 71 nodes, 7 terms | 9.7 | 2.5 | 3.9 |
| Faux Mesa High, 205 nodes, gwesp(0.25) | 3.8 | 1.0 | 3.7 |

nwergm 1.5.2 was faster than ergm on all eight models, and in every pair of fits with the same
seed (the lowest pair ratio was 1.4, on the 30-node model, where the fixed overhead of a Stata command weighs most).
The number of iterations of the Monte Carlo algorithm depends on the seed in both programs and drives most of the
spread. Compare medians, not single fits. The data and scripts are in
[bench/nwergm/run152](https://github.com/thomas-u-grund/nwcommands/tree/main/bench/nwergm/run152).

**At the same amount of work.** With a fixed workload (one iteration with 4,000 draws, interval 1,024, burn-in
16,384, no adaptive sample size) a Metropolis-Hastings proposal of nwergm 1.5.2 cost 0.08 to 0.25 microseconds and
one of ergm 0.20 to 1.04 microseconds, 2.1 to 4.4 times more, the same range as the ratios of whole fits.

## Where the speed comes from

- **Not less sampling.** nwergm runs ergm's default algorithm: the SPDyad proposal, the
  adaptive sample size with ergm's multivariate effective sample size, ergm's convergence test and 16 bridges for
  the log-likelihood. Its fits make about as many Metropolis-Hastings proposals as ergm's (the counts are in the
  replication files of the nwergm article), so the gain is in the cost of each proposal and of the work around the
  sampler.
- **Faster kernels.** The plug-in keeps the adjacency as a bit matrix, updates the change statistics of a proposed
  toggle from the neighborhoods of the two nodes instead of recomputing the statistics of the network, tabulates
  the geometrically weighted kernel once per decay value, draws a random dyad in constant time and
  reads the shared-partner counts of the gwesp-type terms from the cache that SPDyad keeps, as ergm does.
  We did not separate how much each of these contributes.
- **Pseudolikelihood on distinct rows.** For large networks the pseudolikelihood is computed on the distinct rows of
  the design matrix with weights. A directed network of 1,000 nodes has 999,000 dyads but only a few distinct rows.

Compiled (C plug-in): the Metropolis-Hastings sampler, the change statistics, the observed statistics, the design
matrix of the pseudolikelihood and the Newton steps of curved pseudolikelihood fits. Mata and ado: the estimating
step, the covariance, the convergence test, the diagnostics and the output.

## When it is not faster

- **Without the plug-in.** On a platform without the compiled plug-in, or with the option that forces the Mata
  sampler, nwergm is much slower than R: 234 seconds against 1.2 seconds with the plug-in for the Lazega model with
  five terms (one fit and the median of 5), where ergm needed 9.4 seconds (nwergm 1.4.0).
- **Small models.** Every call has a fixed overhead of about 0.05 to 0.25 seconds (parsing, Mata set-up, returning
  results), and the first fit of a session also loads the Mata library. On a model that ergm fits in 0.2 seconds the
  difference is mostly this overhead.
- **Models with one coefficient per node and a dyad-dependent term.** Every iteration draws at least 32 networks
  per coefficient in both programs: `edges mutual sender receiver` on 100 nodes (200 coefficients) took about 20
  minutes in nwergm, and ergm had not finished its second iteration after an hour.
- **Not measured.** Linux and Windows, models outside these eight, and Stata 17.

## How we measured

- **Machine, nwergm run of 9 November.** Apple M5 Pro, macOS, one laptop, with no other Stata or R job running (load average
  1.8 to 3.4 before the fits).
- **Software.** Stata 18 BE, R 4.6.0, nwcommands core 3.17.2, nwergm 1.5.2, ergm 4.12.0. The plug-in is the released build.
- **Data and scripts.** The eight models of the nwergm article; scripts, data and one row per fit in [bench/nwergm/run152](https://github.com/thomas-u-grund/nwcommands/tree/main/bench/nwergm/run152).
- **One fit per process.** Each fit runs in its own Stata or R process after an untimed warm-up fit, so the first
  call (loading libraries) is not in the time. The timer covers the estimation command (for goldfish, the
  `estimate()` call including its preprocessing). Loading the data is not timed.
- **Interleaved, medians.** The programs run in turn, R, Stata, R, Stata, one process at a time, with 7 repeats and
  a different seed for each repeat in both programs. The tables show medians. A single pair of fits can differ
  from the median ratio.
- **Same data, same model, defaults.** Both programs get the same data and the same specification with their default
  control settings. Neither side is tuned. Convergence is checked in every fit with the package's own
  criterion; the tables give the number of converged fits where it differs between the programs.
- **Time limit.** Each fit has a limit of 600 seconds. A fit that reaches it is reported as a time-out, not dropped.

The other model packages are compared with their R counterparts on the page [Speed compared with R](../../nwcommands/speed/).
