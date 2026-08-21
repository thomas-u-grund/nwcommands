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
- ✅ Documented `nwbalance.ado` (structural balance) — `.sthlp` written, `cscripts/test_nwbalance.do` added, certified against a hand-derived signed-K4 worked example. Also fixed a real bug (`save test, replace` polluting the user's working directory with an unused debug file). **Follow-up now done** (harmonisation unit 14): the zero-closed-triads edge case (a network with no triangles errored r(2000) instead of returning zero) is fixed with an explicit empty-result guard, verified with real assertions in `cscripts/test_nwbalance.do`.
- Document `nwrecode.ado` — write `.sthlp`. Real, correct, currently invisible.
- Add missing test coverage for otherwise-solid commands found untested this audit: `nwdyads`, `nwplot` (largest file in the package, zero tests), `nwneighbor`'s migration to sparse accessors. `nwqap` now has substantial test coverage (see harmonisation units 9/15/19); `nwsimilar`/`nwdissimilar`/`nwhierarchy` now do too (see harmonisation unit 20 - this was also a full functional unblock, not just test coverage, see below).
- ✅ Migrated `nwneighbor.ado` to the sparse `neighbors()`/`neighbors_in()` accessors. Surfaced a real, previously-invisible bug: the old `mode(incoming)` branch had a stray unbalanced paren (a genuine Mata syntax error) and had zero test coverage — could never have actually run. Now fixed and certified (see `docs/CERTIFICATION.md`).
- ✅ Fix silent weight-handling gaps: betweenness — done (harmonisation unit 18): added a weighted/Dijkstra-based `weighted` option alongside the existing unweighted default, which is unchanged (a genuine additive option, not a behavior change to any existing call). Eigenvector centrality — already done (see the ✅ item below, `nwevcent, weighted`).

## Stage 2 — Core graph-analysis gaps

Highest-value additions for credible igraph-style coverage:
- Complete the distance-family sparse migration (unblocks `nwcloseness`/`nwgeodesic`/`nwreach`/`nwbridges`/`nwpath` scalability).
- ✅ Cohesive subgroups: k-cores — `nwkcore` + `NWdef::calculate_kcore()`, sparse-neighbor-based degree-peeling (Seidman 1983), certified against 4 hand-computable cases (see `docs/CERTIFICATION.md`). **Remaining**: cliques/k-plexes.
- ✅ Per-node eccentricity + network radius — added to `nwgeodesic` (`generate()`, `r(radius)`). Surfaced a genuine Stata `syntax`-parser bug along the way (see `docs/CERTIFICATION.md`).
- ✅ Common-neighbor similarity family — `nwsimindex` (common/jaccard/dice/cosine/Adamic-Adar), computed via one matrix multiply rather than a per-pair loop. Deliberately distinct from `nwsimilar.ado` (structural equivalence over full tie profiles, a different question). Surfaced two follow-on items — see `docs/CERTIFICATION.md`: `nw2project`'s `replace` option has the same bug this command's own `replace` was fixed to avoid (Pending), and `nw_helpwriter.ado`'s certification check was fragile against a common `capture`+`assert` test idiom (now fixed — see its own certified row; a full audit of the rest of the package's `.sthlp` files against the same historical gap remains Pending).

## Stage 3 — Classical social network analysis (high priority per project brief)

- **`nw2project`** — build fresh from its own existing, complete `.sthlp` spec (three cross-references already document `project()`/`stat(min|max|sum|mean)`). Highest-value, lowest-ambiguity item in the whole audit.
- **`nwburt`** — revive from git history (`git show master:nwburt.ado`), modernize against the current `NWdef` API, certify. Complete Burt suite (effective size, efficiency, constraint with proper per-node aggregation, hierarchy) already proven and documented historically.
- ✅ **`nwsimilar`/`nwdissimilar`/`nwhierarchy` chain fully unblocked** (harmonisation unit 20): the third, previously-unresolved layer of breakage is now root-caused and fixed — see `docs/CERTIFICATION.md`. All three commands run end-to-end, certified with hand-verified numeric assertions. **Remaining** (re-scoped down from "resolve nwset issue first" to just the packaging work originally envisioned): package the chain as a documented "role/position analysis" workflow; add an equivalence-class-to-Stata-variable output step (mirroring `nwcomponents`' pattern) — Small-Medium effort now that the chain itself works.
- ✅ CONCOR — done (harmonisation unit 21): `nwconcor`, a new command with recursive `splits(k)` multi-level blockmodeling (up to 2^k blocks), directed networks supported natively (no `symmetrize` needed, unlike `nwcommunity`).
- ✅ Discrete core-periphery detection — done (harmonisation unit 22): `nwcoreperiphery` (Borgatti & Everett 1999), a new `NWdef::calculate_coreperiphery()` Mata method using greedy local search (the same character of algorithm as `nwcommunity`'s Louvain, fixed reproducible node order). Full blockmodeling (image matrices, SBM, goodness-of-fit) remains E - the `nwsimilar`/`nwdissimilar` engine (fully functional since harmonisation unit 20) is the reusable input layer for that.
- Ego-network extraction as a true induced subgraph (currently only neighbor *listing* exists) — prerequisite for ego-network size/density/composition/effective-size, which are all otherwise blocked.

## Stage 4 — Network inference

- ✅ `nwqap` `eclass` shell — done (harmonisation unit 19): `ereturn post` of `e(b)`/`e(V)` (the latter a diagonal QAP-permutation-variance matrix, not a classical covariance), plus `e(N)`/`e(permutations)`/`e(cmd)`/`e(title)`/`e(depvar)`/`e(qap_regcmd)`/`e(pvalues)` — `estimates store`/`estimates table`/`test`/`lincom` all verified working. **Remaining**: a `predict` subroutine; QAPSPP (X-permutation/semi-partialling) as a second inference mode alongside the existing simple Y-permutation; confirm `esttab` compatibility; a possible dedicated `nwregress`/`nwlogit` command pair if a more Stata-native interface is wanted beyond `nwqap`'s current "any regression command via `type()`" design.
- ✅ CUG tests — `nwcug`, wired against `nwrandom, density()`'s existing conditioned-generation capability (density conditioning, not `census()` — dyad-census conditioning for directed/reciprocity-focused tests remains a natural follow-on, not yet built). `stat()` takes a full command template (`##net##` token) rather than a bare command name, after finding that approach breaks on the second random draw for any command with a fixed-name default output variable.

## Stage 5 — Stata-native integration (high priority per project brief)

- ✅ **Alter/neighbor aggregation** (`nwgen exposure = mean(alter.smoking)`-style): `nwaltergen` (new command) + `NWdef::calculate_alterstat()`, supporting `mean`/`sum`/`min`/`max`/`sd`/`count`. `nwgen` dispatches to it automatically via a narrow, isolated `regexm()` pre-check that leaves `nwgenerate.ado`'s fragile legacy parser completely untouched. The single highest-leverage gap found in this audit for Stata-specific competitive differentiation — no comparable one-line syntax exists in igraph/sna's R-based workflows. ✅ `proportion()`-style categorical aggregation — done (harmonisation unit 26): `proportion(alter.srcvar==value)`/`!=value`, a genuine convenience for picking out one category of a multi-level variable without first hand-building a 0/1 indicator (which `mean()` already covered, and still does - `proportion()` is deliberately not offered without a comparison, to keep one unambiguous way to ask for that case). ✅ Lagged/multi-hop exposure — done (harmonisation unit 28): `hop(k)` aggregates over nodes exactly `k` (unweighted) steps away instead of direct neighbors, via a new `NWdef::calculate_alterstat_hop()` Mata method; combines with `proportion()` too. This completes every item originally scoped for `nwaltergen`'s alter-aggregation work.
- Dyadic dataset export (general, not just dyad-census) — natural pairing with the above.
- Ego/alter comparison variables, lagged network exposure — follow-on extensions once the aggregation primitive exists.

## Stage 6 — Advanced graph functionality

Community algorithms beyond Louvain (Leiden, label propagation — cheap additions to the same `NWdef` Louvain infrastructure), motifs beyond triads, flow/cuts/matching (from scratch), spectral analysis (Laplacian construction + the already-proven `symeigensystem()` call pattern from `nwevcent`), random walks, large-network layouts for `nwplot`.

## Stage 7 — Dynamic/multiplex/relational-event functionality

Only after Stage 0-6 mature. Real reusable adjacency already exists (`NWsdef` multi-network storage, `nwcorrelate`, `nwmovie`'s multi-frame animation) — a stability/turnover command is a smaller lift than the "confirmed E" status suggests once those pieces are assembled deliberately.

## Stage 8 — Native ERGM (long-term flagship)

Starts from zero, not from `nwergm.ado` (which is an R-bridge, not native — see audit). Prerequisites, in order: (1) an incremental single-edge sparse-index update path (current `build_sparse_index()` is a full O(N+M) rebuild with no patch capability — unacceptable for an MCMC inner loop toggling edges thousands of times/iteration); (2) a per-node/edge attribute-caching layer in `NWdef` (currently zero attribute storage in Mata — a deliberate design decision needed before `nodematch()`/`nodecov()`/`edgecov()` are possible without a prohibitively slow per-step Stata-dataset round-trip); (3) a reusable common-neighbor/shared-partner primitive (currently computed inline, differently, in two different places, decomposing to neither a per-edge nor an incremental statistic).

## Top 20 additions ranked by value/effort

1. ✅ `nw2project` (two-mode projection) — Medium value, Small effort, spec already written — done (commits `1ba195e`/`531e018`; the roadmap checkmark was simply never added at the time). Re-verified working (`cscripts/test_nw2project.do` passes) during the harmonisation-phase Part I re-audit; "Supported network types" section added (harmonisation unit 17) — status **A**.
2. ✅ `nwburt` revival — High value, Small effort, proven historical code — done (commit `1ba195e`). Re-verified working (`cscripts/test_nwburt.do` passes) during the harmonisation-phase Part I re-audit; "Supported network types" section added, and a real, subtle math gotcha found and fixed in `nwconstraint`'s own docs while cross-checking the two commands against each other (harmonisation unit 17 — see `docs/CERTIFICATION.md`) — status **A**.
3. ✅ `nwbalance` docs+tests — Medium value, Trivial effort — done, including the zero-closed-triads follow-up (harmonisation unit 14)
4. Fix `nwgenvar`/`nwgenerate` dead code — Low value individually, Trivial effort, correctness hygiene
5. ✅ Alter-aggregation (`mean(alter.x)`) — Very high value, Medium effort, top competitive differentiator — done (`nwaltergen`, `nwgen` shortcut)
6. Distance-family sparse migration — High value (unblocks 5 commands), Large effort
7. ✅ k-cores — High value, Small-Medium effort — done (`nwkcore`)
8. ✅ Weighted betweenness variant — Medium value, Small effort — done (harmonisation unit 18): `nwbetween, weighted alpha()`, a Dijkstra generalization of the existing Brandes'-algorithm BFS betweenness, verified to reduce to the exact same result as the unweighted function at `alpha(0)`
9. ✅ `nwneighbor` sparse migration — Low value alone, Small effort, low risk — done, and surfaced a real broken/untested `mode(incoming)` bug in the process
10. `nwqap` `eclass` — done (harmonisation unit 19). QAPSPP / `predict` / dedicated `nwregress`/`nwlogit` — Very high value, Large effort, remaining
11. ✅ CUG test wrapper around `nwrandom, density()` — Medium value, Small effort — done (`nwcug`)
12. ✅ Common-neighbor similarity family (Jaccard/Dice/cosine/Adamic-Adar) — Medium-high value, Small-Medium effort — done (`nwsimindex`)
13. Structural-equivalence workflow packaging + role-variable output — Medium value, Small effort
14. ✅ Per-node eccentricity + radius — Low-medium value, Trivial effort — done (`nwgeodesic`)
15. ✅ Ego-network size/density — done (`nwego`, harmonisation unit 25) - turned out not to need induced-subgraph extraction at all, both are computable directly from the sparse neighbor accessors. A general induced-subgraph-extraction primitive (for composition/diversity and other measures that need an actual reusable subgraph object) remains open - Medium value, Medium effort.
16. Export-format parity (add GML/GraphML/edgelist to `nwexport`) — Low-medium value, Small effort
17. ✅ CONCOR — Medium value, Medium effort — done (`nwconcor`, harmonisation unit 21)
18. `nwplot` test coverage (largest untested file in the package) — Risk-reduction value, Medium effort (many code paths)
19. ✅ Programming-API documentation chapter — Medium value (unlocks third-party extensibility), Small effort, pure documentation — done (new "[NW-5.2]" section in `nw_programming.sthlp`, including a 10-item pitfalls list drawn from real bugs found this session)
20. ✅ Weighted eigenvector centrality option — Small value, Small effort — done (`nwevcent, weighted`)

## Top 10 existing features to improve

1. `nwqap` — `eclass` done (unit 19); QAPSPP, `predict` remain (see Stage 4)
2. `nwgeodesic`/`nwcloseness`/`nwreach`/`nwbridges`/`nwpath` — sparse migration (see Stage 0 remainder)
3. `nwconstraint` — either fold into the revived `nwburt` or add per-node aggregation + help file
4. `nw2clustering` — sparse migration (currently O(N⁴)-shaped Stata reshape chain)
5. `nwbetween` — add a genuinely weighted (Dijkstra-based) variant
6. ✅ `nwevcent` — added a `weighted` option; also found and fixed a genuine eigenvalue-search bug along the way (silently correct in practice only because of Mata's `symeigensystem()` sort order — see `docs/CERTIFICATION.md`). Migrating off dense materialization was not attempted: eigendecomposition itself requires a dense solver in Mata (no sparse eigensolver available), so this stays dense by necessity, not oversight.
7. `nwneighbor` — sparse migration + add induced-subgraph output (feeds Stage 3's ego-network work)
8. `nwexport` — format parity with `nwimport` (currently 2 vs 6 formats)
9. `nwplot` — test coverage (zero tests on the package's largest file)
10. ✅ `nwrecode`/`nwbalance` — documentation (real functionality, currently invisible) — done; `nwrecode` also turned out to be completely non-functional (crashed on every call) and is now fixed, not just documented (harmonisation units 13-14)

## ERGM-readiness notes

See Stage 8 and `docs/FEATURE_AUDIT.md`'s AH section. Summary: architecture is closer to ERGM-ready than it looks for read-heavy operations (fast `has_edge`/neighbor lookup exist as of this session), but the MCMC-critical path — incremental edge toggling without a full index rebuild — does not exist yet and is the correct first prerequisite, not attribute storage or common-neighbor counting (those matter too, but toggling cost dominates ERGM runtime by orders of magnitude if unaddressed).

## Open items requiring a follow-up audit pass

- Area J (similarity/homophily/mixing/assortativity) fell between fork assignments this pass — needs a dedicated read of `nwhomophily.ado` and a clean confirmation of assortativity's absence.
- ✅ `nwkatz.ado` correctness audit complete (harmonisation phase): confirmed it computes a shortest-path distance-decay sum, not literature-canonical walk-counting Katz centrality (`(I-alpha*A)^-1`) — documented explicitly rather than silently implied by the name/citation; formula/values unchanged for backwards compatibility. A genuine walk-counting Katz centrality implementation (W5) remains a real gap. Investigating this surfaced and fixed 5 unrelated real bugs that meant the command had never actually worked end to end — see `docs/CERTIFICATION.md`.
- GML/GraphML import paths in `nwimport.ado` have lower test-fixture confidence than Pajek/UCINET — worth a dedicated correctness pass with real sample files.
