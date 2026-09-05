---
title: "nwergm"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Exponential-family random graph model (ERGM) estimation"
---

# `nwergm`

Exponential-family random graph model (ERGM) estimation

## Syntax

```stata
nwergm
[netname]
,
edges
[covariate_effects
bipartite_effects
gw_effects
degree_effects
triad_effects
directed_covariate_effects
star_range_effects
sharedpartner_effects
triad_effects_directed
nodelevel_effects
estimation_control]
```

**Required**

| | |
|---|---|
| `edges` | Include the `edges` term (density/intercept); required |

**Node and dyadic covariate effects**

| | |
|---|---|
| `mutual` | Reciprocated-tie count; directed networks only |
| `nodematch(varlist)` | Pooled homophily on each listed categorical node attribute (exact match, one coefficient per variable) |
| `nodematchdiff(varlist)` | Differential homophily: one coefficient PER DISTINCT LEVEL of each listed attribute, rather than pooled across levels |
| `nodecov(varlist)` | Continuous node covariate main effect (sum over tie endpoints) |
| `nodeicov(varlist)` | Directed receiver-covariate effect; directed networks only |
| `nodeocov(varlist)` | Directed sender-covariate effect; directed networks only |
| `edgecov(netname)` | Dyadic covariate effect, taken from an already-loaded network's own tie values |
| `absdist(varlist)` | Absolute-difference effect on a continuous node covariate: sum over ties of \|x_i - x_j\| |
| `nodefactor(varlist)` | One coefficient per NON-BASE distinct level of each listed categorical attribute (the lowest-sorted level is omitted, matching R ergm's own default, to avoid exact collinearity with edges), each counting total degree among nodes at that level |
| `nodemix(varlist)` | Full categorical mixing matrix: one coefficient per distinct unordered pair of levels of each listed attribute |

**Two-mode (bipartite) effects**

| | |
|---|---|
| `bcov1(varlist)` | Bipartite (two-mode) networks only: the `b1cov()` term from R's own `ergm` package (renamed to `bcov1()` because Stata's `syntax` command rejects an option name with a digit followed by a letter, e.g. `b1cov`) - continuous node covariate main effect for the MODE-1 endpoint only (sum, over ties, of the mode-1 endpoint's own covariate value; the mode-2 endpoint's value is never added). Reported coefficient name keeps R's own `b1cov_`*varname* spelling |
| `bcov2(varlist)` | Bipartite networks only: the `b2cov()` term - the `bcov1()` mirror for the MODE-2 endpoint. Reported coefficient name: `b2cov_`*varname* |
| `bfactor1(varlist)` | Bipartite networks only: the `b1factor()` term - one coefficient per NON-BASE distinct level of each listed categorical attribute (lowest-sorted level omitted, same convention as `nodefactor()`), each counting the number of ties whose MODE-1 endpoint carries that level (the mode-2 endpoint never gets credit, unlike `nodefactor()`'s own both-endpoints convention). Reported coefficient name: `b1factor_`*varname*`_`*level* |
| `bfactor2(varlist)` | Bipartite networks only: the `b2factor()` term - the `bfactor1()` mirror for the MODE-2 endpoint. Reported coefficient name: `b2factor_`*varname*`_`*level* |
| `bdegree1(numlist)` | Bipartite networks only: the `b1degree()` term - one coefficient per listed degree value, counting the number of MODE-1 nodes with that exact (total) degree (the mode-2 endpoint never contributes). Dyad-DEPENDENT (needs `method(mcmle)`), unlike `bcov1()`/`bfactor1()`. Reported coefficient name: `b1degree_`*d* |
| `bdegree2(numlist)` | Bipartite networks only: the `b2degree()` term - the `bdegree1()` mirror for the MODE-2 endpoint |
| `bstar1(numlist)` | Bipartite networks only: the `b1star()` term - one coefficient per listed k, counting the number of distinct k-stars centered on a MODE-1 node (C(degree,k) summed over mode-1 nodes only). Dyad-DEPENDENT (needs `method(mcmle)`). Note: `bstar1(1)` equals `bstar2(1)` equals `edges` (R ergm's own documented identity). Reported coefficient name: `b1star_`*k* |
| `bstar2(numlist)` | Bipartite networks only: the `b2star()` term - the `bstar1()` mirror for the MODE-2 endpoint |
| `bnodematch1(varlist)` | Bipartite networks only: the `b1nodematch()` term - pooled homophily (default-parameter scope: no `diff()`/`alpha()`/`beta()`/`byb2attr()`) on each listed categorical attribute, counting only ties whose MODE-1 endpoint carries the matching level. Dyad-DEPENDENT (needs `method(mcmle)`), unlike `bcov1()`/`bfactor1()`. Reported coefficient name: `b1nodematch_`*varname* |
| `bnodematch2(varlist)` | Bipartite networks only: the `b2nodematch()` term - the `bnodematch1()` mirror for the MODE-2 endpoint. Reported coefficient name: `b2nodematch_`*varname* |
| `bgwdegree1(real)` | Bipartite networks only: the `gwb1degree()` term - geometrically weighted degree, fixed decay, counting only MODE-1 nodes' own degree. Dyad-DEPENDENT (needs `method(mcmle)`); no curved (estimated-decay) counterpart yet, unlike plain `gwdegree()`/`gwdegreefree()`. Reported coefficient name: `bgwdegree1_`*decay* |
| `bgwdegree2(real)` | Bipartite networks only: the `gwb2degree()` term - the `bgwdegree1()` mirror for the MODE-2 endpoint. Reported coefficient name: `bgwdegree2_`*decay* |

**Geometrically weighted effects**

| | |
|---|---|
| `gwesp(real)` | Geometrically weighted edgewise shared partners, fixed decay; undirected (UTP) or directed (shared-partner definition set by `type()`, default OTP) |
| `gwespfree(real)` | Geometrically weighted edgewise shared partners with an ESTIMATED (curved) decay parameter; undirected (UTP), or directed (shared-partner definition set by `type()`, default OTP - all five of OTP/ITP/OSP/ISP/RTP supported). The argument is only a starting value for decay, not a fixed value. Both **method(mple)** and **method(mcmle)** are supported (default **mcmle**, as for any other dyad-dependent term - see `method()` below) - reports **gwesp_weight**/**gwesp_decay** in place of a single `gwesp()` coefficient. Cannot be combined with `gwesp()`, `esp()`, or another curved term |
| `gwdegreefree(real)` | Geometrically weighted degree with an ESTIMATED (curved) decay parameter, undirected networks only; the argument is only a starting value for decay, not a fixed value. Both **method(mple)** and **method(mcmle)** are supported (default **mcmle**) - reports **gwdegree_weight**/**gwdegree_decay** in place of a single `gwdegree()` coefficient. Cannot be combined with `gwdegree()`, `degree()`, or another curved term |
| `gwdspfree(real)` | Geometrically weighted dyadwise shared partners with an ESTIMATED (curved) decay parameter, undirected networks only; the argument is only a starting value for decay, not a fixed value. Both **method(mple)** and **method(mcmle)** are supported (default **mcmle**) - reports **gwdsp_weight**/**gwdsp_decay** in place of a single `gwdsp()` coefficient. Cannot be combined with `gwdsp()`, `dsp()`, or another curved term |
| `gwodegreefree(real)` | Geometrically weighted out-degree with an ESTIMATED (curved) decay parameter, directed networks only; the argument is only a starting value for decay, not a fixed value. Both **method(mple)** and **method(mcmle)** are supported (default **mcmle**) - reports **gwodegree_weight**/**gwodegree_decay** in place of a single `gwodegree()` coefficient. Cannot be combined with `gwodegree()`, `odegree()`, or another curved term |
| `gwidegreefree(real)` | Geometrically weighted in-degree with an ESTIMATED (curved) decay parameter, directed networks only; the argument is only a starting value for decay, not a fixed value. Both **method(mple)** and **method(mcmle)** are supported (default **mcmle**) - reports **gwidegree_weight**/**gwidegree_decay** in place of a single `gwidegree()` coefficient. Cannot be combined with `gwidegree()`, `idegree()`, or another curved term |
| `gwnspfree(real)` | Geometrically weighted nonedgewise shared partners with an ESTIMATED (curved) decay parameter, undirected networks only; the argument is only a starting value for decay, not a fixed value. Both **method(mple)** and **method(mcmle)** are supported (default **mcmle**) - reports **gwnsp_weight**/**gwnsp_decay** in place of a single `gwnsp()` coefficient. Cannot be combined with `gwnsp()` or another curved term |
| `gwdsp(real)` | Geometrically weighted dyadwise shared partners, fixed decay; undirected (UTP) or directed (see `type()`) |
| `gwdegree(real)` | Geometrically weighted degree, fixed decay |
| `gwodegree(real)` | Geometrically weighted out-degree, fixed decay; directed networks only |
| `gwidegree(real)` | Geometrically weighted in-degree, fixed decay; directed networks only |
| `gwnsp(real)` | Geometrically weighted NONedgewise (untied-dyad) shared partners, fixed decay; undirected (UTP) or directed (see `type()`). Satisfies gwdsp = gwesp + gwnsp |

**Degree-distribution effects**

| | |
|---|---|
| `degree(numlist)` | One coefficient per listed degree value: count of nodes with that exact (total) degree; undirected only |
| `odegree(numlist)` | One coefficient per listed value: count of nodes with that exact out-degree; directed networks only |
| `idegree(numlist)` | One coefficient per listed value: count of nodes with that exact in-degree; directed networks only |
| `concurrent` | Count of nodes with (total) degree 2 or higher; undirected only |

**Triad-closure effects**

| | |
|---|---|
| `triangle` | Count of triangles (mutually tied triples); undirected only |
| `ctriple` | Count of cyclic triples ((i->j),(j->k),(k->i)); directed networks only |

**Directed covariate effects**

| | |
|---|---|
| `nodeofactor(varlist)` | Directed analogue of nodefactor(): one coefficient per NON-BASE distinct level, each counting OUT-degree among nodes at that level; directed networks only |
| `nodeifactor(varlist)` | Directed analogue of nodefactor(): one coefficient per NON-BASE distinct level, each counting IN-degree among nodes at that level; directed networks only |

**Star and degree-range effects**

| | |
|---|---|
| `kstar(numlist)` | One coefficient per listed k value: count of k-stars ((total) degree choose k, summed over nodes); undirected only |
| `ostar(numlist)` | One coefficient per listed k value: count of out-k-stars; directed networks only |
| `istar(numlist)` | One coefficient per listed k value: count of in-k-stars; directed networks only |
| `degrange(numlist)` | Semi-open-interval degree count: one coefficient per FROM value in this numlist, counting nodes with (total) degree in [from,to); pair with `degrangeto()`; undirected only |
| `degrangeto(numlist)` | TO values pairing with `degrange()`, same order/length; omit for an open-ended upper bound |
| `odegrange(numlist)` | Semi-open-interval OUT-degree count, paired with `odegrangeto()`; directed networks only |
| `odegrangeto(numlist)` | TO values pairing with `odegrange()` |
| `idegrange(numlist)` | Semi-open-interval IN-degree count, paired with `idegrangeto()`; directed networks only |
| `idegrangeto(numlist)` | TO values pairing with `idegrange()` |

**Shared-partner count effects**

| | |
|---|---|
| `esp(numlist)` | One coefficient per listed d value: count of TIED dyads with exactly d shared partners (fixed, non-geometric alternative to `gwesp()`); undirected (UTP) or directed (see `type()`) |
| `dsp(numlist)` | One coefficient per listed d value: count of ALL dyads (tied or not) with exactly d shared partners (fixed, non-geometric alternative to `gwdsp()`); undirected (UTP) or directed (see `type()`). An EXHAUSTIVE d-range (covering every shared-partner value a toggle can produce) is exactly collinear across its own columns - list a subset, not every achievable value |
| `type(OTP\|ITP\|OSP\|ISP\|RTP)` | Shared-partner definition used by every `gwesp()`/`gwdsp()`/`gwnsp()`/`esp()`/`dsp()`/`gwespfree()` term in the model, on a DIRECTED network only (default **OTP**; silently ignored, matching R ergm's own behaviour, when **netname** is undirected - see the **Remarks** section below for the five definitions) |

**Triad-closure effects (directed)**

| | |
|---|---|
| `transitiveties` | Count of TIED arcs i->j for which there also exists a two-path i->k->j (an existence/threshold indicator, not a count - contrast with `gwesp()`/`esp()`); directed networks only |
| `cyclicalties` | Count of TIED arcs i->j for which there also exists a return two-path j->k->i, closing a directed 3-cycle; directed networks only |

**Dyadic covariate and node-level effects**

| | |
|---|---|
| `hamming(netname)` | Hamming distance to a reference network: count of dyads whose tie state disagrees with the same network's |
| `sender` | One coefficient per node (except a base node) equal to that node's own out-degree; directed networks only |
| `receiver` | One coefficient per node (except a base node) equal to that node's own in-degree; directed networks only |

**Estimation control**

| | |
|---|---|
| `method(mple\|mcmle)` | Estimation method; default *mcmle* unless the model is dyad-independent, in which case MPLE already is the MLE |
| `offset(coefname # [coefname # ...])` | Hold one or more named coefficients fixed at a given value rather than estimating them, matching R ergm's own `offset()` formula wrapper. **coefname** must be a coefficient this model would otherwise report (an option must still be typed to register the term, e.g. `triangle`, before `offset(triangle #)` can fix its own coefficient - `offset()` names an EXISTING coefficient, it does not add a second copy of the term). Works with both `method(mple)` and `method(mcmle)`. At least one coefficient in the model must remain free. Not currently supported for a curved (free-decay) term's own weight/decay. The fixed coefficient is reported at exactly the given value with standard error exactly 0 (matching R's own real output) and a zero row/column in **e(V)** - see **Remarks** below |
| `mcmcburnin(int)` | MCMC burn-in steps per simulation; default 3,000 |
| `mcmcinterval(int)` | MCMC steps between recorded draws; default 50 |
| `mcmcsamplesize(int)` | Number of recorded MCMC draws per simulation; default 3,000 |
| `mcmleiterations(int)` | Maximum MCMLE outer iterations; default 20 |
| `proposal(uniform\|tnt)` | Metropolis-Hastings proposal; default *tnt*. Both have a masked variant when `freedyads()` or `blockdiag()` is given |
| `freedyads(netname)` | Restrict the dyad space to fit (see **Remarks**): **netname**'s own ties mark which dyads of the network being fit are free to vary during MCMC; every dyad NOT tied in **netname** is held fixed at its observed value for the rest of the fit (R ergm's own `fixallbut()` constraint). Compatible with both `proposal(uniform)` and `proposal(tnt)`, and native (C)-accelerated when otherwise eligible. See **Limitations (v1 scope)** below |
| `blockdiag(varname)` | Restrict the dyad space to fit (see **Remarks**): only dyads sharing the same value of **varname** are free to vary during MCMC; every cross-value dyad is held fixed at its observed value for the rest of the fit (R ergm's own `blockdiag()` constraint). Cannot be combined with `freedyads()`. Compatible with both `proposal(uniform)` and `proposal(tnt)`, and native (C)-accelerated when otherwise eligible |
| `seed(int)` | Set the random-number seed before simulating (for reproducibility) |
| `verbose` | Show MPLE/MCMLE iteration detail |
| `spcache` | Enable the incremental shared-partner cache for `gwesp()`/`gwdsp()`/`gwnsp()`/`esp()`/`dsp()`/`triangle`/`ctriple` on an undirected network; OFF by default because direct benchmarking found it a net LOSS below roughly average degree 30-40 (the common case) and a net win only above that - enable only for denser undirected networks; no effect on a directed network or without any of those terms |
| `fixdensity` | Hold the total tie count fixed during MCMC (R ergm's own `constraints=~edges`), via a compound tie/non-tie swap proposal rather than the ordinary single-dyad toggle; native (C)-accelerated when otherwise eligible. Requires `method(mcmle)` and at least one term besides `edges` (which is dropped, not estimated, under this constraint - see **Remarks**). Cannot currently be combined with `freedyads()`/`blockdiag()` - v1 supports one dyad-space constraint at a time |
| `nonative` | Force the pure-Mata backend even on an otherwise native-eligible model - an explicit escape hatch for testing or direct comparison against the native (C) backend; not needed for ordinary use, since `nwergm` already picks the native backend automatically whenever a model qualifies |
| `nomcmcsample` | Skip posting **e(mcmcsample)** (**method(mcmle)** only). Populating this matrix from Mata is the single slowest step for a fit with a large `mcmcsamplesize()` - a genuine Stata matrix-engine cost at bulk-data scale (confirmed by direct timing: over 30 seconds at 100,000 rows), not something [estat mcmcdiag](nwergm_estat.md)'s own consumption of it can be blamed for or sped up (reading the already-posted matrix back is fast regardless of size - the cost is entirely in creating it in the first place). Specify `nomcmcsample` when fitting with an unusually large `mcmcsamplesize()` and you do not need `estat mcmcdiag` or to inspect the raw sample directly - the coefficient table, standard errors, and every other stored result are completely unaffected |

## Description

`nwergm` fits an exponential-family random graph model (ERGM) to the network(s) in [netname](netname.md) (default: the currently set network) using a fully native Stata/Mata implementation - no R or other external statistical software is called at any point, at estimation time or otherwise. Statnet's mature `ergm` R package was studied in detail as a behavioural and architectural reference during development (see [statnet.org](https://cran.r-project.org/package=ergm)) and used, during development only, to certify `nwergm`'s own independently-written implementation against real reference output; see [Provenance](nwergm.md) below.

`nwergm` implements a substantial, independently-certified core of Statnet's own `ergm` term surface and estimation machinery: a term registry, Metropolis-Hastings simulation with a genuine tie/no-tie proposal, maximum pseudolikelihood estimation, and Monte Carlo maximum likelihood estimation, backed by an effect library covering the full node-covariate family, dyadic covariates, the geometrically weighted family (including directed shared-partner support and curved/free-decay estimation under both `method(mple)` and `method(mcmle)`), fixed shared-partner counts, the complete degree-distribution family, and directed triad-closure terms - see [Limitations](nwergm.md) below for the complete current list, plus a narrow term family for two-mode (bipartite) networks. What still sets `nwergm` apart from full parity is scope, not term count: a wider bipartite term family and constraints beyond the free binary dyad space are each a genuine architectural addition rather than another term to add, and are not yet supported.

`method()` selects the estimation method. If every requested term is dyad-independent (the node-covariate family - `edges`, `nodematch()`, `nodematchdiff()`, `nodecov()`, `nodeicov()`/`nodeocov()`, `absdist()`, `nodefactor()`, `nodeofactor()`/`nodeifactor()`, `nodemix()`, `sender`, `receiver` - plus the dyadic-covariate terms `edgecov()`/`hamming()`) and no dyad-DEPENDENT term (`mutual`, any geometrically weighted term, any degree-distribution term, `triangle`, `ctriple`, `transitiveties`, `cyclicalties`, `esp()`, or `dsp()`) is present, maximum pseudolikelihood *is* the maximum likelihood estimate - `nwergm` detects this automatically and reports `method(mple)` results directly (labeled as such, not as full ERGM MLE) without ever running MCMC. Otherwise the default is `method(mcmle)`: pseudolikelihood is used only as the starting value for Monte Carlo maximum likelihood. This applies equally to a curved (free-decay) term (`gwespfree()` and its five counterparts) - the curved MPLE fit is the `method(mcmle)` starting point, and MCMLE then refines it using R ergm's own steplength/convergence approach (Hummel, Hunter, and Handcock 2012).

A curved decay parameter can be weakly identified on a small or sparse network, in which case the fit legitimately converges to a boundary solution - decay near 0 (near-complete collapse to a single shared-partner-count effect) or, less often, a large decay (near-complete insensitivity to shared-partner count beyond the first). This is a property of the statistical model, not a bug: R's own `ergm` converges to the same kind of boundary solution on the same data, and can fail to converge at all on a genuinely poorly-identified network (occasionally so does `nwergm`, reported honestly as a non-converged fit rather than a plausible-looking wrong number - see **e(converged)** below). A large standard error on the decay coefficient is the usual sign this has happened; consider a longer `mcmcburnin()`, a larger `mcmcsamplesize()`, a different starting decay, or a fixed-decay (`gwesp()` etc.) or non-curved model instead.

`offset()` fixes a named coefficient at a known value instead of estimating it - useful for imposing a theoretically-motivated effect size, reproducing a published model exactly, or holding a nuisance term constant. Internally: for `method(mple)`, the fixed term's own known contribution is passed to the underlying logistic regression as a GLM offset (the standard mechanism for a fixed-coefficient term in any exponential-family regression), and only the remaining coefficients are estimated; for `method(mcmle)`, the Newton step is restricted to the free coefficients only, while the fixed term's own contribution still fully participates in MCMC sampling (fixing a coefficient does not remove its term from the model - the network is still simulated as if that effect were really present at the given strength). Multiple coefficients may be fixed in one model: **offset(mutual 2 gwesp_weight 0.5)**.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwergm flomarriage, edges
. nwergm flomarriage, edges nodecov(wealth)
. nwergm flomarriage, edges gwesp(.5)
```

## Supported network types

Binary: yes (only) - MPLE/MCMLE estimation here is for a binary tie-formation model; a valued network's own tie values are not used as an outcome (no weighted ERGM family is implemented). Directed: yes, most terms have both directed and undirected forms (see the term list). Weighted: not applicable (see Binary). Signed: not applicable. Two-mode: yes, undirected only - a narrow term family so far (`edges`, `bcov1()`/`bcov2()`/`bfactor1()`/`bfactor2()`, `bdegree1()`/`bdegree2()`/`bstar1()`/`bstar2()`, `bnodematch1()`/`bnodematch2()`, `bgwdegree1()`/`bgwdegree2()`); see Limitations below.

## Stored results

**Scalars**

- **e(N)** number of dyads
- **e(nodes)** number of nodes
- **e(ties)** number of observed ties
- **e(converged)** 1 if MCMLE's own convergence test was satisfied (method(mcmle) only)
- **e(mcmle_iterations)** number of MCMLE outer iterations run (method(mcmle) only)
- **e(mcmc_acceptrate)** Metropolis-Hastings acceptance rate, final simulation (method(mcmle) only)
- **e(mcmc_burnin)** MCMC burn-in steps used (method(mcmle) only)
- **e(mcmc_interval)** MCMC thinning interval requested (method(mcmle) only)
- **e(mcmc_interval_final)** MCMC thinning interval actually used for the last iteration - may
- exceed e(mcmc_interval) if the adaptive-interval mechanism grew it
- to reach an adequate effective sample size (method(mcmle) only)
- **e(mcmc_samplesize)** MCMC recorded-draw count used (method(mcmle) only)
- **e(native)** 1 if the native (C) backend was used for this run (the MCMC sampler
- for method(mcmle); the MPLE design-matrix build for method(mple)),
- 0 if the Mata implementation ran instead - purely informational,
- see [Performance](nwergm.md) below

**Macros**

- **e(cmd)** **nwergm**
- **e(title)** title of estimation
- **e(depvar)** name of the estimated network
- **e(method)** **mple** or **mcmle**
- **e(directed)** **true**/**false**
- **e(proposal)** Metropolis-Hastings proposal used (method(mcmle) only)
- **e(estat_cmd)** **nwergm_estat** (postestimation dispatch)

**Matrices**

- **e(b)** coefficient vector
- **e(V)** variance-covariance matrix
- **e(mcmcsample)** final simulation's sufficient-statistic draws, samplesize x nparam (method(mcmle) only)

## References

Hunter, D.R., Handcock, M.S., Butts, C.T., Goodreau, S.M., Morris, M. (2008). ergm: A Package to Fit, Simulate and Diagnose Exponential-Family Models for Networks. *Journal of Statistical Software*, 24(3), 1-29.

Hunter, D.R., Handcock, M.S. (2006). Inference in curved exponential family models for networks. *Journal of Computational and Graphical Statistics*, 15(3), 565-583. (MPLE)

Hunter, D.R. (2007). Curved exponential family models for social networks. *Social Networks*, 29(2), 216-230. (GWESP/GWDEGREE)

Morris, M., Handcock, M.S., Hunter, D.R. (2008). Specification of Exponential-Family Random Graph Models: Terms and Computational Aspects. *Journal of Statistical Software*, 24(4), 1-24. (TNT proposal)

Hummel, R.M., Hunter, D.R., Handcock, M.S. (2012). Improving Simulation-Based Algorithms for Fitting ERGMs. *Journal of Computational and Graphical Statistics*, 21(4), 920-939. (MCMLE step length)

Geyer, C.J., Thompson, E.A. (1992). Constrained Monte Carlo Maximum Likelihood for Dependent Data. *Journal of the Royal Statistical Society, Series B*, 54(3), 657-699. (MCMLE)

`nwergm` is an independent, native reimplementation and is not affiliated with or endorsed by the Statnet project.

## See also

- [nwqap](nwqap.md), [nwrandom](nwrandom.md), [nwcug](nwcug.md), [feasible network sizes](nw_intro.md)
