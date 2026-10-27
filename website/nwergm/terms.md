---
title: "Terms"
parent: "nwergm (ERGM)"
nav_order: 8
permalink: /nwergm/terms/
description: "An overview of the term families of nwergm: structural, degree, triad, covariate, two-mode, curved and operator terms, with pointers to the help files."
---

# Terms

A term is one statistic of the network with one coefficient. In `nwergm` you request a term by naming it
as an option, in the same way as in R's `ergm`. This page is only a map; the complete lists, with
the options and the names that R uses, are in Stata's help files:

| Help file | Content |
|---|---|
| `help nwergm` | the command, the main terms, the stored results |
| `help nwergm_structural` | the terms of `structural()`: `twopath`, `transitive`, `cycle()`, `altkstar()`, `degree()` with `by()`, `isolates`, ... |
| `help nwergm_covterms` | node and dyad covariate terms |
| `help nwergm_bipartite` | terms for two-mode networks |
| `help nwergm_operators` | operator terms (version 1.1.0) |
| `help nwergm_constraints` | sampling and observation constraints, proposals |
| `help nwergm_estimation` | estimation methods and controls, `nwergm simulate`, `estat gof`, `estat mcmcdiag` |
| `help nwergm_fit` | missing data, fit statistics, `predict` |
| `help nwergm_estat` | postestimation: `estat gof`, `estat mcmcdiag`, `estat ic` |

| Family | Examples (options) | Question |
|---|---|---|
| Baseline | `edges` | density (required; the intercept) |
| Reciprocity and structure | `mutual`, `triangle`, `ctriple`, `structural(twopath transitive cycle(k=3 4) isolates ...)` | reciprocated pairs; triangles; cycles; isolated nodes |
| Degree | `degree()`, `odegree()`, `idegree()`, `concurrent`, `kstar()`, `ostar()`, `istar()`, `degrange()`, `gwdegree()`, `gwodegree()`, `gwidegree()`, `sender`, `receiver` | how ties are distributed over nodes; popular and active nodes |
| Triads and shared partners | `gwesp()`, `gwdsp()`, `gwnsp()`, `esp()`, `dsp()`, `transitiveties`, `cyclicalties`, `type()` | friends of friends; clustering |
| Node covariates | `nodecov()`, `nodefactor()`, `nodeicov()`, `nodeocov()`, `nodeofactor()`, `nodeifactor()`, `sociality()`, `nodecovrange()` | who has more ties; who sends, who receives |
| Homophily and mixing | `nodematch()`, `nodematchdiff()`, `nodemix()`, `absdist()`, `absdiffcat()`, `diff()`, `smalldiff()`, `attrcov()`, `mm()` | do similar nodes tie; mixing between groups |
| Dyadic covariates | `edgecov()`, `dyadcov()`, `hamming()` | does another network (kinship, distance) predict ties |
| Two-mode | `bcov1()`, `bcov2()`, `bfactor1()`, `bdegree1()`, `bdegree2()`, `bstar1()`, `bnodematch1()`, `bgwdegree1()`, `bgwdegree2()`, `bconcurrent1()`, `bdsp1()`, `coincidence()`, `btwostar1()` | how people attach to groups, clubs or events |
| Curved (estimated decay) | `gwespfree()`, `gwdegreefree()`, `gwodegreefree()`, `gwidegreefree()`, `gwdspfree()`, `gwnspfree()`; two-mode `bgwdegreefree1()`, `bgwdspfree1()`; `altkstar()` | the data choose the decay |
| Operators (version 1.1.0) | `operators(Sum() Prod() S() F() NodematchFilter() Symmetrize() Project() I() For() Label() Log() Exp() Offset() Curve())` | terms on a derived network, transformed or combined terms |

## How the terms are written

- Options have the names of R's terms. Where R's name has a digit followed by a letter, the digit moves to
  the end (R's `b1degree` is `bdegree1()`, `gwb2degree` is `bgwdegree2()`, `b1cov` is `bcov1()`), because
  Stata does not allow the other spelling in an option name.
- The terms in `structural()` and in `operators()` are written like R's terms, with R's argument names,
  for example `structural(triangle(attr=sex diff) cycle(k=3 4))`.
- Node attributes are **numeric** variables in the current dataset (use `encode` for strings); networks
  used as covariates (`edgecov()`, `hamming()`) are networks in memory.
- Coefficient names are those of R with `.` replaced by `_` (`gwesp_0.5`, `nodematch_sex`).
- A model whose terms depend only on the attributes of the two nodes of a dyad is dyad-independent and is
  fitted by pseudolikelihood (which is then the maximum likelihood); anything else makes `nwergm` use the
  Monte Carlo sampler automatically. `estimate(mple)` forces the pseudolikelihood.

## Where to see them in use

- [Tutorial 1: A first ERGM](../../tutorials/09-intro-ergm/): `edges`, `nodecov`, `gwesp`.
- [Tutorial 2](../tutorial-2-terms/): `nodematch`, `nodematchdiff`, `nodefactor`, `nodemix`, `mutual`, `nodeicov`, `gwesp`, `gwidegree`.
- [Tutorial 5](../tutorial-5-constraints-twomode-operators/): two-mode terms and operators.

What `nwergm` does not have is listed in [nwergm and R's ergm](../rergm/).
