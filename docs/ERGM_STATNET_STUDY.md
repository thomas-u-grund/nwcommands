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
