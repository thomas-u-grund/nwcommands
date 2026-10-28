---
title: "Speed compared with R"
parent: "nwcommands (core)"
nav_order: 13
description: "Run times of nwergm, nwsaom, nwdynam and nwrem against ergm, RSiena, goldfish and relevent on the same data, with the cases where the Stata package is not faster."
permalink: /nwcommands/speed/
---

# Speed compared with R
{: .no_toc }

This page compares the run time of the four model packages, nwergm, nwsaom, nwdynam and nwrem, with the R
packages they follow: ergm, RSiena, goldfish and relevent. It says where the Stata packages were faster, where
they were not, and what we know about the reason. Times depend on the model, the data and the machine. Treat
the tables as examples, not as promises. Measured on 26 and 27 October 2026 with Stata 18 on one laptop; Stata
17 was not timed.

1. TOC
{:toc}

## Summary

None of the four R packages is slow R code. ergm's sampler is C, RSiena's simulation is C++, goldfish has C++
estimation engines and relevent has compiled code. A difference in time is therefore not a difference between
compiled and interpreted code. The model packages run their inner loops in a compiled plug-in written in C
(nwergm, nwsaom, nwdynam for one effect set) or in Mata, Stata's matrix language (nwrem and the other nwdynam
effect sets).

The algorithms are the same as in R, and the estimates agree: the largest difference between the mean estimates
of the two programs was 0.06 standard errors for nwergm, 0.08 for nwsaom, 0.02 for nwrem and 0.002 for nwdynam
(standard errors of the R package).

| Comparison | Faster than the R package | Not faster |
|---|---|---|
| nwergm 1.3.0 and ergm 4.12.0 | all 8 models, 2.9 to 9.4 times | none of the eight; the fixed overhead matters on very small models |
| nwsaom 1.1.1 and RSiena 1.6.14 | all 28 models on one thread, median 2.1 times, 1.5 to 9.0 | large networks only 1.5 to 1.8 times; RSiena on 5 or 10 R processes is as fast as nwsaom on 10 threads in one model |
| nwdynam 1.2.0 and goldfish 1.6.12 | original structural effects: 7.7 to 76 times; one added covariate effect (Mata): 1.2 to 2.4 times | the gain of the Mata engine shrinks to 1.0 for large networks; not measured for larger networks with the added effect |
| nwrem 1.0.10 and relevent 1.2-1 | degree, inertia and covariate effects: up to 41 times with a Hessian in relevent | recency effects: 0.3 to 1.2 times |

### Where the advantage comes from

The reasons are in the design of the packages, and they are the same in outline for the three that have a plug-in.

- **The core is native code.** The simulation (nwsaom), the Markov chain Monte Carlo sampler (nwergm) and the
  likelihood and gradient of the original structural effects (nwdynam) run in a plug-in written in C. There are no
  interpreted loops in the part of the program that takes most of the time.
- **Change statistics are updated, not recomputed.** When a tie is proposed or an actor makes a step, the plug-in
  works out how the statistics change because of that one step. It does not recompute the statistics of the whole
  network.
- **Degree effects are evaluated directly.** Effects that depend on degrees are computed from the stored degree
  counts and need no pass over the ties.
- **Sparse data structures.** The networks are stored as lists of ties (and, in nwergm, as a bit matrix), so the
  work depends on the number of ties and not on the square of the number of actors. The counters are 64-bit, so
  networks with many ties do not overflow.
- **Threads.** nwsaom spreads the simulations over threads, and the estimates are identical for any number of
  threads (the `cores()` option).

These are reasons, not measurements: we did not separate how much each one contributes. The advantage is small
where the work is dominated by something else (large networks in nwsaom, only 1.5 to 1.8 times), where R can use
several processes (RSiena with 5 or 10 R processes), and in nwrem, which has no plug-in and is slower than
relevent for recency effects (0.3 to 1.2 times). The sections below give the details.

How the numbers were made is at the end of the page. All raw timings, scripts and data are in the
[bench folder](https://github.com/thomas-u-grund/nwcommands/tree/main/bench) of the repository.

---

## nwergm and ergm

Eight models of the nwergm article: networks of 30 to 1,000 nodes and two real networks (Lazega advice,
Faux Mesa High). Median of 7 fits per program. Version 1.2.3 is the release before 1.3.0. All timings are of
nwergm 1.3.0, measured on 26 October 2026. The current release is 1.3.1, which changes the output of
`estat mcmcdiag` and the documentation, not the sampler or the estimation; it was not timed again.

| Model | ergm 4.12.0 (s) | nwergm 1.2.3 (s) | nwergm 1.3.0 (s) | ergm / nwergm 1.3.0 |
|---|---:|---:|---:|---:|
| B1 30 nodes, directed: edges, mutual | 0.20 | 0.59 | 0.038 | 5.4 |
| B2 100 nodes, directed: + nodematch | 0.30 | 0.67 | 0.064 | 4.7 |
| B3 100 nodes, undirected: edges, gwesp | 0.32 | 1.7 | 0.070 | 4.6 |
| B4 500 nodes, sparse, undirected: + nodematch, gwesp | 2.9 | 2.7 | 0.31 | 9.4 |
| B5 1,000 nodes, directed: edges, mutual, nodematch | 8.4 | 4.3 | 1.1 | 7.9 |
| B6 1,000 nodes, sparse, undirected: edges, gwesp, gwnsp | 7.2 | 17.2 | 2.5 | 2.9 |
| Lazega advice, 71 nodes, 7 terms | 10.4 | 19.4 | 3.1 | 3.4 |
| Faux Mesa High, 205 nodes, gwesp(0.25) | 4.0 | 12.5 | 1.4 | 2.9 |


All 168 fits converged. nwergm 1.3.0 was faster than ergm on all eight models. In no single pair of fits was ergm
faster (the lowest pair ratio was 1.3). Version 1.2.3 was slower than ergm on six of the eight models. The number
of iterations of the Monte Carlo algorithm depends on the seed in both programs and drives most of the spread:
ergm needed 6.3 to 17.3 seconds for the 1,000-node directed model. Compare medians, not single fits. The largest
difference between the mean estimates of nwergm 1.3.0 and ergm was 0.06 standard errors.

### Where the speed comes from

- **Less sampling work per fit.** Version 1.3.0 follows ergm's adaptive sampling: a base sample of
  max(256, 32 times the number of parameters) draws, extended until the effective sample size reaches 64, with
  ergm's convergence test, and the covariance matrix and the log-likelihood taken from the last iteration.
  Version 1.2.3 drew a fixed 3,000 per iteration, drew another sample for the covariance and ran 16 bridges of
  3,000 draws for the log-likelihood. On the benchmark models, 1.2.3 ran about 9.5 million Metropolis-Hastings
  steps per fit (77 million for Mesa) and 1.3.0 ran 0.5 to 13 million.
- **Compiled code alone was not the reason.** Version 1.2.3 used the same plug-in and was slower than ergm on six
  of the eight models. Version 1.3.0 is 4 to 25 times faster than 1.2.3.
- **Faster kernels.** The plug-in keeps the adjacency as a bit matrix, updates the change statistics of a proposed
  toggle from the neighborhoods of the two nodes instead of recomputing the statistics of the network, tabulates
  the geometrically weighted kernel once per decay value and draws a random dyad in constant time. The results are
  identical to those of the older kernels. We did not separate how much of the gain comes from the sampling policy
  and how much from the kernels.
- **Pseudolikelihood on distinct rows.** For large networks the pseudolikelihood is computed on the distinct rows of
  the design matrix with weights. A directed network of 1,000 nodes has 999,000 dyads but only a few distinct rows.

Compiled (C plug-in): the Metropolis-Hastings sampler, the change statistics, the observed statistics, the design
matrix of the pseudolikelihood and the Newton steps of curved pseudolikelihood fits. Mata and ado: the estimating
step, the covariance, the convergence test, the diagnostics and the output.

### When it is not faster

- **Without the plug-in.** On a platform without the compiled plug-in, or with the option that forces the Mata
  sampler, nwergm is much slower than R: 233 seconds against 1.1 seconds with the plug-in for the Lazega model with
  five terms (median of 3 and 5 fits), where ergm needed 9.9 seconds.
- **Small models.** Every call has a fixed overhead of about 0.05 to 0.25 seconds (parsing, Mata set-up, returning
  results), and the first fit of a session also loads the Mata library. On a model that ergm fits in 0.2 seconds the
  difference is mostly this overhead.
- **Smaller effective sample size.** At the default target, the final sample of a nwergm fit of the Lazega model
  had an effective sample size of about 215 to 315 (503 draws). In a check with one seed, ergm's final sample had
  about 370 to 500 (774 draws). The adaptive sample is smaller than the older fixed one, which had about 360 to
  550. If you need a larger effective sample size, raise the target with `mcmleeffectivesize()`; this costs time.
- **Not measured.** Linux and Windows, models outside these eight, and Stata 17. The timings are of version 1.3.0
  (see above for 1.3.1).

---

## nwsaom and RSiena

These numbers are from the benchmark of the nwsaom article, re-run on 27 October 2026 with nwsaom 1.1.1 (core
3.10.0) and RSiena 1.6.14, Stata 18 and R 4.6.0. They replace the numbers of version 1.1.0 (26 October). One thread
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

### More than one core

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

### Where the speed comes from

- **A native simulation core.** nwsaom runs the simulation of the actors' steps in a compiled C plug-in. With the
  plug-in switched off, the first model took a median of 47 seconds (3 fits, 41 to 155 seconds, version 1.1.0)
  instead of 0.2 seconds. RSiena's simulation is compiled code as well (C++), so this is not the whole
  explanation.
- **Incremental change statistics.** For a proposed step of an actor the plug-in works out the change of each
  effect from the part of the network that the step touches. It does not recompute the statistic for the whole
  network.
- **Direct evaluation of degree effects.** Effects that depend on in- or out-degrees are computed from stored
  degree counts.
- **Free alternatives in two-mode networks.** For two-mode networks the plug-in keeps for each actor a list of the
  alternatives of the other mode that are still free, and draws from it. This is what turned the model that had
  been slower than RSiena in version 1.1.0 (X2: 1.71 seconds against 0.84) into one that is faster (0.29 against
  0.61). X1 and X2 are both two-mode models.
- **Sparse structures and 64-bit counters.** The network is stored as lists of ties, so the work grows with the
  number of ties, and 64-bit counters avoid overflow in networks with many ties.
- **Threads over simulations.** The simulations of a phase are distributed over the threads, and the result is the
  same for any number of threads.
- **The algorithm is the same.** Same phases, same number of simulations, same model of the ministeps. The gain
  does not come from doing less work. We did not isolate how much each of the points above contributes. In sampling
  profiles of one fit each (version 1.1.0), 60 to 87 percent of RSiena's non-idle samples were in its compiled
  code.

Compiled (C plug-in): the simulation of the process, the derivative estimates of the first phase, the
conditional-estimation step and the maximum-likelihood and Bayesian chains. Mata and ado: the rest (reading the
data, building the model, the parameter updates, the output).

### When it is not faster

- **Large networks.** For 100 to 500 actors (S100, S200, S500, R4, R5) the gain is only 1.5 to 1.8 times (T200, a
  network with behavior, 2.3).
- **RSiena with several processes.** See the table above: in R4 RSiena on 5 or 10 R processes matches nwsaom on ten
  threads, and in R5 and R1 the best RSiena setting is 1.8 and 1.9 times slower than nwsaom with ten threads.
  Whether R uses several cores is the choice of the user.
- **Earlier results.** In version 1.1.0 one two-mode model (X2) was slower than RSiena (0.64 times) and the gain in
  the large networks was 1.0 to 2.5. Both were improved in 1.1.1.
- **Less certain numbers.** The S500 row (the ratio 1.5) is the least certain of the table: the laptop went into
  sleep during the first attempt, and the repeat shared the machine with other jobs (see "How we measured").
  The three S500 fits of the final run took 152, 159 and 165 seconds for nwsaom and 217, 236 and 275 seconds for
  RSiena.

---

## nwdynam and goldfish

Choice sub-model of a dynamic network actor model on simulated event logs of 200 to 20,000 events among 20 to 100
actors. Median of 7 fits (5 at 20,000 events); all fits converged. The first effect set (C1) is the three original
structural effects (inertia, reciprocity, indegree of the alternative). This is the set for which nwdynam has a
compiled plug-in. The second (C2) adds `same(group)`, which runs in Mata. goldfish has three engines; `default_c`
and `gather_compute` took the same time, and `default` was 2 to 5 times slower (see the repository data), so the
tables show `default_c`.

| C1: 3 original effects | goldfish default_c (s) | nwdynam, plug-in (s) | ratio | nwdynam, no plug-in (s) | ratio |
|---|---:|---:|---:|---:|---:|
| 200 events, 20 actors | 0.13 | 0.017 | 7.7 | 0.028 | 4.6 |
| 1000 events, 30 actors | 0.64 | 0.023 | 28 | 0.11 | 5.8 |
| 5000 events, 20 actors | 3.2 | 0.042 | 76 | 0.42 | 7.6 |
| 5000 events, 50 actors | 3.2 | 0.079 | 41 | 1.1 | 3.1 |
| 5000 events, 100 actors | 3.3 | 0.12 | 28 | 2.8 | 1.2 |
| 20000 events, 100 actors | 13.2 | 0.49 | 27 | 12.9 | 1.0 |


| C2: adds same(group), Mata engine | goldfish default_c (s) | nwdynam (s) | ratio |
|---|---:|---:|---:|
| 200 events, 20 actors | 0.13 | 0.057 | 2.3 |
| 1000 events, 30 actors | 0.64 | 0.30 | 2.1 |
| 5000 events, 20 actors | 3.2 | 1.3 | 2.4 |
| 5000 events, 50 actors | 3.3 | 2.8 | 1.2 |


The ratio is the time of goldfish divided by the time of nwdynam. Estimates agree to 0.002 goldfish standard errors.

### Where the speed comes from

- **The plug-in for the original structural effects.** It computes the likelihood and its gradient and keeps running
  in-degree and out-degree counts. On C1 it made nwdynam 1.7 to 26 times faster than nwdynam's own Mata engine,
  and the gain grows with the number of actors.
- **goldfish spends its time in preprocessing.** For the engines `default_c` and `gather_compute`, 98 to 100
  percent of the call is the step that computes the statistics of each event for each possible receiver (timed with
  `preprocessingOnly = TRUE`). The time depends on the number of events, not on the number of actors (about 3.2
  seconds at 5,000 events for 20, 50 and 100 actors). nwdynam has no separate step. The comparison is of whole
  calls for one fit. Whether goldfish can reuse the preprocessing across several fits was not tested.

Compiled (C plug-in): the likelihood and gradient of the original structural choice and rate models. Mata: the
optimizer, every other effect set and the standard errors. Ado: parsing and output.

### When it is not faster

- **Effect sets outside the plug-in.** Without the plug-in (Mata engine on C1, and C2), nwdynam was 4.6, 5.8, 7.6
  and 3.1 times faster than goldfish for up to 50 actors, 1.2 times at 5,000 events and 100 actors, and equal
  (1.0) at 20,000 events and 100 actors. For C2 the gain was 2.3, 2.1, 2.4 and 1.2 times. The gain of the Mata
  engine shrinks as the number of actors grows.
- **Not measured.** The run was stopped early. C2 at 5,000 events with 100 actors and at 20,000 events with 100
  actors and above were not run. Neither were other effect sets (transitivity, covariate effects in the rate
  model) and the rate sub-model.

---

## nwrem and relevent

Five effect sets on simulated event logs of 200 to 20,000 events among 20 to 100 actors: S1 two degree effects;
S2 four degree effects; S3 four degree and two inertia effects; S4 two degree and two recency effects; S5 two
degree and three covariate effects. relevent's `hessian` argument defaults to `FALSE`, but nwrem always returns a
variance matrix, which it gets from the Hessian. A like-for-like comparison therefore uses `hessian = TRUE` in R.
Both settings were timed.

The table shows the time of relevent divided by the time of nwrem, as "with Hessian / without Hessian". Median of
7 fits (fewer in the larger cells: 5, 3 or 1). A ">" means relevent did not finish within the 600-second limit, so
the ratio is a lower bound. "n.r." means relevent was not run because it had timed out in a smaller cell of the same
effect set.

| Effect set \ events / actors | 200 / 20 | 1,000 / 30 | 5,000 / 20 | 5,000 / 50 | 5,000 / 100 | 20,000 / 100 |
|---|---:|---:|---:|---:|---:|---:|
| S1 nodsnd, nidrec | 4.4 / 3.5 | 3.7 / 2.5 | 2.6 / 1.9 | 3.8 / 2.7 | 6.1 / 3.6 | 5.4 / 4.8 |
| S2 four degree effects | 3.5 / 1.8 | 5.4 / 2.7 | 3.7 / 2.2 | 7.0 / 4.2 | 3.7 / 1.8 | >4.0 / 3.9 |
| S3 four degree + two inertia effects | 24 / 12 | 41 / 19 | 34 / 19 | >23 / >23 | n.r. / n.r. | n.r. / n.r. |
| S4 two degree + two recency effects | 1.2 / 0.71 | 0.98 / 0.60 | 0.50 / 0.32 | 1.1 / 0.77 | 1.1 / 0.69 | nwrem >600 s; relevent 588 s (F) |
| S5 two degree + three covariate effects | 3.0 / 1.8 | 2.8 / 1.5 | 2.3 / 1.4 | 3.2 / 2.0 | 3.1 / 1.7 | >1.4 / >1.4 |


In the cells it finished, nwrem's median times range from 0.05 seconds (S1, 200 events) to 439 seconds (S5, 20,000 events, 1 fit). In the
largest S4 cell, nwrem hit the limit and relevent without the Hessian finished in 588 seconds. All finished fits
converged. The largest difference between the mean estimates was 0.02 relevent standard errors.

### Where the speed comes from

- **The Hessian costs relevent time.** Computing the Hessian took 12 to 55 percent of relevent's time. A user who
  does not need standard errors gets relevent 1.1 to 2.2 times faster than in the "with Hessian" figures.
- **Largest gain with inertia effects.** For the model with four degree and two inertia effects the ratio was 24 to
  41 with the Hessian (12 to 19 without). At 5,000 events and 50 actors relevent did not finish in 600 seconds
  and nwrem needed 26 seconds. We have not traced the reason in the code of either program.
- **No plug-in.** nwrem runs entirely in Mata, with ado for parsing and output. relevent's likelihood is compiled
  code. The gain therefore does not come from compiled against interpreted code.

### When it is not faster

- **Recency effects (S4).** Without the Hessian, relevent was faster than nwrem in every S4 cell (ratios 0.32 to
  0.77). With the Hessian the ratios were 0.50 to 1.2: about equal in four cells and slower in one. The code sorts the
  past contact times of each actor for every event; we did not profile whether this is the reason.
- **The largest problems.** At 20,000 events relevent timed out with the Hessian in three of the five effect sets
  (and was not run for a fourth), and without it in one. nwrem finished four of the five sets, in 72 to 439 seconds,
  with 1 to 3 fits each.

---

## How we measured

- **Machine.** Apple M5 Pro, macOS, one laptop. The nwergm, nwrem and nwdynam runs (26 and 27 October) had no
  other R or Stata process running. The one-minute load average before each fit is in the data files: median 2.4
  over 1,238 fits (3.3 in the nwergm run), which includes the benchmark process itself and one to two cores of
  other background load. Two fits started above a load of 7.
- **Machine, nwsaom run of 27 October.** The laptop ran on battery power (low-power setting) throughout. Before
  single-process fits the load average was 1.4 to 5.4 (median 2.7); at the start of each single-process fit no other
  R or Stata process was found. Two things went wrong and were handled. First, the laptop went to sleep during the
  first S500 fits and ran about 1.5 times slower for a while afterwards; those S500 fits and the R5 fits of the
  multi-core table from that period were discarded and repeated after a calibration (N2 and R1 fits) showed the
  earlier speed again. Second, from about 11:46 other jobs on the same machine started Stata and R from time to time;
  a watcher flagged 17 of the 27 fits after that time (the repeated S500 fits and the repeated R5 multi-core
  fits; the RSiena fits with 5 or 10 processes are flagged by mistake, because the watcher does not recognize
  their worker processes). Those results are kept, and repeats agree, but they are less clean than the rest. The discarded fits and
  the watcher's record are in the data folder.
- **Software.** Stata 18 BE, R 4.6.0. nwcommands core 3.10.0, nwergm 1.3.0 (and 1.2.3; the current release is
  1.3.1, see above), nwsaom 1.1.1, nwdynam 1.2.0, nwrem 1.0.10; ergm 4.12.0, RSiena 1.6.14, relevent 1.2-1,
  goldfish 1.6.12. All timings are with Stata 18; Stata 17 was not timed. The plug-ins are the released builds.
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
- **Agreement.** For every comparison we computed the largest difference between the mean estimates of the two
  programs, in standard errors of the R package. The values are given in each section.
- **Data.** The nwergm models are the eight of the nwergm article. The nwsaom models use the Glasgow data of
  RSiena (tiled for larger networks) and generated two-mode and multi-network data. The nwrem and nwdynam data are
  simulated event logs from the generator scripts in the repository.
- **Scripts and raw timings.** [github.com/thomas-u-grund/nwcommands/tree/main/bench](https://github.com/thomas-u-grund/nwcommands/tree/main/bench)
  holds the scripts, the data, one row per fit with the load average, the summaries and a short description of how
  to repeat each comparison.

Times from earlier runs on a loaded machine are not used on this page. The nwsaom numbers are those of version
1.1.1 (27 October 2026); the numbers of nwsaom 1.1.0 (26 October) are kept in the data folder as an earlier run.
Last updated 27 October 2026.
