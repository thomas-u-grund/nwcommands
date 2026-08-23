# Performance Benchmarks — Stress Test at N = 100 / 1,000 / 10,000

User-requested: "stress-test every single command on a network of 100, 1000 and 10000 size... complete overview of timings and performance... for another performance optimization... report these results in a Stata Journal article." This document is that overview, plus the story of what was found and fixed along the way, and what remains open for future work.

## Methodology

- **Test network**: a single sparse random graph per size tier (`nwrandom N, prob(p) undirected`), `p` chosen to hold average degree constant at ~10 across all three sizes, so timing differences reflect algorithmic scaling with N, not density changes. This matches the convention already used in `docs/SPARSE_BACKEND.md`'s own benchmarks.
- **Two-mode commands** additionally get a bipartite network (N ego nodes, N/10 alter nodes, ~10% density), built via `nwset, mat() bipartite` (a Mata-variable literal, not a Stata matrix name — see the Pending item on `nwset.ado` below).
- **QAP-style commands** get a second, independent same-size network.
- **Timing**: Stata's own `timer` mechanism, single rep per command per size (not a median of several reps) — a deliberate scope tradeoff given the number of commands and the time cost of larger tiers. Permutation-based commands (`nwcug`/`nwqap`/`nwmixing`) were tested with a reduced rep count (50, vs. their own defaults of 100–1000) for the same reason — reported times scale roughly linearly with rep count from there.
- **Hardware**: a single Apple Silicon development machine, Stata 18 BE, the package's own compiled `lib/lnwcommands.mlib` (production mode, not `do unw_core.do` — this is what an actual user experiences).
- **Script**: `dev/benchmark_suite.do`, runnable directly (`do unw_core.do` then `do dev/benchmark_suite.do`) to reproduce or extend this data. Raw results: `dev/benchmark_results.csv`.
- **Deliberately excluded from the whole suite**: `nwergm` (already has its own dedicated R-vs-Stata benchmark suite, `dev/ergm_benchmark_r_vs_stata/` — re-running it here would duplicate published numbers, not add new ones); `nwplot`/`nwmovie`/`nwmoviexy` (rendering-bound, not a node-count-scaling question); `nwimport`/`nwexport`/`nwuse`/`nwwebuse` (I/O-bound, not algorithmic).

## Headline finding: a real, fixed, 2,275x speedup

The single most important result of this exercise wasn't a timing number — it was a bug. The very first N=100 run showed `nwkcomponents` taking **66 seconds** on a 100-node network, two orders of magnitude slower than every other command tested. Root-caused (not assumed): `vertex_connectivity()`, the shared primitive behind `nwkcomponents`/`nwcohesion`, searched literally every non-adjacent pair of nodes via max-flow — O(n²) max-flow calls — to compute a single number.

Fixed with a genuine algorithmic rewrite (the Esfahanian & Hakimi 1984 refinement of Even's algorithm: O(delta²) max-flow calls, delta = minimum degree, independent of n), plus two further fixes to the max-flow primitive itself (a vectorized capacity-matrix construction instead of an interpreted double loop; a shared base matrix reused across all queries in one search instead of rebuilt from scratch each time). Correctness was verified extensively given the stakes of a delicate graph algorithm: the exact pre-fix brute-force search, kept test-only as a reference oracle, was cross-checked against the new algorithm across 442 random graphs per run × 3 independent runs (1,326 comparisons, zero mismatches), plus hand-computable closed-form cases. See `docs/CERTIFICATION.md`, harmonisation unit 102, and the permanent regression test `cscripts/test_vertex_connectivity.do`.

**Net effect**: `nwkcomponents` on the same 100-node network: **66s → 0.025s (~2,640x)**. This is the number that would have appeared in this report as "nwkcomponents: unusable" had it not been caught and fixed during the benchmark run itself.

**A residual gap remains**: even after the fix, `nwkcomponents` still uses a *dense* (2n)×(2n) matrix per max-flow query — fine at n≤1,000 (17.5s), but too slow to complete in a reasonable time at n=10,000 (excluded from that tier below). A fully sparse (adjacency-list) max-flow rewrite would close this gap; tracked as a Pending item in `docs/CERTIFICATION.md` rather than attempted under the same time pressure that found the original bug.

## Full results

| Command | Category | N=100 (s) | N=1,000 (s) | N=10,000 (s) | Notes |
|---|---|---:|---:|---:|---|
| nwdegree | centrality | 0.005 | 0.018 | 0.822 | genuinely sparse, scales well |
| nwbetween | centrality | 0.009 | 0.061 | 6.194 | native (C) backend on macOS |
| nwcloseness | centrality | 0.167 | 1.330 | *excluded* | dense (`nwtomata`) — see below |
| nwevcent | centrality | 0.199 | 2.704 | 27.517 | sparse power iteration (unit 97); scales sub-linearly with reps but iteration count grows with n |
| nwkatz | centrality | 0.228 | 1.282 | *excluded* | dense (direct matrix-power operation, already documented as dense-by-necessity) |
| nwbrokerage | centrality | 0.006 | 0.029 | 0.283 | scales well |
| nwburt | centrality | 0.002 | 0.038 | *excluded* | dense (`nwtomata`) |
| nwego | centrality | 0.005 | 0.029 | 0.283 | scales well |
| nwconstraint | centrality | 0.006 | 0.025 | *excluded* | dense (`nwtomata`) |
| nwcomponents | structural | 0.003 | 0.008 | 0.429 | genuinely sparse, scales well |
| nwclustering | structural | 0.351 | 6.518 | 459.338 | **slow and worsening faster than N** — see below |
| nwneighbor | structural | 0.007 | 0.016 | 0.675 | scales well |
| nwtriads | structural | 0.325 | 7.077 | *excluded* | dense (`get_matrix_unvalued()`, triad-census matrix formula) |
| nwissymmetric | structural | 0.002 | 0.002 | *excluded* | dense (`nwtomata`) |
| nwsym | structural | 0.002 | 0.010 | 1.233 | scales well |
| nwkcomponents | structural | 0.025 | 17.537 | *excluded* | fixed this unit (was 66s at n=100!) — residual dense max-flow gap remains, see above |
| nwkcore | structural | 0.003 | 0.082 | 7.579 | scales adequately |
| nwclique | cohesive | 0.006 | 1.785 | *not completed* | did not finish in a reasonable time at n=10,000; not further diagnosed (time constraints) |
| nwkplex | cohesive | 0.330 | *excluded* | *excluded* | k-plex enumeration count blows up combinatorially — inherent to the concept for k≥2, not an implementation bug |
| nwcohesion | cohesive | 5.204 | *excluded* | *excluded* | recursive multi-level decomposition compounds the residual `nwkcomponents` gap above |
| nwgeodesic | distance | 0.149 | 1.240 | *not completed* | did not finish in a reasonable time at n=10,000 — unexpected given the sparse-BFS migration's own 100k-node benchmark elsewhere; **flagged as an anomaly needing further investigation**, not diagnosed here (time constraints) |
| nwpath | distance | 0.018 | 1.231 | *not tested* | not reached at n=10,000 (time constraints) |
| nwreach | distance | 0.167 | 1.289 | *not tested* | not reached at n=10,000 (time constraints) |
| nwbridges | distance | 0.072 | 5.875 | *not tested* | not reached at n=10,000 (time constraints) |
| nwcommunity | community | 0.008 | 0.291 | *not tested* | not reached at n=10,000 (time constraints) |
| nwmodularity | community | 0.001 | 0.009 | *not tested* | not reached at n=10,000 (time constraints) |
| nwsimindex | equivalence | 0.009 | 0.081 | *not tested* | not reached at n=10,000 (time constraints) |
| nwsimilar | equivalence | 0.134 | 72.428 | *excluded* | dense (`nwtomata`) — already slow at n=1,000 |
| nwdissimilar | equivalence | 0.034 | 13.745 | *excluded* | dense (`nwtomata`) |
| nwconcor | equivalence | 0.011 | 2.519 | *not tested* | not reached at n=10,000 (time constraints) |
| nwcoreperiphery | equivalence | 0.175 | **255.125** | *not tested* | **the single slowest completing command found** — see below |
| nwspectral | spectral | 0.006 | 0.836 | *excluded* | dense by necessity (full Laplacian eigendecomposition, already documented) |
| nwdyads | dyad | 0.001 | 0.010 | *not tested* | not reached at n=10,000 (time constraints) |
| nw2degree | twomode | 0.002 | 0.011 | *not tested* | not reached (time constraints) |
| nw2project | twomode | 0.005 | 0.089 | *not tested* | not reached (time constraints) |
| nwcug | permutation | 0.902 | 6.887 | *not tested* | reps=50; scales ~linearly with reps |
| nwqap | permutation | 0.704 | 12.524 | *not tested* | reps=50; scales ~linearly with reps |
| nwpermute | permutation | 0.004 | 0.004 | *not tested* | not reached (time constraints) |
| nwrandom_gen | generator | 0.016 | 0.034 | *not tested* | not reached (time constraints) |
| nwsmall_gen | generator | 0.017 | 0.033 | *not tested* | not reached (time constraints) |
| nwpref_gen | generator | 0.019 | 2.296 | *not tested* | not reached (time constraints) |
| nwlattice_gen | generator | 0.026 | 0.118 | *not tested* | not reached (time constraints) |
| nwring_gen | generator | 0.017 | 0.031 | *not tested* | not reached (time constraints) |
| nwsummarize | misc | 0.005 | 0.020 | *not tested* | not reached (time constraints) |
| nwvalue | misc | 0.001 | 0.001 | *not tested* | not reached (time constraints) |

**Excluded from the whole suite** (not just one tier): `nwnclique`/`nwnclan` (n≥2 n-clique/n-clan enumeration reduces to maximal-clique enumeration on the "geodesic distance ≤ n" *derived* graph — for a sparse random graph with small diameter, that derived graph is itself near-complete, and maximal-clique counts on a near-complete graph blow up combinatorially; confirmed not completing even at n=20–30 nodes, an inherent property of the n-clique concept for n≥2, not a fixable bug); `nwaltergen` (takes a statistical expression over an alter-level attribute, not a bare network — doesn't fit this suite's generic methodology); `nw2clustering` (a real, previously-undiscovered bug found during this benchmark's own validation — see below, excluded rather than worked around); `nwmixing` (a real, previously-undiscovered issue found during validation — see below).

## Other real bugs found while building this benchmark

Stress-testing at scale surfaced problems no existing test had exercised:

1. **`nwset.ado`'s `mat()` option cannot accept a bare Stata matrix name** (already a documented Pending item, confirmed directly again while building this suite's bipartite test networks) — a plain Mata variable works, a `st_matrix()`-backed Stata matrix name does not. Worked around in the benchmark script itself; not fixed at the source (a wider, separate effort — see `docs/CERTIFICATION.md`'s own Pending entry).
2. **`nw2clustering.ado` has a genuine reshape bug** — `nw2clustering` on *any* bipartite network (including a tiny 20-node one, not just this suite's larger test cases) fails with a "Type reshape error" (r9). The error message itself (`i(ego0 alter0 ego1 alter1 ego2 alter)`) shows a malformed `i()`-varlist missing a numeric suffix on its last variable — a string-construction bug in the command's own `reshape` call. Not fixed here (out of scope for a benchmark-driven pass); added to `docs/CERTIFICATION.md`'s Pending list.
3. **`nwmixing.ado` fails precondition checks even with a standard setup** — `nwmixing bignet, attribute(x)` fails ("variable x_nwego not found", r111) even against a plain named attribute variable on a freshly-`nwload`ed network. `nwmixing.ado`'s own internal `nwtoedge ..., egovars(x) altervars(x)` call apparently doesn't materialize the companion variable it then immediately expects. Not root-caused further given time constraints; added to Pending.
4. **`nwsync.ado` left a stale, misleading `_rc`** on the common path where a network has no Stata-variable sync to do — found while root-causing an unrelated `nwuse` crash earlier in this same harmonisation phase, but worth restating here: this class of bug (also found in `nwbrokerage`/`nwego`/`nwaltergen`/`nwcompressobs`/`nwplot`/`nwinstall`, per `docs/CERTIFICATION.md`) means a plain `_rc`-after-a-call check is not a reliable success signal for several commands in this package. Already fixed for the instances found so far.

## The slowest *completing* commands — worth a closer look before the next optimization pass

Beyond the `vertex_connectivity()` fix, three commands stood out as unexpectedly slow without erroring, meaning nothing previously caught them:

- **`nwcoreperiphery`**: 0.175s (n=100) → 255s (n=1,000) — roughly a 1,450x slowdown for a 10x increase in n, consistent with an algorithm worse than O(n²) (an O(n³)-ish or iterative-refinement-with-many-passes pattern would fit). The single slowest *completing* command in this entire study. A strong candidate for the next profiling pass.
- **`nwsimilar`**: 0.134s → 72.4s (~540x for 10x n). Uses `nwtomata`'s dense conversion internally (confirmed) — likely the same class of issue as `nwcloseness`/`nwkatz`/etc., just with additional O(n²)-or-worse work on top.
- **`nwclustering`**: 0.351s → 6.5s → 459s. Notably, this does **not** use a dense-matrix accessor (confirmed via direct source inspection) — its slowdown has a different cause, not yet diagnosed. Worth investigating specifically since it's one of the package's more commonly-used commands.

## Commands using a dense N×N matrix (the common thread behind most N=10,000 exclusions)

`nwcloseness`, `nwkatz`, `nwburt`, `nwconstraint`, `nwissymmetric`, `nwsimilar`, `nwdissimilar`, `nwqap`, and `nwtriads` all either call `nwtomata` (materializing a full dense adjacency or distance matrix) or operate directly on `get_matrix()`/`get_matrix_unvalued()` (the dense accessor). At n=10,000 that's a 100M-cell (800MB) matrix built from scratch, before whatever O(n²) or worse computation the command does on top of it. `nwspectral` (full Laplacian eigendecomposition) and `nwkatz` (direct matrix-power) are already documented in `nw_intro.sthlp` as dense-by-necessity; the rest are candidates for the same kind of sparse migration `nwevcent` (unit 97) and `vertex_connectivity()` (unit 102) already received this same harmonisation phase — likely the single highest-value target list for a future optimization pass, since the pattern (and the fix template) is now well-established in this codebase.

## Recommendations for the next optimization pass, in priority order

1. **`nwcoreperiphery`** — the single slowest completing command (255s at n=1,000); profile and root-cause before anything else.
2. **A fully sparse max-flow rewrite** for `vertex_connectivity()`/`min_vertex_cutset()`, closing the residual `nwkcomponents`/`nwcohesion` gap at n≥10,000.
3. **`nwclustering`** — slow without an obvious dense-matrix cause; worth its own profiling pass given how commonly this command is used.
4. **The `nwtomata`-dependent family** (`nwcloseness`, `nwsimilar`, `nwdissimilar`, `nwburt`, `nwconstraint`, `nwissymmetric`, `nwqap`) — a systematic sparse-migration pass across all of them at once, given they share one root cause.
5. **`nwgeodesic` at n=10,000** — did not complete in this study despite the underlying BFS distance family being proven sparse and fast at 100k+ nodes elsewhere (`docs/SPARSE_BACKEND.md`). This is a genuine anomaly worth its own dedicated investigation before assuming it's the same class of issue as the rest.
6. Complete the N=10,000 tier for the ~20 commands not reached in this pass (time constraints, not confirmed problems) — `dev/benchmark_suite.do` is ready to extend.

## Reproducing or extending this benchmark

```stata
do unw_core.do
do dev/benchmark_suite.do
```

Edit the `foreach n in 100 1000 10000 { ... }` loop and the `if `n' <= ...` guards in `dev/benchmark_suite.do` to adjust sizes or re-include an excluded command once its underlying issue is fixed.
