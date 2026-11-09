---
title: "Speed compared with R"
parent: "nwcommands (core)"
nav_order: 22
description: "Run times of nwergm, nwsaom, nwdynam and nwrem against ergm, RSiena, goldfish and relevent on the same data, with the cases where the Stata package is not faster."
permalink: /nwcommands/speed/
---

# Speed compared with R
{: .no_toc }

This page compares the run time of the four model packages, nwergm, nwsaom, nwdynam and nwrem, with the R
packages they follow: ergm, RSiena, goldfish and relevent. It says where the Stata packages were faster, where
they were not, and what we know about the reason. Times depend on the model, the data and the machine. Treat
the tables as examples, not as promises. Measured on 26 and 27 October 2026 (nwergm: 9 November; nwsaom: 8 and 9 November) with Stata 18 on one laptop; Stata
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
of the two programs was 0.09 standard errors for nwergm, 0.10 for nwsaom, 0.02 for nwrem and 0.002 for nwdynam
(standard errors of the R package).

| Comparison | Faster than the R package | Not faster |
|---|---|---|
| nwergm 1.5.2 and ergm 4.12.0 | all 8 models, 2.1 to 4.0 times | none of the eight; the fixed overhead matters on very small models |
| nwsaom 1.5.7 and RSiena 1.6.14 | all 27 models on one thread, median 3.8 times, 1.9 to 11.5 | none of the 27; with several cores on 200 actors only 2.0 to 4.2 times RSiena's best setting |
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

These are reasons, not measurements: we did not separate how much each one contributes. The advantage is smaller
where R can use several processes (RSiena with 5 or 10 R processes on large networks), and in nwrem, which has no plug-in and is slower than
relevent for recency effects (0.3 to 1.2 times). The speed page of each package gives the details.

How the numbers were made is at the end of this page and on each package's page. All raw timings, scripts and data are in the
[bench folder](https://github.com/thomas-u-grund/nwcommands/tree/main/bench) of the repository.

---

## The packages one by one

The benchmarks, the reasons for the differences and the cases where a package is not faster are on the speed page
of each package:

- [nwergm and ergm](../../nwergm/speed/)
- [nwsaom and RSiena](../../nwsaom/speed/)
- [nwdynam and goldfish](../../nwdynam/speed/)
- [nwrem and relevent](../../nwrem/speed/)

---

## How we measured

- **Machine.** Apple M5 Pro, macOS, one laptop. The nwergm, nwrem and nwdynam runs (26 and 27 October) had no
  other R or Stata process running. The one-minute load average before each fit is in the data files: median 2.4
  over 1,238 fits (3.3 in the nwergm run), which includes the benchmark process itself and one to two cores of
  other background load. Two fits started above a load of 7.
- **Machine, nwergm run of 9 November.** The same laptop, with no other Stata or R job running (load average
  1.8 to 3.4 before the fits).
- **Machine, nwsaom run of 8 and 9 November.** The same laptop; RSiena ran on 8 November and nwsaom on 9 November,
  with no other Stata or R job running during a fit (median load average 2.2 and 2.9).
- **Software.** Stata 18 BE, R 4.6.0. nwcommands core 3.10.0 (3.17.2 for the nwergm and nwsaom runs), nwergm 1.5.2, nwsaom 1.5.7, nwdynam 1.2.0, nwrem 1.0.10; ergm 4.12.0, RSiena 1.6.14, relevent 1.2-1,
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

Last updated 9 November 2026.
