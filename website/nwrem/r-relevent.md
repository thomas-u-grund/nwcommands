---
title: "REM: nwrem and relevent"
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
  the optimiser's starting point changes the fifth digit at most.

## What differs

Not implemented in `nwrem`:

- triadic and shared-partner effects;
- fixed effects;
- the full likelihood that uses the waiting times (the non-ordinal likelihood);
- Bayesian estimation.

There is no goodness-of-fit command and no intercept (an intercept cancels out of the ordinal likelihood, so it is not
estimable there). `nwrem` has no compiled plugin; the fits run in Mata. Data preparation differs as well: instead of an
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

## Acknowledgment

`nwrem` rests on the work of Carter T. Butts, who developed the relational event framework and the relevent package. If you
use `nwrem`, please cite the paper and the package, as on the page [How to cite](../citation/).
