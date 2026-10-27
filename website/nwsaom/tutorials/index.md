---
title: "nwsaom tutorials"
nav_order: 2
permalink: /nwsaom/tutorials/
description: "Worked tutorials for nwsaom."
nav_exclude: true
---

# nwsaom tutorials
{: .no_toc }

Worked tutorials for nwsaom, each with real Stata output. Install the package first (see [Install](../install/)).

- [Tutorial 1: A first SAOM](/nwsaom/tutorial-1-first-saom/): Fit a first stochastic actor-oriented model to the Glasgow friendship data with nwsaom and read the coefficient table, the rates and the convergence check.
- [Tutorial 2: Convergence](/nwsaom/tutorial-2-convergence/): How to read the convergence diagnostics of nwsaom and what to do when a model has not converged: restart from the estimates, simplify, and test hypotheses with Stata's own Wald tests.
- [Tutorial 3: Goodness of fit](/nwsaom/tutorial-3-goodness-of-fit/): Check how well an nwsaom model describes the Glasgow friendship network with estat gof, read the violin plots, and improve a poorly fitting model.
- [Tutorial 4: Selection and influence](/nwsaom/tutorial-4-selection-influence/): Model friendship and drinking together with nwsaom: network-behavior co-evolution, selection and influence effects, on the Glasgow data.
- [Tutorial 5: Testing and comparing](/nwsaom/tutorial-5-testing-comparing/): Score tests for effects held fixed with fix(), tests of time heterogeneity and the relative importance of effects with nwsaom (estat score, estat timetest, estat importance).
- [Tutorial 6: Beyond the basic model](/nwsaom/tutorial-6-beyond/): Maximum likelihood and Bayesian estimation with nwsaom, and two networks that change together (nwsaom multinet), with short runnable examples.
- [Tutorial 7: Changing actor sets and missing data](/nwsaom/tutorial-7-composition-missing/): Pupils who join or leave between waves and values that were not observed: composition change with present(), joinat() and leaveat(), and missing data with missnet() and missbeh() in nwsaom.
- [Tutorial 8: Time-varying and dyadic covariates](/nwsaom/tutorial-8-covariates/): Covariates that change between waves (tvcov) and covariates defined for pairs of actors (dyadcov, dyadcovrecip) in nwsaom, shown on a Dutch school class observed four times.
- [Tutorial 9: Undirected and two-mode networks](/nwsaom/tutorial-9-undirected-twomode/): Stochastic actor-oriented models for undirected networks (symtype) and for two-mode networks in which actors choose among events, with nwsaom.
- [Tutorial 10: Endowment, creation, interactions and rate effects](/nwsaom/tutorial-10-endowment-interaction-rate/): Separate effects for creating and for ending ties (endow, creation), interactions between effects (interact), and effects on the rate of change (ratecov, outrate) in nwsaom.
- [Tutorial 11: Simulation and what-if analysis](/nwsaom/tutorial-11-simulation/): Use a fitted stochastic actor-oriented model to simulate networks (estat simulate, nwsaom simulate) and to ask what a network would look like if an effect did not operate (estat mems).
- [Tutorial 12: Conditional and unconditional estimation, threads and speed](/nwsaom/tutorial-12-estimation-speed/): What conditional and unconditional estimation mean in nwsaom, how to restart an unconditional fit, how threads (cores) and the number of simulations (k0, k3) affect speed and precision.
- [Tutorial 13: Combining several groups with a meta-analysis](/nwsaom/tutorial-13-meta-analysis/): Fit the same stochastic actor-oriented model to several school classes and combine the estimates with nwsaom meta, the counterpart of RSiena's siena08.
- [Tutorial 14: Several groups at once](/nwsaom/tutorial-14-several-groups/): Estimate one stochastic actor-oriented model for several groups jointly with the option groups(): the data layout, the rates of every group, behavior co-evolution, groups with different waves, tests after the fit, and when to prefer the meta-analysis.
