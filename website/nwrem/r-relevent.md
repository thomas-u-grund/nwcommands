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
  `ordinal = TRUE` and `fit.method = "MLE"`.
- **The effects** of the table below, with relevent's definitions: the degree statistics are normalised shares, and the
  degree-accumulation semantics were checked against the output of relevent's `acl.deg()`.
- **The comparison.** Coefficients and log likelihoods were compared with `rem.dyad()` of relevent 1.2-1 on identical simulated event
  sequences; they agree within the tolerances of the package's test scripts. See [Tutorial 3](../tutorial-3-comparing/) for how
  the optimizer's starting point changes the fifth digit at most.

## What differs

Not implemented in `nwrem`:

- triadic and shared-partner effects;
- fixed effects;
- the full likelihood that uses the waiting times (the non-ordinal likelihood);
- Bayesian estimation.

There is no goodness-of-fit command and no intercept (an intercept cancels out of the ordinal likelihood, so it is not
estimable there). `nwrem` has no compiled plugin; the fits run in Mata (see Speed below). Data preparation differs as well: instead of an
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
| `CovSnd`, `CovRec`, `CovInt` with `covar = list(...)` | `covsnd(var)`, `covrec(var)`, `covint(var)`, the variable holding one value per actor |
| `CovEvent` | `covevent(netname)`, a network with the same actors holding the pair values |
| `summary()` of the fit | the table printed by `nwrem`; `e(b)`, `e(V)`, `e(ll)`, `e(N)`, `e(nodes)` |

## Speed

`nwrem` runs in Mata (there is no compiled plugin). On 26 October 2026 we timed it against `rem.dyad()` of relevent 1.2-1 (ordinal likelihood, covariance matrix computed by both) on simulated event streams of 200 to 20,000 events among 20 to 100 actors (Apple M5 Pro, Stata 17, R 4.6; median of 5 fits, fewer for the largest). The time of relevent divided by the time of `nwrem` ranged from 0.75 to 36:

- degree effects (`nodsnd nidrec nidsnd nodrec`): `nwrem` faster by 1.3 to 5.9 times (the two-effect model at 200 events: equal, 0.92); covariate effects: 1.7 to 2.5 times;
- with `frpsndsnd frrecsnd` added: 14 times (200 events) and 36 times (1,000 events); at 5,000 events relevent needed more than 10 minutes, `nwrem` 34 seconds;
- recency effects (`rsndsnd rrecsnd`): `nwrem` slightly slower up to 1,000 events (0.75 to 0.9 times the speed of relevent), about equal at 5,000 events; with 20,000 events neither finished within 10 minutes;
- the largest fits of `nwrem` (20,000 events, 100 actors) took 1.6 to 9.5 minutes;
- relevent with `hessian=FALSE` is 1.4 to 2.2 times faster than in these timings; `nwrem` always computes the covariance matrix.

The coefficients of the two programs agree to about three significant digits, not to six, because each stops at its own convergence tolerance. Timings depend on the machine, the data and the effects.

## Acknowledgment

`nwrem` rests on the work of Carter T. Butts, who developed the relational event framework and the relevent package. If you
use `nwrem`, please cite the paper and the package, as on the page [How to cite](../citation/).
