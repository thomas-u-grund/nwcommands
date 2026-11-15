---
title: "Speed"
parent: "nwrem (REM)"
nav_order: 5.5
description: "Run times of nwrem 1.2.0 against R's relevent on the same data and models, in every cell nwrem was faster; the closest case, the largest fits and the memory."
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
7 fits of nwrem (5 in the largest S4 cell) against the medians of relevent (7 fits; 5, 3 or 1 in the larger cells). A ">" means relevent did not finish within the 600-second limit, so
the ratio is a lower bound. "n.r." means relevent was not run because it had timed out in a smaller cell of the same
effect set.

| Effect set \ events / actors | 200 / 20 | 1,000 / 30 | 5,000 / 20 | 5,000 / 50 | 5,000 / 100 | 20,000 / 100 |
|---|---:|---:|---:|---:|---:|---:|
| S1 nodsnd, nidrec | 22 / 17 | 39 / 27 | 23 / 17 | 62 / 44 | 117 / 69 | 107 / 94 |
| S2 four degree effects | 17 / 9.1 | 44 / 22 | 25 / 15 | 86 / 51 | 88 / 42 | >98 / 94 |
| S3 four degree + two inertia effects | 84 / 41 | 213 / 96 | 137 / 76 | >154 / >154 | n.r. / n.r. | n.r. / n.r. |
| S4 two degree + two recency effects | 5.0 / 3.1 | 7.3 / 4.5 | 3.3 / 2.1 | 12 / 8.7 | 15 / 9.2 | >6.2 / 6.1 |
| S5 two degree + three covariate effects | 20 / 12 | 36 / 19 | 22 / 14 | 58 / 35 | 105 / 58 | >47 / >47 |

nwrem's median times (seconds), in the same layout:

| Effect set \ events / actors | 200 / 20 | 1,000 / 30 | 5,000 / 20 | 5,000 / 50 | 5,000 / 100 | 20,000 / 100 |
|---|---:|---:|---:|---:|---:|---:|
| S1 | 0.009 | 0.042 | 0.19 | 0.40 | 0.78 | 3.7 |
| S2 | 0.015 | 0.067 | 0.32 | 0.56 | 1.8 | 6.1 |
| S3 | 0.059 | 0.36 | 1.6 | 3.9 | 13 | 43 |
| S4 | 0.070 | 0.54 | 3.4 | 6.7 | 14 | 97 |
| S5 | 0.024 | 0.14 | 0.60 | 1.4 | 2.8 | 13 |

nwrem was faster than relevent in every cell in which both programs finished: the ratios range from 3.3 to 213 with
the Hessian and from 2.1 to 96 without. The cells with a ">" are lower bounds. The largest fit nwrem was timed on has 20,000 events and 100
actors (S4: 97 seconds, median of 5 fits). The peak memory of the Stata process, which includes the data and the warm-up fit, was 0.21 GB at 200 events, 0.28 to 0.30 GB at 5,000
events and 20 actors, 0.35 to 0.37 GB at 5,000 events and 50 actors, 0.42 to 0.44 GB at 5,000 events and 100 actors and 0.55 to 0.59 GB at 20,000 events and 100 actors;
the memory of relevent was not measured. The largest difference between the mean estimates of the two programs was
0.006 relevent standard errors in the cells where relevent computed the Hessian, and 0.016 in the coefficients
(about 10 to 50) of the two cells at 20,000 events for which only the fit without the Hessian finished.

## Where the speed comes from

- **The Hessian costs relevent time.** Computing the Hessian took 12 to 55 percent of relevent's time. A user who
  does not need standard errors gets relevent 1.1 to 2.2 times faster than in the "with Hessian" figures. nwrem
  was faster than relevent in every cell also against the faster setting (ratios 2.1 to 96).
- **Largest gain with inertia effects.** For the model with four degree and two inertia effects the ratio was 84 to
  213 with the Hessian (41 to 96 without). At 5,000 events and 50 actors relevent did not finish in 600 seconds
  and nwrem needed 3.9 seconds. We have not traced the reason in the code of relevent.
- **No plug-in.** nwrem runs entirely in Mata, with ado for parsing and output. relevent's likelihood is compiled
  code. The gain therefore does not come from compiled against interpreted code.

## The closest case and the largest fits

- **Recency effects (S4).** This is the effect set with the smallest ratios: 3.3 to 15 with the Hessian and 2.1 to
  9.2 without. nwrem still needed 97 seconds at 20,000 events and 100 actors (5 fits), where relevent without the
  Hessian needed 588 seconds (1 fit) and with the Hessian did not finish in 600 seconds.
- **The largest problems.** At 20,000 events relevent timed out with the Hessian in three of the five effect sets
  (and was not run for a fourth), and without it in one. nwrem finished all five sets, in 3.7 to 97 seconds.
- **Start-up.** The first nwrem call in a Stata session takes about 0.1 seconds longer, because the Mata library is
  loaded. The times above do not contain it (each fit follows an untimed warm-up fit).

## How we measured

- **Machine.** Apple M5 Pro, macOS, one laptop. The times of relevent were measured on 26 and 27 October 2026 and those of nwrem on 15 November 2026. In both runs no other R or Stata process was running; the one-minute load average before each fit is in the data files (1.7 to 3.9 before the nwrem fits).
- **Software.** nwrem 1.2.0 with nwcommands core 3.25.1 in Stata 17 BE (15 November 2026); relevent 1.2-1 in R 4.6.0 (26 and 27 October 2026). The times of relevent were not repeated; the times of nwrem were measured again with the same data, seeds (the repeat number), effect sets and design.
- **Data and scripts.** Simulated event logs from the generator scripts; scripts, data and one row per fit in the [bench folder](https://github.com/thomas-u-grund/nwcommands/tree/main/bench).
- **One fit per process.** Each fit runs in its own Stata or R process after an untimed warm-up fit, so the first
  call (loading libraries) is not in the time. The timer covers the estimation command (for goldfish, the
  `estimate()` call including its preprocessing). Loading the data is not timed.
- **Medians.** The fits of one program run one process at a time, with up to 7 repeats and a different seed for each
  repeat (the same seeds as in the relevent runs). The relevent fits of October were run in turn with Stata fits; the
  nwrem 1.2.0 fits were run on their own, so the two programs were not timed in turn.
  The tables show medians of the repeats.
- **Same data, same model, defaults.** Both programs get the same data and the same specification with their default
  control settings. Neither side is tuned. Fits that finished in both programs agree in their estimates (see above).
- **Time limit.** Each fit has a limit of 600 seconds. A fit that reaches it is reported as a time-out, not dropped.

The other model packages are compared with their R counterparts on the page [Speed compared with R](../../nwcommands/speed/).
