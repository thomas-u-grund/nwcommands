---
title: "Speed"
parent: "nwsaom (SAOM)"
nav_order: 16.5
description: "Run times of nwsaom against R's RSiena on the same data and models, where nwsaom is faster, where it is not, and why."
permalink: /nwsaom/speed/
---

# Speed compared with RSiena
{: .no_toc }

1. TOC
{:toc}

## Benchmark

These numbers are from the benchmark of the nwsaom article, run on 27 October 2026 with nwsaom 1.1.1 (core
3.10.0) and RSiena 1.6.14, Stata 18 and R 4.6.0. One thread
for both programs (RSiena without `useCluster`, nwsaom with `cores(1)`). The main models are the 20 of the article:
directed and undirected networks of 50 actors, networks with behavior, larger networks of 100 to 500 actors, and
models with covariates. The further models are two-mode networks, several networks at once and some less common
effects. Median seconds per fit; 7 fits per program (5 for T200, R4 and R5, 3 for S500). The programs ran in turn,
one process at a time; the fits of one program use different seeds.

Main models:

| Model | RSiena (s) | nwsaom (s) | RSiena / nwsaom | converged RSiena / nwsaom |
|---|---:|---:|---:|---:|
| N1 50 actors, 2 waves: outdegree, reciprocity | 0.877 | 0.233 | 3.8 | 7/7 / 7/7 |
| N2 3 waves, + gwesp | 1.85 | 1.08 | 1.7 | 7/7 / 7/7 |
| N4 + same smoking | 2.4 | 1.2 | 2.0 | 7/7 / 7/7 |
| N5 + gwesp, indegree and outdegree effects (inPopSqrt, outAct) | 2.97 | 1.37 | 2.2 | 7/7 / 7/7 |
| N6 + ego, alter and similarity of alcohol use | 3.5 | 1.46 | 2.4 | 7/7 / 7/7 |
| N7 as N2, unconditional estimation | 2.52 | 1.41 | 1.8 | 7/7 / 7/7 |
| U1 undirected, 2 waves, default effects | 0.315 | 0.106 | 3.0 | 7/7 / 7/7 |
| U2 undirected, pairwise model | 1.04 | 0.116 | 9.0 | 7/7 / 7/7 |
| C1 network and behavior (drinking) | 4.84 | 1.99 | 2.4 | 7/7 / 7/7 |
| C2 network and behavior (smoking) | 5.51 | 2.07 | 2.7 | 6/6 / 7/7 |
| C3 as C1, 2 waves | 1.81 | 0.43 | 4.2 | 7/7 / 7/7 |
| R1 network with covariates and 8 structural effects | 5.64 | 2.93 | 1.9 | 7/7 / 6/7 |
| R2 network, covariates and behavior | 7.96 | 4.06 | 2.0 | 6/7 / 7/7 |
| R3 undirected, gwesp, covariates | 0.785 | 0.38 | 2.1 | 7/7 / 7/7 |
| S100 as N2, 100 actors | 7.35 | 4.64 | 1.6 | 7/7 / 7/7 |
| S200 as N2, 200 actors | 31.4 | 20.1 | 1.6 | 7/7 / 7/7 |
| T200 200 actors, network and behavior | 69.4 | 30.2 | 2.3 | 5/5 / 5/5 |
| R4 as R1, 200 actors | 96.2 | 52.9 | 1.8 | 4/5 / 5/5 |
| R5 as R2, 200 actors | 114 | 62 | 1.8 | 4/5 / 5/5 |
| S500 as N2, 500 actors | 236 | 159 | 1.5 | 3/3 / 3/3 |

Further models:

| Model | RSiena (s) | nwsaom (s) | RSiena / nwsaom | converged RSiena / nwsaom |
|---|---:|---:|---:|---:|
| X1 two-mode 40 x 20: outdegree, inPopSqrt, cycle4 | 2.83 | 0.864 | 3.3 | 1/7 / 7/7 |
| X2 two-mode 40 x 30: five effects incl. cycle4, outIso, antiInIso2 | 0.614 | 0.29 | 2.1 | 7/7 / 7/7 |
| X3 two networks, reciprocity, crprod | 4.04 | 1.61 | 2.5 | 7/7 / 7/7 |
| X4 two networks and behavior | 8.74 | 1.26 | 6.9 | 6/7 / 7/7 |
| X5 two networks, behavior, ego/alter/similarity, closure | 12 | 4.13 | 2.9 | 6/7 / 7/7 |
| X6 two networks (one symmetric), crprod | 3.22 | 1.12 | 2.9 | 7/7 / 7/7 |
| X7 one network, gwesp, covariate triad effects | 4.49 | 2.98 | 1.5 | 7/7 / 7/7 |
| X8 one network, transitive-triplet and Jout effects | 2.96 | 1.65 | 1.8 | 6/7 / 6/7 |

On one thread nwsaom was faster than RSiena in all 28 models: median ratio 2.1, range 1.5 to 9.0 (the 20 main
models alone: median 2.0, 1.5 to 9.0). No model was slower. The largest differences are in small models: the
undirected pairwise model (9.0), the two-network model with behavior (6.9) and the first model (3.8). In the models
with gwesp the ratio is 1.7 to 2.4, and in the networks of 100 to 500 actors 1.5 to 2.3. The largest difference
between the mean estimates of the two programs was 0.08 RSiena standard errors, over 228 parameters.

Convergence is not the same on both sides in every row, and the timings are medians over all fits, converged or
not. **RSiena converged in only 1 of 7 fits of the first two-mode model (X1)** (overall convergence ratio below 0.25
by its criterion), nwsaom in 7 of 7; the speed-up of 3.3 for X1 therefore compares fits that did not stop at the
same quality, and the agreement of the estimates was computed from the fits that converged. RSiena also stopped
short in a few other rows (see the last column). One RSiena fit of C2 crashed with an error and is not counted.
One nwsaom fit each of R1 and X8 did not converge.

## More than one core

Both programs can use several cores (nwsaom with `cores()`, RSiena with `useCluster` and several R processes).
Median seconds per fit over 3 seeds; nwsaom threads and RSiena processes:

| Model | nwsaom 1 | nwsaom 2 | nwsaom 5 | nwsaom 10 | RSiena 1 | RSiena 5 | RSiena 10 |
|---|---:|---:|---:|---:|---:|---:|---:|
| R1 (50 actors) | 2.96 | 2.38 | 2.02 | 1.91 | 5.08 | 3.65 | 4.02 |
| R4 (200 actors) | 54.4 | 42.5 | 34.5 | 31.9 | 99.6 | 34.4 | 30.7 |
| R5 (200 actors) | 60.4 | 34.8 | 28.8 | 25.9 | 117 | 47.9 | 49.4 |

Ten threads are 1.5 (R1), 1.7 (R4) and 2.3 (R5) times faster than one thread, and 2.7 to 4.5 times faster than one
RSiena process. Against the best RSiena setting, nwsaom with ten threads is 1.9 (R1) and 1.8 (R5) times faster. For
R4, RSiena with 5 or 10 R processes (34.4 and 30.7 seconds) takes as long as nwsaom with ten threads (31.9
seconds): the advantage is gone. The estimates of nwsaom are identical for every number of threads.

## Where the speed comes from

- **A native simulation core.** nwsaom runs the simulation of the actors' steps in a compiled C plug-in. With the
  plug-in switched off, the first model took a median of 47 seconds (3 fits, 41 to 155 seconds)
  instead of 0.2 seconds. RSiena's simulation is compiled code as well (C++), so this is not the whole
  explanation.
- **Incremental change statistics.** For a proposed step of an actor the plug-in works out the change of each
  effect from the part of the network that the step touches. It does not recompute the statistic for the whole
  network.
- **Direct evaluation of degree effects.** Effects that depend on in- or out-degrees are computed from stored
  degree counts.
- **Free alternatives in two-mode networks.** For two-mode networks the plug-in keeps for each actor a list of the
  alternatives of the other mode that are still free, and draws from it (the two-mode models X1 and X2).
- **Sparse structures and 64-bit counters.** The network is stored as lists of ties, so the work grows with the
  number of ties, and 64-bit counters avoid overflow in networks with many ties.
- **Threads over simulations.** The simulations of a phase are distributed over the threads, and the result is the
  same for any number of threads.
- **The algorithm is the same.** Same phases, same number of simulations, same model of the ministeps. The gain
  does not come from doing less work. We did not isolate how much each of the points above contributes. In sampling
  profiles of one fit each, 60 to 87 percent of RSiena's non-idle samples were in its compiled
  code.

Compiled (C plug-in): the simulation of the process, the derivative estimates of the first phase, the
conditional-estimation step and the maximum-likelihood and Bayesian chains. Mata and ado: the rest (reading the
data, building the model, the parameter updates, the output).

## When it is not faster

- **Large networks.** For 100 to 500 actors (S100, S200, S500, R4, R5) the gain is only 1.5 to 1.8 times (T200, a
  network with behavior, 2.3).
- **RSiena with several processes.** See the table above: in R4 RSiena on 5 or 10 R processes matches nwsaom on ten
  threads, and in R5 and R1 the best RSiena setting is 1.8 and 1.9 times slower than nwsaom with ten threads.
  Whether R uses several cores is the choice of the user.
- **Less certain numbers.** The S500 row (the ratio 1.5) is the least certain of the table: the laptop went into
  sleep during the first attempt, and the repeat shared the machine with other jobs (see "How we measured").
  The three S500 fits of the final run took 152, 159 and 165 seconds for nwsaom and 217, 236 and 275 seconds for
  RSiena.

## How we measured

- **Machine, nwsaom run of 27 October.** Apple M5 Pro, macOS, one laptop. It ran on battery power throughout. Two things went wrong. The laptop
  went to sleep during the first S500 fits, so those fits and the R5 fits of the multi-core table from that period were
  discarded and repeated. Later, other jobs on the same machine started Stata and R from time to time during 17 of the
  27 fits; those results are kept, repeats agree, but they are less clean than the rest. The discarded fits and the
  record of other processes are in the data folder.
- **Software.** Stata 18 BE, R 4.6.0, nwcommands core 3.10.0, nwsaom 1.1.1, RSiena 1.6.14. The plug-in is the released build.
- **Data and scripts.** The Glasgow data of RSiena (tiled for larger networks) and generated two-mode and multi-network data; scripts, data and one row per fit in the [bench folder](https://github.com/thomas-u-grund/nwcommands/tree/main/bench).
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
