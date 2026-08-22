# nwergm extension roadmap

Living document. Started 2026-08-22, alongside the first `nwergm` implementation.

This is the prioritised list of what `nwergm` v1 deliberately does NOT include,
for future work. v1's own scope (what it DOES include) is documented in
`docs/CERTIFICATION.md`'s own `nwergm` harmonisation entries and in
`nwergm.ado`'s embedded SMCL help. See `docs/ERGM_ARCHITECTURE.md` for how to
add any of these without rewriting the estimator - that is the whole point of
the term/proposal/constraint API design.

## Ranking key

Each item is ranked on three axes, each High/Medium/Low:
- **Usage** - how often applied researchers reach for this in practice.
- **Effort** - implementation cost given v1's existing infrastructure.
- **Infra value** - how much reusable machinery it forces into existence
  that benefits other future items too.

## Term families (highest priority first)

| Item | Usage | Effort | Infra value | Notes |
|---|---|---|---|---|
| `nodefactor()` | High | Low | Low | Directed-agnostic per-category main effect; nearly free once `nodematch`'s attribute-resolution machinery exists (same `check.ErgmTerm`-equivalent attribute lookup, different statistic). |
| `nodemix()` | High | Medium | Low | Full mixing-matrix effect; needs a "levels x levels" coefficient block, a genuine but bounded extension of `nodematch`'s categorical machinery. |
| `nodeifactor()`/`nodeofactor()` | High (directed research) | Low | Low | Directed sender/receiver category effects - deferred from v1 only to keep the initial release small; the term API already anticipates these (see `nodecov`'s own directed-semantics design note in the architecture doc). |
| GWDSP (geometrically weighted dyadwise shared partners) | Medium | Medium | High | Shares the exact shared-partner cache `gwesp` v1 builds - this is the most "nearly free" post-v1 addition. |
| Directed GWESP variants (ITP/OTP/OSP/ISP beyond v1's default) | Medium | Medium | Medium | v1 ships one directed shared-partner definition (matching Statnet's own directed default); the others are the same cache with a different neighbor-direction rule. |
| `gwnsp` (geometrically weighted nonedgewise shared partners) | Low-Medium | Medium | Medium | Same cache family as GWESP/GWDSP. |
| Plain triangle / k-star / alternating-k-star family | Medium (mostly superseded by GW terms in modern practice) | Low-Medium | Low | Statnet itself now recommends GW terms over these for degeneracy reasons; still useful for teaching/replication of older models. |
| `isolates` | Low-Medium | Low | Low | A simple degree==0 count; trivial once `degree()` is available (already is, via the existing sparse accessor). |
| `concurrent` / concurrency terms | Medium (esp. epidemiology) | Low-Medium | Low | Degree>=2 count and variants; same primitive as `isolates`. |
| Two-path / `dsp/esp` non-geometric variants | Low | Low-Medium | Low | Rarely used un-weighted; mostly superseded by GW terms. |
| Degree distribution terms (`degree(d)`, `idegree(d)`, `odegree(d)`) | Medium | Low-Medium | Low | Direct degree-sequence indicator terms. |
| Bipartite terms (`b1nodematch`, `b1star`, `b2star`, bipartite GWESP analogues) | Medium (two-mode research) | High | High | Blocked on native bipartite dyad-space support in the proposal/constraint layer - see "Two-mode ERGMs" below; do not attempt term-by-term before that infrastructure exists. |
| Curved parameters beyond fixed-decay GW terms (free/estimated decay) | Medium | High | High | Needs the `eta`-map (theta -> curved-parameter linking function) and its Jacobian in the MCMLE loop - a real architectural addition, not a term-only change; see `docs/ERGM_ARCHITECTURE.md`'s own "Curved parameters" section for the hook already left in the term interface. |
| User-defined/custom terms | Medium (power users) | Medium | High | The term registry (`docs/ERGM_ARCHITECTURE.md`) is designed so this is "write a term following the documented contract, then register it" - a dedicated `nwergm` "how to add a term" tutorial is the main remaining work, not new estimator code. |

## Estimation/inference extensions

| Item | Usage | Effort | Infra value | Notes |
|---|---|---|---|---|
| QAPSPP-style / alternative variance estimators | Low-Medium | Medium | Low | v1 ships the Statnet-style MC-corrected sandwich estimator; alternatives are a self-contained addition to the variance-computation stage only. |
| Curved-parameter MCMLE (see above) | Medium | High | High | Shared with the curved-term item above. |
| Additional MH proposals (`MH_TNT` is v1's main sparse-network proposal; add e.g. constrained-degree proposals, block-restricted proposals) | Medium | Medium | High | The proposal API (`docs/ERGM_ARCHITECTURE.md`) is built precisely so a new proposal is a self-contained object; no estimator changes needed. |
| Constraints beyond v1's "free binary dyad space" (fixed density, degree constraints, block restrictions, allowable-dyads mask, egocentric constraints) | Medium-High | Medium-High | High | The sample-space/proposal separation in the architecture doc anticipates this; each constraint pairs with one or more compatible proposals. |
| Offsets/fixed-coefficient terms beyond v1's minimal support | Medium | Low-Medium | Medium | v1's model object already carries an `isfixed` flag per term (see architecture doc); wiring it fully through MCMLE's Newton step is the remaining work. |
| Parallel/multi-chain MCMC | Low-Medium (mostly a performance want, not correctness) | High | Medium | Meaningful only after the C/C++ performance kernel exists (see Performance below) - parallelising Mata-level MCMC has limited payoff. |

## Network-type extensions

| Item | Usage | Effort | Infra value | Notes |
|---|---|---|---|---|
| Two-mode (bipartite) ERGMs | Medium-High (two-mode is common in this package's own user base) | High | High | Needs its own dyad-space definition (only cross-mode dyads are togglable), its own proposal, and its own term family (see Bipartite terms above). v1 explicitly refuses two-mode networks with an informative error rather than silently projecting - do not build bipartite terms before the dyad-space/proposal layer exists, or they will need rework. |
| Valued/weighted ERGMs | Medium | High | High | A materially different statistical framework (reference measures, valued change statistics) - Statnet ships this as a large, separate subsystem (`wt*.c`/`InitWtErgmTerm.R` etc.) for exactly this reason. Track as a genuinely separate future initiative, not an incremental v1 addition. |
| Signed ERGMs | Low-Medium | High | Medium | No mature, settled statistical framework in the field comparable to valued ERGMs; lower priority until the literature matures further. |
| Temporal/TERGM/STERGM/relational-event models | Medium-High (this package already has temporal metadata groundwork) | Very high | High | Explicitly out of scope per this task's own instructions. `nwergm` v1 requires an explicit static slice of any temporal network and never silently collapses time. A future `nwtergm`-style command is a separate, large initiative that would reuse `nwergm`'s term/proposal API as its own foundation. |

## Diagnostics / GOF extensions

| Item | Usage | Effort | Infra value | Notes |
|---|---|---|---|---|
| Full `mcmc.diagnostics()`-equivalent (Geweke/Heidelberger-Welch style formal tests, not just descriptive traces) | Medium | Medium | Low | v1 ships descriptive MCMC diagnostics (trace summary, autocorrelation, acceptance rate, ESS); formal convergence hypothesis tests are a bounded follow-on. |
| Richer GOF statistic families (triad census for directed models, full geodesic-distance distribution) | Medium | Low-Medium | Low | v1's GOF reuses `nwdegree`/`nwdistance`-style existing `nw*` commands for a modest first set; extending the comparison set is mostly "call another existing `nw*` command inside the same simulation loop". |

## Performance

| Item | Usage | Effort | Infra value | Notes |
|---|---|---|---|---|
| C/C++ MCMC kernel (Stata plugin, `stplugin.h`/`stplugin.c`) | High (for networks beyond a few hundred nodes at realistic MCMC sample sizes) | High | High | v1 deliberately ships a pure-Mata kernel (associative-array-backed sparse graph, per PART XXXVI's own "do not move ordinary functionality into C merely for ideological reasons" and PART XXXVII's own scope discipline) and profiles it first. This is the top performance-track item once profiling (done as part of v1's own acceptance criteria) identifies the real hot loop - almost certainly the per-toggle change-statistic evaluation inside the MH accept/reject loop. Build as a single "run N MCMC steps, return sampled statistics" native call (see architecture doc's "Stata/Mata to C boundary" principle) - never a per-toggle Stata<->C round trip. |
| Cross-platform plugin builds (macOS Intel/ARM, Windows, Linux) | High (once a C kernel exists at all) | Medium | Low | Pure build/packaging work once the C kernel above exists; keep source + build scripts in the repository, never ship a Mac-only binary. |
| Incremental shared-partner cache for GWESP (`ErgmGraph::common_neighbors()` currently recomputes on demand, O(min(deg_i,deg_j)) per pair, every time `change_gwesp()`/`stat_gwesp()` needs a shared-partner count) | Medium (matters once networks/MCMC sample sizes grow past the moderate scale v1 targets) | Low-Medium | Medium | A genuine, deliberate v1 simplification, not an oversight - the incremental-cache version (an `asarray()`-keyed shared-partner count, updated O(degree) per accepted toggle instead of recomputed) was independently prototyped and certified during this session's own development (2,800+ random toggles, zero mismatches against full recomputation) but not adopted into the shipped v1 file, since the simpler on-demand version is already correct and v1's own scope discipline (`docs/CERTIFICATION.md`'s own unit-68 entry) explicitly defers this exact optimization until profiling shows it matters. Swapping it in later needs no change to `change_gwesp()`'s own call signature. |

## Explicitly out of scope for the foreseeable future (per the governing task)

- Full parity with Statnet's ~150 term-computing algorithms - never a goal; this package targets a small, well-certified, extensible core.
- Reproducing Statnet's entire constraint/hint/auxiliary-network system.
- A general-purpose curved-exponential-family framework beyond the fixed-decay GW terms and the documented extension hook.
