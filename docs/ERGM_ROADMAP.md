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
| `nwergm simulate` support for covariate-based terms (`nodematch()`/`nodecov()`/`nodeicov()`/`nodeocov()`/`edgecov()`) | Medium | Low | Low | v1's simulate interface (harmonisation unit 78) deliberately only supports terms needing no external covariate data (`edges`/`mutual`/the gw family), reusing `nwergm`'s own term-construction code directly. Extending it to covariate terms needs a syntax for supplying BOTH a coefficient and the underlying variable/network per term (unlike edges/mutual/gw, which only need a coefficient) - straightforward but not free, since it means either a two-part option syntax (e.g. `nodematch(varname coef)`) or a separate `theta()`-ordering convention paired with the existing `nodematch(varlist)`-style option; no estimator/sampler change needed either way. |

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

**Benchmarked** (harmonisation unit 79, `dev/ergm_benchmark.do`, n=200 nodes, ~10-degree
moderately dense graph, single-threaded Mata, results are per-call/per-step averages; TNT row
below shows both the ORIGINAL O(n+nties)-per-proposal figure and the POST-FIX figure after unit
80's live edge list, described in the table beneath this one):

| Operation | Cost | Notes |
|---|---|---|
| `ErgmGraph::toggle()` | 1.61 us/call | asarray-backed, O(1)-average as designed. |
| `ErgmGraph::has_edge()` | 0.44 us/call | asarray-backed, O(1)-average as designed. |
| `ErgmGraph::common_neighbors()` | 13.24 us/call | O(min(deg_i,deg_j)) as designed; not yet a bottleneck at this scale. |
| `change_gwesp()` | 77.29 us/call | Calls `common_neighbors()` for the toggled dyad plus every shared neighbor - the incremental-cache roadmap item below would cut this materially at larger scale. |
| One MCMC step, **uniform** proposal | 5.80-7.35 us/step | The proposal itself is O(1) (a single random-index unranking, no graph traversal); unchanged by unit 80. |
| One MCMC step, **TNT** proposal - BEFORE unit 80 | 1072.65 us/step | **~185x slower than uniform, at n=200** - overwhelmingly dominated by `ergm_propose_tnt()`'s own `G.all_ties()` call, materializing the FULL tie list (O(n+nties)) on every single proposal. |
| One MCMC step, **TNT** proposal - AFTER unit 80 | 8.30 us/step | **~129x faster than before the fix, now within ~13% of the uniform proposal's own cost** - the live edge list (`ErgmGraph.elist`/`.edgepos`) made TNT's own tie-pick O(1), eliminating the gap almost entirely. |

**DONE (harmonisation unit 80)** - a real head-to-head benchmark against Statnet's own `ergm()`
(R 4.12.0) on an identical 30-node directed network, `edges + mutual`, each tool's own default
settings, motivated a full round of profiling-driven fixes rather than assumption-driven ones:

| Item | Usage | Effort | Infra value | Notes |
|---|---|---|---|---|
| ~~Live edge list for TNT's own edge-pick~~ **DONE** | Was the measured, dominant bottleneck (185x the uniform proposal's own cost at n=200) | Low-Medium (as estimated) | High | `ErgmGraph` now maintains `elist`/`edgepos` incrementally in `toggle()` (O(1)-amortized append via capacity doubling, O(1) removal via swap-with-last), so `ergm_propose_tnt()`'s own tie-pick is O(1) instead of rebuilding the full tie list via `all_ties()` on every proposal - measured 129x faster (1072.65 -> 8.30 us/step at n=200). `all_ties()` itself is now also O(nties) (a direct slice of `elist`) rather than O(n+nties). Certified via an independent brute-force cross-check (every-dyad `has_edge()` scan) across 1700 toggles on both directed/undirected graphs, plus the full existing `cscripts/test_nwergm_*` suite (all still pass, no numeric regressions). On the 30-node benchmark network this alone took the full `nwergm edges+mutual` wall time from 163.18s to ~18s. |
| ~~MCMLE convergence: replace the per-coordinate "all \|Dbar\|<0.5*se" rule with a joint test~~ **DONE** | Statnet needed 1 MCMLE iteration on the benchmark network; nwergm's old rule needed 10-20 (sometimes hitting the iteration cap without ever declaring convergence) | Low (once identified) | Medium | Root cause: requiring EVERY marginal coordinate to individually clear a threshold compounds probabilities across parameters, so even an already-converged theta had only a modest per-iteration chance of jointly clearing every coordinate under ordinary Monte Carlo noise. Replaced with a genuine joint Hotelling's T² test (via its exact F transformation, `invF()`), matching Statnet's own default "confidence" method's actual statistical structure at the same 99% confidence level Statnet itself reports. Combined with the TNT fix above, took the same 30-node benchmark to 6.6-7.0s (7 iterations) on one seed and as low as 1.8s (1 iteration, matching Statnet exactly) on another - both a large further improvement AND a materially more reliable/consistent one (no more hitting the 20-iteration cap without converging). |
| **Variance estimator: batch-means alternative to lag-1 - TRIED AND REJECTED, kept as a documented negative result** | N/A - direct evidence went against adopting it | N/A | N/A | A batch-means variance-inflation estimator (robust to any autocorrelation shape, not assuming pure AR(1) dynamics the way the existing lag-1 correction does) was implemented and directly compared against real Statnet reference values across 8 seeds on this suite's own canonical directed edges+mutual network. Result: the EXISTING lag-1 correction landed tightly clustered around Statnet's own true vcov diagonal (edges 0.39-0.50 vs Statnet's 0.4447; mutual 1.89-2.28 vs Statnet's 2.1716), while batch-means (with the standard `floor(sqrt(samplesize))` batch-count heuristic) was both far noisier and often badly biased across the SAME 8 seeds (edges 0.34-5.06, several runs 2-10x too large) - at nwergm's own default samplesize (3000, giving only ~54 batches), batch-means' own statistical efficiency is too low, despite being the more general method in principle. The lag-1 correction remains in place; the batch-means code was removed rather than shipped as unused dead code, with the finding documented in `ErgmMCMLE()`'s own header comment in `unw_ergm.do`. Statnet's own full spectral/HAC estimator remains a real, larger undertaking - not attempted this unit - if this gap is revisited, it should be against a broader set of test networks/models than the single canonical case used here, not just re-tried with a different batch-count heuristic. |
| C/C++ MCMC kernel (Stata plugin, `stplugin.h`/`stplugin.c`) | High (for networks beyond a few hundred nodes at realistic MCMC sample sizes, once Mata-level fixes are exhausted) | High | High | v1 deliberately ships a pure-Mata kernel (associative-array-backed sparse graph, per PART XXXVI's own "do not move ordinary functionality into C merely for ideological reasons" and PART XXXVII's own scope discipline) and profiles it first (done twice now: units 79 and 80). The measured hot loop WAS TNT's own `all_ties()` call, not per-toggle change-statistic evaluation as originally hypothesized before benchmarking - now fixed at the Mata level (item above). A real head-to-head benchmark against Statnet's own `ergm()` after both fixes above shows nwergm at roughly 6-24x Statnet's own wall time on a 30-node network (down from ~566x before this unit) - a C kernel remains a legitimate future step once Mata-level fixes are exhausted and networks/sample sizes genuinely demand it, but the case for reaching for it immediately is now much weaker than it looked before profiling. Build as a single "run N MCMC steps, return sampled statistics" native call (see architecture doc's "Stata/Mata to C boundary" principle) - never a per-toggle Stata<->C round trip. |
| Cross-platform plugin builds (macOS Intel/ARM, Windows, Linux) | High (once a C kernel exists at all) | Medium | Low | Pure build/packaging work once the C kernel above exists; keep source + build scripts in the repository, never ship a Mac-only binary. |
| Incremental shared-partner cache for GWESP (`ErgmGraph::common_neighbors()` currently recomputes on demand, O(min(deg_i,deg_j)) per pair, every time `change_gwesp()`/`stat_gwesp()` needs a shared-partner count) | Medium (matters once networks/MCMC sample sizes grow past the moderate scale v1 targets; measured at 77.29 us/call for `change_gwesp()` at n=200 - real but currently well below TNT's own cost above) | Low-Medium | Medium | A genuine, deliberate v1 simplification, not an oversight - the incremental-cache version (an `asarray()`-keyed shared-partner count, updated O(degree) per accepted toggle instead of recomputed) was independently prototyped and certified during this session's own development (2,800+ random toggles, zero mismatches against full recomputation) but not adopted into the shipped v1 file, since the simpler on-demand version is already correct and v1's own scope discipline (`docs/CERTIFICATION.md`'s own unit-68 entry) explicitly defers this exact optimization until profiling shows it matters. Swapping it in later needs no change to `change_gwesp()`'s own call signature. |

## Explicitly out of scope for the foreseeable future (per the governing task)

- Full parity with Statnet's ~150 term-computing algorithms - never a goal; this package targets a small, well-certified, extensible core.
- Reproducing Statnet's entire constraint/hint/auxiliary-network system.
- A general-purpose curved-exponential-family framework beyond the fixed-decay GW terms and the documented extension hook.
