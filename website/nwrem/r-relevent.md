---
title: "nwrem and relevent"
parent: "nwrem (REM)"
nav_order: 5
permalink: /nwrem/r-relevent/
description: "Where nwrem comes from, what it shares with the R package relevent, what it lacks, how it was compared, and a translation table from relevent to nwrem."
---

# nwrem and relevent

`nwrem` implements the relational event framework of Carter Butts (2008), and relevent, Butts' R package, is the program it
was checked against. `nwrem` is not affiliated with or endorsed by the relevent project, and errors in `nwrem` are the
author's. If you can use R, relevent remains the reference and the more complete program; `nwrem` is for people who work
in Stata, or prefer it.

## Where the package comes from

In plain words, as in the notice that ships with the package: `nwrem` implements the statistical model of Butts (2008). It
was developed with the R package relevent as the reference implementation and as the target of the cross-checks. Because the
package follows the structure of relevent, it is distributed under the GNU General Public License, version 3, which is
compatible with relevent's license (GPL, version 2 or later). The package exists because of that work.

The software was developed with Claude Code (Anthropic), an AI coding assistant, working under the author's direction;
its correctness rests on numerical comparison with the R package.

## What is the same

- **The model.** The ordinal partial likelihood of Butts (2008) with maximum likelihood estimation, the analogue of `rem.dyad()` with
  `ordinal = TRUE` and `fit.method = "MLE"`; the likelihood that uses the waiting times (`interval`); the posterior mode (`postmode`,
  relevent's `fit.method = "BPM"`); fits with a restricted risk set.
- **The effects** of the table below, with relevent's definitions: the degree statistics are normalised shares, and the
  degree-accumulation semantics were checked against the output of relevent's `acl.deg()`.
- **The comparison.** Coefficients and log likelihoods were compared with `rem.dyad()` of relevent 1.2-1 on identical simulated event
  sequences; they agree within the tolerances of the package's test scripts. See [Tutorial 3](../tutorial-3-comparing/) for how
  the optimizer's starting point changes the fifth digit at most.

## What differs

Not implemented in `nwrem`:

- the simulation-based estimation methods (`fit.method = "MCMC"` and `"BSIR"`: their output is random and cannot be reproduced
  from R's random numbers);
- sampling of the risk set (`sample.size`), simulation and goodness-of-fit residuals and predictions;
- time-varying covariates;
- the participation shifts that relevent defines with undefined targets: relevent's coefficients for them are always zero.

One statistic differs on purpose: relevent 1.2-1 computes `OSPSnd` asymmetrically (a pair counts twice in one direction and not
at all in the other); `ospsnd` in `nwrem` is the symmetric statistic that the definition describes, and it was checked against
`rem()` of relevent fed with that statistic.

There is no goodness-of-fit command and no intercept (an intercept cancels out of the ordinal likelihood, so it is not
estimable there). Every fit runs in a compiled plugin (see Speed below). Data preparation differs as well: instead of an
R edgelist matrix you declare the events with `nwset ..., eventtime()`, add actors that never appear in the log with
`nwaddnodes`, and read actor attributes from the dataset of the actors (`nwload ..., xvars`).

## Translation table

| relevent | nwrem |
|---|---|
| the event list passed to `rem.dyad(edgelist, n, ...)` | `nwset sender receiver, directed eventtime(t) name(net)` (actors absent from the log: `nwaddnodes`) |
| `rem.dyad(..., ordinal = TRUE, fit.method = "MLE")` | `nwrem net, <effects>` |
| `NODSnd` | `nodsnd` |
| `NIDRec` | `nidrec` |
| `NIDSnd` | `nidsnd` |
| `NODRec` | `nodrec` |
| `NTDegSnd`, `NTDegRec` | `ntdegsnd`, `ntdegrec` |
| `FrPSndSnd` | `frpsndsnd` (inertia) |
| `FrRecSnd` | `frrecsnd` (reciprocity of receipt) |
| `RSndSnd`, `RRecSnd` | `rsndsnd`, `rrecsnd` |
| `OTPSnd`, `ITPSnd`, `OSPSnd`, `ISPSnd` | `otpsnd`, `itpsnd`, `ospsnd`, `ispsnd` (triadic and shared-partner effects) |
| `FESnd`, `FERec`, `FEInt` | `fesnd`, `ferec`, `feint` (one coefficient per actor except the first) |
| `PSAB-BA`, `PSAB-BY`, `PSAB-XA`, `PSAB-XB`, `PSAB-XY`, `PSAB-AY` | `psabba`, `psabby`, `psabxa`, `psabxb`, `psabxy`, `psabay` |
| `CovSnd`, `CovRec`, `CovInt` with `covar = list(...)` | `covsnd(varlist)`, `covrec(varlist)`, `covint(varlist)`, variables holding one value per actor |
| `CovEvent` | `covevent(netlist)`, networks with the same actors holding the pair values |
| `ordinal = FALSE` (waiting times) | `interval` with `starttime()` and `endtime()` |
| `conditioned.obs` | `condition(k)` |
| `fit.method = "BPM"` with `prior.mean`, `prior.scale`, `prior.nu` | `postmode` with `priormean()`, `priorscale()`, `priordf()` |
| `rem()` with a support matrix | `riskset(net)` (a pair with value 0 cannot occur), `entry(var)` and `exit(var)` for actors that enter or leave |
| `summary()` of the fit | the table printed by `nwrem`; `e(b)`, `e(V)`, `e(ll)`, `e(N)`, `e(nodes)` |

## Speed

Every fit of `nwrem` runs in a compiled plugin. We timed `nwrem` 1.4.0 against `rem.dyad()` of relevent 1.2-1 (R 4.6.0) on simulated event streams of 200 to 20,000 events among 20 to 100 actors on a Linux server (16 November 2026). `nwrem` always computes the covariance matrix, so the like-for-like setting in relevent is `hessian=TRUE`; relevent's default is `hessian=FALSE`, and both were timed. `nwrem` was faster than relevent in every cell in which both programs finished: 22 to 3,560 times with the Hessian and 16 to 2,208 times without; the smallest ratios are with the recency effects (`rsndsnd rrecsnd`). relevent did not finish most of the 20,000-event fits within 600 seconds, while `nwrem` finished all of them in 0.2 to 9.5 seconds. All cells, the machine and the method are on the page [Speed compared with relevent](../speed/).

## Acknowledgment

`nwrem` rests on the work of Carter T. Butts, who developed the relational event framework and the relevent package. If you
use `nwrem`, please cite the paper and the package, as on the page [How to cite](../citation/).
