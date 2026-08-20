# nwcommands Roadmap

Living document. Last updated: 2026-08-21. See `docs/FEATURE_AUDIT.md` for the evidence behind every claim here, and `docs/SPARSE_BACKEND.md` for the sparse-migration architecture.

## Guiding principle

Modern scalable graph algorithms + classical SNA + network inference + deep Stata integration, on the existing `nw*` command surface. No new prefix, no wholesale rewrites, no silent behavior changes. Preserve compatibility; extend and consolidate before adding exotic new areas.

## Priority framework (used to rank everything below)

1. Scientific usefulness
2. Frequency of likely use
3. Dependencies on other functionality
4. Ability to exploit/test the sparse backend
5. Competitive importance relative to igraph/sna/UCINET
6. Stata-specific workflow advantage
7. Infrastructure value for later features

## Stage 0 — Sparse backend and architecture — mostly done

Commits 1-7 complete and verified (see `docs/SPARSE_BACKEND.md`): additive CSR/CSC sparse index, `calculate_components`/`calculate_clustering`/`calculate_betweenness`/`get_outdegree`/`get_indegree` migrated, genuinely sparse-native construction (`set_edge_from_triplets`), lazy dense materialization with a size-guarded compatibility shim, benchmark proving the 100k-node/1M-edge milestone. **Remaining**: `nwfromedge.ado` itself is not yet rewired to the sparse-native construction path (its downstream side effects — `nwsym` symmetrization, bipartite embedding, `nw_datasync` — need their own audit first); the distance family (`calculate_distances`/`Brute_dist`/`Dijkstra_dist`, feeding `nwgeodesic`/`nwcloseness`/`nwreach`/`nwbridges`/`nwpath`) is still fully dense and is the single highest-value remaining sparse-migration target, since it blocks 5 downstream commands.

## Stage 1 — Consolidate existing functionality

Cheap, high-confidence fixes to things already built:
- ✅ Fixed `nwgenvar.ado` (was dead code — filename/program-name mismatch, never actually loadable; now a genuine thin wrapper matching `nwgen.ado`).
- ✅ `nwgenerate.ado`'s 8 dead commented-out dispatch branches (`dyadprob`/`homophily`/`lattice`/`path`/`pref`/`ring`/`small`/`transpose`) now error clearly instead of silently no-op'ing. **Remaining**: actually restore each shortcut against its target command's current syntax (each needs individual verification — the commented-out bodies predate several syntax changes) — Medium effort, not done yet.
- ✅ Documented `nwbalance.ado` (structural balance) — `.sthlp` written, `cscripts/test_nwbalance.do` added, certified against a hand-derived signed-K4 worked example. Also fixed a real bug (`save test, replace` polluting the user's working directory with an unused debug file). **Found, not fixed**: a network with zero closed triads errors instead of returning zero — the Stata-reshape-based triad enumeration pipeline needs an empty-result guard; flagged as its own follow-up (Small-Medium effort) rather than risked in the same pass as the documentation work.
- Document `nwrecode.ado` — write `.sthlp`. Real, correct, currently invisible.
- Add missing test coverage for otherwise-solid commands found untested this audit: `nwdyads`, `nwqap`, `nwsimilar`, `nwdissimilar`, `nwhierarchy`, `nwplot` (largest file in the package, zero tests), `nwneighbor`'s migration to sparse accessors.
- Migrate `nwneighbor.ado` to the sparse `neighbors()`/`neighbors_in()` accessors (small, low-risk, already-proven pattern).
- Fix silent weight-handling gaps: betweenness (add a weighted/Dijkstra-based variant alongside the existing unweighted one — do not change the current default without a documented, tested option), eigenvector centrality (`nosym`-style `weighted` option instead of always dichotomizing).

## Stage 2 — Core graph-analysis gaps

Highest-value additions for credible igraph-style coverage:
- Complete the distance-family sparse migration (unblocks `nwcloseness`/`nwgeodesic`/`nwreach`/`nwbridges`/`nwpath` scalability).
- ✅ Cohesive subgroups: k-cores — `nwkcore` + `NWdef::calculate_kcore()`, sparse-neighbor-based degree-peeling (Seidman 1983), certified against 4 hand-computable cases (see `docs/CERTIFICATION.md`). **Remaining**: cliques/k-plexes.
- ✅ Per-node eccentricity + network radius — added to `nwgeodesic` (`generate()`, `r(radius)`). Surfaced a genuine Stata `syntax`-parser bug along the way (see `docs/CERTIFICATION.md`).
- Common-neighbor similarity family (Jaccard/Dice/cosine/Adamic-Adar) — also directly useful as an ERGM/one-mode-projection primitive later.

## Stage 3 — Classical social network analysis (high priority per project brief)

- **`nw2project`** — build fresh from its own existing, complete `.sthlp` spec (three cross-references already document `project()`/`stat(min|max|sum|mean)`). Highest-value, lowest-ambiguity item in the whole audit.
- **`nwburt`** — revive from git history (`git show master:nwburt.ado`), modernize against the current `NWdef` API, certify. Complete Burt suite (effective size, efficiency, constraint with proper per-node aggregation, hierarchy) already proven and documented historically.
- Structural equivalence: package the existing `nwsimilar`→`nwhierarchy`→`nwdendrogram` chain as a documented "role/position analysis" workflow; add an equivalence-class-to-Stata-variable output step (mirroring `nwcomponents`' pattern).
- CONCOR — natural extension of the existing similarity engine; genuinely new algorithm work but with reusable input machinery already in place.
- Blockmodeling / core-periphery — from scratch; the `nwsimilar`/`nwdissimilar` engine is the reusable input layer.
- Ego-network extraction as a true induced subgraph (currently only neighbor *listing* exists) — prerequisite for ego-network size/density/composition/effective-size, which are all otherwise blocked.

## Stage 4 — Network inference

- `nwqap` → `nwregress`/`nwlogit`: wrap in a proper `eclass` shell (own `e(b)`/`e(V)`/`predict`), add QAPSPP (X-permutation/semi-partialling) as a second inference mode alongside the existing simple Y-permutation, certify with tests, confirm `esttab`/`estimates store` compatibility. Extension of substantial existing machinery, not a from-scratch build.
- CUG tests — wire `nwrandom, census()`'s existing conditioned-generation capability into a formal hypothesis-test command (generate K conditioned random networks, compare an observed statistic's percentile). The hard part (conditioned generation) already exists.

## Stage 5 — Stata-native integration (high priority per project brief)

- ✅ **Alter/neighbor aggregation** (`nwgen exposure = mean(alter.smoking)`-style): `nwaltergen` (new command) + `NWdef::calculate_alterstat()`, supporting `mean`/`sum`/`min`/`max`/`sd`/`count`. `nwgen` dispatches to it automatically via a narrow, isolated `regexm()` pre-check that leaves `nwgenerate.ado`'s fragile legacy parser completely untouched. The single highest-leverage gap found in this audit for Stata-specific competitive differentiation — no comparable one-line syntax exists in igraph/sna's R-based workflows. **Remaining**: `proportion()`-style categorical aggregation (achievable today via `mean()` on a 0/1 indicator, so not a hard blocker), lagged/multi-hop exposure.
- Dyadic dataset export (general, not just dyad-census) — natural pairing with the above.
- Ego/alter comparison variables, lagged network exposure — follow-on extensions once the aggregation primitive exists.

## Stage 6 — Advanced graph functionality

Community algorithms beyond Louvain (Leiden, label propagation — cheap additions to the same `NWdef` Louvain infrastructure), motifs beyond triads, flow/cuts/matching (from scratch), spectral analysis (Laplacian construction + the already-proven `symeigensystem()` call pattern from `nwevcent`), random walks, large-network layouts for `nwplot`.

## Stage 7 — Dynamic/multiplex/relational-event functionality

Only after Stage 0-6 mature. Real reusable adjacency already exists (`NWsdef` multi-network storage, `nwcorrelate`, `nwmovie`'s multi-frame animation) — a stability/turnover command is a smaller lift than the "confirmed E" status suggests once those pieces are assembled deliberately.

## Stage 8 — Native ERGM (long-term flagship)

Starts from zero, not from `nwergm.ado` (which is an R-bridge, not native — see audit). Prerequisites, in order: (1) an incremental single-edge sparse-index update path (current `build_sparse_index()` is a full O(N+M) rebuild with no patch capability — unacceptable for an MCMC inner loop toggling edges thousands of times/iteration); (2) a per-node/edge attribute-caching layer in `NWdef` (currently zero attribute storage in Mata — a deliberate design decision needed before `nodematch()`/`nodecov()`/`edgecov()` are possible without a prohibitively slow per-step Stata-dataset round-trip); (3) a reusable common-neighbor/shared-partner primitive (currently computed inline, differently, in two different places, decomposing to neither a per-edge nor an incremental statistic).

## Top 20 additions ranked by value/effort

1. `nw2project` (two-mode projection) — Medium value, Small effort, spec already written
2. `nwburt` revival — High value, Small effort, proven historical code
3. `nwbalance` docs+tests — Medium value, Trivial effort
4. Fix `nwgenvar`/`nwgenerate` dead code — Low value individually, Trivial effort, correctness hygiene
5. ✅ Alter-aggregation (`mean(alter.x)`) — Very high value, Medium effort, top competitive differentiator — done (`nwaltergen`, `nwgen` shortcut)
6. Distance-family sparse migration — High value (unblocks 5 commands), Large effort
7. ✅ k-cores — High value, Small-Medium effort — done (`nwkcore`)
8. Weighted betweenness variant — Medium value, Small effort
9. `nwneighbor` sparse migration — Low value alone, Small effort, low risk
10. `nwqap` → `eclass` + QAPSPP → `nwregress`/`nwlogit` — Very high value, Large effort
11. CUG test wrapper around `nwrandom, census()` — Medium value, Small effort
12. Common-neighbor similarity family (Jaccard/Dice/cosine/Adamic-Adar) — Medium-high value, Small-Medium effort
13. Structural-equivalence workflow packaging + role-variable output — Medium value, Small effort
14. ✅ Per-node eccentricity + radius — Low-medium value, Trivial effort — done (`nwgeodesic`)
15. Ego-network induced-subgraph extraction — Medium value (unblocks ego-network size/density/composition), Medium effort
16. Export-format parity (add GML/GraphML/edgelist to `nwexport`) — Low-medium value, Small effort
17. CONCOR — Medium value, Medium effort
18. `nwplot` test coverage (largest untested file in the package) — Risk-reduction value, Medium effort (many code paths)
19. Programming-API documentation chapter — Medium value (unlocks third-party extensibility), Small effort, pure documentation
20. Weighted eigenvector centrality option — Small value, Small effort

## Top 10 existing features to improve

1. `nwqap` — add `eclass`, QAPSPP, tests (see Stage 4)
2. `nwgeodesic`/`nwcloseness`/`nwreach`/`nwbridges`/`nwpath` — sparse migration (see Stage 0 remainder)
3. `nwconstraint` — either fold into the revived `nwburt` or add per-node aggregation + help file
4. `nw2clustering` — sparse migration (currently O(N⁴)-shaped Stata reshape chain)
5. `nwbetween` — add a genuinely weighted (Dijkstra-based) variant
6. `nwevcent` — add a weighted option, migrate off forced dense materialization where possible
7. `nwneighbor` — sparse migration + add induced-subgraph output (feeds Stage 3's ego-network work)
8. `nwexport` — format parity with `nwimport` (currently 2 vs 6 formats)
9. `nwplot` — test coverage (zero tests on the package's largest file)
10. `nwrecode`/`nwbalance` — documentation (real functionality, currently invisible)

## ERGM-readiness notes

See Stage 8 and `docs/FEATURE_AUDIT.md`'s AH section. Summary: architecture is closer to ERGM-ready than it looks for read-heavy operations (fast `has_edge`/neighbor lookup exist as of this session), but the MCMC-critical path — incremental edge toggling without a full index rebuild — does not exist yet and is the correct first prerequisite, not attribute storage or common-neighbor counting (those matter too, but toggling cost dominates ERGM runtime by orders of magnitude if unaddressed).

## Open items requiring a follow-up audit pass

- Area J (similarity/homophily/mixing/assortativity) fell between fork assignments this pass — needs a dedicated read of `nwhomophily.ado` and a clean confirmation of assortativity's absence.
- `nwkatz.ado` does not appear to do genuine Katz-style eigen-computation (just `rowsum`/`colsum`) — worth a dedicated correctness audit against the literature definition.
- GML/GraphML import paths in `nwimport.ado` have lower test-fixture confidence than Pajek/UCINET — worth a dedicated correctness pass with real sample files.
