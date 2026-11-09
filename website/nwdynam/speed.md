---
title: "Speed"
parent: "nwdynam (DyNAM)"
nav_order: 5.5
description: "Run times of nwdynam against R's goldfish on the same data and models, where nwdynam is faster, where it is not, and why."
permalink: /nwdynam/speed/
---

# Speed compared with goldfish
{: .no_toc }

1. TOC
{:toc}

## Benchmark

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

## Where the speed comes from

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

## When it is not faster

- **Effect sets outside the plug-in.** Without the plug-in (Mata engine on C1, and C2), nwdynam was 4.6, 5.8, 7.6
  and 3.1 times faster than goldfish for up to 50 actors, 1.2 times at 5,000 events and 100 actors, and equal
  (1.0) at 20,000 events and 100 actors. For C2 the gain was 2.3, 2.1, 2.4 and 1.2 times. The gain of the Mata
  engine shrinks as the number of actors grows.
- **Not measured.** The run was stopped early. C2 at 5,000 events with 100 actors and at 20,000 events with 100
  actors and above were not run. Neither were other effect sets (transitivity, covariate effects in the rate
  model) and the rate sub-model.

## How we measured

- **Machine.** Apple M5 Pro, macOS, one laptop, 26 and 27 October 2026, no other R or Stata process running; the load average before each fit is in the data files.
- **Software.** Stata 18 BE, R 4.6.0, nwcommands core 3.10.0, nwdynam 1.2.0, goldfish 1.6.12. The plug-in is the released build.
- **Data and scripts.** Simulated event logs from the generator scripts; scripts, data and one row per fit in the [bench folder](https://github.com/thomas-u-grund/nwcommands/tree/main/bench).
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
