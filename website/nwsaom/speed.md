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

These numbers are from the benchmark of the nwsaom article: nwsaom 1.5.7 (core 3.17.2) in Stata 18 BE, run on
9 November 2026, against RSiena 1.6.14 in R 4.6.0, run on 8 November 2026. One thread for both programs (RSiena
without `useCluster`, nwsaom with `cores(1)`). The main models are the 20 of the article: directed and undirected
networks of 50 actors, networks with behavior, larger networks of 100 to 500 actors, and models with covariates.
The further models are two-mode networks, several networks at once and some less common effects. Median seconds
per fit; 7 fits per program and model, or 5 when the first fit took more than 60 seconds and 3 when it took more
than 200 seconds (the fit counts are in the last column).

Main models:

| Model | RSiena (s) | nwsaom (s) | RSiena / nwsaom | converged RSiena / nwsaom |
|---|---:|---:|---:|---:|
| N1 50 actors, 2 waves: outdegree, reciprocity | 0.839 | 0.219 | 3.8 | 7/7 / 7/7 |
| N2 3 waves, + gwesp | 1.81 | 0.515 | 3.5 | 7/7 / 7/7 |
| N4 + same smoking | 2.24 | 0.596 | 3.8 | 7/7 / 7/7 |
| N5 + gwesp, indegree and outdegree effects (inPopSqrt, outAct) | 3.02 | 0.771 | 3.9 | 7/7 / 7/7 |
| N6 + ego, alter and similarity of alcohol use | 3.57 | 0.825 | 4.3 | 7/7 / 7/7 |
| N7 as N2, unconditional estimation | 2.48 | 0.632 | 3.9 | 7/7 / 7/7 |
| U1 undirected, 2 waves, default effects | 0.329 | 0.093 | 3.5 | 7/7 / 7/7 |
| U2 undirected, pairwise model | 1.03 | 0.09 | 11.5 | 7/7 / 7/7 |
| C1 network and behavior (drinking) | 4.66 | 0.982 | 4.8 | 7/7 / 7/7 |
| C2 network and behavior (smoking) | 5.52 | 1.05 | 5.2 | 6/6 / 6/7 |
| C3 as C1, 2 waves | 1.84 | 0.447 | 4.1 | 7/7 / 7/7 |
| R1 (50 actors) | 5.29 | 1.33 | 4.0 | 7/7 / 7/7 |
| R2 network, covariates and behavior | 7.35 | 1.64 | 4.5 | 6/7 / 7/7 |
| R3 undirected, gwesp, covariates | 0.743 | 0.237 | 3.1 | 7/7 / 7/7 |
| S100 as N2, 100 actors | 6.82 | 1.97 | 3.5 | 7/7 / 7/7 |
| S200 as N2, 200 actors | 31.9 | 8.3 | 3.8 | 7/7 / 7/7 |
| S500 as N2, 500 actors | 231 | 64.5 | 3.6 | 3/3 / 5/5 |
| T200 200 actors, network and behavior | 66.5 | 13.8 | 4.8 | 5/5 / 7/7 |
| R4 (200 actors) | 90.1 | 22.2 | 4.1 | 4/5 / 7/7 |
| R5 (200 actors) | 109 | 23.6 | 4.6 | 4/5 / 6/7 |

Further models:

| Model | RSiena (s) | nwsaom (s) | RSiena / nwsaom | converged RSiena / nwsaom |
|---|---:|---:|---:|---:|
| X1 two-mode 40 x 20: outdegree, inPopSqrt, cycle4 | 2.75 | 0.847 | 3.2 | 1/7 / 7/7 |
| X2 two-mode 40 x 30: five effects incl. cycle4, outIso, antiInIso2 | 0.606 | 0.252 | 2.4 | 7/7 / 7/7 |
| X3 two networks, reciprocity, crprod | 3.75 | 1.41 | 2.7 | 7/7 / 5/7 |
| X4 two networks and behavior | 8.32 | 1.17 | 7.1 | 6/7 / 6/7 |
| X5 two networks, behavior, ego/alter/similarity, closure | 11.5 | 3.91 | 2.9 | 6/7 / 7/7 |
| X6 two networks (one symmetric), crprod | 3.08 | 0.997 | 3.1 | 7/7 / 7/7 |
| X7 one network, gwesp, covariate triad effects | 4.26 | 2.22 | 1.9 | 7/7 / 7/7 |
| X8 one network, transitive-triplet effects (transTrip1, transRecTrip2) | 2.06 | 1.16 | 1.8 | 7/7 / 7/7 |

On one thread nwsaom was faster than RSiena in all 28 models: median ratio 3.8, range 1.8 to 11.5 (the 20 main
models alone: 3.1 to 11.5). The largest ratio is for the undirected pairwise model (U2, 11.5), followed by the
two-network model with behavior (X4, 7.1). In the models with gwesp the ratio is 3.5 to 4.3, in the networks of
100 to 500 actors 3.5 to 4.8, and in the co-evolution models 4.1 to 5.3. Over 227 parameters, the mean estimates of
the two programs differ by at most 0.10 RSiena standard errors.

The timings are medians over all fits, converged or not (overall maximum convergence ratio below 0.25).
**RSiena converged in only 1 of 7 fits of the first two-mode model (X1)**, nwsaom in 7 of 7, so the ratio of 3.3
for X1 compares fits that did not stop at the same quality. nwsaom did not converge in 2 of 7 fits of X3 and in one
fit each of C2, R5 and X4; RSiena in one fit each of R2, R4, R5, X4 and X5. One RSiena fit of C2 stopped with
an error and is not counted. The comparison of the estimates uses the converged fits.

## More than one core

Both programs can use several cores (nwsaom with `cores()`, RSiena with `useCluster` and several R processes).
Median seconds per fit over 3 seeds; nwsaom threads and RSiena processes:

| Model | nwsaom 1 | nwsaom 2 | nwsaom 5 | nwsaom 10 | RSiena 1 | RSiena 5 | RSiena 10 |
|---|---:|---:|---:|---:|---:|---:|---:|
| R1 (50 actors) | 1.34 | 1.11 | 0.96 | 0.92 | 4.74 | 3.53 | 3.97 |
| R4 (200 actors) | 22.0 | 18.1 | 15.4 | 14.7 | 89.5 | 34.4 | 29.7 |
| R5 (200 actors) | 23.6 | 14.0 | 11.7 | 10.9 | 111 | 46.0 | 49.1 |

Ten threads are 1.5 (R1 and R4) and 2.2 (R5) times as fast as one thread, and 5.2 to 10.2 times as fast as one
RSiena process. Against the best RSiena setting, nwsaom with ten threads is 3.8 (R1), 2.0 (R4) and 4.2 (R5) times
as fast. The gain from threads is less than proportional because the second phase of the estimation, where each
step needs the previous estimate, cannot be split over threads. The estimates of nwsaom are identical for every
number of threads.

## Where the speed comes from

Both programs run the same algorithm with RSiena's default settings (the same phases, Phase 2 rules and convergence
criteria), and about the same number of simulations per fit; the difference is in how a simulation is carried out.

- **Less overhead around each simulation.** RSiena runs the loop over a fit's roughly 2,000 simulations in R and
  calls its compiled code once per simulation. By R's sampling profiler, this R code takes about a fifth of
  RSiena's time on the first model (N1) and about a tenth with gwesp (N2). nwsaom runs the simulations of the first
  and third phases in batches inside its compiled plug-in, and its own loop in the second phase costs less than
  half as much per step.
- **Change statistics computed together.** RSiena loops over an actor's alternatives and, for each, over the
  effects. The plug-in passes once over all alternatives per effect and computes quantities that several effects
  share once per actor: for example, the two-path counts serve gwesp and its variants, transitive reciprocated
  triplets, transitive ties and balance, and the geometrically weighted terms come from a table computed once per
  fit.
- **Two-mode and several networks.** Several networks share one data structure, and two-mode networks loop only
  over the nodes of the other mode (X2).
- **Threads over simulations.** The simulations of the first and third phases are distributed over the threads,
  and the result is the same for any number of threads.

How much each point contributes was not measured inside RSiena's C++ code; the split rests on the profile and on
reading the source. nwsaom's own Mata implementation of the same algorithm is about 200 times slower than the
plug-in, which shows how much the implementation alone can matter.

## When it is not faster

- **Large networks and several cores.** On 200 actors, RSiena with 5 or 10 R processes is two to three times as
  fast as on one, and with ten threads nwsaom is then only 2.0 (R4) to 4.2 (R5) times as fast.
- **The cheapest further models.** For a few of the further models (X7 and X8, with covariate triad and
  transitive-triplet effects) the ratio is below 2.

## How we measured

- **Machine.** Apple M5 Pro (18 cores), macOS 26.5.1, one laptop that also ran other jobs. The one-minute load
  average was recorded before every fit: median 2.3 during the RSiena fits and 2.8 during the nwsaom fits, on 18
  cores, which affects single-threaded fits little. A fit waited while another Stata or R process was running.
- **Software.** Stata 18 BE, R 4.6.0, nwcommands core 3.17.2, nwsaom 1.5.7, RSiena 1.6.14. The plug-in is the
  released build.
- **Data and scripts.** The Glasgow data of RSiena (tiled for larger networks) and generated two-mode and
  multi-network data; the scripts, the data and one row per fit are in the replication package of the nwsaom
  article.
- **One fit per process.** Each fit runs in its own Stata or R process after an untimed warm-up fit, so the first
  call (loading libraries) is not in the time. The timer covers the estimation command. Loading the data is not
  timed.
- **Medians over seeds.** Each repeat uses a different seed, the same seeds in both programs. The tables show
  medians; a single pair of fits can differ from the median ratio.
- **Same data, same model, defaults.** Both programs get the same data and the same specification with their
  default control settings. Neither side is tuned. Convergence is checked in every fit with RSiena's criterion.
- **Time limit.** Each fit has a limit of 600 seconds. A fit that reaches it is reported as a time-out, not
  dropped; none did.

The other model packages are compared with their R counterparts on the page [Speed compared with R](../../nwcommands/speed/).
