# `nwergm` — Licensing and Provenance

Required by the project brief's Part II before any Statnet-informed code was written.

## What was inspected

The public `statnet/ergm` GitHub repository (cloned locally, version 4.13.0-8214, R package
version 4.12.0 also independently confirmed installed via `Rscript`). Read directly:
`LICENSE`, `LICENSE.note`, `DESCRIPTION`, and the copyright headers of representative R and C
source files (`R/mcmle.R`, `R/ergm.R`, `src/MCMC.c`, `src/changestats.c`).

## License (verbatim, from `ergm`'s own `LICENSE` file)

> This software is distributed under the GPL-3 license. It is free, open source, and has the
> following attribution requirements (GPL Section 7):
>
> (a) you agree to retain in 'ergm' and any modifications to 'ergm' the copyright, author
> attribution and URL information as provided at statnet.org/attribution
>
> (b) you agree that 'ergm' and any modifications to 'ergm' will, when used, display the
> attribution: *Based on 'statnet' project software (statnet.org). For license and citation
> information see statnet.org/attribution*

Confirmed in `DESCRIPTION`: `License: GPL-3 + file LICENSE`.

Every R and C source file in the repository carries an identical per-file header, e.g. (from
`src/MCMC.c`):

```
/*  File src/MCMC.c in package ergm, part of the Statnet suite of packages for
 *  network analysis, https://statnet.org .
 *
 *  This software is distributed under the GPL-3 license.  It is free, open
 *  source, and has the attribution requirements (GPL Section 7) at
 *  https://statnet.org/attribution .
 *
 *  Copyright 2003-2026 Statnet Commons
 */
```

**Third-party embedded code** (per `LICENSE.note`): `khash.h` and `kvec.h` (hash-table/vector
utility headers used inside `ergm`'s own C sources) are separately copyright (c) 2008-2011
Attractive Chaos, under the MIT license — not GPL, and not relevant to `nwergm` since neither
file is used here. `LICENSE.note` also records that `R/simulate.formula.R` specifically is
released under the more permissive MIT license (an ergm-internal exception, not something
`nwergm` draws on).

## What `nwergm` actually did with this

**No Statnet source code — R or C — was copied, translated line-by-line, or adapted into
`nwergm`.** Every `nwergm` term, proposal, and estimation routine was written directly against
the published statistical definitions (Hunter & Handcock 2006 for MPLE; Hunter 2007 for GWESP/
GWDEGREE; Morris, Handcock & Hunter 2008 for TNT; Hummel, Hunter & Handcock 2012 for the MCMLE
step-length algorithm; Geyer & Thompson 1992 for the lognormal MCMLE approximation) and against
this project's own architecture notes in `docs/ERGM_STATNET_STUDY.md`, which record *what the
algorithms do and why*, not *how ergm's source expresses them*. Every formula reproduced in
`docs/ERGM_STATNET_STUDY.md` (the TNT Hastings-ratio constants, the lognormal closed-form
update, the sandwich variance decomposition) was cross-checked against the actual shipped
source as a correctness check on this project's own independent derivation, not copied from it.

Because this is a clean-room reimplementation against published statistical results rather than
a derivative of `ergm`'s copyrighted expression of those results, `nwergm` incurs **no GPL-3
obligation** (no ergm source, comment, or identifier boilerplate is present in this repository).
No `khash.h`/`kvec.h`/MIT-licensed material was used either.

## Attribution given anyway (intellectual honesty, not a legal requirement)

Even without a licensing obligation, `nwergm`'s own embedded help (`nwergm.sthlp`, via
`nwergm.ado`'s SMCL header) and `docs/ERGM_ARCHITECTURE.md` credit the Statnet project and cite
the specific papers whose published algorithms `nwergm` implements:

- Hunter, D.R., Handcock, M.S., Butts, C.T., Goodreau, S.M., Morris, M. (2008). ergm: A Package
  to Fit, Simulate and Diagnose Exponential-Family Models for Networks. *Journal of Statistical
  Software*, 24(3), 1-29. `doi:10.18637/jss.v024.i03`
- Krivitsky, P.N., Hunter, D.R., Morris, M., Klumb, C. (2023). ergm 4: New Features for
  Analyzing Exponential-Family Random Graph Models. *Journal of Statistical Software*, 105(6),
  1-44. `doi:10.18637/jss.v105.i06`
- Hunter, D.R., Handcock, M.S. (2006). Inference in curved exponential family models for
  networks. *Journal of Computational and Graphical Statistics*, 15(3), 565-583.
- Hunter, D.R. (2007). Curved exponential family models for social networks. *Social Networks*,
  29(2), 216-230. (GWESP/GWDEGREE definitions)
- Morris, M., Handcock, M.S., Hunter, D.R. (2008). Specification of Exponential-Family Random
  Graph Models: Terms and Computational Aspects. *Journal of Statistical Software*, 24(4),
  1-24. (TNT proposal)
- Hummel, R.M., Hunter, D.R., Handcock, M.S. (2012). Improving Simulation-Based Algorithms for
  Fitting ERGMs. *Journal of Computational and Graphical Statistics*, 21(4), 920-939. (MCMLE
  step-length algorithm)
- Geyer, C.J., Thompson, E.A. (1992). Constrained Monte Carlo Maximum Likelihood for Dependent
  Data. *Journal of the Royal Statistical Society, Series B*, 54(3), 657-699. (lognormal MCMLE
  approximation)

`nwergm`'s help also states plainly that it is an independent, native reimplementation and is
not affiliated with or endorsed by the Statnet project, to avoid any implication of official
sanction.

## Development-time use of R/Statnet (not a runtime dependency)

R 4.6.0 with `ergm` 4.12.0 installed locally was used *during development only*, to compute
reference values (observed statistics, MPLE coefficients, small simulated distributions) for
certifying `nwergm`'s own independently-written Mata/C implementation against a working
Statnet installation — exactly as the brief's Part XXVII requires. `nwergm` itself never shells
out to, links against, or otherwise depends on R or `ergm` at runtime; every R script that
generates a reference value lives in `dev/ergm_reference/` (see its own `README.md`) - a
development-only directory excluded from every package manifest, never part of the shipped
command; the reference values it produces are hand-transcribed as literal constants into the
permanent `cscripts/test_nwergm_*.do` certification suite.
