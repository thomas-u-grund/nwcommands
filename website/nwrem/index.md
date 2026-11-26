---
title: "nwrem (REM)"
nav_order: 8
has_children: true
permalink: /nwrem/
description: "nwrem: relational event models (REM) for Stata, written from Butts (2008) and cross-checked with the R package relevent. Installation, worked tutorials, a guide for relevent users and how to cite."
parent: "Packages and reference"
---

<h1 class="pkg-logo"><img src="{{ '/assets/images/packages/nwrem.png' | relative_url }}" alt="nwrem" width="196" height="76"></h1>

Relational event models (REM) for Stata: why this sender and this receiver, in a stream of timestamped events.
{: .fs-6 .fw-300 }

[Install](install/){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[What it is](what-is/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Tutorials](../tutorials/nwrem/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Manual](https://doi.org/10.5281/zenodo.24398012){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[nwrem on GitHub](https://github.com/thomas-u-grund/nwrem){: .btn .fs-5 .mb-4 .mb-md-0 }

## What nwrem is

`nwrem` fits relational event models (Butts 2008) to a sequence of timed events between actors: who sent what to whom, and
when (e-mails, phone calls, messages). At each event the model asks which of all possible ordered pairs of actors
was going to interact, and estimates which effects make the pair that was observed more likely than the others.
The effects include the activity of sender and receiver (degrees), inertia (the sender returns to partners of the past),
reciprocity of receipt, recency, and covariates of actors and of pairs. The estimation is by the ordinal partial likelihood, as in a Cox model.
`nwrem` was written from Butts' paper and cross-checked against the R package relevent, and is part of the nwcommands family of packages.

## Who it is for

`nwrem` is for people who work in Stata, or prefer it to R, and who have a stream of timed events between actors.
`nwrem` follows the R package relevent and is not a replacement for it: relevent is the reference implementation and the more complete program, and the page
[nwrem and relevent](r-relevent/) says what `nwrem` has and what it lacks. `nwrem` is not affiliated with or endorsed by the authors of relevent; errors in `nwrem` are the author's. For how a REM differs from the other longitudinal
models of the nwcommands family, see [Intro to Longitudinal Network Models](../tutorials/19-intro-longitudinal-models/);
the sister package that splits each event into the choice of the actor and the choice of the partner is [nwdynam](../nwdynam/).

## Key facts

| | |
|---|---|
| Likelihood | ordinal partial likelihood, maximum likelihood estimation (no intercept: it cannot be estimated in this likelihood) |
| Effects | degree effects (6), inertia and reciprocity of receipt (2), recency (2), actor covariates (3), pair covariate (1): 14 in all |
| Networks | directed one-mode event networks, declared with `nwset ..., eventtime()` |
| Agreement with relevent | coefficients and log likelihoods compared with `rem.dyad()` of relevent 1.2-1 on identical simulated event sequences |
| Postestimation | `estat rank`, `estat actors` and `estat time`: the rank of the observed event among all pairs of the risk set, observed against expected events by actor and over time, with graphs (from version 1.6.0; extensions, relevent has no such methods) |
| Not implemented | MCMC and BSIR estimation, risk-set sampling, simulation, goodness-of-fit residuals, time-varying covariates |
| Engine | a compiled plugin for the likelihood, gradient and Hessian (macOS, Linux, Windows); the optimization runs in Mata |
| Speed | Faster than relevent in every timed cell: 22 to 3,560 times when relevent computes its Hessian (as nwrem always does), 16 to 2,208 times without; the smallest ratios are with recency effects; see [Speed compared with relevent](speed/) |
| Version | 1.7.2 (23 November 2026) |
| License | GNU General Public License, version 3 |

## Tutorials and reference

- [Tutorials](../tutorials/nwrem/): three worked tutorials. New to `nwrem`? Start with [Tutorial 1](tutorial-1-first-rem/).
- [Install](install/): core first, then `nwrem`; releases, updating.
- [nwrem and relevent](r-relevent/): what is the same, what differs, a translation table, and where the package comes from.
- [Manual](manual/): the reference, as a PDF.
- [How to cite](citation/)

## Links

- Source code and releases: [github.com/thomas-u-grund/nwrem](https://github.com/thomas-u-grund/nwrem)
- Stata's own documentation: `help nwrem`
- Teaching: [workshop session on relational events](/book/teaching/workshop/#session-3-optional-relational-events-with-nwrem-and-nwdynam-3-hours) (slides with speaker notes)
- The R package: [relevent on CRAN](https://cran.r-project.org/package=relevent)
