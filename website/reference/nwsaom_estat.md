---
title: "nwsaom_estat"
parent: "Command reference"
nav_exclude: true
search_exclude: false
---

# `nwsaom_estat`

## Description

The following postestimation command is available after [nwsaom](nwsaom.md):

- **`estat gof`** --- RSiena-style goodness-of-fit test and violin plot
- **`estat mems`** --- Micro Effects on Macro Structure (Duxbury) mediation-style sensitivity analysis

## Examples

```stata
. nwset, mat((0,1,1,0,1,0\0,0,1,0,0,1\1,0,0,1,0,0\0,0,0,0,1,1\1,0,0,0,0,1\0,1,0,0,0,0)) directed name(wave1)
. nwset, mat((0,1,1,1,1,0\1,0,1,0,0,1\1,1,0,1,0,0\0,0,1,0,1,1\1,0,1,0,0,1\0,1,0,1,0,0)) directed name(wave2)
. nwsaom, wave1(wave1) wave2(wave2) outdegree reciprocity transtrip
. estat gof
```
```stata
. estat gof, nsim(200) stats(outdegree geodesic) maxdeg(10)
```
```stata
. estat gof, twotailed name(mygof)
```
```stata
. estat gof, stats(outdegree triad) nsim(200)
```
```stata
. estat gof, join(off)
```
```stata
. program myDensity, rclass
.     args netname
.     nwsummarize `netname', matonly
.     return scalar stat = r(density)
. end
. estat mems, effect(reciprocity) macro(myDensity) nsim(500) seed(42)
```

## Supported network types

Not applicable - `estat gof` operates on the fitted model and the wave data left behind by [nwsaom](nwsaom.md), not on a network directly; see that command's own classification.

## Stored results

`estat gof` stores the following in `r()`, one pair per requested statistic (default **outdegree**/**indegree**/**geodesic**, plus **behavior** for a co-evolution fit; **triad** only if requested via `stats()`). With `join(off)`, each period gets its own pair instead, suffixed `_p*#*` (e.g. `r(p_outdegree_p1)`, `r(p_outdegree_p2)`):

**Scalars**

- **r(p_*stat*)** empirical Mahalanobis-distance test p-value for that statistic
- **r(mhd_*stat*)** observed vector's own Mahalanobis distance from the simulated mean

`estat mems` stores the following in `r()`:

**Scalars**

- **r(mems)** MEMS point estimate (mean paired difference in the macro statistic)
- **r(mems_sd)** Monte Carlo standard deviation of the paired difference
- **r(mems_lb)**/**r(mems_ub)** 95% percentile interval
- **r(mems_p)** Monte Carlo p-value
- **r(propchange)** "Prop. Change in M" point estimate

**Macros**

- **r(effect)** the `effect()` requested
- **r(macro)** the `macro()` program name requested

## References

Lospinoso, J., Snijders, T.A.B. (2019). Goodness of fit for stochastic actor-oriented models. *Methodological Innovations*, 12(3).

Ripley, R.M., Snijders, T.A.B., Boda, Z., Voros, A., Preciado, P. (2024). Manual for RSiena.

Duxbury, S.W. (2023). Micro Effects on Macro Structure. *Sociological Methodology*. DOI: 10.1177/00811750231209040.

Duxbury, S.W., Zhao, X. `netmediate`: Micro-Macro Analysis for Social Networks (R package).

## See also

- [nwsaom](nwsaom.md)
