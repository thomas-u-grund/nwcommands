---
title: "Speed"
parent: "nwrem (REM)"
nav_order: 5.5
description: "Run times of nwrem 1.4.0 against R's relevent on the same data and models: every cell, the closest case and the largest fits."
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
variance matrix, which it gets from the exact Hessian. A like-for-like comparison therefore uses `hessian = TRUE` in R.
Both settings were timed. "-" means relevent did not finish within the 600-second limit or was not run because it had
timed out in a smaller cell of the same effect set ("n.r." in the last column). The last column is the time of relevent
divided by the time of nwrem, with the Hessian / without.

| Cell | nwrem (s) | relevent, Hessian (s) | relevent, no Hessian (s) | ratio with / without |
|---|---:|---:|---:|---:|
| S1, 200 events, 20 actors | 0.006 | 0.133 | 0.107 | 22 / 18 |
| S1, 1000 events, 30 actors | 0.009 | 1.104 | 0.774 | 123 / 86 |
| S1, 5000 events, 20 actors | 0.016 | 3.240 | 2.478 | 202 / 155 |
| S1, 5000 events, 50 actors | 0.024 | 16.3 | 11.8 | 679 / 491 |
| S1, 5000 events, 100 actors | 0.041 | 58.5 | 40.7 | 1,428 / 992 |
| S1, 20000 events, 100 actors | 0.213 | 396.1 | 320.3 | 1,859 / 1,504 |
| S2, 200 events, 20 actors | 0.010 | 0.292 | 0.155 | 29 / 16 |
| S2, 1000 events, 30 actors | 0.013 | 3.213 | 1.636 | 247 / 126 |
| S2, 5000 events, 20 actors | 0.039 | 8.795 | 5.306 | 226 / 136 |
| S2, 5000 events, 50 actors | 0.048 | 49.5 | 29.3 | 1,032 / 611 |
| S2, 5000 events, 100 actors | 0.068 | 151.4 | 73.4 | 2,227 / 1,079 |
| S2, 20000 events, 100 actors | 0.261 | - | 576.4 | n.r. / 2,208 |
| S3, 200 events, 20 actors | 0.013 | 7.012 | 3.428 | 539 / 264 |
| S3, 1000 events, 30 actors | 0.051 | 106.3 | 49.2 | 2,085 / 965 |
| S3, 5000 events, 20 actors | 0.176 | 312.2 | 174.6 | 1,774 / 992 |
| S3, 5000 events, 50 actors | 0.667 | - | - | n.r. / n.r. |
| S3, 5000 events, 100 actors | 1.334 | - | - | n.r. / n.r. |
| S3, 20000 events, 100 actors | 9.534 | - | - | n.r. / n.r. |
| S4, 200 events, 20 actors | 0.014 | 0.402 | 0.249 | 29 / 18 |
| S4, 1000 events, 30 actors | 0.042 | 4.333 | 2.694 | 103 / 64 |
| S4, 5000 events, 20 actors | 0.137 | 12.8 | 8.103 | 93 / 59 |
| S4, 5000 events, 50 actors | 0.599 | 84.1 | 62.0 | 140 / 104 |
| S4, 5000 events, 100 actors | 0.792 | 203.8 | 125.4 | 257 / 158 |
| S4, 20000 events, 100 actors | 6.568 | - | - | n.r. / n.r. |
| S5, 200 events, 20 actors | 0.012 | 0.558 | 0.326 | 46 / 27 |
| S5, 1000 events, 30 actors | 0.015 | 5.587 | 3.187 | 372 / 212 |
| S5, 5000 events, 20 actors | 0.040 | 15.2 | 9.390 | 379 / 235 |
| S5, 5000 events, 50 actors | 0.053 | 81.6 | 48.5 | 1,540 / 916 |
| S5, 5000 events, 100 actors | 0.083 | 295.4 | 169.2 | 3,560 / 2,038 |
| S5, 20000 events, 100 actors | 0.352 | - | - | n.r. / n.r. |

nwrem was faster than relevent in every cell in which both programs finished: the ratios range from 22 to 3,560 with the Hessian and from 16
to 2,208 without. Fits with several hundred events take a few milliseconds in nwrem. The largest fit, S3 with 20,000 events among 100 actors (relevent did not finish), took 9.5 seconds. Estimates agree: the
largest relative difference of a coefficient between the programs was 4.2e-3, in a cell where relevent's own optimizer stops early
(its estimates differ from the exact maximum by about that much); the other cells agree to 1e-3 or better.

## Where the speed comes from

- **Compiled likelihood, gradient and Hessian.** Every fit of nwrem runs in a plug-in written in C that computes the likelihood, the gradient and the exact Hessian
  (all 14 effects); the optimizer takes Newton steps with it.
- **The Hessian costs relevent time.** Computing the Hessian took up to half of relevent's time. A user who
  does not need standard errors gets relevent up to about 2 times faster than in the "with Hessian" figures. nwrem was faster in every cell also against the faster setting.
- **Largest gain with inertia and covariate effects.** Where relevent finishes, S3 has ratios of 540 to 2,085 with the Hessian.
  relevent did not finish at 5,000 events among 50 actors within 600 seconds; nwrem needed 0.7 seconds.

## The closest case and the largest fits

- **Recency effects (S4).** This is the effect set with the smallest ratios (29 to 257 with the Hessian). The largest S4 fit
  (20,000 events, 100 actors) took 6.6 seconds in nwrem; relevent did not finish.
- **The largest problems.** At 20,000 events relevent finished only the two-degree and four-degree sets (and then only without the Hessian for four degree effects). nwrem finished all five sets, in 0.21 to 9.5 seconds.
- **Earlier versions.** Version 1.2.0, which ran in Mata, needed 7 to 136 seconds in the largest S3 and S4 cells; the plug-in of
  version 1.3.0 and the evaluation changes of 1.4.0 made fits 1.5 to 32 times faster than 1.2.0 (the 20,000-event recency fit took 136 seconds in 1.2.0 and 6.6 seconds in 1.4.0).

## How we measured

- **Machine.** Intel Core i7-12700K (20 logical CPUs), 125 GB RAM, Ubuntu 22.04.4 LTS (kernel 6.5.0), one server with no other load (load average about 1). Stata is StataNow 19.5 MP (limited to 8 processors by the licence; the fits use one core), R 4.6.0.
- **Dates.** the times of nwrem 1.4.0 (the table): 16 November 2026; the times of relevent 1.2-1 (R 4.6.0): 15 November 2026, measured with nwrem 1.2.0 on the same machine and not repeated. The two programs were therefore not timed in turn for this table.
- **Data and scripts.** Simulated event logs from the generator scripts; scripts, data and one row per fit in the [bench folder](https://github.com/thomas-u-grund/nwcommands/tree/main/bench).
- **One fit per process.** Each fit runs in its own Stata or R process after an untimed warm-up fit, so the first call (loading libraries) is not in the time. The timer covers the estimation command (for the R packages, the estimation call including its preprocessing). Loading the data is not timed.
- **Medians.** Up to 7 repeats with a different seed for each repeat in both programs (5, 3 or 1 in the largest cells of the R packages); the tables show medians.
- **Same data, same model, defaults.** Both programs get the same data and the same specification with their default control settings. Neither side is tuned.
- **Time limit.** Each fit has a limit of 600 seconds. A fit that reaches it is reported as a time-out, not dropped.

The other model packages are compared with their R counterparts on the page [Speed compared with R](../../nwcommands/speed/).
