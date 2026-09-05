---
title: "nwergm_estat"
parent: "Command reference"
nav_exclude: true
search_exclude: false
---

# `nwergm_estat`

## Description

The following postestimation commands are available after [nwergm](nwergm.md):

- **`estat mcmcdiag`** --- Basic MCMC diagnostics for the final simulation (method(mcmle) only)
- **`estat gof`** --- Basic simulation-based goodness of fit

## Examples

Fit a dyad-dependent [nwergm](nwergm.md) model (`method(mcmle)` runs automatically whenever any dyad-dependent term like `gwesp()` is present), then check MCMC diagnostics and basic goodness of fit:

```stata
. nwwebuse florentine, nwclear
. nwergm flomarriage, edges gwesp(.5)
. estat mcmcdiag
. estat gof, nsim(50)
```

## Supported network types

Not applicable - these postestimation tools operate on the fitted model and its own MCMC/simulation output left behind by [nwergm](nwergm.md), not on a network directly; see that command's own classification.

## Stored results

`estat mcmcdiag` stores the following in `r()`:

**Scalars**

- **r(acceptrate)** Metropolis-Hastings acceptance rate over the final simulation

**Matrices**

- **r(geweke)** 1 x *p* row vector of Geweke z-scores, one per model term (same
- column order as **e(b)**)
- **r(heidel)** *p* x 6 matrix, one row per model term, columns
- **stest** (1/0, stationarity test passed), **start** (first retained
- iteration, missing if **stest**=0), **teststat** (the retained window's
- own Cramer-von-Mises statistic), **htest** (1/0, halfwidth test passed,
- missing if **stest**=0), **mean** and **halfwidth** of the retained
- window (both missing if **stest**=0)

`estat gof` stores the following in `r()`:

**Scalars**

- **r(obs_meandeg)** observed mean degree
- **r(sim_meandeg)** simulated mean degree, averaged over `nsim()` draws
- **r(obs_avgpath)** observed average geodesic distance
- **r(sim_avgpath)** simulated average geodesic distance (missing if every draw was disconnected)
- **r(obs_triad300)** observed complete-triad count
- **r(sim_triad300)** simulated complete-triad count, averaged over contributing draws
- **r(obs_triad*XXX*)** observed count for MAN triad type *XXX* (one per [nwtriads](nwtriads.md) category
- for the network's directedness - e.g. **r(obs_triad_021D)**, **r(obs_triad_300)**)
- **r(sim_triad*XXX*)** simulated mean count for MAN triad type *XXX*, averaged over contributing draws

## See also

- [nwergm](nwergm.md)
