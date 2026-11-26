---
title: "nwdynam (DyNAM)"
nav_order: 7
has_children: true
permalink: /nwdynam/
description: "nwdynam: dynamic network actor models (DyNAM) for Stata, after the R package goldfish. Installation, worked tutorials, a guide for goldfish users and how to cite."
parent: "Packages and reference"
---

<h1 class="pkg-logo"><img src="{{ '/assets/images/packages/nwdynam.png' | relative_url }}" alt="nwdynam" width="309" height="76"></h1>

Dynamic network actor models (DyNAM) for Stata: who acts next, and whom do they choose, in a stream of
timestamped events.
{: .fs-6 .fw-300 }

[Install](install/){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[What it is](what-is/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Tutorials](../tutorials/nwdynam/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[nwdynam on GitHub](https://github.com/thomas-u-grund/nwdynam){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Manual](https://doi.org/10.5281/zenodo.24398099){: .btn .fs-5 .mb-4 .mb-md-0 }

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
[Intro to Longitudinal Network Models](../tutorials/19-intro-longitudinal-models/); the sister package for
the simpler relational event model is [nwrem](../nwrem/).

**Speed is a good reason to use it.** `nwdynam` was faster than goldfish in all 16 cases of our benchmark of choice
and rate models (simulated logs of 200 to 20,000 events): 7 to 119 times as fast as goldfish's faster engine, with
estimates that agree (`nwdynam` 1.8.0, goldfish 1.6.12, one Linux server). Coordination models were not compared.
The [speed page](speed/) has the times and the method.

## Key facts

| | |
|---|---|
| Sub-models | choice, rate (ordinal partial likelihood, or with an intercept the continuous-time hazard), and choice_coordination for undirected events |
| Effects | inertia, reciprocity, in- and out-degree, transitivity and other closure effects, covariate effects (same, diff, sim, ego, alter and more), windowed and weighted versions, effects through other networks (also mixed closures), two-mode attribute and closure effects; postestimation with `estat ic`, `eventlik`, `eventprob`, `outliers`, `changepoints`, `choiceplot` and `rateplot` |
| Networks | directed one-mode, undirected one-mode (coordination), two-mode (a narrow set of effects) |
| Agreement with goldfish | coefficients and log likelihoods compared with goldfish 1.6.12 on its bundled Social Evolution data, on the manufacturing email data of the tutorials and on small hand-built examples |
| Engine | a compiled plugin for the likelihood, gradient and Hessian of every fit (macOS, Linux, Windows); the optimization runs in Mata |
| Speed | Faster than goldfish in every timed cell: 7 to 119 times against its `default_c` engine and 12 to 1,637 times against its default engine (choice and rate models, every fit in the compiled plug-in); see [Speed compared with goldfish](speed/) |
| Version | 1.11.2 (26 November 2026) |
| License | GNU General Public License, version 3 |

## Tutorials and reference

- [Tutorials](../tutorials/nwdynam/): three worked tutorials. New to `nwdynam`? Start with [Tutorial 1](tutorial-1-first-dynam/).
- [Install](install/): core first, then `nwdynam`; releases, updating, the plugin.
- [nwdynam and goldfish](r-goldfish/): what is the same, what differs, a translation table.
- [Manual](manual/): the PDF reference, with worked examples and the comparison with goldfish.
- [How to cite](citation/)

## Links

- Source code and releases: [github.com/thomas-u-grund/nwdynam](https://github.com/thomas-u-grund/nwdynam)
- Stata's own documentation: `help nwdynam`
- Teaching: [workshop session on relational events](/book/teaching/workshop/#session-3-optional-relational-events-with-nwrem-and-nwdynam-3-hours) (slides with speaker notes)
- The R package: [goldfish on CRAN](https://cran.r-project.org/package=goldfish)
