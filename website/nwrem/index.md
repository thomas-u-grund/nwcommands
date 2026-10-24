---
title: "nwrem (REM)"
nav_order: 8
has_children: true
permalink: /nwrem/
description: "nwrem: relational event models (REM) for Stata, written from Butts (2008) and cross-checked with the R package relevent. Installation, worked tutorials, a guide for relevent users and how to cite."
---

# nwrem
{: .fs-9 }

Relational event models (REM) for Stata: why this sender and this receiver, in a stream of timestamped events.
{: .fs-6 .fw-300 }

[Install](install/){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Start with Tutorial 1](tutorial-1-first-rem/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[nwrem on GitHub](https://github.com/thomas-u-grund/nwrem){: .btn .fs-5 .mb-4 .mb-md-0 }

## What nwrem is

`nwrem` fits relational event models (Butts 2008) to a sequence of timed events between actors: who sent what to whom, and
when (phone calls, e-mails, messages). At each event the model asks which of all possible ordered pairs of actors
was going to interact, and estimates which effects make the pair that was observed more likely than the others.
The effects include the activity of sender and receiver (degrees), inertia (the sender returns to partners of the past),
reciprocity of receipt, recency, and covariates of actors and of pairs. The estimation is by the ordinal partial likelihood, as in a Cox model.
`nwrem` was written from Butts' paper and cross-checked against the R package relevent, and is part of the nwcommands family of packages.

## Who it is for

`nwrem` is for people who work in Stata, or prefer it to R, and who have a stream of timed events between actors.
It does not aim to replace relevent. relevent is the reference implementation and the more complete program, and the page
[nwrem and relevent](r-relevent/) says what `nwrem` has and what it lacks. For how a REM differs from the other longitudinal
models of the nwcommands family, see [Intro to Longitudinal Network Models](../tutorials/10-intro-longitudinal-models/);
the sister package that splits each event into the choice of the actor and the choice of the partner is [nwdynam](../nwdynam/).

## Key facts

| | |
|---|---|
| Likelihood | ordinal partial likelihood, maximum likelihood estimation (no intercept: it cannot be estimated in this likelihood) |
| Effects | degree effects (6), inertia and reciprocity of receipt (2), recency (2), actor covariates (3), pair covariate (1): 14 in all |
| Networks | directed one-mode event networks, declared with `nwset ..., eventtime()` |
| Agreement with relevent | coefficients and log likelihoods compared with `rem.dyad()` of relevent 1.2-1 on identical simulated event sequences |
| Not implemented | triadic and shared-partner effects, fixed effects, the waiting-time (non-ordinal) likelihood, Bayesian estimation |
| Engine | Mata (no compiled plugin) |
| Version | 1.0.1 (24 October 2026) |
| License | GNU General Public License, version 3 |

## In this section

- [Install](install/): core first, then `nwrem`; releases, updating.
- [Tutorial 1: A first relational event model](tutorial-1-first-rem/): the event sequence, degree and inertia effects, reading the table.
- [Tutorial 2: Effects and interpretation](tutorial-2-effects/): actor and pair covariates, recency, side-by-side comparison.
- [Tutorial 3: Comparing specifications](tutorial-3-comparing/): AIC, BIC and likelihood-ratio tests, stability, limits.
- [nwrem and relevent](r-relevent/): what is the same, what differs, a translation table, and where the package comes from.
- [How to cite](citation/)

## Links

- Source code and releases: [github.com/thomas-u-grund/nwrem](https://github.com/thomas-u-grund/nwrem)
- Stata's own documentation: `help nwrem`
- The R package: [relevent on CRAN](https://cran.r-project.org/package=relevent)
