# Certification Status

Living document. Last updated: 2026-08-21.

Per-feature stage tracking. A feature is not "done" until all four stages are checked: **implemented** (code written) → **tested** (cscripts test exists and passes, both dev and production mode) → **certified** (verified against known-correct values / dense-vs-sparse regression / edge cases, per the certification standard below) → **documented** (`.sthlp` exists and is current, including any new options/limitations).

## Certification standard (applied to every row below)

- **Syntax**: valid Stata syntax, documented options work, invalid options fail cleanly, missing required inputs give an informative error.
- **Functional**: verified against a small network with an analytically known correct answer.
- **Regression** (where replacing/extending existing code): compared against the prior implementation on small networks; if results differ, the discrepancy is investigated and documented, not silently accepted.
- **Edge cases**: empty network, isolates, disconnected components, directed/undirected, weighted, self-loops, non-consecutive node IDs — as applicable to the feature.
- **Scalability** (sparse-backend features only): tested on a realistically large sparse network, memory/time checked, absence of accidental dense allocation confirmed.

## Status table

| Feature | Implemented | Tested | Certified | Documented | Notes |
|---|---|---|---|---|---|
| Sparse index (`neighbors`/`degree`/`has_edge`/`edge_weight`/`edgelist`) | ✅ | ✅ | ✅ | ✅ (this doc + inline comments) | `test_sparse_index.do`, both modes |
| `set_edge_from_triplets`/`create_by_name_sparse`/lazy materialization | ✅ | ✅ | ✅ | ✅ | `test_sparse_lazy_dense.do`, both modes; benchmark at 3 tiers |
| `calculate_components()` sparse migration | ✅ | ✅ | ✅ | ✅ | byte-identical to prior dense output |
| `calculate_clustering()` sparse migration + self-inclusion bugfix | ✅ | ✅ | ✅ | ✅ | dead code (zero callers), bugfix documented in-line |
| `calculate_betweenness()` sparse migration + dequeue/brace/nosym/halving fixes | ✅ | ✅ | ✅ | ✅ | `test_nwbetween.do`, both modes; first-ever successful execution of this command |
| `get_outdegree()`/`get_indegree()` sparse migration | ✅ | ✅ | ✅ | ✅ | `test_nwdegree.do` (existing), both modes |
| `nwvalue.ado` bracket-syntax + off-by-one fix | ✅ | ✅ | ✅ | ✅ | `test_nwvalue.do` |
| `nwclustering.ado` rename-quirk fix | ✅ | ✅ | ✅ | — (no doc change needed, internal fix) | `test_nwclustering.do` |
| `nwgeodesic.ado`/`nwdyadprob.ado` `nw_syntax`-clobbering fixes | ✅ | ✅ | ✅ | — | `test_nwgeodesic.do`, `test_nwdyadprob.do` |
| `nwcommunity`/`nwmodularity` (Louvain community detection) | ✅ | ✅ | ✅ | ✅ | 3 hand-computable networks, exact match |
| `build_sparse_index()` rowidx sizing bugfix | ✅ | ✅ | ✅ | ✅ | dedicated regression test added |

## Session 2 additions (2026-08-21)

| Feature | Implemented | Tested | Certified | Documented | Notes |
|---|---|---|---|---|---|
| `nw2project` (two-mode one-mode projection) | ✅ | ✅ | ✅ | ✅ | Phantom command (spec existed, .ado didn't) built fresh, sparse-native. All 5 `stat()` formulas match the pre-existing documented worked example exactly. `test_nw2project.do`, both modes. |
| `nwburt` (Burt structural holes: effsize/efficiency/constraint/hierarchy) | ✅ | ✅ | ✅ | ✅ | Revived from git history (`master:nwburt.ado`), modernized (`nw_syntax`, `st_store`, `replace` guard). Found and fixed a real bug in the process: matrix multiplication on a missing-diagonal input silently corrupts every two-step redundancy/constraint calculation to 0 — fixed by zeroing the diagonal before the matrix products. `test_nwburt.do`, both modes, matches both documented worked examples (star=3, K4=1) and a from-scratch regression re-derivation of the historical formulas. |
| `nwkcore` (k-core decomposition) | ✅ | ✅ | ✅ | ✅ | New command + new `NWdef::calculate_kcore()` Mata method (standard Seidman 1983 iterative degree-peeling, monotone `core[v]=max(klevel, degree_at_removal)`). Directed networks use the union of out/in-neighbors, matching `nwcomponents`' directed-network convention. Draft caught and fixed a real bug before testing: an initial `pointer(real matrix) rowvector` design aliased every pointer to the same reused loop variable — rewritten as a padded dense `adjmat` matrix (matching the existing `get_adjlist()` idiom) instead. Certified against 4 hand-computable cases: triangle+pendant (2,2,2,1), K5 (all 4, the (n-1)-core of Kn), empty network (all 0), path graph (all 1, no 2-core in an acyclic graph), plus a directed-network case and a `replace`-guard check. `test_nwkcore.do`, both modes. |
| `nwaltergen` (alter/neighbor attribute aggregation, `nwgen exposure = mean(alter.x)`-style) | ✅ | ✅ | ✅ | ✅ | New command + new `NWdef::calculate_alterstat()` Mata method. Implements `mean`/`sum`/`min`/`max`/`sd`/`count` aggregation of an existing Stata variable's values over each node's alters (out-neighbors for directed networks — a deliberate, documented difference from `nwkcore`'s union-of-both-directions convention, since exposure is inherently directional). Missing `srcvar` values among a node's alters are dropped before aggregating (available-case, matching `egen`), never silently propagated — the exact failure mode found in the `nwburt` matrix-multiplication bug earlier this session, guarded against explicitly here by design rather than discovered by accident. `nwgen` itself gained a narrow `regexm()` pre-check dispatching `mean(alter.x)`-style calls straight to `nwaltergen`, implemented as a pure early-return in `nwgen.ado` with zero changes to the fragile legacy string-parser in `nwgenerate.ado` — a regression test confirms the existing `nwgenerate` dispatch shortcuts (e.g. `duplicate(...)`) are unaffected. Certified against a star network (hand-computed mean/sum/min/max/sd/count with a missing alter value dropped correctly), a directed network (out-neighbor-only semantics), an isolate node (sum/count=0, others missing), the `nwgen` shortcut's output matching `nwaltergen` directly, the `replace` guard, and invalid-stat/missing-variable error paths. `test_nwaltergen.do`, both modes. |
| `nwgeodesic`: per-node eccentricity + network radius | ✅ | ✅ | ✅ | ✅ | Additive extension to an existing, already-tested command — no `unw_core.do` change (reuses the already-computed distance matrix and the pre-existing `rowmax()` builtin), so no `.mlib` rebuild was needed. Adds `generate()` (default `_eccentricity`) and `r(radius)`, following the exact same "undefined" convention already used by `r(diameter)`/`r(avgpath)` (missing per-node, `r(radius)=-1` in aggregate) when the network has unconnected pairs and `unconnected()` wasn't specified. Found and worked around a genuine Stata `syntax`-parser bug during implementation: declaring a new `replace` option in the same syntax line as the file's pre-existing (dead, unused) `noreplace` option causes Stata to silently fail to populate the `replace` local at all, confirmed via an isolated minimal repro before touching the real file — worked around by reusing the already-functional `nwreplace` for the eccentricity-variable guard instead of adding a second, broken `replace` option; documented in-line. Certified against a path graph (ecc 4,3,2,3,4; radius=2), K4 (all ecc=1, radius=1), a disconnected network (undefined case, both aggregate and per-node), and the same case with `unconnected(max)` (all become finite); extended the pre-existing `test_nwgeodesic.do` (not a new file) with radius/eccentricity assertions on its existing directed-valued fixture across all 3 of its pre-existing invocation patterns, confirming zero regression to any prior assertion. Both modes. |

| `nwgenvar` dead-code fix | ✅ | ✅ | ✅ | ✅ (inherits `nwgen`'s doc) | Was a broken duplicate of `nwgenerate.ado` under a mismatched filename, never actually loadable as `nwgenvar`. Converted to a genuine thin wrapper matching `nwgen.ado`'s proven pattern. Verified working via `nwgenerate.ado`'s own certified test pattern. |
| `nwgenerate.ado` dead dispatch branches | ✅ (partial) | ✅ | ✅ | — | 8 silently-no-op'ing shortcut branches (`dyadprob`/`homophily`/`lattice`/`path`/`pref`/`ring`/`small`/`transpose`) now give a clear, immediate error instead of silently doing nothing. Full restoration (re-wiring each to its target command's current syntax) deferred - see ROADMAP.md Stage 1. |
| `nwbalance` docs+tests+bugfix | ✅ | ✅ | ✅ | ✅ | Was undocumented (no `.sthlp`) and untested. Also fixed a real bug: an unconditional `save test, replace` wrote an unwanted `test.dta` into the user's working directory on every call (unused debug leftover) - removed. Certified against a hand-derived signed-K4 worked example (Cartwright-Harary strong balance). One genuine pre-existing limitation found and documented, not silently fixed: a network with zero closed triads errors (r(2000)) instead of reporting zero - flagged in ROADMAP.md as a real gap in the reshape-based triad enumeration pipeline. |

## Pending (queued for implementation, not yet started)

| Feature | Priority (see ROADMAP.md) | Est. effort |
|---|---|---|
| `nwgenerate.ado` full shortcut restoration (8 branches) | Stage 1 | Medium |
| `nwbalance` zero-closed-triads edge case | Stage 1 | Small-Medium |
| Alter-aggregation (`nwgen ... = mean(alter.x)`) | Stage 5, top | Medium |
| Distance-family sparse migration | Stage 0 remainder | Large |
| `nwqap` → `eclass` + QAPSPP → `nwregress`/`nwlogit` | Stage 4 | Large |
| Cliques/k-plexes (cohesive subgroups beyond k-core) | Stage 2 | Medium |
| `nwaltergen`: `proportion`-style categorical aggregation, lagged/multi-hop exposure | Stage 5 follow-on | Small-Medium |
