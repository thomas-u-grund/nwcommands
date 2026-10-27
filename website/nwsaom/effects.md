---
title: "Effects"
parent: "nwsaom (SAOM)"
nav_order: 16
permalink: /nwsaom/effects/
description: "An overview of the effect families of nwsaom; the full list is in help nwsaom and in the manual."
---

# Effects

An effect is one rule in the model, with one coefficient. In `nwsaom` you request an effect by
naming it as an option. This page is only a map; the complete list, with RSiena's names, is in Stata's
`help nwsaom` (and `help nwsaom_remarks`) and in the manual (PDF) in the
[GitHub repository](https://github.com/thomas-u-grund/nwsaom/blob/main/manual/nwsaom_manual.pdf).
`detail` after a fit prints the RSiena name of each effect.

| Family | Examples (options) | Question |
|---|---|---|
| Baseline | `outdegree`, `reciprocity` | density; return of ties |
| Triadic closure | `transtrip`, `transties`, `transmedtrip`, `transrectrip`, `cycle3`, `cycle4`, `balance`, `gwesp()` | clustering of friends of friends |
| Degree effects | `indegpopularity`, `outpopularity`, `outactivity`, `inactivity`, `outtrunc`, `outmore`, ... | popular and active actors |
| Isolates and assortativity | `isolatenet`, `outiso`, `outoutass`, `ininass`, `inoutass`, ... | isolated actors; degree matching |
| Covariate effects | `egox()`, `altx()`, `samex()`, `simx()`, `absdiffx()`, `diffx()`, `higher()`, `dyadcov()` | who sends, who receives, who chooses similar others |
| Interactions | `interact()` | does one effect depend on another |
| Endowment and creation | `endow()`, `creation()` | different rules for keeping and for creating ties |
| Rate effects | `ratecov()` | who gets more opportunities to change |
| Behavior | `behavior()` with `linear`, `quadratic`, `avalt`, `avsim`, `beheff()` | influence and the shape of behavior change |
| Network on behavior | `behsim`, `behegox`, `behaltx` | selection on the behavior |
| Several networks | `nwsaom multinet` with `eff1()`, `cross1()`, ... | effects of one network on another |
| Two-mode, undirected | detected from the data; `symmetric`, `symtype()` | affiliation and mutual ties |

Used in the tutorials: [1](../tutorial-1-first-saom/) (baseline, closure, covariates),
[3](../tutorial-3-goodness-of-fit/) (degree effects, `gwesp`), [4](../tutorial-4-selection-influence/)
(behavior effects), [6](../tutorial-6-beyond/) (cross-network effects),
[8](../tutorial-8-covariates/) (changing and dyadic covariates), [9](../tutorial-9-undirected-twomode/) (undirected and two-mode networks) and
[10](../tutorial-10-endowment-interaction-rate/) (endowment, creation, interactions, rate effects). For how the effects relate to RSiena's
table see [nwsaom and RSiena](../rsiena/).
