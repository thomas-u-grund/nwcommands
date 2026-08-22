# Statnet `ergm` Architecture Study (for `nwergm`)

Internal technical reference produced before implementing `nwergm`, per the project brief's
Part I requirement. Based on a direct clone and read of the public `statnet/ergm` GitHub
repository (`ergm` version 4.13.0-8214, cloned 2026-08-22), not on tutorials or prior training
knowledge alone. This is a map of the parts of ergm's own architecture that inform `nwergm`'s
design — it is not a copy of ergm's code (see `docs/ERGM_PROVENANCE.md` for licensing and
provenance).

## 1. Call-flow trace

`ergm(y ~ edges + mutual + nodematch("sex"))`:

```
ergm() [R/ergm.R]
  -> ergm_model() / model.R           build the term list from the formula, calling
                                        InitErgmTerm.<name>() for each term (R/InitErgmTerm*.R)
  -> ergm_state() [R/state.R]         wrap the observed network + model + proposal + constraints
                                        into one opaque state object passed to C
  -> ergm.getMCMCsample / MCMC.c      (not called yet for MPLE-only fits)
  -> ergm.mple() [R/mple.R]           always computed first, as the starting value for MCMLE
       -> ergm.pl()                   builds the pseudo-likelihood design matrix: one row per
                                        dyad, columns = that dyad's change statistics, response
                                        = observed tie indicator (R/mple_components.R)
       -> glm(y ~ X - 1, family=binomial)   ordinary logistic regression via R's own glm()
  -> is.dyad.independent(model)?      if every term has dependence=FALSE (edges/nodematch/
                                        nodecov/nodefactor/edgecov are all dyad-independent;
                                        mutual/gwesp/gwdegree are NOT), MPLE == MLE and ergm()
                                        stops here.
  -> ergm.MCMLE() [R/mcmle.R]         otherwise, iterate:
       -> ergm_MCMC_sample()          simulate networks at current theta via the C MCMC engine
                                        (src/MCMC.c), return sampled sufficient statistics
       -> .Hummel.steplength()        [R/stepping.R] choose how far to move toward the
                                        Newton-Raphson target this iteration (see §4)
       -> ergm.estimate()             [R/mcmle_update.R] closed-form "lognormal" MLE update
                                        (see §4) using the (possibly shrunk) MC sample's mean
                                        and covariance
       -> convergence test            Hotelling/precision/confidence criteria on the estimating
                                        equations; loop again if not converged
  -> ergm.MCMCse() [R/mcmc_se.R]      final sandwich-form variance-covariance matrix (see §5)
  -> mcmc.diagnostics(), gof()        optional postestimation (user-invoked, not part of the
                                        fit itself)
```

`ergm(y ~ edges + gwesp(0.5, fixed=TRUE) + nodematch("sex"))` follows the identical flow;
`gwesp` and `mutual` are the two terms in this study's target model list that are
dyad-*dependent* (their change statistic at dyad (i,j) depends on the rest of the network, not
just node attributes), which is what forces the MCMLE path rather than stopping at MPLE.

## 2. Term architecture (`R/InitErgmTerm*.R`, `src/changestats*.c`)

Each term is registered as an R function `InitErgmTerm.<name>(nw, arglist, ...)` that:

1. Validates arguments via `check.ErgmTerm()`, which centrally enforces directed/undirected/
   bipartite support (e.g. `mutual` declares `directed=TRUE`, i.e. undirected networks are
   rejected with a clear error *before* any C code runs — exactly the network-type-validation
   pattern `nwergm`'s own term registry needs, per Part IV/XXXIII).
2. Returns a list carrying the term's metadata: `name`, `coef.names` (one or more, since a
   single term specification like `nodematch(attr, diff=TRUE)` can expand into several
   columns), `dependence` (TRUE/FALSE — whether the term violates dyadic independence, which
   determines whether MPLE alone suffices), `minval`/`maxval` (bounds used for degeneracy
   sanity checks), and any C-side "input parameters" (e.g. the node attribute vector for
   `nodematch`, encoded as a plain numeric array passed to C).
3. The actual per-toggle change statistic is a C function (`changestats.c`,
   `changestats_dgw_sp.c` for the geometrically-weighted shared-partner family) matching the
   term by name via a lookup table (`src/model.c` builds this at model-init time from the
   term list) — one function per term, called once per proposed toggle during MCMC and once per
   dyad during MPLE design-matrix construction. This "one function per term, called through a
   shared driver loop" structure is exactly `nwergm`'s own term-API requirement (Part VII):
   *adding an effect means writing one term's `statistic()`/`change()` pair, not touching the
   sampler or estimator*.

Confirmed change-statistic definitions read directly from `src/changestats.c` (used as the
`nwergm` behavioural reference, not copied):

- **`edges`**: change statistic for any toggle of (i,j) is always exactly ±1 (+1 if adding,
  −1 if removing) — the trivial case, but establishes the calling convention (a change function
  receives the current edge state and returns the *signed* effect of toggling it).
- **`mutual`** (`c_mutual`, `src/changestats.c:2239`): toggling (tail,head) changes the mutual
  count *only if* the reverse edge (head,tail) already exists — the change is +1 if the toggle
  is adding the edge (creating a new mutual pair) or −1 if removing it (destroying one).
  Directed-only, exactly as `nwergm`'s own spec requires; confirms the "fast reverse-edge
  lookup" the brief calls for is precisely `has_edge(head, tail)`.
- **GWESP** (`src/changestats_dgw_sp.c` / `.h`, the `espOTP_change` macro family): confirms the
  standard structure from Hunter (2007) — toggling (i,j) affects (a) the toggled dyad's own
  GWESP contribution, evaluated at its shared-partner count *excluding* the toggled tie itself,
  and (b) for every node k that is currently a common neighbor of both i and j, the two
  *already-existing* edges (i,k) and (j,k) each have their own shared-partner count shift by
  ±1, changing their own contribution to the sum. `ergm`'s C code caches shared-partner counts
  per dyad (`ergm_dyad_hashmap`/`spcache`) purely for performance; the underlying math is the
  published Hunter (2007) GWESP definition, which `nwergm` implements directly (see
  `docs/ERGM_ARCHITECTURE.md`) rather than porting the cache macros.
- **MPLE** (`R/mple.R`, `R/mple_components.R`): exactly the textbook Hunter & Handcock (2006)
  approach — one row per dyad, columns = that dyad's change statistics (computed by running
  every registered term's change function once per dyad against the empty-vs-observed network),
  response = the observed tie indicator, fit via ordinary logistic regression
  (`glm(y ~ X - 1, family=binomial)`). Confirms Part XII's design is exactly right.

## 3. MCMC proposal mechanism (`src/MHproposals.c`, `inst/include/ergm_MHproposal.h`)

The default proposal for an unconstrained binary network is **TNT** ("tie/no-tie",
`Mp_TNT`), confirmed read directly from `src/MHproposals.c:62-89`:

- With probability P=0.5: pick a uniformly random *existing* edge (propose removing it).
- With probability Q=1−P=0.5: pick a uniformly random dyad from the *entire* dyad space
  (propose toggling it — it may or may not already be an edge).

Because these two paths have different reverse-proposal probabilities (picking "a random edge"
gets easier as the network gets sparser, while "a random dyad" doesn't), the acceptance ratio
needs a correction term (the Hastings ratio) or the chain will not target the right
distribution. The exact log-ratio formulas, read directly from
`inst/include/ergm_MHproposal.h:47-51`:

```
TNT_LR_E / TNT_LR_DE  (proposing to remove an edge):
  log( E==1 ? 1/(DP+Q) : E/(DO+E) )

TNT_LR_DN (proposing to add a non-edge):
  log( E==0 ? DP+Q : 1 + DO/(E+1) )
```

where `E` = current edge count before the toggle, `DP = P * ndyads`, `DO = DP/Q` (= `ndyads`
when P=Q=0.5). The overall Metropolis-Hastings acceptance probability is then
`min(1, exp(theta' * ChangeStat + logratio))`. This is the standard TNT construction from
Morris, Handcock & Hunter (2008, JSS) — `nwergm` implements it directly from this formula
(with citation), confirmed against the actual shipped C constants rather than reconstructed
from memory. A plain uniform-random-dyad proposal is `nwergm`'s fallback/simplest proposal
(`P=0`, i.e. always the "pick a random dyad" branch, `logratio=0` since it's already symmetric).

Proposals are a completely separate C module from the terms/change-statistics — the term
code never has any notion of "how was this toggle chosen," only "what changed." `nwergm`'s own
architecture keeps this separation (Part X: `ErgmProposal` independent of `ErgmTerm`).

## 4. MCMLE core algorithm (`R/mcmle.R`, `R/mcmle_update.R`, `R/stepping.R`)

**The problem the stepping algorithm solves**: a naive one-shot Newton-Raphson MCMLE update
(simulate at theta0, fit a linear/quadratic approximation to the log-likelihood ratio around
theta0, jump straight to its maximizer) can badly overshoot when theta0 is far from the true
MLE, because the MC sample was drawn from a distribution that may not resemble the target
distribution at all — the "approximation" is only trustworthy in the region actually explored
by the sample. Hummel, Hunter & Handcock (2012, JCGS) fix this by never fully trusting the
naive Newton target: at each iteration, find the largest step length `gamma <= 1` such that
moving only `gamma` of the way toward the naive target keeps the (shrunk) sample statistics
inside the convex hull of the *observed*-relative sample — read directly from
`R/stepping.R`'s `.Hummel.steplength()`/`shrink_into_CH()`, which solves this via linear
programming (for each candidate direction, minimize a linear objective subject to the point
being a member of the convex hull, using `Rglpk` or `lpSolveAPI`). `gamma=1` means "the full
Newton step is safe"; smaller values mean "only move partway, then re-simulate and try again."

**The closed-form ("lognormal") update itself** (`R/mcmle_update.R`, `ergm.estimate()`,
confirmed by direct read): for a non-curved model, the log-likelihood ratio
`l(eta) - l(eta0)` is approximated by treating the simulated sufficient statistics as
approximately multivariate normal (the standard Geyer & Thompson 1992 device for exponential
families), which gives a *closed-form* quadratic approximation maximized at

```
eta_new = eta0 + V^{-1} * (-mean(D))
```

where `D` = simulated statistics minus observed statistics (so the target is `mean(D) = 0`),
shrunk toward 0 by the step length (`D_shifted = D - (1-gamma)*mean(D)`), and `V` =
sample covariance of `D_shifted`. This closed-form path is used whenever the model is not
curved and has no box constraints — true for every term `nwergm` v1 supports (fixed decay
GWESP/GWDEGREE are non-curved by construction), so `nwergm`'s own MCMLE core can use this exact
closed-form update rather than a general nonlinear optimizer, faithfully matching ergm's own
default numerical method for this model class.

**Outer loop** (`ergm.MCMLE()`, `R/mcmle.R`): repeat {simulate at current theta -> compute
step length -> closed-form update -> convergence test} until either (a) the step length reaches
1 for two consecutive iterations and an estimating-equation convergence test (Hotelling's T² by
default, comparing the simulated-vs-observed statistic difference against its own Monte Carlo
sampling variability) fails to reject "no more improvement," or (b) `MCMLE.maxit` iterations are
exhausted. Typical default is up to 20-60 outer iterations depending on model complexity; each
iteration's MC sample size and burn-in/interval can adapt (grow) if convergence stalls.

## 5. Final standard errors (`R/mcmc_se.R`)

The reported `e(V)` is **not** simply `V^{-1}` from the last MCMLE iteration. It is a sandwich
estimator, confirmed by direct read of `ergm.MCMCse()`:

```
Var(theta_hat) ~= H^{-1} * Var(g_bar) * H^{-1}
```

- `H` ("bread"): the sample covariance of the sufficient statistics from a *fresh* MCMC sample
  drawn at the final `theta_hat` (not reusing a step-shrunk intermediate sample) — this is the
  observed-information analogue, i.e. what the variance *would* be if the likelihood surface
  were known exactly.
- `Var(g_bar)` ("filling"): the variance of the *sample mean* of the sufficient statistics from
  that same final MCMC run, corrected for MCMC autocorrelation via a spectral-density-at-zero
  estimator (`spectrum0.mvar`, effectively a batch-means/HAC-style long-run variance) — this
  captures the *extra* uncertainty from only having a finite, autocorrelated Monte Carlo sample
  rather than the exact likelihood. If the MC sample were infinite and independent, this term
  would shrink to (H / n), and the sandwich would collapse to the ordinary `H^{-1}` MLE variance
  scaled by sample size.

`nwergm` reproduces this sandwich structure exactly (bread = final-sample statistic covariance,
filling = autocorrelation-corrected variance of the sample mean) but uses a simpler,
self-contained batch-means estimator for the autocorrelation correction rather than porting
`coda`'s spectral-density routine — documented explicitly in `docs/ERGM_ARCHITECTURE.md` as a
deliberate, disclosed simplification, not silently different behavior.

## 6. Diagnostics and GOF (`R/mcmc.diagnostics.R`, `R/gof.R`) — summary only

- **MCMC diagnostics**: trace plots of each sampled statistic across the MCMC run; sample mean/
  SD; lag-1 (and higher) autocorrelation; effective sample size; Geweke and
  Heidelberger-Welch stationarity tests (via the `coda` package) on whether the chain has
  converged to its stationary distribution within the run. `nwergm`'s own "basic" diagnostics
  (Part XIX) cover trace summary/mean/SD/autocorrelation/ESS/acceptance rate directly; the
  formal Geweke/Heidelberger-Welch hypothesis tests are recorded as a Pending roadmap item
  rather than implemented in v1 (would require porting nontrivial spectral-test machinery for
  a diagnostic that is supplementary, not part of the fit itself).
- **GOF**: simulates many networks from the fitted parameters and compares the *distributions*
  (not just means) of degree, edgewise shared partners, geodesic distances, and (for directed
  models) the triad census against the single observed network's values, typically displayed as
  boxplots-over-simulations with the observed value overlaid. `nwergm`'s v1 GOF reuses this
  exact comparison idea but delegates the actual statistic computation to already-existing
  `nwcommands` commands (`nwdegree`, `nwdistance`/`nwgeodesic`, `nwtriads`) rather than
  reimplementing them, per the brief's own explicit instruction (Part XX).

## 7. Network representation (`src/edgetree.c`, `src/ergm_state.c`)

`ergm`'s own C-level network representation is a per-node binary search tree of neighbors
(`edgetree`), giving O(log d) neighbor lookup/insert/delete for a node of degree d — a classic
mutable sparse-graph structure optimized for the toggle-heavy MCMC access pattern. This
confirms the key architectural lesson for `nwergm`: **the existing `nwcommands` `NWdef` sparse
index (CSR-style, `unw_core.do`) is not a good fit for the MCMC inner loop**, because
`build_sparse_index()` rebuilds the entire CSR structure from scratch (O(n + nnz)) rather than
supporting incremental single-edge insert/delete — rebuilding it after every toggle would make
MCMC catastrophically slow. `nwergm` therefore uses `NWdef`'s sparse accessors only for reading
the *observed* network once at setup time (and for validation/metadata), and implements its own
lightweight, toggle-friendly adjacency representation (Mata associative arrays via `asarray()`,
giving expected O(1) neighbor/edge-existence queries and updates) for the actual MCMC state —
documented in `docs/ERGM_ARCHITECTURE.md`.

## 8. Control parameters (`R/control.ergm.R`)

Confirms the control surface `nwergm` should expose a *subset* of (Part XIV): MCMC burn-in
(`MCMC.burnin`), interval/thinning (`MCMC.interval`), sample size (`MCMC.samplesize`), number of
MCMLE iterations (`MCMLE.maxit`), initial-value method (`init.method`, defaults to MPLE),
proposal type (`MCMC.prop`, defaults to TNT for unconstrained binary networks), step-length
controls (`MCMLE.steplength`, `MCMLE.steplength.margin`), convergence-test type
(`MCMLE.termination`), and a verbosity level. `nwergm`'s own default values are set to be
directly comparable where the underlying algorithm is the same (see
`docs/ERGM_ARCHITECTURE.md`'s control-defaults table for the exact correspondence and any
deliberate differences).

## Appendix A: Full R-level architecture study (detailed reference)

The following is the complete, detailed R-architecture study this document's own §1-2 and §4-5 summarize. Produced from a direct, independent read of `R/model.R`, `R/InitErgmTerm*.R`, `R/check.ErgmTerm.R`, `R/mple.R`, `R/mcmle.R`, `R/stepping.R`, `R/mcmc_se.R`, `R/nonidentifiability.R`, and `R/control.ergm.R`.

## 1. Top-level flow: `ergm(formula, ...)` (`R/ergm.R`)

```
ergm(formula, reference=~Bernoulli, constraints=~., offset.coef=NULL,
     target.stats=NULL, estimate=c("MLE","MPLE","CD"), control=control.ergm(), ...)
```

Sequence (all in `ergm()` / `ergm.fit()`):

1. `estimate` selects `control$main.method`: `"MPLE"` → skip init, main.method="MPLE";
   `"CD"` → main.method="CD"; else default main.method is `"MCMLE"` (or
   `"Stochastic-Approximation"`, alternate).
2. `set.seed(control$seed)` if given — **this is ergm's only reproducibility hook**;
   there is no separate internal RNG stream bridged from R.
3. Extract `nw` from LHS of formula. Build MH proposal(s) for the constrained
   sample space (`.init_ergm_proposal`) — one for the full space, one for the
   observed/missing-data space (`obs.constraints`, default `~.-observed`, i.e.
   integrate only over missing dyads).
4. **`model <- ergm_model(formula, nw, ...)`** — builds the `ergm_model` object
   (see §2/§3 below). This is the single most important data structure: it is
   passed to every subsequent stage unchanged.
5. Compute `info`: `terms_dind` (are ALL terms dyad-independent?),
   `space_dind` (is the constraint/sample-space itself dyad-independent?),
   `MPLE_is_MLE` = `reference=="Bernoulli" && terms_dind && space_dind && !force.main`.
   **If `MPLE_is_MLE` is TRUE, ergm silently uses plain MPLE as the exact MLE and
   never runs MCMC at all** — this is the "edges + nodematch + nodecov" case:
   dyad-independent models never need MCMC.
6. If `target.stats` given: run `san()` (simulated annealing) to build a network
   matching the target statistics, replace `nw` with it. (nwergm v1 can skip
   `target.stats`/SAN entirely — defer.)
7. Pick `init.method` (defaults to MPLE unless space is not dyad-independent, in
   which case MPLE is removed from the candidate list and a different reference
   default is used — for Bernoulli reference this doesn't arise).
8. `ergm.checkextreme.model()`: statistics at their theoretical min/max on the
   observed network get **dropped** (coefficient fixed at ±Inf) if
   `control$drop=TRUE` (default) — e.g. an all-present-or-all-absent nodematch
   category. **This must exist in nwergm v1** — it is a common real-data failure
   mode (e.g. edges term with 0 or 100% observed density, or nodematch on a
   category with only one node).
9. `ergm.fit()`: single-impute missing dyads if any, build the `ergm_state`
   (network + model + proposal + a `stats` offset vector = observed-vs-target
   shift, almost always zero), then dispatch on `main.method`:
   `"MPLE"` → `ergm.mple()`; `"MCMLE"` → `ergm.MCMLE()`;
   `"Stochastic-Approximation"` → `ergm.stocapprox()`; `"CD"` → `ergm.CD.fixed()`.
10. Post-fit: optionally evaluate the log-likelihood via **bridge sampling**
    (`eval.loglik`, default TRUE) — this is a separate, expensive path-integral
    estimate of the actual normalizing constant ratio, NOT needed for point
    estimates/SEs. **Defer entirely for nwergm v1** — report an approximate/NA
    log-likelihood instead, exactly as ergm itself documents ("approximate
    change in log-likelihood in the last iteration" is available for free from
    MCMLE; the bridge-sampled absolute log-likelihood is a separate optional
    feature).

### `ergm` fit object fields worth mirroring in `e()` results
`coef`, `sample` (mcmc.list of centered stats), `iterations`, `MCMCtheta`,
`loglikelihood` (approx, free), `gradient`, `covar`, `failure`, `coef.init`,
`est.cov`, `coef.hist`/`steplen.hist`/`stats.hist` (MCMLE iteration trace),
`etamap`, `offset`, `drop`, `estimable`, `info$terms_dind`/`space_dind`, `null.lik`.

## 2. `ergm_model` object (`R/model.R`)

`ergm_model(formula, nw, ...)` dispatches on formula → `list_rhs.formula` (splits
`y ~ a + b + offset(c)` into a `term_list`) → `ergm_model.term_list`:

- For each RHS term, detect `offset(...)` wrapper, then call
  **`call.ErgmTerm(term, env, nw, term.options=...)`**, which:
  - Looks up `InitErgmTerm.<name>` (binary) or `InitWtErgmTerm.<name>` (valued;
    chosen once via `is.valued(nw)` for the WHOLE model — binary and valued
    terms cannot be mixed).
  - Builds a call `f(nw, arglist, term.options...)` and evaluates it in the
    formula's own environment (so terms can reference variables in the caller's
    scope, e.g. `nodematch(sex_var)` where `sex_var` is an R object, not just a
    network attribute name — **nwergm can skip this generality**: attribute
    names should just be Stata varnames).
  - Post-processes the returned list: fills `dependence` default TRUE,
    `pkgname` auto-detected, attaches `aux.slots` for terms needing auxiliary
    network representations (nwergm v1: **no auxiliaries needed** for
    edges/mutual/nodematch/nodecov/edgecov/gwesp/gwdegree — auxiliaries exist
    for shared-partner *caching* across multiple sp-terms, an optimization to
    defer).
  - Coerces `inputs`→double, `iinputs`→integer (the C-side parameter vectors).
- `updatemodel.ErgmTerm()` appends the term's `minval`/`maxval` (padded to
  `-Inf`/`+Inf` if absent) and the term list itself to `model$terms`.
- After all terms: `ergm.auxstorage()` (skip — no auxiliaries in v1),
  **`model$etamap <- ergm.etamap(model)`** (builds theta→eta mapping —
  identity for fixed-decay/non-curved terms, the GW map/gradient for curved
  ones; see §4), `model$uid <- .GUID()`.
- Offset decoration: renames `coef.names` for offset terms to
  `"offset(name)"` for display.

### `ergm_model` object fields
`terms` (list, one entry per initialized term = the raw `InitErgmTerm.*` return
value, i.e. this list itself doubles as the **term registry entries for THIS
model instance**), `etamap`, `term.options`, `uid`, `minval`/`maxval` (vectors,
one per canonical statistic), `offset` (logical vector).

## 3. The `InitErgmTerm.*` return-value contract

Every `InitErgmTerm.<name>(nw, arglist, ...)` function must return `NULL`
(term contributes nothing — silently dropped with a message) or a list with:

| field | required? | meaning |
|---|---|---|
| `name` | **yes** | Name of the **C changestat function** to call (`c_<name>` in C source) — NOT necessarily the same as the R term name (e.g. R term `gwesp` → C function family `dgwesp`/`dgwespdist` depending on fixed/curved). |
| `coef.names` | **yes** | Character vector, one per **canonical** (eta-space) statistic contributed. Length = number of columns this term adds to the sufficient-statistic vector. |
| `inputs` | no | `double` vector passed verbatim to the C function (node covariates, decay params, dyadic covariate matrices flattened). |
| `iinputs` | no | `integer` vector, same idea (type codes, level codes, node indices). |
| `params` | no | For **curved** terms only: a *named* list, one entry per **theta-space** (non-canonical) parameter; `NULL` entries mean "this theta IS estimated", non-NULL entries mean "this theta is fixed at this numeric value" (e.g. gwesp's `decay` when `fixed=TRUE` is NOT curved at all — it only becomes `params=list(stat=NULL, stat.decay=fixed_decay_value)` when `fixed=FALSE`, i.e. **curved = decay itself is estimated**). |
| `map` | needed if curved | `function(theta_free, n, ...) -> eta_vector` mapping the term's own theta parameters to its `n` canonical statistics' eta coefficients. |
| `gradient` | needed if curved | `function(theta_free, n, ...) -> matrix` (d eta_i / d theta_j), used for the delta-method variance transform and for the MCMLE eta-space optimization step. |
| `minval`/`maxval` | no | Per-canonical-statistic theoretical bounds on the observed network (used by the extreme-value "drop" check). |
| `emptynwstats` | no | Value of the statistic on the empty network (nonzero e.g. for `edges` under a non-Bernoulli reference, or `nsp`/`dsp` at `d=0`). |
| `dependence` | no (default TRUE) | `FALSE` marks the term dyad-independent — enables MPLE=MLE shortcut, and lets ergm skip MCMC entirely if ALL terms + constraints are dyad-independent. **Every one of nwergm's v1 dyadic/nodal-covariate terms (edges, nodematch, nodecov, nodefactor, edgecov, nodeicov/nodeocov/nodeifactor/nodeofactor) sets this FALSE. `mutual`, `gwesp`, `gwdegree` do NOT set it (default TRUE = dependent).** |
| `conflicts.constraints` | no | Declares this term is redundant with a same-named sample-space constraint (skip in v1 — no constraint system yet). |
| `auxiliaries` | no | One-sided formula requesting shared auxiliary network representations (skip in v1). |
| `pkgname` | no | Auto-detected shared-library name housing the C symbol; **this is nwergm's plugin-file analogue** — every term must declare which compiled kernel provides its C symbol. |

`ergm_GWDECAY` (`R/InitErgmTerm.R:70-82`) is the **exact reusable curved-parameter
spec every GW term shares** — reproduce its math (not its code) precisely:

```
map(x, n):       eta_i = x[1] * exp(x[2] + log1mexp(-log1mexp(x[2]) * i)),  i = 1..n
gradient(x, n):  a = log1mexp(x[2]); w_i = exp(x[2] + log1mexp(-a*i))
                 d(eta_i)/d(x[1]) = w_i
                 d(eta_i)/d(x[2]) = x[1] * (w_i - i*exp(a*(i-1)))
minpar: x[2] >= 0  (x[1] unconstrained)
```
where `x[1]` is the GW term's own reported coefficient and `x[2]` relates to
the decay `alpha` via `x[2] = log(alpha)`... **actually verify by direct
numerical comparison against R** (`ergm:::ergm_GWDECAY$map`) rather than
re-deriving algebraically — the important point for nwergm is that **fixed
decay (v1's scope) needs NONE of this**: fixed-decay gwesp/gwdegree collapse to
a single canonical statistic = the geometrically-weighted SUM computed directly
in the change-statistic (see `changestats_dgw_sp.c`/C study notes), with
`eta = theta` (identity map, non-curved). The curved map above is only needed
when `fixed=FALSE` (decay itself estimated) — **out of scope for nwergm v1 per
the user's own brief**, but the architecture (a `map`/`gradient` slot on the
term, defaulting to identity) should exist from day one so adding curved-decay
later requires no redesign.

## 4. `check.ErgmTerm()` contract (`R/check.ErgmTerm.R`)

Every `InitErgmTerm.*` calls this FIRST. It:
1. Rejects the term outright if `directed`/`bipartite` arguments (declared by
   the calling `InitErgmTerm.*`, e.g. `mutual` passes `directed=TRUE`) don't
   match the actual network — **this is the exact "return informative errors
   for unsupported types" mechanism the nwergm term registry needs**: each
   term declares directed-required / directed-forbidden / bipartite-required /
   bipartite-forbidden as three-valued flags (`TRUE`/`FALSE`/`NULL`=either).
2. Always rejects directed+bipartite combined (ergm never supports this at
   all, regardless of term).
3. Builds a synthetic function whose formal arguments are `varnames` with
   `defaultvalues`, marks which were `missing()` (→ `attr(out,"missing")`),
   and `do.call`s it with the user's `arglist` — this is really just "named
   argument matching with defaults + missingness tracking", reimplementable
   directly as Stata option parsing (Stata's own `syntax` already does this
   natively and better — **nwergm does NOT need an R-`check.ErgmTerm`-style
   helper; Stata's own option-parsing conventions replace it entirely**, one
   term-suboption per architecturally-distinct term argument).
4. Validates each argument's type against `vartypes` (comma-separated allowed
   R classes) — again, subsumed by Stata's own typed option syntax.
5. Attribute arguments (e.g. `nodematch("sex")`) are NOT resolved here — that
   happens inside each `InitErgmTerm.*` via `ergm_get_vattr(attrarg, nw)`,
   which pulls the named vertex attribute off the `network` object. **nwergm's
   analogue: read a Stata variable by name from the current dataset, aligned
   to node order** (nwcommands already has exactly this convention via
   `nw_syntax`/attribute variable lookups used elsewhere in the package).

## 5. MPLE (`R/mple.R`, `ergmMPLE.R`)

Core idea (Hunter & Handcock 2006, cited directly in the source): construct,
for every "informative" dyad `(i,j)` (all dyads unless a dyad-dependent
constraint restricts the sample space), a row = **the vector of change
statistics `Δg(y)_{ij}` for toggling that dyad**, with response
`y = 1[edge (i,j) present]`. Then:

```
logit P(Y_ij=1 | Y_-ij) = theta' * Δg_ij(y)
```

is fit as an ordinary **weighted logistic regression** (`glm(y ~ Δg - 1,
family=binomial, weights=...)`, `R/mple.R:103`) — dyads with IDENTICAL change
statistic rows are pre-aggregated (`weights` = count) before the GLM, a
significant and easy performance win for symmetric/repeated-pattern terms.
For curved models or models with explicit parameter bounds, a custom BFGS
logistic regression (`ergm.logitreg`, `optim(method="BFGS")` on the binomial
deviance) is used instead of `glm()` — **nwergm should use Stata's native
`logit`/`_ml`-based fitting for the standard (non-curved v1) case exactly as
the user's own brief suggests** (Part XII), reserving a from-scratch IRLS/BFGS
only if curved terms are added later.

`is.dyad.independent(model)` gates whether MPLE == exact MLE (§1 step 5) — for
nwergm v1's term set, this is TRUE iff the model contains ONLY
edges/nodematch/nodecov/nodefactor/edgecov/nodeicov/nodeocov/nodeifactor/
nodeofactor (all `dependence=FALSE`) and NEITHER `mutual` NOR any `gwesp`/
`gwdegree` term is present (both are dyad-dependent by default).

MPLE existence check (`mple.existence`, Konis 2007): a **linear program**
testing for perfect separation (no MPLE exists if a hyperplane perfectly
separates present/absent dyads in change-statistic space). Good defensive
check to port; not blocking for v1 correctness.

MPLE covariance: for dyad-INDEPENDENT models, plain GLM `cov.unscaled`
(inverse Fisher information) IS the correct MLE covariance. For
dyad-DEPENDENT models fit via `estimate="MPLE"` explicitly (not the
`MPLE_is_MLE` shortcut), ergm optionally computes a **Godambe/sandwich
correction** (`control$MPLE.covariance.method`) via extra simulation — this
is a genuinely separate, harder feature; nwergm v1 can simply label
dyad-dependent MPLE runs' SEs as "naive/GLM, NOT sandwich-corrected" (the
user's brief explicitly requires labeling MPLE as pseudolikelihood, not MLE).

## 6. MCMLE (`R/mcmle.R` — the hardest, most important file)

This is a **Geyer & Thompson (1992) Monte Carlo MLE** with a specific,
carefully engineered step-length control (Hummel, Hunter & Handcock 2012) and
several selectable convergence tests. High-level loop (`ergm.MCMLE`,
`for(iteration in 1:control$MCMLE.maxit)`):

```
mcmc.init <- init                      # from MPLE
repeat up to MCMLE.maxit times:
    z <- ergm_MCMC_sample(s, control, theta=mcmc.init)   # draw statsmatrix at mcmc.init
    esteq <- ergm.estfun(statsmatrices, theta=mcmc.init, model)  # canonical-space centering
    check_nonidentifiability(esteq, ...)                 # QR-rank check, see §8
    steplen <- .Hummel.steplength(esteq, esteq.obs, margin=0.05, max=1)   # see below
    v <- ergm.estimate(init=mcmc.init, model, control,
                        statsmatrices, steplen=steplen)   # theta update, see below
    coef.hist <- rbind(coef.hist, coef(v))
    # convergence test selects one of: confidence (DEFAULT) | Hummel | Hotelling | precision | none
    if (converged) break
    mcmc.init <- coef(v)
```

### 6a. Step length: Hummel et al. (2012) via convex-hull shrinkage

Motivation: a raw Newton step using the current MCMC sample's mean/covariance
can be wildly wrong if `mcmc.init` is far from the MLE (the sample may not
even contain the observed statistics' region). Instead of a fixed damping
factor, ergm computes the **largest γ ∈ (0,1]** such that shrinking the
sampled statistics toward the observed target (origin, since already
centered) by factor γ keeps every point (and, with `margin`, a slightly
inflated version) **inside the convex hull of the untouched sample** —
solved via a **linear program per test point** (`shrink_into_CH`,
`R/stepping.R:150`): minimize `p'z` subject to `Mz >= -1`, giving the
signed distance-to-boundary `-1/objective`; γ = min over all test points'
distances, capped at `steplength.max=1`. This is genuinely an LP-per-point
algorithm (uses `Rglpk` or `lpSolveAPI`), with a PCA-whitening preprocessing
step to make the LP numerically well-conditioned and a fast/approximate path
that subsamples to the `x2.num.max` (default `max(2·ncol,30)`) farthest
points when the constrained (`.obs`) sample is large.

Once γ is found, **`ergm.estimate()`'s theta update itself SHRINKS the
sampled statistics matrix toward `(1-γ)·statsmean`** before computing the
importance-sampling-reweighted mean/covariance used for the Newton step
(`R/mcmle_update.R:66-71`, `.shift_scale_points` in `stepping.R:17`) — i.e.
the step length doesn't scale a gradient step directly; it dampens by
making the "apparent" observed-vs-simulated gap smaller before solving.

**Recommendation for nwergm v1**: implement the LP-based Hummel step length
faithfully if a Stata/Mata LP solver is readily available (Mata has no
built-in general LP solver — would need either a small custom LP routine, or
approximate via a simpler bounded-line-search: try γ=1, and geometrically
back off (e.g. γ ← γ/2) while checking a cheaper approximate criterion,
such as "is the observed target within X standard deviations of the shrunk
sample's mean/covariance ellipse" instead of the exact convex-hull LP). This
should be flagged explicitly as a documented, deliberate simplification if
taken — it is the single hardest piece of ergm to reproduce exactly.

### 6b. Theta update: importance-sampling MC-MLE (`ergm.estimate`, `R/mcmle_update.R`)

Standard Geyer-Thompson: having a sample `X_1..X_n ~ P_theta0`, the
log-likelihood-ratio surface `l(theta) - l(theta0) = (theta-theta0)'g(y_obs) -
log E_theta0[exp((eta(theta)-eta(theta0))'g(X))]` is approximated by replacing
the expectation with its importance-sampling estimate from the MCMC sample,
then MAXIMIZED (Newton-Raphson on this surrogate). ergm supports several
"metrics" for this surrogate (`control$MCMLE.metric`, default **`"lognormal"`**
first in the vector): `lognormal` assumes `eta'g(X)` is approximately normal
across the sample (a log-normal correction term is added to stabilize the
IS-weight variance — this is what makes it more robust than naive IS when the
sample is far from theta), `naive`/`median`/`logtaylor` are alternatives.
`IS_weights()` (`R/mcmc_se.R:161`) computes un-normalized importance weights
`exp((eta-eta0)'x_i)` (numerically shifted by the max for stability).

**Recommendation for nwergm v1**: implement the "naive"/direct Newton step on
`av = weighted mean of centered stats`, `V = weighted covariance`, i.e. solve
`V * delta_eta = -av` (equivalent to one step of Fisher scoring using the
sample covariance as the observed-information proxy) — this is the simplest
metric and is a completely standard, well-documented MCMLE building block
(it is literally the classical Geyer-Thompson Newton step); the lognormal
correction is a refinement that can be added once the naive version is
certified against Statnet.

### 6c. Convergence tests (`control$MCMLE.termination`, default **`"confidence"`**)

Five options, precise defaults/behavior:

- **`"confidence"` (DEFAULT)**: after each iteration, if the estimating
  equation's Mahalanobis distance from zero (on a "tolerance-region" precision
  scale, `target_prec()`) is `< 2`, run a formal **Hotelling T² test**
  (`confidence_test()`, `R/mcmle.R:584`) of "estimating function == 0" at
  `control$MCMLE.confidence=0.99`; if p-value indicates convergence
  (`pval < 1-confidence`), STOP; else boost MCMC sample size by
  `MCMLE.confidence.boost=2` (bounded, `^MCMLE.sampsize.boost.pow=0.5` scaling)
  and continue, unless the estimating equation hasn't improved for
  `MCMLE.confidence.boost.lag=4` iterations more than
  `MCMLE.confidence.boost.threshold=1` times.
- **`"Hummel"`**: stop when the Hummel step length itself converges to
  `1.0` on two CONSECUTIVE iterations (i.e., the model is no longer being
  meaningfully damped — evidence the sample already brackets the MLE); boosts
  sample size (`MCMLE.last.boost=4`) once before requiring the second
  confirmation.
- **`"Hotelling"`**: simpler two-sample Hotelling test
  (`approx.hotelling.diff.test`) between constrained/unconstrained estimating
  functions, threshold `MCMLE.conv.min.pval=0.5`, needs two consecutive
  "no evidence of nonconvergence" hits.
- **`"precision"`**: stop when the relative loss of precision due to Monte
  Carlo error (`MCMLE.MCMC.precision`, default `0.05` for confidence-style,
  `0.005` otherwise) in the standard errors is small enough, twice in a row;
  otherwise scale up MCMC sample size/burn-in by the shortfall factor.
- **`"none"`**: run exactly `MCMLE.maxit` iterations, no early stop.

**Hard failure conditions** (not just "keep iterating"): simulated network
edge count exceeding observed by `MCMLE.density.guard=exp(3)≈20.1`× → hard
`stop()` ("strong indicator of model degeneracy"); estimating-function sample
with **zero variance in every column** (`all(cols_constant(esteq))`) → hard
stop ("did not mix at all"); step length stuck near its floor
(`MCMLE.steplength.min=0.0001`) for 2+ iterations → hard stop ("estimation
stuck... excessive correlation between model terms"); hitting `MCMLE.maxit`
(default **60**) without convergence → non-fatal warning, returns the
last iterate with an explicit "did not converge" message (never silently
reports as converged) — **all four of these are exactly the "detect/report
signs of degeneracy" behaviors required by the user's brief and should be
ported as literal, named checks**, even though the precise numeric procedure
around each can be simplified.

**Recommendation for nwergm v1**: implement `"Hummel"`-style OR a simplified
fixed-iteration-count-with-Hotelling-style-check termination (simpler to
verify against Statnet: run the SAME number of iterations Statnet used on a
canonical test model, compare coefficient trajectories directly, rather than
independently re-deriving a convergence rule that then needs its OWN
certification against Statnet's numerically-different rule).

## 7. Final variance-covariance matrix (`R/mcmc_se.R`, `ergm.MCMCse`)

A **sandwich/Godambe-type estimator**, not a naive inverse-Hessian:

```
Bread^-1 ("H")   = importance-sampling-reweighted SAMPLE COVARIANCE of the
                   canonical sufficient statistics at the final theta
                   (lweighted.var(gsim, IS-log-weights))
Meat ("cov.zbar") = variance of the (IS-)weighted sample MEAN, but with an
                   AUTOCORRELATION-ADJUSTED long-run variance
                   (vcov_wmean_ar -> spectrum0.mvar, i.e. a spectral-density-
                   at-zero-frequency / HAC-Newey-West-style estimator that
                   inflates the naive variance by the sample's own MCMC
                   integrated autocorrelation time)
mc.cov (variance of theta-hat) = sandwich_sginv(-H, cov.zbar)   # ~ H^-1 * Meat * H^-1
```

This is the ONE piece where a naive Mata implementation (plain inverse of the
raw sample covariance, ignoring MCMC serial correlation) would give
systematically TOO-SMALL standard errors — **the autocorrelation correction on
the sample mean's variance is not optional for a "serious first
implementation"**; a basic batch-means or lag-window spectral estimator
(`spectrum0.mvar`'s role) should be implemented even in a simplified MCMLE,
using the effective-sample-size machinery already needed for MCMC diagnostics
(Part XIX of the user's brief) — same underlying computation serves both.

## 8. Nonidentifiability / degeneracy detection (`R/nonidentifiability.R`)

`check_nonidentifiability(x, theta, model, tol=1e-10)`:
1. Compute `v = cov(x)` (statistics) or `crossprod(x)` (MPLE covariates).
2. **Nonvarying check**: any statistic with `diag(v)==0` → warns ("may indicate
   the observed data occupies an extreme point... or a dead-end
   configuration"). Direct, cheap, should be run EVERY iteration.
3. **Linear-dependence check** (`ergm_lindep`, QR decomposition with
   tolerance): find the rank-deficient subspace of `v` via `qr(v, tol=tol)`,
   express the dependent columns as exact linear combinations of the
   independent ones, report as human-readable equations
   ("term_a + term_b = CONSTANT") — a genuinely useful diagnostic message,
   directly portable to Mata (`qrd()` + rank detection via pivoted
   diagonal-of-R magnitude against `tol`).
4. Action per finding is one of `"message"|"warning"|"error"`
   (`MPLE.nonvar`/`MPLE.nonident` default `"warning"`;
   `MCMLE.nonvar` default `"message"`, `MCMLE.nonident` default `"warning"`).

## 9. `control.ergm()` full default inventory (`R/control.ergm.R:523-690`)

Organized by category (defaults as literally coded; `NULL` defaults are almost
always then computed adaptively — noted where relevant):

**Initial method / MPLE**
`init.method=NULL` (→ MPLE unless space not dyad-indep), `MPLE.type="glm"`
(alternatives `"penalized"`,`"logitreg"`), `MPLE.maxit=10000`,
`MPLE.nonvar="warning"`, `MPLE.nonident="warning"`, `MPLE.nonident.tol=1e-10`,
`MPLE.covariance.method="invHess"`, `MPLE.check="glpk"` (existence-LP solver,
falls back to `"lpsolve"`), `MPLE.constraints.ignore=FALSE`.

**Main method**
`main.method="MCMLE"` (alt. `"Stochastic-Approximation"`), `force.main=FALSE`,
`main.hessian=TRUE`.

**MCMC sampling** (used for both MCMLE-internal sampling and standalone
`simulate()`)
`MCMC.prop=~sparse + .triadic` (**default proposal is "sparse" — i.e. **NOT**
naive uniform-dyad toggling**; see C-side notes for what `sparse`/TNT actually
means), `MCMC.interval=NULL` (adaptive if `MCMC.effectiveSize` set, else a
fixed default computed elsewhere ~ a small multiple of dyad count),
`MCMC.burnin = 16 * MCMC.interval`, `MCMC.samplesize=NULL`,
`MCMC.effectiveSize=NULL` (if set, switches to **adaptive ESS-targeted**
burn-in/interval selection rather than fixed counts — a materially more
sophisticated scheme, see `MCMC.effectiveSize.*` sub-params), `MCMC.maxedges=
Inf` (density guard), `MCMC.return.stats=4096` (thinning target for the
returned/diagnosable sample).

**MCMLE**
`MCMLE.termination="confidence"` (**DEFAULT** — alternatives `"Hummel"`,
`"Hotelling"`, `"precision"`, `"none"`), `MCMLE.maxit=60`,
`MCMLE.conv.min.pval=0.5` (Hotelling), `MCMLE.confidence=0.99` (confidence),
`MCMLE.confidence.boost=2`, `MCMLE.confidence.boost.threshold=1`,
`MCMLE.confidence.boost.lag=4`, `MCMLE.MCMC.precision=0.05` (confidence-style
default) `else 0.005`, `MCMLE.metric="lognormal"` (first of
lognormal/logtaylor/median/naive/...), `MCMLE.steplength.margin=0.05`,
`MCMLE.steplength = 1 if margin given else 0.5`, `MCMLE.sequential=TRUE`
(carry forward the final simulated network as the next iteration's start —
NOT restart from the original observed network each time),
`MCMLE.density.guard=exp(3)≈20.09`, `MCMLE.density.guard.min=10000`,
`MCMLE.effectiveSize=64` (target ESS per iteration when adaptive),
`MCMLE.interval=1024`, `MCMLE.burnin=1024*16=16384`,
`MCMLE.samplesize.per_theta=64`, `MCMLE.samplesize.min=512` (so
`MCMLE.samplesize = max(512, 64 * n_free_params)` when not explicit — **a
directly reusable formula for nwergm's own default sample-size control**),
`MCMLE.steplength.min=0.0001`, `MCMLE.last.boost=4`.

**Observational/missing-data variants**: every `MCMC.*`/`MCMLE.*` control has
an `obs.*` twin, generally scaled down by `obs.MCMC.mul=1/4` (smaller
constrained-sample chains) — **skip entirely for nwergm v1** (no missing-data
support planned).

**Reproducibility**: `seed=NULL` (passed straight to `set.seed()` once, at the
very top of `ergm()`) — confirms there is exactly ONE global RNG stream, no
special per-thread/per-plugin seeding beyond R's own `parallel` package
mechanics for `parallel>0`.

**SAN** (used only for `target.stats`): `SAN.maxit=4`, `SAN.nsteps.times=8` —
skip entirely for v1 (no `target.stats` support planned).

**Stochastic-Approximation** (`SA.*`): an entirely separate main-estimation
method (Robbins-Monro-style), not used by default (`main.method="MCMLE"`
default) — skip for v1, note as a roadmap alternative.

**CD** (Contrastive Divergence, `estimate="CD"`, experimental in ergm itself):
skip for v1.

## 10. What nwergm v1 should explicitly NOT attempt to match

- Bridge-sampling log-likelihood (`eval.loglik`) — report approximate
  log-likelihood-improvement only (free from the MCMLE loop itself), label
  clearly as approximate/relative, not an absolute log-likelihood.
- The exact Hummel LP-based step length — a documented simplification is
  acceptable (see §6a) if flagged and tested against Statnet's own step-length
  *trajectory* (not just final coefficients) on canonical models.
- `target.stats`/SAN, missing-data (`obs.*`) machinery, curved-decay GW terms,
  parallel/multi-thread MCMC, Stochastic-Approximation and CD main methods.
- Auxiliary-network machinery (shared-partner caching across multiple sp-terms)
  — v1 has at most one gwesp-family term active, so no sharing opportunity
  exists yet; the term API should still leave room for an `auxiliaries` slot.

## 11. Direct architectural translations for `nwergm`

| ergm concept | nwergm analogue |
|---|---|
| `InitErgmTerm.<name>` | Mata function/class registered under `<name>` in a term registry, returning a struct with the same conceptual fields (coef.names, inputs, dependence, minval/maxval, map/gradient placeholders) |
| `check.ErgmTerm` argument validation | Stata `syntax`/option parsing PLUS a per-term Mata `validate(nw)` call checking directed/undirected/bipartite support flags from the registry |
| `ergm_model` object | A Mata class/struct holding the term list + per-term coef-name offsets + minval/maxval + offset flags, built once per `nwergm` call |
| C changestat dispatch by `name=` string | Mata function-pointer array or a `switch`/registry dispatch by term-id, calling each term's own `statistic()`/`change()` Mata (later C) implementation |
| `set.seed()` → single RNG stream | Bridge to Stata's `set seed`/`runiform()` — no separate C RNG state unless/until a real C-plugin kernel is built, in which case seed it explicitly from a value drawn via Stata's own RNG at call time |
| MPLE via `glm()` | Stata's native `logit`/`_ml` machinery on the change-statistic design matrix |
| MCMLE Newton step (naive/lognormal metric) | Mata-side weighted mean/covariance + Newton step on eta; lognormal correction deferred |
| Godambe/sandwich SE with autocorrelation correction | Mata implementation of a lag-window (Newey-West-style) long-run variance estimator on the MCMC statistic stream, reused for both SEs and MCMC diagnostics (ESS) |
| `check_nonidentifiability` (QR rank) | Mata `qrd()`-based rank check on the sample covariance of statistics, same tolerance convention (1e-10) |

## Appendix B: Full C-level architecture study (detailed reference)

The following is the complete, detailed C-architecture study this document's own §2-3 and §7 summarize. Produced from a direct, independent read of `src/ergm_edgetree.h`, `src/ergm_changestat.h`, `src/changestats_spcache.c`, `src/changestats_dgw_sp.c`, `src/changestats.c`, `src/MCMC.c`, and `src/MHproposal*.c/.h`.


## 1. Network representation (`inst/include/ergm_edgetree.h`, `inc/ergm_edgetree*.h`)

`Network` is **not** an adjacency matrix and **not** a CSR/CSC sparse index. It
is a **per-vertex unbalanced binary search tree**, one tree per node per
direction:

```c
typedef struct TreeNode {
  Vertex value;   // neighbor at the other end
  Edge   parent, left, right;  // indices into the SAME edges[] array (0 = none)
} TreeNode;

typedef struct Network {
  TreeNode *inedges;    // inedges[i] is the ROOT of vertex i's in-neighbor BST
  TreeNode *outedges;   // outedges[i] is the ROOT of vertex i's out-neighbor BST
  Rboolean directed_flag;
  Vertex bipartite;      // 0 if not bipartite, else count of mode-1 nodes
  Vertex nnodes;
  Edge nedges, last_inedge, last_outedge, maxedges;
  Vertex *indegree, *outdegree;   // O(1) degree lookup, kept in sync on every toggle
  ... on_edge_change callback array (for auxiliary/cache invalidation, see §3)
} Network;
```

Both `inedges` and `outedges` are flat arrays sized `maxedges` (grown/reallocated
as needed); index 0 is a sentinel ("no edge"). For an **undirected** network,
only `outedges` is used and by convention every tie `{a,b}` is stored once as
`(min(a,b), max(a,b))` in `outedges` — `inedges` is unused, and `IS_UNDIRECTED_EDGE`
canonicalizes `(a,b)` to `(min,max)` before searching `outedges`.

Key operations and their real complexity (all **O(log d)** average / **O(d)**
worst case, where `d` = degree of the relevant node, since the tree is an
*unbalanced* BST with no rotation/rebalancing — insertion order determines
depth):

- `EdgetreeSearch(a,b,tree)` — walk down from `tree[a]` comparing `b` against
  node values (a plain BST search). This is `has_edge(a,b)`.
- `EdgetreeMinimum`/`Maximum`, `EdgetreeSuccessor`/`Predecessor` — standard BST
  in-order traversal primitives, used to enumerate a node's neighbors in
  **sorted vertex-id order** one at a time (`STEP_THROUGH_OUTEDGES` /
  `_INEDGES` macros), i.e. neighbor iteration is a generator, not a materialized
  list — O(1) amortized per step, O(degree) total per full walk.
- `ToggleEdge(tail,head,nwp)` — search; if found, delete (standard BST delete
  with successor-splice) and decrement degree/nedges; if absent, insert
  (standard BST insert at the found NULL leaf position) and increment.
  **O(log d)** average.
- `GetEdge(tail,head,nwp)` = weighted `EdgetreeSearch` (returns 0/weight).

**Design implication for Mata**: an unbalanced-BST-per-node is not a natural
Mata data structure. The behaviourally equivalent, idiomatic Mata choice is
**one `asarray()` (hash map) per node holding its neighbor set**, plus a
**global `asarray()` keyed by the packed dyad id** `(i-1)*n+j` for O(1)
`has_edge`/`edge_weight`, plus plain Mata vectors for `outdegree`/`indegree`
(kept in sync on every toggle, exactly as ergm does). This gives O(1) average
`has_edge`/toggle/degree instead of ergm's O(log d) — a genuine, deliberate
*improvement* on the reference architecture that Mata's `asarray()` makes free,
not a compromise. Neighbor enumeration becomes `asarray_keys()` on a node's own
set (O(degree), unordered — order doesn't matter for any of the terms below).

## 2. The changestat function-pointer contract (`inst/include/ergm_changestat.h`, `inc/ergm_changestat.h.template...`)

Each term is a `ModelTerm` struct holding **function pointers**, not a single
function — this is the key architectural fact to replicate as a Mata class
with equivalent methods:

```c
typedef struct ModelTerm {
  void (*i_func)(ModelTerm*, Network*);                                    // I: init
  void (*c_func)(Vertex tail, Vertex head, ModelTerm*, Network*, Rboolean edgestate); // C: change stat for ONE proposed toggle
  void (*u_func)(Vertex tail, Vertex head, ModelTerm*, Network*, Rboolean edgestate); // U: called AFTER a toggle is ACCEPTED — update caches
  void (*f_func)(ModelTerm*, Network*);                                    // F: finalize/free
  void (*s_func)(ModelTerm*, Network*);                                    // S: compute statistic FROM SCRATCH (full recomputation)
  void (*d_func)(...);   // legacy multi-toggle batch variant, deprecated in favour of c_func
  double *dstats;        // OUTPUT: this term's change-statistic vector (length nstats)
  double *inputparams, *iinputparams; // term's own constant parameters (e.g. decay, covariate values)
  void *storage; void **aux_storage;  // term-private / shared auxiliary cache pointers (see §3)
  unsigned int nstats, statspos;      // how many stats this term contributes, and its offset in the model's combined vector
} ModelTerm;
```

**This IS exactly the `initialise()/statistic()/change()/on_toggle()/destroy()`
API the task brief sketches** — ergm's own mature design converged on exactly
that split, which strongly validates using it verbatim as `nwergm`'s term
contract:

| ergm      | `nwergm` Mata method (proposed)     | called when |
|-----------|--------------------------------------|--------------|
| `i_func`  | `initialise(graph, params)`          | once, when the model is built |
| `c_func`  | `change(tail, head, edgestate)`      | every PROPOSED toggle (returns a vector of length `nstats`) |
| `u_func`  | `on_toggle(tail, head, edgestate)`   | only after a toggle is ACCEPTED — updates any term-private cache (e.g. GWESP's shared-partner map) |
| `f_func`  | `destroy()`                           | once, at teardown |
| `s_func`  | `statistic()`                         | full from-scratch recomputation — used for (a) initial network's observed statistic, (b) the reference/certification path (§9), (c) as a fallback so a lazy term author can get `change()` "for free" as `statistic(after) - statistic(before)` before writing a real incremental version |

`edgestate` (a boolean: does the edge already exist, i.e. is this toggle a
*removal*) is passed into **every** per-toggle call — this is the single most
important convention to copy: it means "change" functions never need to guess
add-vs-remove, and it is exactly why `mutual`'s check is `IS_OUTEDGE(head,tail)`
(the *reverse* edge) with the sign taken from `edgestate`, not from re-deriving
add/remove some other way.

The overall per-proposal flow (`MCMC.c`, see §5) is: build the toggle list →
for the model, sum every term's `c_func` output into one combined `Δstats`
vector → `ip = θ · Δstats` → Metropolis accept/reject → if accepted, call every
term's `u_func` (cache update) and commit the toggle; if rejected, discard.

## 3. Auxiliary/shared caches (`src/changestats_spcache.c`, `ergm_dyad_hashmap.h`)

Terms that need expensive derived state (shared-partner counts, two-path
counts) don't recompute it inline — they register a **shared, private
auxiliary network** (a `StoreStrictDyadMapUInt`, i.e. a **hash map from dyad
→ count**, built on `khash.h`) via their own `i_func`/`u_func`/`f_func` triple,
and the *consuming* term (e.g. `gwesp`) reads from that cache via
`GET_AUX_STORAGE`. This is a clean separation: the cache-maintenance term and
the statistic-computing term are different `ModelTerm`s wired together by the
R-level model-builder. For `nwergm` v1 this separation is more machinery than
needed — it is simplest (and still fully correct/efficient) to let `gwesp`
maintain its own shared-partner cache internally rather than factor it out as
a separate registered term; note this as a v2 refactor opportunity if a second
term ever wants to share the same cache (e.g. a future `dsp`/`nsp` term).

### The shared-partner cache itself (`i__utp_wtnet`/`u__utp_wtnet`, undirected case — this is the one `nwergm`'s v1 GWESP needs)

**Init** (`i__utp_wtnet`, O(m·davg) once at model setup): for every existing
edge `(i,j)`, for every other neighbor `k` of `i` (`k≠j`), `sp(j,k) += 1`; for
every other neighbor `k` of `j` (`k≠i`), `sp(i,k) += 1`. After this loop,
`sp(a,b)` = the number of common neighbors of `a` and `b`, for **every** pair
`(a,b)` that has at least one common neighbor (not just tied pairs — this is
essential: GWESP's own change statistic needs `sp` for pairs that are NOT
(yet) edges too).

**Update** (`u__utp_wtnet`, called only on an ACCEPTED toggle of `(tail,head)`,
O(degree(tail)+degree(head))): let `echange = edgestate ? -1 : +1`. For every
*current* neighbor `k` of `head` (`k≠tail`): `sp(tail,k) += echange`. For every
current neighbor `k` of `tail` (`k≠head`): `sp(head,k) += echange`. (Symmetric
in each pair, so `sp` only needs to be stored once per unordered pair.)

This O(degree) incremental maintenance — never a full O(n²) or O(m) recount —
is the single most important performance idea to replicate.

## 4. Change-statistic formulas actually implemented

All of the following use the `ECHANGE(x) = edgestate ? -x : +x` convention
(the statistic's own definitional building block, signed once at the end
rather than branched throughout):

- **`edges`**: `Δ = ECHANGE(1)`. Trivial; `s_func` returns the current edge count.
- **`mutual`** (directed only): `Δ = 0` unless the *reverse* edge `(head,tail)`
  already exists (`IS_OUTEDGE(head,tail)`), in which case `Δ = ECHANGE(1)`.
  This is the "fast reverse-edge lookup" the task brief asks for —
  `has_edge(head,tail)` is the entire mechanism.
- **`nodecov(x)`** (undirected/one-mode): `Δ = ECHANGE(x[tail] + x[head])` —
  the *sum* of both endpoints' covariate values. Directed variants exist and
  are semantically different, not just "the same but on a digraph":
  - **`nodeicov(x)`**: `Δ = ECHANGE(x[head])` only (in-covariate: sender's value
    doesn't matter, only the receiver's — this is the "receiver effect" of a
    continuous covariate).
  - **`nodeocov(x)`**: `Δ = ECHANGE(x[tail])` only (sender's value only).
  - Plain undirected `nodecov` is the natural v1 case; `nodeicov`/`nodeocov`
    are trivial variants once `nodecov` exists (this directly matches the task
    brief's instruction that all four directed actor-covariate effects should
    be "trivial additions later" if the API is designed right — confirmed: it
    is exactly the same code with a different endpoint selected).
- **`nodefactor(categorical x)`**: for each endpoint, if its category maps to
  a modeled level, `CHANGE_STAT[level] += ECHANGE(1)` — i.e. **both** endpoints
  contribute independently (unlike nodematch, this doesn't require a match).
  `nodeifactor`/`nodeofactor` are the same restricted to head-only / tail-only.
- **`nodematch(categorical x, diff=FALSE)`**: `Δ = 0` unless
  `x[tail] == x[head]`, in which case `Δ = ECHANGE(1)` (one combined
  statistic). With `diff=TRUE`, there is one statistic per level and only the
  matching level's slot gets `ECHANGE(1)`.
- **`edgecov(W)`**: `Δ = ECHANGE(W[tail,head])` — a direct lookup into a
  precomputed dense covariate matrix flattened into `INPUT_ATTRIB` at term-init
  time (ergm always densifies edgecov's input matrix once, up front; this is
  fine for the moderate network sizes this package already targets — see
  `docs/SPARSE_BACKEND.md`'s own precedent of accepting O(n²) for
  moderate-scale commands).
- **`gwdegree(decay)`** (undirected): let `d(v)` be `v`'s degree *not counting*
  the toggled edge (`DEG(v) - edgestate`, i.e. always "the degree on the side
  of the toggle that doesn't include it"). Then
  `Δ = echange · [(1-e^{-decay})^{d(tail)} + (1-e^{-decay})^{d(head)}]`,
  `echange = edgestate ? -1 : +1`. (Derivation: a node's own total contribution
  to the statistic is `f(d) = e^{decay}·(1-(1-e^{-decay})^d)`, and
  `f(d+1)-f(d) = (1-e^{-decay})^d` exactly — confirmed algebraically, matches
  the C code exactly.) **`gwidegree`**/**`gwodegree`** (directed): identical
  formula but using only `head`'s in-degree / `tail`'s out-degree respectively
  (only one term, not summed over both endpoints — reciprocal ties don't
  double-count for these).
- **`gwesp(alpha)`** (undirected `UTP` variant — the only one v1 needs; ergm
  also has directed `OTP`/`ITP`/`RTP`/`OSP`/`ISP` variants sharing the same
  cache machinery, correctly deferred): using the shared-partner cache `sp`
  from §3, for a proposed toggle of `(tail,head)` with current `edgestate`:
  1. `L2th = sp(tail,head)` (pre-toggle common-neighbor count of the dyad
     itself — 0 if never computed, i.e. no common neighbors).
  2. `focal = e^{alpha}·(1-(1-e^{-alpha})^{L2th})` — the new/removed edge's own
     contribution *as an edge* with `L2th` shared partners.
  3. For every node `u` that is a **current common neighbor of both** `tail`
     and `head` (walk `head`'s neighbor set, filter to those also adjacent to
     `tail` — O(degree(head))): let `L2tu = sp(tail,u)`, `L2uh = sp(u,head)`
     (both pre-toggle, from cache). Add
     `(1-e^{-alpha})^{L2tu-edgestate} + (1-e^{-alpha})^{L2uh-edgestate}` to a
     running `cumchange` — these are the *existing* edges `(tail,u)` and
     `(u,head)` each gaining/losing one shared partner because of this toggle.
  4. `cumchange += focal`; final `Δ = edgestate ? -cumchange : cumchange`.

  This is the exact, verified-by-derivation formula (matches
  `changestats_dgw_sp.c`'s `espUTP_change`/`gw_calc` macros precisely — the
  per-path term `(1-e^{-alpha})^{L2-edgestate}` and the focal term
  `e^{alpha}(1-(1-e^{-alpha})^{L2th})` were both independently re-derived from
  the standard GWESP definition and checked against the C macros token by
  token). **`nwergm`'s GWESP term should implement precisely this** — it is
  the single hardest and most valuable piece of this study.

## 5. MCMC acceptance loop (`src/MCMC.c.template.do_not_include_directly.h`, function `MetropolisHastings`)

Per step: `MHp->p_func` proposes a toggle list (§6) and sets `MHp->logratio`
(0 for a symmetric proposal); the model sums every term's `c_func` into a
combined `Δstats` vector (`m->workspace`); `ip = θ · Δstats` (plain dot
product, `θ` = current natural parameter vector `eta`); `cutoff = ip +
MHp->logratio`; **accept iff `cutoff ≥ 0` or `log(uniform(0,1)) < cutoff`**
(standard log-space MH accept/reject, textbook — nothing exotic). On accept:
commit the toggle to the network, call every term's `u_func`, and add
`Δstats` to the running sampled-statistics vector (which starts at the
*observed* network's statistic and accumulates the *change* at each accepted
step — i.e. the sample is stored as raw statistic levels, not deviations, by
initializing the running total to the observed value before burn-in). On
reject: discard, no state change at all. `MCMCSample` wraps this: run
`burnin` steps discarding output, then for `samplesize` draws run `interval`
steps each, recording the statistic vector after each block.

## 6. MHproposal contract (`inst/include/ergm_MHproposal.h`) and TNT

```c
#define MH_P_FN(a) void a (MHProposal *MHp, Network *nwp)   // propose: fill toggle list + logratio
#define MH_U_FN(a) void a (Vertex tail, Vertex head, MHProposal*, Network*, Rboolean edgestate) // rarely used, proposal-side bookkeeping
#define MH_I_FN(a) void a (MHProposal *MHp, Network *nwp)   // init (allocate proposal-private storage)
#define MH_F_FN(a) void a (MHProposal *MHp, Network *nwp)   // finalize
```

A proposal only needs to (1) pick a toggle (or toggle list) and (2) set
`MHp->logratio` to the log Hastings correction for its own selection
asymmetry — it never touches change statistics or the model at all. This is
already the clean separation the task brief asks for
(`ErgmProposal.propose()/log_ratio()`, independent of terms).

**Basic/uniform proposal**: pick a uniformly random dyad; `logratio = 0`
(symmetric).

**TNT (tie/no-tie)**, exact formulas from `ergm_MHproposal.h`
(`P = 0.5` fixed, `Q = 1-P`, `D` = total dyad count, `E` = current edge count
*before* this proposal, `DP = P·D`, `DO = DP/Q`):

- With probability `P`: pick a uniformly random **existing edge** (always a
  removal proposal). Log-ratio: `E==1 ? -log(DP+Q) : log(E/(DO+E))`.
- With probability `Q=1-P`: pick a uniformly random **dyad** (any of the `D`
  possible dyads, tie or not).
  - If it turns out to already be an edge (removal proposal reached via the
    "dyad" branch instead of the "edge" branch): **same** log-ratio formula as
    above (`E==1 ? -log(DP+Q) : log(E/(DO+E))`) — the combined forward density
    of reaching this exact removal is identical regardless of which branch
    produced it, so the correction collapses to one formula.
  - If it's a non-edge (an addition proposal): log-ratio
    `E==0 ? log(DP+Q) : log(1 + DO/(E+1))`.

TNT's whole point: on a sparse network, a *uniform* dyad proposal almost never
lands on an existing tie, so removal moves are proposed vanishingly rarely and
mixing is poor; TNT deliberately proposes "remove a tie" and "toggle a random
dyad" with comparable frequency (via the `P`/`Q` mixture) and then corrects
the acceptance ratio for the resulting non-uniform proposal density via the
formulas above. **This is important to implement early** per the task brief —
it is a ~15-line addition once uniform-dyad and uniform-edge sampling both
exist (uniform-edge sampling itself needs O(1) "pick the k-th edge" — trivial
with an `asarray`-of-edges-plus-count representation, or just reservoir-sample
over the edge hash map).

## 7. Practical guidance for `nwergm`'s Mata graph/term design

1. Represent the mutable ERGM working graph as its **own** lightweight Mata
   class (call it e.g. `ErgmGraph`), separate from `NWdef` — `NWdef`'s CSR
   sparse index is rebuilt wholesale (`build_sparse_index()`, O(n+m)) rather
   than incrementally maintained, which is fine for the rest of `nwcommands`
   (static analysis, rare mutation) but would make every single MCMC toggle
   O(n+m) instead of O(1)/O(degree) — catastrophic for millions of proposals.
   Build `ErgmGraph` **from** an `NWdef`'s edgelist/attributes at model-setup
   time (reusing `NWdef`'s existing accessors for that one-time read), but
   let it own independent `asarray()`-based adjacency for the MCMC's sake.
2. Give every term a Mata class implementing `initialise/statistic/change/
   on_toggle/destroy`, matching ergm's I/S/C/U/F split exactly (§2 table) —
   this is a mature, battle-tested API, not a guess.
3. `edgestate` must be threaded through every per-toggle call, exactly as
   ergm does — resist the temptation to have `change()` "figure out" add vs.
   remove some other way (e.g. from an ambient random-graph diff); asking the
   caller for it is what makes `mutual`/`gwesp`/`gwdegree` simple.
4. Reference/certification path: since `statistic()` (the `S`-equivalent) is
   required for every term anyway (initial value, degeneracy-safe fallback),
   the "slow reference implementation" the task brief's Part IX asks for is
   free: `change_reference(tail,head,edgestate) := statistic(toggle(g)) -
   statistic(g)`. Every term's fast `change()` should be checked against this
   on random small graphs as the permanent certification suite.
