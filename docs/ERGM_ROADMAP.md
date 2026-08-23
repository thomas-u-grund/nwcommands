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
| ~~`nodefactor()`~~ **DONE (unit 88)** | High | Low | Low | Directed-agnostic per-category main effect - one coefficient per distinct level, each counting total degree among nodes at that level. Implemented, certified (brute-force change-statistic cross-check), wired into `nwergm.ado` as `nodefactor(varlist)`. |
| ~~`nodemix()`~~ **DONE (unit 88)** | High | Medium | Low | Full mixing-matrix effect - one coefficient per distinct unordered level-pair (undirected v1 scope). Implemented, certified, wired in as `nodemix(varlist)`. |
| ~~`absdist()` (Statnet's `absdiff`)~~ **DONE (unit 88)** | High (user-requested) | Low | Low | Sum over ties of `|x_i - x_j|` on a continuous covariate - a natural companion to the existing `nodecov` (sum). Implemented, certified, wired in as `absdist(varlist)`. |
| ~~`nodematch(diff=TRUE)` (differential homophily)~~ **DONE (unit 88)** | High (user-requested) | Low-Medium | Low | One coefficient PER LEVEL rather than pooled across levels. Wired in as a separate `nodematchdiff(varlist)` option (not a suboption on `nodematch()` itself - Stata option syntax does not cleanly support a per-variable-in-a-varlist modifier the way R's `diff=TRUE` argument does). |
| ~~`nodeifactor()`/`nodeofactor()`~~ **DONE (unit 91)** | High (directed research) | Low | Low | Directed sender/receiver category effects, same base-level omission as `nodefactor()`. Implemented, certified, wired in as `nodeofactor(varlist)`/`nodeifactor(varlist)`. |
| ~~GWDSP (geometrically weighted dyadwise shared partners)~~ **DONE (unit 88)** | Medium | Medium | High | Sums over EVERY dyad (tied or not), unlike GWESP's tied-only sum - `stat_gwdsp()` needs a genuine O(n²) full-dyad enumeration (no `all_ties()`-style shortcut), but the CHANGE statistic is structurally simpler than GWESP's own (no "must also be a tie" restriction, no separate own-dyad term). Implemented, certified, wired in as `gwdsp(real)`, undirected v1 scope, dyad-dependent (MCMLE only). Native (C) backend NOT extended to it yet - no evidence yet that it needs to be (unit 83's own "decide term by term through profiling" instruction). |
| ~~Directed GWESP/GWDSP/GWNSP/esp/dsp via OTP (R ergm's own default directed shared-partner definition)~~ **DONE (unit 91)** | Medium | Medium | Medium | Implemented `ErgmGraph::shared_partners_otp()` (SP_OTP(i,j) = #{k: i->k and k->j}) plus dedicated `_otp` change-statistic variants for gwesp/gwdsp/esp/dsp (gwnsp needed none - it is a thin composition and inherits the dispatch for free); `td.sptype` field on `ErgmTermData` selects "OTP" vs. the default "" (undirected/UTP), set automatically by `nwergm.ado` whenever the network is directed. Certified via a direct brute-force cross-check of `shared_partners_otp()` itself (independent O(n) scan) PLUS the usual `ErgmCertifyChangeStat()` change-statistic check, PLUS two structural identities (esp sums to arc count; dsp sums to all n*(n-1) ORDERED pairs - note GWDSP's own dyad-space genuinely doubles for directed OTP, since SP_OTP(i,j) != SP_OTP(j,i) in general). ITP/OSP/ISP/RTP (R's other four `type=` options) remain NOT implemented - see the row below. |
| ITP/OSP/ISP/RTP directed shared-partner definitions (the other four of R ergm's five `type=` options for gwesp/gwdsp/gwnsp/esp/dsp on directed networks - OTP, R's own default, is now done, see above) | Low-Medium (OTP already covers the default/most-used case; these are for users who deliberately want a non-default directed dependence structure) | Medium | Low (the dispatch infrastructure - `td.sptype`, the `_otp`-suffix naming convention, `nwergm.ado`'s auto-set-when-directed wiring - already exists; each additional type is "derive+certify one more `shared_partners_TYPE()`/`change_TERM_TYPE()` pair", not new architecture) | Precise definitions fresh-checked against R's own `src/changestats_spcache.c`/`R/InitErgmTerm.dgw_sp.R`: ITP (i<-k<-j: k->i and j->k), OSP (i->k<-j: i->k and j->k), ISP (i<-k->j: k->i and k->j), RTP (i<->k<->j: mutual i-k and mutual k-j). Each needs its own change-statistic derivation (which third-party dyads are affected by toggling arc (i,j) differs by type - NOT a simple parameter swap on the OTP version) before it can be brute-force certified the way OTP was. |
| ~~`gwnsp` (geometrically weighted nonedgewise shared partners)~~ **DONE (unit 90)** | Low-Medium | Medium | Medium | Implemented as a thin composition of the now-done `gwesp`/`gwdsp` (`gwdsp = gwesp + gwnsp`, confirmed against R ergm's own current source and via a dedicated identity test) rather than a new traversal. |
| ~~Plain triangle / k-star family~~ **DONE (units 90-91)** - alternating-k-star not done | Medium (mostly superseded by GW terms in modern practice) | Low-Medium | Low | `triangle`/`ctriple` (unit 90) and `kstar`/`ostar`/`istar` (unit 91) implemented; the alternating-k-star (curved-parameter) variant is not - see the "Curved parameters" row below, it needs the same `eta`-map infrastructure. |
| ~~`isolates`~~ **NOT ADDED - subsumed by `degree(0)` (unit 90)** | Low-Medium | Low | Low | Fresh checking of R ergm's own current source found `isolates` appears to have been REMOVED from current ergm in favor of `degree(0)` (absent from the current term-listing file) - `nwergm`'s own new `degree()` term (below) already covers this exactly, so no separate term was added. |
| ~~`concurrent` / concurrency terms~~ **DONE (unit 90)** | Medium (esp. epidemiology) | Low-Medium | Low | Implemented as `concurrent` (degree>=2 count). |
| Two-path / `dsp/esp` non-geometric variants | Low | Low-Medium | Low | Rarely used un-weighted; mostly superseded by GW terms. |
| ~~Degree distribution terms (`degree(d)`, `idegree(d)`, `odegree(d)`)~~ **DONE (unit 90 - see above)** | Medium | Low-Medium | Low | |
| Bipartite terms (`b1nodematch`, `b1star`, `b2star`, bipartite GWESP analogues) | Medium (two-mode research) | High | High | Blocked on native bipartite dyad-space support in the proposal/constraint layer - see "Two-mode ERGMs" below; do not attempt term-by-term before that infrastructure exists. |
| Curved parameters beyond fixed-decay GW terms (free/estimated decay) | Medium | High | High | Needs the `eta`-map (theta -> curved-parameter linking function) and its Jacobian in the MCMLE loop - a real architectural addition, not a term-only change; see `docs/ERGM_ARCHITECTURE.md`'s own "Curved parameters" section for the hook already left in the term interface. |
| User-defined/custom terms | Medium (power users) | Medium | High | The term registry (`docs/ERGM_ARCHITECTURE.md`) is designed so this is "write a term following the documented contract, then register it" - a dedicated `nwergm` "how to add a term" tutorial is the main remaining work, not new estimator code. |

### Prioritized survey of R ergm's remaining term library (harmonisation unit 88, phase D)

Per the user's own explicit instruction: goes through R `ergm`'s own term
library (the `ergm-terms` help page's full inventory) beyond what the table
above already covers, prioritizes by (typical applied usefulness x
implementation effort x whether the needed infrastructure already exists),
and DEPRIORITIZES every two-mode/bipartite term as a single group (not
itemized further - each would otherwise appear individually below) since
two-mode ERGMs are their own later initiative, not a term-by-term
extension of the current one-mode term library.

**High priority (next wave candidates - low effort, existing infra covers most of the work):**

| Term | Usage | Effort | Notes |
|---|---|---|---|
| ~~`nodeifactor()`/`nodeofactor()`~~ **DONE (unit 91 - see above)** | High (directed research) | Low | |
| ~~`degree(d)`/`idegree(d)`/`odegree(d)`~~ **DONE (unit 90)** | High (very commonly reported descriptively, sometimes as a model term) | Low | `d` accepted as a numlist (multiple simultaneous degree-value statistics per term instance, matching R ergm's own vector-valued `d` argument, confirmed from source). |
| ~~`concurrent`/`concurrentties`~~ **DONE (unit 90 - see above)** | Medium | Low | |
| ~~`triangle`/`ctriple`~~ **DONE (unit 90)** | Medium (classic, still taught/replicated even though GW terms are now preferred for degeneracy reasons) | Low-Medium | The change statistic turned out to need NO neighbor-loop/kernel-reweighting term at all (simpler than GWESP's own): toggling a dyad with p shared partners creates/destroys exactly p triangles, full stop - derived on paper before coding. |
| ~~`gwnsp` (geometrically weighted NONedgewise shared partners)~~ **DONE (unit 90 - see above)** | Medium | Low | |

**Medium priority (real value, moderate effort or depends on a not-yet-built primitive):**

| Term | Usage | Effort | Notes |
|---|---|---|---|
| ~~`kstar(k)`/`istar(k)`/`ostar(k)`~~ **DONE (unit 91)** | Medium (superseded by GW-degree terms in modern practice, per Statnet's own current guidance, but still used for replication/teaching) | Low-Medium | Direct degree-sequence combinatorial term (`C(degree,k)`, via a new general `_ergm_choose(d,k)` helper), same shape as the `istar2` demonstration term. Cross-checked against `istar2` exactly (`kstar(2)` == `istar2`). Implemented, certified, wired in as `kstar(numlist)`/`ostar(numlist)`/`istar(numlist)`. |
| ~~`degrange(from,to)`/`idegrange()`/`odegrange()`~~ **DONE (unit 91)** | Medium | Low-Medium | Semi-open-interval `[from,to)` degree counts via `td.levelpairs`, `to=.` meaning an open-ended upper bound (matching R's own `to=+Inf` default). Implemented, certified, wired in as `degrange(numlist)`/`degrangeto(numlist)` (+ `o`/`i` directed analogues). |
| ~~`transitiveties`/`cyclicalties`~~ **DONE (unit 91)** | Medium (directed triad structure beyond `mutual`) | Medium | Directed-only (matching `ctriple`'s own directed-only scope). Fresh-checked against R ergm's OWN dedicated `R/InitErgmTerm.transitiveties.R` (easy to miss - these two are NOT in the main `InitErgmTerm.R` dispatcher file). Definitions: `transitiveties` = count of tied arcs i->j with an existing forward two-path i->k->j; `cyclicalties` = count of tied arcs i->j with an existing RETURN two-path j->k->i (closing a directed 3-cycle) - both threshold/existence indicators (not counts) built directly on wave 5's `shared_partners_otp()`, needing only the change-statistic's threshold-crossing logic (0->1/1->0) worked out fresh for each. Certified via `ErgmCertifyChangeStat()` PLUS a fully independent brute-force statistic recomputation with zero dependence on `shared_partners_otp()` itself (catches any error shared between the two). |
| Directed GWESP/GWDSP/GWNSP/esp/dsp variants beyond OTP (ITP/OSP/ISP/RTP) | Low-Medium | Medium | OTP (R's own default) is now DONE - see the term-families table above. Already tracked there in full detail (exact definitions, effort estimate) - not repeated here. |
| ~~`esp(d)`/`dsp(d)` (fixed, non-geometric shared-partner count AT EXACTLY d)~~ **DONE (unit 91)** | Low-Medium (legacy - Statnet itself recommends GW terms over these) | Low | Undirected/UTP scope only (matching v1's `gwesp`/`gwdsp`, no directed common-neighbor definition built yet) - implemented as `gw_kernel(p,decay)` replaced by an exact-match indicator in the already-certified GWESP/GWDSP change-statistic shape. Caveat, disclosed in `nwergm.ado`'s own doc header: an EXHAUSTIVE `d`-range (covering every shared-partner value a toggle on the network can produce) is exactly collinear across its own columns - not a code bug, the modeler's responsibility to avoid (same as requesting every level of a factor with an intercept), matching R ergm's own convention (unlike `nodefactor()`/etc., `esp`/`dsp` do not auto-drop a level). |

**Low priority / deferred (real but narrow use cases, or blocked on other infrastructure):**

| Term | Usage | Effort | Notes |
|---|---|---|---|
| ~~`sender`/`receiver` (per-node fixed effects)~~ **DONE (unit 91)** | Low (high-dimensional - one parameter per node, rarely used outside small networks) | Low | R's own `sender`/`receiver` are literally per-node out-/in-degree effects with base=1 omitted - mathematically identical to `nodeofactor()`/`nodeifactor()` with the node's own identity as the "attribute". Implemented as a THIN convenience wrapper reusing the already-certified `stat_nodeofactor()`/`stat_nodeifactor()` directly - zero new Mata statistic/change code. |
| ~~`hamming` (distance from a reference network)~~ **DONE (unit 91)** | Low (niche - temporal/multi-network comparison designs) | Medium | Genuinely dyad-independent (each dyad's own mismatch depends only on its own state and its own reference value) - simpler than expected once derived: change statistic is `has_edge(i,j)==ref ? +1 : -1`, no third-party effects at all. Reuses `edgecov()`'s own `edgecovmat`/`nw_syntax()` network-resolution plumbing, but with a BINARY (not weighted) reference matrix. Implemented, certified, wired in as `hamming(netname)`. |
| `balance`/signed-tie structural-balance terms | Low (signed networks are a distinct data type this package does not otherwise support) | High | Would need signed-tie representation throughout, not just a new term - out of scope until/unless signed networks become a real initiative. |
| Curved parameters (free/estimated decay for any GW term, rather than v1's fixed-decay-only scope) | Medium (statistically more flexible, but a real architectural addition) | High | Needs the `eta`-map (theta -> curved-parameter linking function) and its Jacobian inside the MCMLE loop, not a term-only change - see `docs/ERGM_ARCHITECTURE.md`'s own "Curved parameters" hook. Affects every GW term at once, not a per-term decision. |

**Explicitly deprioritized as a group (per the user's own explicit instruction): all two-mode/bipartite terms** -
`b1nodematch`/`b1star`/`b2star`/`b1degree`/`b2degree`/`b1mindegree`/`b2mindegree`/`gwb1degree`/`gwb2degree`/`b1cov`/`b2cov`/`b1factor`/`b2factor` and
bipartite GWESP analogues. All of these are blocked on native bipartite dyad-space support in the proposal/constraint layer regardless of individual term effort (see "Two-mode ERGMs" elsewhere in this roadmap) - do not attempt any of them term-by-term before that infrastructure exists, and do not let their sheer number crowd out the one-mode items above in prioritization.

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
| ~~Variance estimator: batch-means alternative to lag-1~~ **TRIED, REJECTED (unit 80); SUPERSEDED BY A PROPER AR(p)/SPECTRAL ESTIMATOR (unit 86)** | Was N/A (batch-means rejected on direct evidence); the AR(p) replacement was the user's own explicitly requested "phase B" priority once native execution removed the excuse not to investigate variance carefully | Low (once the shape of the fix was clear) | High | Batch-means (robust to any autocorrelation shape) was tried first and rejected: compared against real Statnet reference values across 8 seeds, the existing lag-1 correction already landed tightly clustered around Statnet's true vcov (edges 0.39-0.50 vs 0.4447; mutual 1.89-2.28 vs 2.1716) while batch-means was noisier and often badly biased (edges 0.34-5.06) at nwergm's own default samplesize. That left lag-1 in place with a known gap: it is only exact for TRUE AR(1) autocorrelation structure. Unit 86 fetched Statnet's own CURRENT `R/mcmc_se.R` fresh (not relying on the earlier study) and found it uses `spectrum0.mvar()` - fitting an AR model to the MCMC series and evaluating its spectral density at frequency 0 (Geyer 1992), not a single-lag correction. Implemented the same idea per-dimension via AIC-ordered Yule-Walker AR(p) fitting (`ergm_ar_yw_infl()`/`ergm_spectral0_ar()`) - confirmed to be a strict generalization of lag-1 (identical on true AR(1) data) that correctly catches higher-order persistence lag-1 misses (a synthetic AR(2) series with near-zero lag-1 correlation: new estimator reports infl=24.4 vs lag-1's 2.0). Validated against the one case with an exact external ground truth (the 5-node network real-Statnet-reference test): error roughly halved on edges, ~68x smaller on mutual, relative to lag-1. Adopted as the production estimator in both of `ErgmMCMLE()`'s own usage sites (the per-iteration convergence test and the final reported vcov). See `docs/CERTIFICATION.md` unit 86. Statnet's own estimator is genuinely multivariate (a full VAR fit, not per-dimension AR) - this remains a disclosed simplification, not yet closed. |
| ~~C/C++ MCMC kernel (Stata plugin, `stplugin.h`/`stplugin.c`)~~ **DONE for macOS (unit 83)** | Superseded once units 81-82 pinned the gap on GWESP specifically and the user explicitly relaxed the Mata-first default | High (as estimated) | High | Built as `native/ergm_mcmc.c`, exactly the "single 'run N MCMC steps, return sampled statistics' native call, never a per-toggle round trip" design this row originally called for - see the dedicated native-backend row earlier in this table and `docs/ERGM_ARCHITECTURE.md`'s own section for the full account. This row is kept (struck through, not deleted) as the historical record of when a C kernel was first anticipated as a *possible future step*, contrasted with the row above recording when it was actually evidence-justified and built. |
| ~~Cross-platform plugin builds~~ **INFRASTRUCTURE DONE, BINARIES STILL PENDING (unit 87)** | High (macOS done; Windows/Linux still needed for the native backend to accelerate those platforms) | Medium | Low | macOS (arm64+x86_64 universal binary) DONE since unit 83. No Windows/Linux toolchain, cross-compiler, or Docker was available locally (confirmed by direct probe, unit 87) - so rather than leave this as an indefinitely-blocked local task, unit 87 built `.github/workflows/build-plugins.yml`: real, runnable CI configuration that builds all three platforms' plugins on GitHub's own hosted runners and commits them back into `lib/plugins/` automatically. This surfaced and fixed a genuine bug before it could ship: macOS's and Windows's own binaries cannot share the single path Stata's own ".plugin may be renamed" convention suggested (two different binaries, one path, in the same commit) - fixed via per-platform subdirectories (`lib/plugins/{macos,windows,unix}/`) and a new `ErgmNativePluginSubdir()`. The workflow cannot actually RUN until this repository exists on GitHub (see the pending migration item) - Windows/Linux binaries remain not-yet-built, honestly, not fabricated or assumed. `ErgmNativeAvailable()` continues to fall back to Mata gracefully wherever a binary is absent. |
| ~~Incremental shared-partner cache for GWESP~~ **BUILT, CERTIFIED, and DELIBERATELY NOT ADOPTED BY DEFAULT (unit 82)** | Was elevated to High after unit 81's benchmarks pinned the gap on GWESP specifically - see below for why the obvious fix did not pay off in practice | Low-Medium (as estimated) | Medium | Implemented exactly as long anticipated (`ErgmGraph::enable_sp_cache()`/`sp_adjust()`/`shared_partners()`, an `asarray()`-keyed shared-partner count updated O(deg_i+deg_j) per toggle instead of recomputed on demand) and fully certified (brute-force cross-check across 2000+ toggles, end-to-end `stat_gwesp()`/`change_gwesp()` equivalence - `cscripts/test_nwergm_spcache.do`). Wired to auto-enable whenever `gwesp()` is requested, then RE-BENCHMARKED against unit 81's own two GWESP cases per the user's own explicit instruction - and found to make the 100-node benchmark SLOWER (23.1s -> 39.3s), not faster, in a clean controlled A/B test. Root-caused fully (see `docs/CERTIFICATION.md` unit 82's own detailed account): the real fitted model's own Metropolis-Hastings acceptance rate is 92.9% (measured, not assumed) - TNT accepts almost every proposal for a converged sparse model - so `toggle()`'s own cache-maintenance cost (paid on nearly every step) dominates the cheaper O(1) lookup's own savings at this network's LOW degree (~4-6). A systematic degree sweep at matched high acceptance rates found the cache is a net LOSS at degree 4-20 (1.6-2.0x slower) and only becomes a net WIN around degree ~30-40+ (1.6x faster) - both realistic benchmark networks sit well below that crossover. The auto-enable wiring was reverted; the cache machinery itself remains available in `unw_ergm.do` for the degree-aware heuristic or opt-in control item below. |
| Degree-aware auto-enable heuristic (or an explicit opt-in control option) for the shared-partner cache above | Medium (real for genuinely dense networks - social networks with degree 30-40+ are not rare, e.g. saturated friendship/citation networks) | Low (the cache itself is done; this is just a decision rule plus, if opt-in, one new `nwergm` option) | Low-Medium | Now that the crossover point is measured (roughly degree 30-40, though this will shift somewhat with the model's own acceptance rate - denser fitted models with modest coefficients could cross over at somewhat different degree than the sparse, well-fitted case measured here), the natural next step is either: (a) have `nwergm.ado` estimate the observed network's own average degree and auto-enable the cache only above some threshold (simple, but a heuristic threshold is inherently approximate and could be wrong for atypical acceptance-rate regimes); or (b) expose an explicit `spcache` on/off option and let the user decide, documenting the tradeoff in the SMCL help (simpler to implement correctly, puts the decision in the hands of someone who knows their own network's density). Not implemented - a genuine open design question, not just unstarted work, since option (a)'s own threshold would itself need validating across a wider range of models/densities than the single network this unit measured. |
| ~~Native (C) MCMC backend~~ **DONE (unit 83)** | The user explicitly relaxed this project's earlier Mata-first default after unit 82's own finding that the cache did not close the GWESP gap - this row is the direct response | Medium (as estimated) | High | A genuine Stata C plugin (`native/ergm_mcmc.c`, SPI 3.0) implements the entire burnin+sampling MCMC loop natively for the four terms the benchmark suite exercises (edges/mutual/nodematch/gwesp), crossing the Mata/native boundary once per `ErgmMCMCSample()` call, never once per proposal. Result, same five benchmarks, default settings: 6.6-7.0s→0.311s (30-node, ratio ~1.07x vs R); 13.746s→0.495s (100-node dir, ~1.02x); 22.065s→0.419s (100-node GWESP, ~1.29x, down from ~68x); 93.174s→3.932s (500-node sparse, ~1.72x, down from ~40.6x, still non-converged - see the new convergence-at-scale row below); 27.762s→4.883s (1000-node control, now FASTER than R's 9.177s, ratio ~0.53x). Cross-certified against the Mata reference (statistical equivalence of sampled distributions, not trajectory identity - the two backends use independent RNG streams by design) via `cscripts/test_nwergm_native.do`. Mata implementation fully preserved as reference/fallback/certification oracle - see `docs/ERGM_ARCHITECTURE.md`'s own "Native (C) MCMC backend" section for the full design, extension guide, and `docs/CERTIFICATION.md` unit 83 for the complete evidence trail (including a fresh, direct re-verification of Statnet's own current C source, not merely this project's earlier study). Currently built and verified for macOS only (arm64+x86_64 universal binary); Windows/Linux build recipes are documented in `native/Makefile` but not yet built (no toolchain available) - `ErgmNativeAvailable()` transparently falls back to Mata wherever the compiled plugin is absent, so no platform is left broken, only unaccelerated. |
| ~~Native backend scope relaxation - "move all effects to C"~~ **DONE for waves 1-4 (unit 92) - migration complete except edgecov/hamming** | User-mandated, not profiling-gated - see this section's own "Update (unit 92)" note above | Medium (as estimated) | High | Wave 1: generalized the native dispatch protocol (multi-column terms via per-slot `attridx`/`p1`/`p2`, multiple distinct attribute arrays via `native_attrmat`) and ported the full dyad-independent attribute/factor family plus the GW-degree family. Found and fixed two real bugs: directed (OTP) `gwesp` silently, wrongly reported native-eligible; a NULL-pointer dereference crashed the whole Stata process for any directed model lacking a `gwodegree`/`gwidegree` term. Measured **~29x** speedup on the motivating case. Wave 2: the full degree-COUNT family (`degree`/`odegree`/`idegree`/`concurrent`/`kstar`/`ostar`/`istar`/`degrange`/`odegrange`/`idegrange`), needing only wave 1's own `outdeg`/`indeg` bookkeeping plus two direct C ports of existing Mata combinatorics helpers. Wave 3: the undirected shared-partner family beyond `gwesp` itself (`gwdsp`/`gwnsp`/`esp`/`dsp`/`triangle`) - reused `gwesp`'s own existing `adj[]`/`common_neighbors()` graph infrastructure entirely, only new change-statistic formulas needed (`gwnsp` needed no separate function at all, dispatching as `gwdsp - gwesp` inline, the same "thin composition" property its Mata version has; `triangle` needed no traversal loop either, just `delta * common_neighbors(i,j)`). Wave 4 (a later, separate user instruction: "complete the migration of all remaining ERGM effects to the C backend"): the full DIRECTED shared-partner family - the OTP mode of `gwesp`/`gwdsp`/`gwnsp`/`esp`/`dsp` (dispatched via `tdt.sptype == "OTP"`) plus `ctriple`/`transitiveties`/`cyclicalties`, all backed by a genuinely new `common_neighbors_otp()` primitive and a new `outadj`/`inadj` directed-adjacency pair in `native/ergm_mcmc.c`. This closes the exact bug wave 1 found (directed gwesp wrongly reported eligible) the right way, by actually porting OTP rather than leaving it permanently excluded. `ctriple` needed no dedicated function at all - `delta * common_neighbors_otp(g,j,i)`, a one-line composition, matching `triangle`'s own wave-3 simplicity. Every dyad-independent term, every degree-based term, and now every shared-partner term (both UTP and OTP) is fully native. See `docs/CERTIFICATION.md` unit 92 for all four waves' complete evidence trail. The ONE remaining gap: `edgecov`/`hamming`, which need an n x n dyadic covariate matrix marshalled across the plugin boundary - a genuinely different wire-protocol shape (a dense matrix, not a per-node attribute array or scalar parameter) from every other native term, deliberately left as the last well-scoped follow-on. |
| ~~`nwergm.ado`'s MPLE design matrix routed through an intermediate Stata MATRIX~~ **DONE (unit 81)** | Was blocking ANY directed model with more than a few hundred nodes, independent of which ERGM terms were used | Low (once identified) | High | Found while building the 1000-node control benchmark below: the fit did not complete after 35+ minutes. Root-caused to `mata: st_matrix("nw_ergm_D", ...)` - a bare, isolated `st_matrix()` call on a 999,000-row matrix did not complete within 2 minutes in direct testing, where the equivalent `st_store()` directly onto Stata dataset variables took 0.008 seconds for the identical data. Fixed by never routing the MPLE design matrix through a Stata matrix at all. Impact: the 1000-node benchmark went from not completing to 27.8 seconds; the 500-node GWESP benchmark went from 151.2s to 93.2s (~1.6x) with byte-identical coefficients. See `docs/ERGM_ARCHITECTURE.md`'s own integration-layer section for the general principle (`st_store()` for anything scaling with the DATA, `st_matrix()` only for small, model-sized structures) and `docs/CERTIFICATION.md` unit 81 for the full account. **A related, lower-priority risk not yet addressed**: `e(mcmcsample)` (the final MCMC sample, `estat mcmcdiag`'s own data source) is still posted via `st_matrix()`, sized `mcmcsamplesize x nparam` - safe at the default `mcmcsamplesize=3000`, but a user setting an unusually large `mcmcsamplesize()` could hit the same class of slowdown. Not fixed now since it requires reworking `estat mcmcdiag`'s own matrix-based consumption of `e(mcmcsample)` (a documented, shipped API), unlike the MPLE case which was purely internal plumbing. |

**Benchmarked further (harmonisation unit 81)** - four additional canonical R-vs-Stata
benchmarks beyond the original 30-node case, each tool's own default settings, generated once
per network (fixed seed) and exported identically for both:

| Benchmark | R `ergm` | `nwergm` | Ratio | nwergm converged? |
|---|---|---|---|---|
| 30-node directed, edges+mutual | 0.29s | 6.6-7.0s (as low as 1.8s some seeds) | ~23-25x | yes |
| 100-node directed, edges+mutual+nodematch | 0.484s | 13.746s | ~28.4x | yes (12 iter) |
| 100-node undirected, edges+gwesp | 0.326s | 22.065s | ~67.7x | yes (5 iter) |
| 500-node sparse undirected, edges+nodematch+gwesp | 2.293s | 93.174s | ~40.6x | no (hit 20-iter cap) |
| 1000-node directed CONTROL (no gwesp), edges+mutual+nodematch | 9.177s | 27.762s | **~3.0x** | no (hit 20-iter cap) |

Coefficients agreed closely with R on every benchmark, including the two that did not converge
within the default iteration cap (the same "correct estimate, needs more iterations on this
particular seed" pattern already characterized above - not a correctness concern). The two
non-converged runs' own ratios are somewhat pessimistic (nwergm did the full 20 iterations'
worth of work where a converging run would stop earlier) - not re-run to force convergence,
since the point is realistic default-settings behavior, not a best-case number.

**The pattern is now clear and actionable**: GWESP-involving models sit at 40-68x; the
GWESP-FREE control, even at 10x the node count of the original benchmark, sits at ~3x. The
remaining performance gap concentrates specifically in the shared-partner machinery
(`common_neighbors()`/`change_gwesp()`), not in raw node count, MCMC step count, or the MCMLE
controller generally (unit 81's own time-breakdown profiling separately confirmed ~94% of a
real MCMLE run's wall time is genuine MCMC simulation, ~6% controller/variance overhead - there
is no large hidden inefficiency in the outer loop to chase).

**Decision framework** (adapted from the user's own stated rule, applied to these results):
non-GWESP models (3-28x here) are comfortably within "stay in Mata, optimize only obvious
hotspots" - the 1000-node control case at ~3x is squarely in "stay in Mata" territory outright.
GWESP-involving models (40-68x here) are in "10x+ slower" territory - the incremental
shared-partner cache was the obvious next Mata-level lever to try, and unit 82 DID try it (not
merely propose it): built, certified, wired in, and re-benchmarked immediately, exactly as
planned. **It did not pay off** - it made the realistic sparse-network GWESP benchmarks slower,
not faster (see unit 82's own entry above and in `docs/CERTIFICATION.md` for the fully
root-caused why: TNT's high acceptance rate on a fitted model makes the cache's own maintenance
cost dominate its lookup savings below roughly degree 30-40). This does NOT immediately mean
"reach for C++" either, per the user's own explicit caution against moving to C prematurely -
before that, worth checking: (1) whether `change_gwesp()`'s own loop structure or the
`neighbors_out()`/`asarray` overhead it and the (unused) cache both pay can be reduced directly
(the decomposition in unit 82 found `toggle()`'s own two `neighbors_out()` calls, each
allocating a fresh array, to be a real, nameable cost - independent of whether the cache is
enabled, since ordinary `common_neighbors()` also calls `neighbors_out()`); (2) whether GWESP's
own 40-68x gap is dominated by a genuinely large NUMBER of shared-partner evaluations per
proposal (an algorithmic property of the term itself, not fixable by caching alone) versus a
per-call constant-factor overhead Mata's own interpreted execution imposes. Only once those are
characterized - not merely assumed - would a C/C++ kernel scoped specifically to the shared-
partner/change-statistic path become the next reasonable step, per the "profile before
rewriting" discipline this whole unit followed twice now (once vindicated at unit 80, once
correctly steering away from a plausible-but-wrong optimization at unit 82).

**Update (unit 83) - the decision framework above is now superseded, not merely revised**: the
user explicitly relaxed the Mata-first default this framework was written under, characterized
exactly the two open questions this paragraph posed (per-call constant-factor overhead vs. a
genuinely large number of shared-partner evaluations), and authorized moving forward regardless
of which one turned out to dominate. Both a fresh, direct re-verification of Statnet's own
current C source AND a new Mata primitive microbenchmark (`change_gwesp()` costing 50-100x a
plain term's own per-call cost at realistic degree, where the actual number of shared-partner
comparisons performed is small) confirmed the first hypothesis: this was Mata's own per-call
interpreter/hash-lookup/allocation overhead, not an algorithmic property of the term. The native
(C) MCMC backend row above is the result: all five benchmarks now sit at ~1.0-1.7x Statnet
(two of them at effective parity or faster), far beyond the "<10x good, ~2-5x excellent" target
this framework's own governing instructions set. See `docs/CERTIFICATION.md` unit 83 for the
complete account. The remaining open item at the time was the still-unconverged 500-/1000-node
benchmarks (a convergence-at-scale question, orthogonal to backend speed - see the row below).

**Update (unit 92) - "decide term by term" superseded again, this time explicitly**: the user
found the ALL-OR-NOTHING consequence of unit 83's narrow four-term native scope unacceptable -
verbatim: "as soon as gwesp is mixed with other terms, it falls back to the Mata version. That is
not acceptable. I would rather move all effects to C. Relax the restriction in this regard." This
is architecturally correct, not just a preference: every term's change statistic must be evaluated
on every MH proposal, so native cannot mix "some terms in C, some in Mata" per-toggle without
reintroducing the exact boundary-crossing overhead the whole native design exists to eliminate -
the only real fix is porting more terms into C so fewer realistic model specifications fall
outside the native set at all. Unit 92 generalized the native dispatch protocol (multi-column
terms, multiple distinct attribute arrays, not just one) and ported the full dyad-independent
attribute/factor family plus the GW-degree family - see the dedicated row below. Found and fixed
two real bugs in the process: directed (OTP) `gwesp` was silently, wrongly reported native-
eligible (a stale check predating OTP's own existence); and a NULL-pointer dereference crashed the
whole Stata process for any directed model without a `gwodegree`/`gwidegree` term. Measured a
~29x speedup on the exact motivating scenario (gwesp+nodefactor+nodecov, 300 nodes). See
`docs/CERTIFICATION.md` unit 92 for the complete account. "Decide term by term" still governs
WHICH remaining terms to port next and in what order (see the row below) - it no longer means
"only port a term once a specific model has been profiled and found slow."

| Item | Usage | Effort | Infra value | Notes |
|---|---|---|---|---|
| ~~Investigate MCMLE convergence at scale~~ **ROOT-CAUSED AND FIXED (unit 84)** | Was flagged as mattering more than further runtime once native execution made speed a solved problem | Low (once root-caused) | High | A direct iteration-by-iteration comparison against a real, verbose Statnet trace on the identical benchmark-4 network found the OPTIMIZER was never the problem (theta tracked Statnet's own converged value from iteration 1 in every case) - the per-iteration Hotelling T²/F convergence test itself was invalid, treating a thinned, still-autocorrelated MCMC chain as if it were i.i.d. of size `samplesize`, exactly as Statnet's own printed degrees-of-freedom (non-integer, far below the raw sample size, growing across iterations) revealed Statnet's own test does NOT do. Fixed by applying the SAME lag-1-autocorrelation inflation the final variance step already used one step earlier - inside the per-iteration test - and using the resulting effective sample size in place of the raw one for `T2`/`Fstat`/`Fcrit`. Result: all five R-vs-Stata benchmarks now converge in 1-2 iterations (was up to 20/capped); the original 30-node benchmark's own 20-seed variability probe went from niter 2-20 (19/20 converged) to exactly 2 on all 20 seeds. See `docs/CERTIFICATION.md` unit 84 for the full account, including why "exactly 2, not 1" is itself explained (the trust-region step-length cap) rather than a leftover puzzle. |
| ~~Default `mcmcinterval`/mixing-quality investigation for large GWESP models~~ **RESOLVED via an adaptive mechanism, not a static default change (unit 85)** | Was flagged as affecting estimate PRECISION, not just whether MCMLE terminates | Low (once the shape of the fix was clear) | High | Rather than guessing a new fixed default (risking either still-too-thin for hard cases or unnecessarily slow for easy ones), `ErgmMCMLE()` now grows `interval` automatically whenever the achieved effective sample size (already computed for unit 84's own convergence test) falls short of a target floor (`max(200, 64*nparam)`, mirroring Statnet's own documented `MCMLE.effectiveSize=64`-per-parameter target) - convergence is only declared once both the statistical test passes AND that floor is met. Small/well-mixing models (the original 30-node and 100-node GWESP benchmarks) never trigger it at all (confirmed by a dedicated regression test asserting exactly this under nwergm's own real production defaults); the 500-/1000-node benchmarks now take 3 iterations instead of 1, converge with `interval` grown from 50 to 300-600, and the 500-node benchmark's own fitted `gwesp` coefficient moved from 0.0179 to 0.0363 - much closer to Statnet's own 0.0371, direct evidence of a real precision gain, not just more iterations for their own sake. See `docs/CERTIFICATION.md` unit 85. The related final-SE-may-still-understate-uncertainty observation from unit 84's 5-seed probe remains open, folded into the variance-estimator item below rather than treated as resolved by this row. |

## Explicitly out of scope for the foreseeable future (per the governing task)

- Full parity with Statnet's ~150 term-computing algorithms - never a goal; this package targets a small, well-certified, extensible core.
- Reproducing Statnet's entire constraint/hint/auxiliary-network system.
- A general-purpose curved-exponential-family framework beyond the fixed-decay GW terms and the documented extension hook.
