---
title: "Speed"
parent: "nwrem (REM)"
nav_order: 5.5
description: "Run times of nwrem against R's relevent on the same data and models, where nwrem is faster, where it is not, and why."
permalink: /nwrem/speed/
---

# Speed compared with relevent
{: .no_toc }

1. TOC
{:toc}

## Benchmark

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

## Where the speed comes from

- **The Hessian costs relevent time.** Computing the Hessian took 12 to 55 percent of relevent's time. A user who
  does not need standard errors gets relevent 1.1 to 2.2 times faster than in the "with Hessian" figures.
- **Largest gain with inertia effects.** For the model with four degree and two inertia effects the ratio was 24 to
  41 with the Hessian (12 to 19 without). At 5,000 events and 50 actors relevent did not finish in 600 seconds
  and nwrem needed 26 seconds. We have not traced the reason in the code of either program.
- **No plug-in.** nwrem runs entirely in Mata, with ado for parsing and output. relevent's likelihood is compiled
  code. The gain therefore does not come from compiled against interpreted code.

## When it is not faster

- **Recency effects (S4).** Without the Hessian, relevent was faster than nwrem in every S4 cell (ratios 0.32 to
  0.77). With the Hessian the ratios were 0.50 to 1.2: about equal in four cells and slower in one. The code sorts the
  past contact times of each actor for every event; we did not profile whether this is the reason.
- **The largest problems.** At 20,000 events relevent timed out with the Hessian in three of the five effect sets
  (and was not run for a fourth), and without it in one. nwrem finished four of the five sets, in 72 to 439 seconds,
  with 1 to 3 fits each.

## How we measured

- **Machine.** Apple M5 Pro, macOS, one laptop, 26 and 27 October 2026, no other R or Stata process running; the load average before each fit is in the data files.
- **Software.** Stata 18 BE, R 4.6.0, nwcommands core 3.10.0, nwrem 1.0.10, relevent 1.2-1.
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
