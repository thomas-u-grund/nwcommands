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
    real matrix elist                 // live edge array (rows 1..nties valid)
    pointer scalar edgepos            // asarray: canonical (i,j) -> row in elist

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

`elist`/`edgepos` maintain a live array of every current tie (canonical
`(min,max)` pairs for undirected, `(tail,head)` for directed), updated
incrementally by `toggle()` — **not** rebuilt from the adjacency sets.
Adding a tie appends to `elist` (amortized O(1) via capacity doubling —
`elist` starts at a small fixed capacity and doubles whenever the live
count would exceed it, the standard dynamic-array growth trick); removing
one swaps the removed edge's row with the current last live row (found in
O(1) via `edgepos`, an `asarray` mapping each live tie to its own row
index) and shrinks the live count — no shifting or rebuilding of the rest
of the array. `all_ties()` is now simply `elist[1::nties, .]`, an O(nties)
slice. This replaced an earlier version where `all_ties()` reconstructed
the tie list from scratch by iterating every node's own adjacency set —
correct, but O(n + nties), and (see `docs/CERTIFICATION.md` harmonisation
unit 79) the single dominant cost in the entire sampler once anything
called it from inside the MCMC inner loop (the TNT proposal did, once per
proposal, just to pick one random existing tie — see the proposal section
below). Certified against an independent brute-force check (a from-scratch
`has_edge()` scan over every possible dyad, comparing set-equality against
`all_ties()`'s own output) across 1700 toggles on both directed and
undirected graphs.

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
  chain would target the wrong stationary distribution. The tie-pick
  itself is O(1) via `ErgmGraph`'s own live edge array (`elist`/
  `edgepos`, described above) — this used to call `all_ties()` to
  materialize the full tie list on every single proposal (O(n+nties)),
  measured (`docs/CERTIFICATION.md` unit 79) at ~185x the cost of the
  uniform proposal above at n=200 nodes; fixing it (unit 80) cut TNT's
  own per-step cost by ~129x, to within ~13% of the uniform proposal's
  own cost. The Q-branch (uniform dyad pick) was never affected — it was
  already O(1) via closed-form index unranking, never touching
  `all_ties()` at all.

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
   just a simpler one. A batch-means alternative (robust to any
   autocorrelation shape, not just AR(1)) was implemented and directly
   compared against real Statnet reference values across 8 seeds on this
   suite's own canonical network (`docs/CERTIFICATION.md` harmonisation
   unit 80) — the lag-1 correction landed tightly clustered around
   Statnet's own true value while batch-means (at nwergm's own default
   samplesize) was far noisier and often badly biased. Rejected on that
   direct evidence and removed rather than shipped as unused code; the
   finding is recorded in `ErgmMCMLE()`'s own header comment. Statnet's
   own full spectral/HAC estimator remains unattempted.

Convergence is declared via a genuine joint Hotelling's T² test (via its
exact F transformation, Mata's own `invF()`) that the centered sample
mean is statistically indistinguishable from the zero vector, *and* the
last step was untruncated (`gamma==1`) — matching the actual statistical
structure of Statnet's own default "confidence" termination method (a
joint test across all parameters simultaneously, at the same 99%
confidence level Statnet itself reports), not merely inspired by its
name. An earlier version of this test used a per-coordinate rule ("every
`|Dbar_k| < 0.5*se_k` simultaneously") that was a materially different,
needlessly conservative test — requiring every marginal coordinate to
individually clear its own threshold compounds probabilities across
parameters, so even an already-converged theta had only a modest
per-iteration chance of jointly clearing every coordinate under ordinary
Monte Carlo noise. This was found, and fixed, via a real head-to-head
benchmark against Statnet's own `ergm()` on identical data: the
per-coordinate rule needed 10–20 MCMLE iterations where Statnet needed 1
on the same network; the joint Hotelling test now typically needs 1–7 —
see `docs/ERGM_ROADMAP.md`'s own Performance section for the full
benchmark numbers (harmonisation unit 80). Both this and the step-length
simplification above are certified, not merely asserted safe:
`cscripts/test_nwergm_mcmle.do` fits `edges + mutual` on a real network and
checks the result against real Statnet `ergm()` MCMLE output
(`dev/ergm_reference/ref_mcmle.R`) within Monte Carlo tolerance, and
`dev/ergm_benchmark_r_vs_stata/` is a permanent, repeatable head-to-head
timing/coefficient comparison against a live R `ergm()` installation on a
shared exported network (see its own README).

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
- **Never routes a large, per-observation Mata matrix through an
  intermediate Stata MATRIX.** The MPLE design matrix
  (`ErgmModel::build_mple_data()`) is handed directly to `st_store()`
  from Mata — never to `st_matrix()`. Stata matrices are architected for
  small structures (coefficient vectors, VCV matrices), not bulk
  per-observation data: a bare `mata: st_matrix("x", J(999000,4,1.5))`
  call did not complete within 2 minutes (killed, not merely slow) in a
  direct isolated test, where the equivalent `st_store()` call on the
  identical data completed in 0.008 seconds. An earlier version of this
  file routed the MPLE design matrix through exactly that slow path
  (`st_matrix()` immediately after building it, then read back out of
  that same Stata matrix later just to feed `st_store()`) — invisible at
  the tiny scale (a handful of dyads) every existing certification
  network uses, but effectively hanging any directed model at a few
  hundred nodes or more (`docs/CERTIFICATION.md` unit 81 — found while
  building a 1000-node benchmark, which went from not completing after
  35+ minutes to 27.8 seconds once fixed). **Any future code path that
  moves a Mata matrix whose row count scales with the network (dyad
  count, tie count, node count) into Stata must go through `st_store()`
  onto dataset variables, never through `st_matrix()`.** A handful of
  scalars or a `nparam × nparam` covariance matrix is exactly the kind
  of small, fixed-size structure `st_matrix()` remains the right tool
  for (e.g. `e(b)`/`e(V)` themselves) — the distinction is whether the
  matrix's own size scales with the DATA rather than with the MODEL.

## Native (C) MCMC backend

Harmonisation unit 83 (`docs/CERTIFICATION.md`) relaxed this project's
earlier standing Mata-first default for `nwergm` specifically, after units
80-82's own evidence (the GWESP gap surviving both the TNT/MPLE fixes and a
correctly-reasoned-but-rejected shared-partner cache) pointed at Mata's own
per-call interpreter overhead, not an algorithmic gap, as the remaining
cause. This relaxation does **not** extend to the rest of `nwcommands`
(`nwdegree`/`nwcomponents`/`nwset`/general sparse-backend code stay on the
existing architecture per the user's own explicit scoping) and it does not
mean "rewrite nwergm in C" — the Mata implementation remains the reference
implementation, the correctness oracle, the fallback, and the only backend
available on any platform without a compiled plugin.

**Files**: `native/ergm_mcmc.c` (the kernel itself — read its own header
comment first, it carries the full evidence trail and design rationale in
more detail than this section repeats), `native/spi/` (StataCorp's own
official Stata Plugin Interface 3.0 headers, redistributed exactly as
published at stata.com/plugins for this purpose), `native/Makefile` (macOS
build, verified; Windows/Linux recipes documented, not yet built — no
toolchain was available). The compiled artifact lives at
`lib/plugins/ergm_mcmc.plugin`; `unw_ergm.do`'s `ErgmNativeAvailable()`
checks for it via `fileexists()` and never errors when it is absent.

**The boundary is crossed once per `ErgmMCMCSample()`/`ErgmMCMCSampleDiag()`
call** (i.e. once per MCMLE iteration) — the entire burnin+sampling loop
(propose, evaluate every active term, accept/reject, toggle, record) runs
inside a single `plugin call`. Crossing the Mata/native boundary once per
*proposal* (potentially millions of times per fit) would reintroduce
exactly the interpreter-crossing overhead this backend exists to eliminate
— never design a native term or proposal that requires per-step round
trips back into Mata.

**Scope is decided once per model, never inside the loop**:
`ErgmNativeSetup(M, proposal_code)` (called once by `nwergm.ado`, right
before `ErgmMCMLE()`) inspects `M`'s own term names and populates
`M.native_enabled`/`native_termcodes`/`native_decays`/`native_attr` — a
model using any term outside the native kernel's own set (currently:
`edges`, `mutual`, `nodematch`, `gwesp`) leaves `native_enabled` at its
`ErgmModel::init()` default of 0, and `ErgmMCMCSample()`/
`ErgmMCMCSampleDiag()`'s own top-of-function check falls straight through
to the original, completely unmodified Mata loop. These native-backend
config fields live on `ErgmModel` itself (not genuine Mata "global"
variables — `set matastrict on` does not support declaring those inside a
function body, confirmed by direct trial) purely because `M` already flows
through every relevant call and Mata class instances exhibit reference
semantics across calls, the same property `ErgmGraph::toggle()` already
relies on for sequential MCMLE.

**Data crossing the boundary**: the edge list (the one object whose size
scales with the network) goes through Stata dataset variables in a
dedicated, isolated frame (`st_addobs()`/`st_addvar()`/`st_store()`/
`SF_vdata()` on the C side) — never `st_matrix()`, per the package-wide
rule this section's own predecessor established (see the `.ado` integration
layer section above and `docs/SPARSE_BACKEND.md`). Small, model-scale data
(theta, term codes/decays, the observed statistic, MCMC control scalars)
crosses via one space-separated argument string, tokenized on the C side
with plain `strtok()`. Two Stata Plugin Interface contract details were
confirmed by direct trial rather than assumed from general SPI
documentation, and are load-bearing for anyone extending this file: the
plugin's exported C entry point must be named exactly `stata_call`
regardless of the Stata-side `program name, plugin` name chosen, and the
`plugin call ..., "args"` string arrives as a single `argv[0]` token, not
pre-split on whitespace.

**RNG and reproducibility**: the plugin uses a self-contained xorshift128+
generator, seeded once per call from a value the Mata caller draws via
`runiform()` — so a given `set seed` reproducibly drives the same native
run, satisfying the user's own explicit reproducibility requirement, but
the native and Mata backends do NOT share an RNG stream and will not
produce bit-identical sample paths for the same seed. This is disclosed and
deliberate: `cscripts/test_nwergm_native.do`'s own cross-certification
standard is statistical equivalence of sampled distributions (mean
agreement within an autocorrelation-corrected Monte Carlo standard error,
reusing `ergm_lag1_autocorr()`), not trajectory-level identity, matching
the user's own stated contract.

**No shared-partner cache in the native GWESP path**, deliberately: unit
82's own finding (cache maintenance cost exceeds lookup savings below
degree ~30-40 in Mata) has no logical reason to flip in compiled code, since
both sides of that tradeoff shrink together — the C kernel's GWESP change
statistic is a direct, correctness-preserving port of `common_neighbors()`'s
own on-demand neighbor-intersection approach. A future degree-adaptive
cache remains an open `docs/ERGM_ROADMAP.md` item, not implemented here.

### How to add a new native term

Mirrors the Mata term-extension walkthrough below, at the C level:

1. Add a `TERMCODE_*` constant in `native/ergm_mcmc.c`.
2. Add one `case` to `change_term()`'s `switch()` implementing the change
   statistic (the graph primitives it needs — `has_edge()`,
   `common_neighbors()`, `g->deg[i]` — are already available; add a new
   primitive only if the term genuinely needs one, following the existing
   O(1)/O(degree) discipline).
3. If the term needs per-node adjacency enumeration (like `gwesp`), set
   `need_adj` when that termcode is present during argument parsing.
4. Extend `ErgmNativeSetup()` in `unw_ergm.do` to recognize the term's own
   name pattern and map it to the new termcode.
5. Rebuild (`cd native && make macos`), add a cross-certification case to
   `cscripts/test_nwergm_native.do` (statistical-equivalence + self-
   consistency, exactly like the two existing cases), and re-run the full
   benchmark suite to confirm the term is actually worth native treatment
   before shipping it — per the user's own "decide term by term through
   profiling" instruction, not every future term needs or benefits from
   this.

The loop structure itself (`stata_call()`'s two `for` loops over
burnin/sampling) never needs to change for a new term — only the dispatch
table and argument-string layout grow.

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
