---
title: "nwsaom: SAOM"
parent: "Tutorials"
has_children: true
has_toc: false
nav_order: 5
permalink: /tutorials/nwsaom/
description: "Tutorials for nwsaom: stochastic actor-oriented models in Stata."
---

# Stochastic actor-oriented models with nwsaom
{: .no_toc }

**The question:** How did a network, observed in two or more waves, change?

You need the core and the package [nwsaom](/nwsaom/) ([how to install it](/nwsaom/install/)).

- [Tutorial 1: A first SAOM](/nwsaom/tutorial-1-first-saom/): a first model for the Glasgow friendship data, and how to read the table.
- [Tutorial 2: Convergence](/nwsaom/tutorial-2-convergence/): what the convergence line means and what to do when a model does not converge.
- [Tutorial 3: Goodness of fit](/nwsaom/tutorial-3-goodness-of-fit/): `estat gof`, and improving a poor model.
- [Tutorial 4: Selection and influence](/nwsaom/tutorial-4-selection-influence/): friendship and drinking together.
- [Tutorial 5: Testing and comparing](/nwsaom/tutorial-5-testing-comparing/): `estat score`, `estat timetest`, `estat importance`, `fix()`.
- [Tutorial 6: Beyond the basic model](/nwsaom/tutorial-6-beyond/): maximum likelihood, Bayesian estimation, several networks.
- [Tutorial 7: Changing actor sets and missing data](/nwsaom/tutorial-7-composition-missing/): `present()`, `joinat()`/`leaveat()`, `missnet()`, `missbeh()`: actors who join or leave, and missing data.
- [Tutorial 8: Time-varying and dyadic covariates](/nwsaom/tutorial-8-covariates/): `tvcov()` and `dyadcov()`: covariates that change over time and covariates of pairs.
- [Tutorial 9: Undirected and two-mode networks](/nwsaom/tutorial-9-undirected-twomode/): undirected networks (`symtype()`) and two-mode networks.
- [Tutorial 10: Endowment, creation, interactions and rate effects](/nwsaom/tutorial-10-endowment-interaction-rate/): `endow()`/`creation()`, `interact()`, `ratecov()`, `outrate`.
- [Tutorial 11: Simulation and what-if analysis](/nwsaom/tutorial-11-simulation/): `estat simulate`, `nwsaom simulate`, `estat mems`.
- [Tutorial 12: Conditional and unconditional estimation, threads and speed](/nwsaom/tutorial-12-estimation-speed/): conditional and unconditional estimation, `cores()`, `k0()`/`k3()`.
- [Tutorial 13: Combining several groups with a meta-analysis](/nwsaom/tutorial-13-meta-analysis/): `nwsaom meta` for several groups (RSiena's `siena08`).
- [Tutorial 14: Several groups at once](/nwsaom/tutorial-14-several-groups/): one model for all groups with `groups()` and `gwaves()` (RSiena's `sienaGroupCreate`).
