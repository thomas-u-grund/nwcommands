# nwergm developer architecture

This is the developer-facing design document for `nwergm`'s native ERGM
estimator, forward-referenced from `unw_ergm.do`'s own header comment,
`nwergm.ado`'s SMCL help, `docs/ERGM_PROVENANCE.md`, and
`docs/ERGM_STATNET_STUDY.md`. It documents how the system is put together
and, concretely, how to extend it — in particular how to add a new ERGM
term without touching the estimator, sampler, MPLE builder, or MCMLE
controller.

See `docs/ERGM_STATNET_STUDY.md` for the Statnet `ergm` architecture this
implementation used as a behavioural/architectural reference, and
`docs/ERGM_PROVENANCE.md` for the licensing/attribution account (clean-room
reimplementation against published statistical definitions — no `ergm`
source, comment, or identifier is copied anywhere in this codebase).
`docs/ERGM_ROADMAP.md` lists what is deliberately deferred past v1.

## File layout

- `unw_ergm.do` — the Mata core: `ErgmGraph`, `ErgmTermData`, the term
  function pairs, `ErgmModel`, the certification helper, the MCMC engine
  and proposal functions, and `ErgmMCMLE`. Compiled into the same
  `lib/lnwcommands.mlib` as `unw_core.do` (see `lib/build.do`, which
  sources this file immediately after `unw_core.do` before creating the
  library) — kept as a separate source file because the ERGM subsystem is
  architecturally self-contained, not because it needs a different build
  step.
- `nwergm.ado` — the Stata-facing `eclass` command: network-type
  validation, the NWdef→`ErgmGraph` bridge, term-option parsing (builds an
  `ErgmModel` from the user's requested options), MPLE-vs-MCMLE dispatch,
  and `ereturn` result posting.
- `nwergm_estat.ado` — postestimation (`estat mcmcdiag`, `estat gof`),
  dispatched via `e(estat_cmd)` (set by `nwergm.ado`), not the
  `<cmd>_estat`-by-bare-convention some other Stata packages use — see
  the "adding a new `estat` subcommand" note below.
- `cscripts/test_nwergm_statistics.do` / `test_nwergm_changestat.do` /
  `test_nwergm_mple.do` / `test_nwergm_mcmc.do` / `test_nwergm_mcmle.do` /
  `test_nwergm_ado.do` — the permanent certification suite, one file per
  subsystem layer (statistics → change statistics → MPLE → MCMC →
  MCMLE → the `.ado` glue), each with a production-mode copy under
  `lib/cscripts_prod/`.
- `dev/ergm_reference/` — development-only R scripts (never shipped) that
  print real Statnet `ergm`/`ergmMPLE` output, hand-transcribed as literal
  constants into the certification tests above.

## Why a separate graph representation from NWdef

`NWdef`'s own sparse index (`build_sparse_index()`) rebuilds the entire
CSR structure from scratch on every change — `O(n + nnz)` per rebuild.
That is fine for a network that changes rarely (the package's normal use
case) but is catastrophic for MCMC, which toggles a single edge millions
of times over the course of one estimation. `ErgmGraph` (below) instead
gives each node its own Mata associative array (`asarray()`) as an
`O(1)`-average adjacency set, supporting genuine incremental
toggle/lookup — the same lesson Statnet's own C `edgetree` (a per-node
binary search tree) encodes for the same reason, confirmed directly from
its source during this project's own Statnet study
(`docs/ERGM_STATNET_STUDY.md` Appendix B §2).

`ErgmGraph` is read from the current `NWdef` network exactly once, via
`ergm_bridge_from_netobj()` (a file-scope Mata function defined at the
bottom of `nwergm.ado`, called once per `nwergm` invocation). After that
single read, `ErgmGraph` never touches `NWdef` again — the two
representations are fully decoupled, by design.

## `ErgmGraph`: mutable MCMC graph state

```
class ErgmGraph {
    real scalar n, directed, nties
    pointer rowvector adjout, adjin   // asarray-handle adjacency sets
    real colvector dout, din          // degree bookkeeping

    void init(n, directed)
    real scalar has_edge(i, j)
    void toggle(i, j)
    real rowvector neighbors_out(i) / neighbors_in(i)
    real scalar degree_out(i) / degree_in(i) / degree_total(i)
    real scalar common_neighbors(i, j)
    real matrix all_ties()
}
```

For an undirected graph, `adjin` is simply aliased to `adjout` (a tie is
stored symmetrically in both endpoints' own `adjout`), avoiding a second,
redundant set of arrays. `common_neighbors(i,j)` iterates whichever of
`i`/`j` has the smaller neighbor set — `O(min(deg_i, deg_j))`, not `O(n)`.
`all_ties()` materializes the full tie list as an `nties × 2` matrix
(`O(n + nties)`) and is deliberately used only outside the MCMC inner loop
(model setup, certification, MPLE design construction) — never per
proposal.

## `ErgmTermData`: the generic per-term-instance container

Mata cannot dispatch polymorphically the way C++ virtual classes can, so
every term instance shares one small struct-like class rather than each
term defining its own:

```
class ErgmTermData {
    real scalar decay        // gwesp / gwdegree / gwodegree / gwidegree
    real colvector attr      // nodematch / nodecov / nodeicov / nodeocov
    real matrix edgecovmat   // edgecov: dense n x n dyadic covariate
}
```

A term's own `statistic()`/`change()` functions read only the fields they
actually need. This is the "C struct" alternative the governing design
brief explicitly permitted in place of a class hierarchy — see the next
section for why function pointers, not virtual methods, are the actual
dispatch mechanism.

## The term API contract

Every ERGM term is a **pair of plain Mata functions** with a fixed
signature, registered by name in an `ErgmModel` (not looked up through any
central "registry" data structure — see below for why):

```
real rowvector statistic(class ErgmGraph scalar G, class ErgmTermData scalar td)
    -> current value of this term's statistic(s) (length = the term's own
       npar) on the whole graph G.

real rowvector change(class ErgmGraph scalar G, real scalar i, real scalar j,
                       class ErgmTermData scalar td)
    -> the SIGNED effect on this term's statistic(s) of toggling dyad
       (i,j). G is NOT yet toggled when this is called — has_edge(i,j)
       still reflects the PRE-toggle state, and the returned value is
       "new − old" for whichever toggle direction is actually about to
       happen (i.e. if the dyad is currently tied, this is the value of
       REMOVING it; if untied, the value of ADDING it).
```

This mirrors the `i_func`/`s_func`/`c_func`/`u_func`/`f_func`
function-pointer contract found in Statnet's own C `ModelTerm` struct
(`docs/ERGM_STATNET_STUDY.md` Appendix B §3) — confirmed during this
project's own study to be the right shape for this problem, not
independently reinvented. `nwergm`'s v1 scope only needs the `S`
(statistic) and `C` (change) halves; there is no per-term
initialize/destroy step because `ErgmTermData` construction and
population happens once, in `nwergm.ado`'s own option-parsing code,
before the model is ever handed to the sampler.

**Every term must satisfy one invariant, and it is checked by machine, not
just asserted in a comment**: for every dyad and every reachable graph
state, `change()`'s return value must exactly equal
`statistic(after toggle) − statistic(before toggle)`. This is what
`ErgmCertifyChangeStat()` (below) checks by brute force, and every term in
the codebase is certified against it (`cscripts/test_nwergm_changestat.do`)
before being trusted by the sampler, MPLE, or MCMLE.

### The 8 v1 terms

`edges`, `mutual` (directed), `nodematch()` (exact categorical match),
`nodecov()` (undirected-style symmetric sum, also used for directed main
effect), `nodeocov()`/`nodeicov()` (directed sender-only/receiver-only),
`edgecov()` (dense dyadic covariate), `gwdegree()`/`gwodegree()`/
`gwidegree()` (fixed-decay geometrically weighted degree family, sharing
one kernel function `gw_kernel()`), `gwesp()` (fixed-decay geometrically
weighted edgewise shared partners, undirected only in v1). See
`unw_ergm.do`'s own per-term header comments for the exact statistical
definition and change-statistic derivation of each.

## `ErgmModel`: the term list, and why there is no separate "registry"

```
class ErgmModel {
    real scalar nterms
    string rowvector names, coefnames
    real rowvector npar
    pointer rowvector statfn, chgfn, td

    void init()
    void addterm(name, npar, &statfn(), &chgfn(), td_instance, coefnames)
    real scalar nparam()
    real rowvector full_statistic(G)
    real rowvector full_change(G, i, j)
    real rowvector change_toward_one(G, i, j)
    real matrix build_mple_data(G)
}
```

`ErgmModel` is an ordered list of term *instances* (not term *types* — a
model can, in principle, include the same term type twice with different
`ErgmTermData`, e.g. `nodematch()` on two different attributes, each its
own instance with its own coefficient name). This is deliberately the
**only** place in the codebase that knows "a model is a list of terms":
the sampler (`ErgmMCMCSample`), the MPLE design builder
(`build_mple_data`), and the MCMLE controller (`ErgmMCMLE`) all call only
`full_statistic()`/`full_change()` — they never reference a term by name
and never need to change when a term is added.

There is no separate central "term registry" keyed by name/metadata (arg
count, directed/undirected support, curved-vs-fixed, etc.) as a distinct
data structure in `unw_ergm.do` itself — that validation metadata lives in
`nwergm.ado`'s own option-parsing code (e.g. the explicit
directed/undirected checks before each `addterm()` call), not in Mata.
This was a deliberate v1 simplification: with 8 terms, one dispatch site,
hand-written validation in the `.ado` layer is simpler and no less
correct than a generic metadata table would be. If the term count grows
substantially (see `docs/ERGM_ROADMAP.md`), promoting that per-term
directed/undirected/argument metadata into a genuine lookup table in
`nwergm.ado` (keyed by term name, consulted once at the top of option
parsing rather than duplicated as scattered `if` checks) is the natural
next step — nothing in `ErgmModel`'s own design would need to change for
that.

`change_toward_one()` and `build_mple_data()` exist on `ErgmModel` rather
than as free functions because they need the term list to compute
`full_change()` — see the MPLE section below for what they do.

## Certification: the "slow reference implementation"

```
real scalar ErgmCertifyChangeStat(class ErgmModel scalar M, class ErgmGraph scalar G)
```

For every dyad in `G` (skipping the diagonal, and only the upper triangle
for undirected graphs), this computes `full_statistic()` before toggling,
toggles, computes `full_statistic()` after, restores the graph, and
compares `(after − before)` against `full_change()`'s own claim — the
maximum absolute discrepancy across every dyad is the return value. This
**is** the "slow reference implementation" a permanent certification
suite needs (the governing design brief's own requirement) — it exists by
construction, not as a hand-written duplicate implementation that could
itself drift out of sync with the fast path. `cscripts/test_nwergm_changestat.do`
calls this across several random small networks (directed and undirected)
and asserts the result is numerically zero (~1e-14) for every registered
term, before any MCMC or estimation code is trusted to consume that
term's `change()`.

## MPLE

Maximum pseudolikelihood estimation (Hunter & Handcock 2006). For every
dyad `(i,j)`, `ErgmModel::change_toward_one(G,i,j)` gives the change
statistic in the fixed "toward tie present" direction (regardless of the
dyad's current state — `change()` itself is antisymmetric in the toggle
direction, so this is simply `full_change()` negated when the dyad is
currently tied). `build_mple_data(G)` stacks one such row per dyad plus
the observed tie indicator as a final column, into a single
`ndyads × (nparam+1)` matrix.

Fitting `logit P(Y_ij=1 | Y_-ij) = theta' * covariates_ij` on this design
recovers the MPLE `theta`. **The actual logistic regression is not done in
Mata** — `nwergm.ado` copies this matrix into a temporary Stata dataset
and calls Stata's own `logit ..., noconstant` (the governing design
brief's own explicit instruction: use Stata's native machinery rather than
reimplementing IRLS). `noconstant` because the `edges` term already plays
the role of an intercept; a second, redundant constant would make the
design rank-deficient.

MPLE is exactly the MLE when every term is dyad-independent and the
sample space is unconstrained (the same "MPLE is the MLE" shortcut
Statnet itself takes — `docs/ERGM_STATNET_STUDY.md` §1 step 5).
`nwergm.ado` auto-selects `method(mple)` precisely when the requested
model contains only dyad-independent terms (`edges`/`nodematch`/
`nodecov`/`nodeicov`/`nodeocov`/`edgecov`, no `mutual` or GW term), and
otherwise uses the MPLE fit as MCMLE's own starting value
(`theta0`).

## The proposal API and MCMC engine

A proposal is a plain Mata function with the fixed signature:

```
real rowvector fn(class ErgmGraph scalar G)
    -> (tail, head, logratio)
```

returning the proposed dyad and the log Hastings-ratio correction for its
own selection asymmetry (`0` for a symmetric proposal). Proposals know
nothing about terms or change statistics, and terms know nothing about
how a toggle was chosen — the same separation Statnet's own
`MHProposal`/`ModelTerm` split enforces
(`docs/ERGM_STATNET_STUDY.md` Appendix B §6), confirmed during this
project's own study as the right design rather than independently
reinvented. Two proposals ship in v1:

- `ergm_propose_uniform(G)` — pick any of the `D` possible dyads with
  equal probability. Symmetric (`logratio=0`). The simplest correct MH
  proposal, and the fallback `nwergm` ships alongside TNT.
- `ergm_propose_tnt(G)` — the TNT ("tie/no-tie") proposal (Morris,
  Handcock & Hunter 2008). With probability `P=0.5`, propose removing a
  uniformly random *existing* tie; otherwise propose a uniformly random
  dyad from the full dyad space. Dramatically improves mixing on sparse
  networks (where a uniform proposal would almost never touch an existing
  tie) — but requires the accompanying Hastings-ratio correction in
  `unw_ergm.do`'s own header comment on this function, without which the
  chain would target the wrong stationary distribution.

`ErgmMCMCSample(M, G, theta, burnin, interval, samplesize, proposalfn)`
is the actual Metropolis-Hastings loop: standard log-space accept/reject
(`cutoff = theta·chg' + logratio`; accept if `cutoff>=0` or
`ln(runiform()) < cutoff`), mutating `G` in place. It returns a
`samplesize × nparam` matrix of the model's sufficient statistics as
LEVELS (seeded from `G`'s own current statistic, not from zero) — matching
Statnet's own convention, and letting a caller compare sampled rows
directly against the observed network's own statistic.

**Adding a new proposal** (e.g. a future degree-constrained or
block-restricted one — see `docs/ERGM_ROADMAP.md`) means writing one such
function with the correct Hastings-ratio math for its own selection
asymmetry; `ErgmMCMCSample` itself never changes.

## MCMLE

`ErgmMCMLE(M, G, theta0, maxit, burnin, interval, samplesize, proposalfn, verbose)`
implements the Geyer & Thompson (1992) Monte Carlo MLE outer loop:
simulate at the current `theta`, take a Newton step using the simulated
sample's own mean/covariance of the *centered* statistics (centered on the
observed network's statistic — the target is exactly `Dbar=0`), and
continue sequentially (the network carries over between iterations rather
than restarting from the observed network each time, matching Statnet's
own `MCMLE.sequential=TRUE` default).

Two points are **deliberate, disclosed simplifications** relative to
Statnet's own considerably more elaborate machinery (both flagged in
`unw_ergm.do`'s own header comment on this function, not silently
different behavior):

1. **Step length** is a Mahalanobis-trust-region cap on the Newton step's
   own norm (in the metric of the simulated sample's covariance), rather
   than Hummel, Hunter & Handcock's (2012) exact convex-hull linear
   program — no general LP solver is available in Mata, and this
   project's own Statnet study explicitly recommended this substitute.
2. **Final variance-covariance** applies a simple per-dimension lag-1-
   autocorrelation inflation factor `(1+rho)/(1-rho)` to the final
   simulated sample's own covariance before inverting, rather than
   Statnet's full spectral/HAC long-run-variance estimator — still a
   genuine autocorrelation correction (not the naive, uncorrected
   covariance that would give systematically too-small standard errors),
   just a simpler one.

Convergence is declared when every component of the centered sample mean
is small relative to its own Monte Carlo standard error *and* the last
step was untruncated (`gamma==1`) — a simplified stand-in for Statnet's
own default "confidence" (Hotelling T²) termination test, disclosed the
same way. Both simplifications are certified, not merely asserted safe:
`cscripts/test_nwergm_mcmle.do` fits `edges + mutual` on a real network and
checks the result against real Statnet `ergm()` MCMLE output
(`dev/ergm_reference/ref_mcmle.R`) within Monte Carlo tolerance.

## The `.ado` integration layer

`nwergm.ado` is the only file that:

- Validates the network type (rejects two-mode, temporal, and
  valued/weighted networks outright — see Parts XXII–XXIV of the
  governing design brief — and rejects each directed-only/undirected-only
  term against a mismatched network).
- Bridges `NWdef` → `ErgmGraph` via `ergm_bridge_from_netobj()`, a
  file-scope Mata function defined once at the bottom of the file (guarded
  with `capture mata: mata drop ergm_bridge_from_netobj()` so redefining it
  on a second `nwergm` call doesn't error). It is file-scope rather than
  defined inline inside the program body because a nested Mata `for`/`if`
  construct does not parse reliably as a one-line interactive `mata:`
  command, and a multi-line `mata:...end` block inside a Stata loop breaks
  batch-mode execution — both confirmed the hard way during this
  implementation.
- Parses every term option into a sequence of `ErgmModel::addterm()` calls,
  building the corresponding `ErgmTermData` instance for each (populating
  `.attr`/`.decay`/`.edgecovmat` as appropriate) — this is where a new
  term's Stata-side wiring lives (see the extension walkthrough below).
- Auto-selects `method(mple)` vs `method(mcmle)` based on whether every
  requested term is dyad-independent, dispatches to the MPLE or MCMLE
  code path, and posts results via `ereturn post`.
- **Owns cleanup of every Mata object it creates.** Every `tempname` +
  one-line interactive `mata: X = ...` call creates a genuine, permanent
  Mata variable that Mata's own garbage collector never reclaims on its
  own (unlike a real Mata function's local variables) — the program
  accumulates each such tempname's expanded name into a running Stata
  local (`__ergm_matatemps`) as it creates it, then drops the entire list
  in one `mata: mata drop `__ergm_matatemps'` call at the very end. Missing
  this (as an earlier version of this file did, for all but three of these
  objects) leaks Mata objects into the ambient workspace on every call,
  eventually colliding with Mata objects Stata's own internal machinery
  allocates — see `docs/CERTIFICATION.md` unit 73 for the exact failure
  this caused (`estimates table` erroring with "Mata object __NNNNNN
  already exists") and its fix. **Any new tempname created inside
  `nwergm`'s program body that holds a genuine Mata object (as opposed to
  a Stata matrix/local) must be added to this list.**

## Postestimation: adding a new `estat` subcommand

`nwergm.ado` sets `ereturn local estat_cmd "nwergm_estat"` in both the MPLE
and MCMLE branches. Stata's own `estat.ado` reads `e(estat_cmd)` and, if
set, dispatches the entire `estat ...` command line to that program
(`nwergm_estat mcmcdiag, ...` for `estat mcmcdiag, ...`) — this is the
real, documented mechanism (confirmed by reading `estat.ado`'s own
source), not the "just name your program `<cmd>_estat`" convention some
other packages happen to also use as a coincidence of the same
mechanism.

**A genuinely non-obvious gotcha, found the hard way while building
`estat mcmcdiag`**: `nwergm_estat` is a thin dispatcher that calls a
separate `rclass` subroutine per subcommand (e.g.
`nwergm_estat_mcmcdiag`). A nested `rclass` program call does **not**
automatically propagate its own `r()` results back up through the calling
program once that program returns — Stata's `estat.ado` itself handles
this for its own call into `e(estat_cmd)` via an explicit `return add`
immediately afterward, and any command-specific dispatcher must do the
same for its own nested subcommand calls, or the subcommand's `r()`
results silently read back as missing (while the subcommand's own
`di`-based display output looks completely correct — this is what made it
non-obvious rather than a simple typo; confirmed via an isolated 2-level
`rclass`-nesting repro before concluding this was the actual cause). A
future subcommand (e.g. a `gof` subcommand — see `docs/ERGM_ROADMAP.md`)
must follow the same `nwergm_estat_mcmcdiag`/`return add` pattern
(`estat gof`, described next, already does).

Two further, genuinely non-obvious lessons surfaced while building
`estat gof`, worth knowing before writing another `.ado` file that needs
either of these:

- **A Mata function defined at one `.ado` file's own file scope is not
  reliably callable from a different `.ado` file's own, separate
  auto-load event** - even after the first file's own command has
  already run successfully earlier in the same session. Confirmed by
  direct trial: right after a successful `nwergm mynet, edges` call
  (which itself calls `ergm_bridge_from_netobj()` internally), a plain
  `capture mata: mata which ergm_bridge_from_netobj()` from the same
  session fails to resolve it - even though it is defined at
  `nwergm.ado`'s own file scope, guarded exactly like a normal file-scope
  helper. It reliably works from an explicit `run nwergm.ado` (as opposed
  to ordinary command auto-load) - which is why this was missed until a
  plain `cscript`-style dev-mode test exercised the real auto-load path,
  rather than an ad hoc scratch script using `run`. Fix: each `.ado`
  file that needs a shared file-scope Mata helper must define its own
  copy at its own file scope (`nwergm_estat.ado` has its own
  `nwergm_estat_bridge_from_netobj()`, identical logic to
  `ergm_bridge_from_netobj()`, distinct name) - this is not unwanted
  duplication, it is the only combination confirmed to work reliably
  under normal auto-load. Functions compiled into the `.mlib` library
  (`ErgmGraph`, `stat_edges()`, etc.) are NOT affected - Mata's own
  library-autoload mechanism is a completely different, reliable code
  path from `.ado` file-scope code.
- **`nwtriads.ado` has a genuine, pre-existing bug**, unrelated to
  `nwergm`: it crashes with "n not found - data already wide" (r(111))
  on any network with zero ties (confirmed via an isolated repro
  independent of `nwergm` entirely - `nwset, mat((0,0\0,0)) undirected
  name(x)` then `nwtriads x` reproduces it in a bare session). A
  simulated network hitting exactly zero ties is a real possibility
  during MCMC, so `estat gof` wraps every `nwtriads`/`nwgeodesic` call on
  a simulated network in `capture`, excluding that draw from the
  relevant average rather than crashing the whole command - the same
  discipline any future GOF-adjacent code should follow. Not fixed at
  the source (out of this subsystem's scope); see
  `docs/CERTIFICATION.md`'s Pending list for the full disclosure.
- **A related bug this uncovered, since fixed**: `nwergm.ado`'s own
  `e(ties)` was captured from `__nwergm_last_G.nties` after
  `ErgmMCMLE()` returned - but `__nwergm_last_G` is the live MCMC state,
  mutated throughout simulation, not a frozen copy of the observed
  network (see `ErgmGraph`'s own class comment). For any `method(mcmle)`
  fit, `e(ties)` was silently reporting the last simulated tie count,
  not the true observed one - caught only once `estat gof` needed a
  genuinely correct observed mean degree and its own "Observed" column
  didn't match the network by hand-inspection. Fixed by capturing the
  observed tie count into a Stata local immediately after
  `ergm_bridge_from_netobj()` runs (before any MCMC), and posting THAT
  value as `e(ties)` in both branches.

## How to add a new term

This is the concrete guarantee the architecture above exists to make: a
new term should never require touching `ErgmModel`, `ErgmMCMCSample`,
`ErgmMPLE`/`build_mple_data`, or `ErgmMCMLE`. Concretely, for a term with
no auxiliary parameters beyond what `ErgmTermData` already has fields for:

1. **Write the statistic/change function pair** in `unw_ergm.do`, inside
   the first `mata:...end` block (alongside the other term functions),
   with the exact `statistic(G, td)` / `change(G, i, j, td)` signatures
   from the term API section above. If the term needs a genuinely new kind
   of auxiliary data `ErgmTermData` has no field for, add one field to
   `ErgmTermData` (do not create a new class — see the section above on
   why).
2. **Verify the change statistic by hand** against the published
   statistical definition before trusting the certification helper alone
   — the certification helper only catches an *inconsistency* between
   `statistic()` and `change()`, not a case where both are consistently
   wrong relative to the actual ERGM literature definition.
3. **Add it to `nwergm.ado`**: a new option in the `syntax` line, any
   directed/undirected validation it needs (following the existing
   pattern for `mutual`/`gwodegree`/etc.), and one block building its
   `ErgmTermData` instance and calling
   `M.addterm("myterm", npar, &stat_myterm(), &change_myterm(), td, coefnames)`
   — following the existing per-term blocks exactly. If it creates any new
   Mata tempname objects, append each to `__ergm_matatemps` as described
   above.
4. **Certify it**: add the term to `cscripts/test_nwergm_changestat.do`'s
   own loop over registered terms (brute-force change-statistic check
   across several random small networks), and — where a real Statnet
   comparison is feasible — extend `dev/ergm_reference/ref_statistics.R`
   to print the same network's real Statnet statistic value and hardcode
   it into `cscripts/test_nwergm_statistics.do`.
5. **Document it**: add the term to `nwergm.ado`'s own SMCL help header
   (syntax, supported network types, any parameters) and to this file's
   "The 8 v1 terms" list (now 9).
6. **Run the full regression sweep** (`cscripts/*.do`, both dev mode via
   `do unw_core.do`/`do unw_ergm.do` and production mode against the
   recompiled `lib/lnwcommands.mlib`) before considering the term done —
   per this project's own established discipline, never move to certifying
   the next stage while a previous one is uncertified.

### Worked example: a demonstration term through this exact process

To prove this process actually works for someone who is not the original
author — not merely assert it — `unw_ergm.do` includes one deliberately
minimal, clearly-marked demonstration term, `istar2` (the undirected
2-star count, `sum_i C(deg(i), 2)`), built through exactly the steps
above and certified in its own dedicated test file,
`cscripts/test_nwergm_demoterm.do`. It is **not** wired into `nwergm.ado`'s
real option surface — it exists purely as a working, certified proof that
steps 1–2 and 4 above are sufficient to add a fully-working term, without
implying `istar2` is an officially supported v1 effect (2-star family
terms are, deliberately, on the roadmap rather than in v1 — see
`docs/ERGM_ROADMAP.md`). Its own header comment in `unw_ergm.do` walks
through the change-statistic derivation (toggling `(i,j)` changes only
`i`'s and `j`'s own 2-star contribution, each shifting by
`C(d±1,2) - C(d,2) = ±d` for the pre-toggle degree `d` — no third node is
affected, the same "changes only touch the endpoints' own local counts"
shape as `gwdegree`) as a template for a future real implementer to follow.
