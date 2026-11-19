---
title: "Ego-network ERGM"
parent: "nwergm (ERGM)"
nav_order: 7.3
permalink: /nwergm/ego/
description: "Fit an ERGM to egocentrically sampled data with nwergm ego, after R's ergm.ego: when you have a sample of egos and their alters rather than a whole network."
---

# Ego-network ERGM
{: .no_toc }

In many surveys nobody observes the whole network. A sample of people, the egos, is asked about their contacts, the alters: how many, and of what kind. `nwergm ego` (since version 1.10.0) fits an ERGM to such data,
following R's `ergm.ego` (Krivitsky and Morris 2017). The question is the same as for any ERGM, which local patterns build the network, but the data are a sample of ego networks rather than one complete network.

## The idea

The statistics of an ERGM (the number of ties, the number of people of a given degree, the number of ties between people of the same group) can be estimated from a sample of egos, because they are counts of what each ego
sees. The method first estimates these statistics of the whole network from the egos (with survey weights if the sample is not equally likely), then finds the ERGM whose expected statistics equal them. The ERGM is fitted on a
*pseudopopulation*, a network of the size of the population (or a chosen size) that has the statistics of the sample, using the same Monte Carlo sampler as the other `nwergm` fits. Standard errors account for the sampling of the egos: they
are the design-based covariance of the estimated statistics carried through the information of the model.

## How it is used

The data in memory are the egos, one row each. The alters are in a second frame, or, when only the number of contacts was collected, a variable holds each ego's degree.

```stata
. nwergm ego, edges degree(1/3) nodefactor(race sex) nodematch(race sex) absdist(grade) egoid(id) alters(alters) popsize(205)
. estat gof, nsim(100)
. nwergm simulate
```

No network has to be declared. The terms available are `edges`, `degree()`, `degrange()`, `concurrent`, `nodefactor()`, `nodematch()`, `nodematchdiff()`, `nodecov()` and `absdist()`: the terms that
depend on the ties of the ego and the attributes of ego and alters only. `weights()` gives the sampling weights, `popsize()` the size of the population (the size adjustment of the number of ties), and `ppopsize()` the size of
the pseudopopulation. `estat gof` compares the model statistics and the degree distribution with simulated networks, `nwergm simulate` draws networks of the size of the pseudopopulation from the fit, and `estat mcmcdiag` works. There is a dialog box (`db nwergm_ego`) and `help nwergm_ego`.

## What to keep in mind

- **Only what egos can see.** Terms that need the ties among the alters (`gwesp`, `triangle`, `esp`, `transitiveties`) cannot be estimated from egocentric data; this is a limit of the data, not of the program. Say so when you interpret the model: it describes degrees and mixing, not clustering.
- **Population size matters.** The coefficient of `edges` depends on how large the population is, which the sample does not tell you. State `popsize()` and check how much the results change with it.
- **Weights.** If egos were sampled with unequal probabilities, give the weights; the estimated statistics and their variance depend on them.
- **Not available** (R has them): `esp`-type terms, `degree1.5`, `nodemix`, `mm`, the bootstrap, jackknife and asymptotic covariance estimators, and the shared-partner statistic of `estat gof`. `estat ic` and `predict` are not available after `nwergm ego`.

## Agreement with R

The estimates and standard errors agree with `ergm.ego` 1.1.4 on the example data of the package (a high school network sampled with equal weights) and on a simulated network of 1,000 nodes sampled with equal and with unequal weights.

## Reference

- Krivitsky, P. N. and Morris, M. (2017). Inference for social network models from egocentrically sampled data, with application to understanding persistent racial disparities in HIV prevalence in the US. *The Annals of Applied Statistics* 11(1), 427-455. [doi:10.1214/16-AOAS1010](https://doi.org/10.1214/16-AOAS1010)
