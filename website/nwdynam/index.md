---
title: "nwdynam (DyNAM)"
nav_order: 7
has_children: true
permalink: /nwdynam/
description: "nwdynam: dynamic network actor models (DyNAM) for Stata, after the R package goldfish. Installation, worked tutorials, a guide for goldfish users and how to cite."
---

# nwdynam
{: .fs-9 }

Dynamic network actor models (DyNAM) for Stata: who acts next, and whom do they choose, in a stream of
timestamped events.
{: .fs-6 .fw-300 }

[Install](install/){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Start with Tutorial 1](tutorial-1-first-dynam/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[nwdynam on GitHub](https://github.com/thomas-u-grund/nwdynam){: .btn .fs-5 .mb-4 .mb-md-0 }

## What nwdynam is

`nwdynam` fits dynamic network actor models (Stadtfeld and Block 2017) to **relational event data**: a
list of who did what to whom, and when (phone calls, e-mails, messages, treaties). The model splits each
event into two decisions. The **rate** model says which actor acts next (some people call more often
than others, and more so when they are well connected). The **choice** model says, given the actor who
acts, whom the actor picks (people call those they called before, those who called them, ...). Each
sub-model has its own effects and its own coefficients. `nwdynam` is a port of the R package
goldfish to Stata and is part of the nwcommands family of packages.

## Who it is for

`nwdynam` is for people who work in Stata, or prefer it to R, and who have a stream of timed events
between actors. `nwdynam` follows the R package goldfish and is not a replacement for it: goldfish is the reference
implementation and the more complete program, and the page [nwdynam and goldfish](r-goldfish/) says what `nwdynam` has and what
it lacks. `nwdynam` is not affiliated with or endorsed by the authors of goldfish; errors in `nwdynam` are
the author's. For how a DyNAM differs from the other longitudinal models of the nwcommands family, see
[Intro to Longitudinal Network Models](../tutorials/10-intro-longitudinal-models/); the sister package for
the simpler relational event model is [nwrem](../nwrem/).

## Key facts

| | |
|---|---|
| Sub-models | choice, rate (ordinal partial likelihood, or with an intercept the continuous-time hazard), and choice_coordination for undirected events |
| Effects | inertia, reciprocity, in- and out-degree, transitivity and other closure effects, covariate effects (same, diff, sim, ego, alter and more), windowed and weighted versions, a separate static network |
| Networks | directed one-mode, undirected one-mode (coordination), two-mode (a narrow set of effects) |
| Agreement with goldfish | coefficients and log likelihoods compared with goldfish 1.6.12 on its bundled Social Evolution data and on small hand-built examples |
| Engine | a compiled plugin for the likelihood and gradient (macOS, Linux, Windows); the optimization runs in Mata |
| Version | 1.1.2 (26 October 2026) |
| License | GNU General Public License, version 3 |

## In this section

- [Install](install/): core first, then `nwdynam`; releases, updating, the plugin.
- [Tutorial 1: A first DyNAM](tutorial-1-first-dynam/): event data, the rate and the choice sub-model, reading the table.
- [Tutorial 2: Effects and interpretation](tutorial-2-effects/): covariates, closure, windows, comparing models.
- [Tutorial 3: Limits and diagnostics](tutorial-3-limits/): what a small event log can and cannot tell you.
- [nwdynam and goldfish](r-goldfish/): what is the same, what differs, a translation table.
- [How to cite](citation/)

## Links

- Source code and releases: [github.com/thomas-u-grund/nwdynam](https://github.com/thomas-u-grund/nwdynam)
- Stata's own documentation: `help nwdynam`
- The R package: [goldfish on CRAN](https://cran.r-project.org/package=goldfish)
