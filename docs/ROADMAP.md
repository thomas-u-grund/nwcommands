# nwcommands Roadmap

Living document. Last updated: 2026-08-22. See `docs/FEATURE_AUDIT.md` for the evidence behind every claim here, and `docs/SPARSE_BACKEND.md` for the sparse-migration architecture.

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

## Stage 0 — Sparse backend and architecture — done

Commits 1-9 complete and verified (see `docs/SPARSE_BACKEND.md`): additive CSR/CSC sparse index, `calculate_components`/`calculate_clustering`/`calculate_betweenness`/`get_outdegree`/`get_indegree` migrated, genuinely sparse-native construction (`set_edge_from_triplets`), lazy dense materialization with a size-guarded compatibility shim, benchmark proving the 100k-node/1M-edge milestone, `nwfromedge.ado` itself rewired to the sparse-native construction path (harmonisation unit 48 — six real bugs surfaced and fixed along the way, none pre-existing/dormant, all newly exposed by removing the dense path's implicit safety net), and the distance family (`calculate_distances`/`calculate_distance_pair`/`calculate_distances_without`, feeding `nwgeodesic`/`nwcloseness`/`nwreach`/`nwbridges`/`nwpath`) migrated to sparse BFS/Dijkstra (harmonisation unit 49 — a further bug surfaced and fixed mid-migration, see that unit's own row). The sparse-backend migration itself is now complete; `Brute_dist()` stays dense (used only by `nclan_diameter_ok()`'s own small induced-subgraph work) and `nwevcent`'s eigendecomposition stays dense by necessity (no sparse eigensolver in Mata) — both deliberate, not remaining migration work.

## Stage 1 — Consolidate existing functionality

Cheap, high-confidence fixes to things already built:
- ✅ Fixed `nwgenvar.ado` (was dead code — filename/program-name mismatch, never actually loadable; now a genuine thin wrapper matching `nwgen.ado`).
- ✅ `nwgenerate.ado`'s 8 dead commented-out dispatch branches (`dyadprob`/`homophily`/`lattice`/`path`/`pref`/`ring`/`small`/`transpose`): all 7 restorable ones now genuinely work (harmonisation units 47 and 58 - `dyadprob`/`pref`/`ring`/`small`/`transpose` in unit 47, `lattice`/`homophily` in unit 58 once their own underlying commands were fixed), `path` kept as a deliberate, better-explained error (doesn't fit nwgen's own single-network-per-call contract). `nwlattice`'s own root cause turned out to be a red herring in its original diagnosis: not a missing `nwvalidvars.ado` (that file was genuinely fine, just prematurely archived without checking `nwlattice` still needed it), but `nwset.ado`'s own `vars()` option having been silently dropped from its syntax line despite still being documented - a separate, previously-undiscovered bug with a wider blast radius than `nwlattice` alone. `nwhomophily`'s crash was a redundant, unreachable `mata drop` cleanup line. **New, separate finding while fixing `nwhomophily`, not yet resolved**: the actual statistical homophily effect appears not to work - `homophily(2)` and `homophily(-2)` produce identical output under the same seed, traced to `nwdyadprob.ado`'s own density-conditioned branch and the third-party `gsample` package's weighted sampling, not fully root-caused - see `docs/CERTIFICATION.md`'s own Pending row.
- ✅ `nwgenerate.ado`'s *separate* family of 16 variable-producing shortcuts (harmonisation unit 46): 13 (`degree`/`outdegree`/`indegree`/`isolates`/`components`/`lgc`/`clustering`/`closeness`/`farness`/`nearness`/`between`/`evcent`/`context`) now genuinely dispatch to their already-tested target command; the remaining 3 (`addnodes`/`collapse`/`subset`) raise a clear error instead of silently no-op'ing, since they don't naturally reduce to "one value per node". Also fixed a pervasive `nwclustering` stale-`_rc` bug found along the way (every plain, non-`symmetrize` call returned a nonzero `_rc` despite completing correctly) — see `docs/CERTIFICATION.md`'s own unit 46 row for the full detail.
- ✅ Documented `nwbalance.ado` (structural balance) — `.sthlp` written, `cscripts/test_nwbalance.do` added, certified against a hand-derived signed-K4 worked example. Also fixed a real bug (`save test, replace` polluting the user's working directory with an unused debug file). **Follow-up now done** (harmonisation unit 14): the zero-closed-triads edge case (a network with no triangles errored r(2000) instead of returning zero) is fixed with an explicit empty-result guard, verified with real assertions in `cscripts/test_nwbalance.do`.
- ✅ Document `nwrecode.ado` — done (harmonisation unit 13, `.sthlp` written alongside the crash fix); this line was simply never checked off at the time.
- ✅ `nwdyads` now has test coverage (harmonisation unit 31) — writing real known-answer tests surfaced and fixed a genuine, previously-invisible `calculate_dyadcensus()` bug (the null-dyad count was silently doubled for every one-mode network; see `docs/CERTIFICATION.md`). `nwnoderename` also gained test coverage in the same unit (confirmed correct as-is). **Remaining**: `nwplot` (largest file in the package, zero tests), `nwneighbor`'s migration to sparse accessors. `nwqap` now has substantial test coverage (see harmonisation units 9/15/19); `nwsimilar`/`nwdissimilar`/`nwhierarchy` now do too (see harmonisation unit 20 - this was also a full functional unblock, not just test coverage, see below).
- ✅ Migrated `nwneighbor.ado` to the sparse `neighbors()`/`neighbors_in()` accessors. Surfaced a real, previously-invisible bug: the old `mode(incoming)` branch had a stray unbalanced paren (a genuine Mata syntax error) and had zero test coverage — could never have actually run. Now fixed and certified (see `docs/CERTIFICATION.md`).
- ✅ Fix silent weight-handling gaps: betweenness — done (harmonisation unit 18): added a weighted/Dijkstra-based `weighted` option alongside the existing unweighted default, which is unchanged (a genuine additive option, not a behavior change to any existing call). Eigenvector centrality — already done (see the ✅ item below, `nwevcent, weighted`).

## Stage 2 — Core graph-analysis gaps

Highest-value additions for credible igraph-style coverage:
- ✅ Distance-family sparse migration (harmonisation unit 49) — unblocks `nwcloseness`/`nwgeodesic`/`nwreach`/`nwbridges`/`nwpath` scalability; see `docs/SPARSE_BACKEND.md`.
- ✅ Cohesive subgroups: k-cores — `nwkcore` + `NWdef::calculate_kcore()`, sparse-neighbor-based degree-peeling (Seidman 1983), certified against 4 hand-computable cases (see `docs/CERTIFICATION.md`). ✅ Cliques — `nwclique` (harmonisation unit 29). ✅ K-plexes — `nwkplex` (harmonisation unit 34), generalizing `nwclique`'s own Bron-Kerbosch backtracking to the Seidman & Foster (1978) k-plex rule. ✅ N-cliques/n-clans — `nwnclique`/`nwnclan` (harmonisation unit 36): an n-clique turned out to be simply an ordinary clique of the "geodesic distance <= n" graph, reusing `BronKerbosch()` completely unmodified; n-clans add the induced-subgraph diameter refinement (Mokken 1979) on top. ✅ K-components — `nwkcomponents` (harmonisation unit 37), built on genuinely new vertex-connectivity/max-flow Mata infrastructure (node-splitting max-flow reduction, Edmonds-Karp, Menger's theorem) - the package's first graph-flow capability, and the natural foundation for a future full Moody-White (2003) multi-level cohesive-blocking hierarchy. ✅ Full multi-level Moody-White hierarchy — `nwcohesion` + `NWdef::calculate_cohesion_hierarchy()`/standalone `CohesionHierarchy()` (harmonisation unit 59): recursively re-applies the existing `KComponents()`/`vertex_connectivity()` primitives at increasing levels, reporting every block actually visited (not just one requested level) at its own true connectivity; certified against a two-triangles-plus-bridge network (levels 1/2/2, hand-derived), a lone triangle, a fully disconnected graph, and two genuinely disconnected triangles (level-0 top block, level-2 children) - see `docs/CERTIFICATION.md`. Also added `NWdef::extract_subgraph()`, a fresh-unregistered-copy induced-subgraph primitive (hand-verified: original network provably untouched, induced tie structure exact) for reuse by Stage 3's ego-network extraction; not needed by `nwcohesion` itself, since `KComponents()` already operates on 0/1 node-indicators over the shared adjacency directly. Building this surfaced a real, previously-invisible gap: `NWdef::keep_nodes()`/`drop_nodes()` never called `ensure_dense_built()` before reading `edge` directly (unlike every other dense-touching method) - would have silently misbehaved on a sparse-native network; now fixed. **Remaining**: lambda sets (edge-connectivity-based - a parallel primitive to the vertex-connectivity one already built, not a reuse of it) and factions (a genuinely different technique - block-model partition fitting, not connectivity-based enumeration) — both deferred, see `docs/CERTIFICATION.md`'s Pending table.
- ✅ Per-node eccentricity + network radius — added to `nwgeodesic` (`generate()`, `r(radius)`). Surfaced a genuine Stata `syntax`-parser bug along the way (see `docs/CERTIFICATION.md`).
- ✅ Common-neighbor similarity family — `nwsimindex` (common/jaccard/dice/cosine/Adamic-Adar), computed via one matrix multiply rather than a per-pair loop. Deliberately distinct from `nwsimilar.ado` (structural equivalence over full tie profiles, a different question). Surfaced two follow-on items: `nw2project`'s `replace` option had the same bug this command's own `replace` was fixed to avoid - ✅ also fixed (re-verified during Stage 2 follow-up: the fix and its own dedicated regression test - name-collision auto-increment, `replace` reusing the exact name, `r(nodes)`/`r(ties)` reading correctly - were already both in place in `cscripts/test_nw2project.do`, just not previously checked off here); `nw_helpwriter.ado`'s certification check was fragile against a common `capture`+`assert` test idiom (now fixed — see its own certified row; a full audit of the rest of the package's `.sthlp` files against the same historical gap remains Pending).

## Stage 3 — Classical social network analysis (high priority per project brief)

- ✅ **`nw2project`** — done (harmonisation unit 8 era; see `docs/CERTIFICATION.md`) — built fresh from its own existing, complete `.sthlp` spec; this line simply never got its checkmark. `replace`/`r(nodes)`/`r(ties)` display bugs found and fixed later (Stage 2 follow-on, also done).
- ✅ **`nwburt`** — done (harmonisation unit 17's Part I re-audit; see `docs/CERTIFICATION.md`) — revived from git history, modernized against the current `NWdef` API, certified; complete Burt suite (effective size, efficiency, constraint with proper per-node aggregation, hierarchy). This line simply never got its checkmark either.
- ✅ **`nwsimilar`/`nwdissimilar`/`nwhierarchy` chain fully unblocked** (harmonisation unit 20): the third, previously-unresolved layer of breakage is now root-caused and fixed — see `docs/CERTIFICATION.md`. All three commands run end-to-end, certified with hand-verified numeric assertions. ✅ **Packaged as a documented role/position-analysis workflow** (harmonisation unit 35): `nwhierarchy` gained `groups()`/`equivgen()`/`replace`, cutting the dendrogram straight into a single per-node equivalence-class variable (mirroring `nwcomponents`' own output shape) via Stata's native `cluster generate ..., groups()` postestimation command — no new clustering algorithm needed, since that capability already existed natively, just wasn't wired up. Also gave `nwhierarchy.ado` a proper embedded doc header (it had none before) documenting the full three-stage workflow.
- ✅ CONCOR — done (harmonisation unit 21): `nwconcor`, a new command with recursive `splits(k)` multi-level blockmodeling (up to 2^k blocks), directed networks supported natively (no `symmetrize` needed, unlike `nwcommunity`).
- ✅ Discrete core-periphery detection — done (harmonisation unit 22): `nwcoreperiphery` (Borgatti & Everett 1999), a new `NWdef::calculate_coreperiphery()` Mata method using greedy local search (the same character of algorithm as `nwcommunity`'s Louvain, fixed reproducible node order). Full blockmodeling (image matrices, SBM, goodness-of-fit) remains E - the `nwsimilar`/`nwdissimilar` engine (fully functional since harmonisation unit 20) is the reusable input layer for that.
- ✅ Ego-network size/density/composition/effective-size — this line's own original premise (all four "blocked" on a true induced-subgraph-extraction primitive) turned out to be wrong on every count once actually checked: size/density were already done directly from sparse neighbor accessors (`nwego`, harmonisation unit 25, no subgraph needed); effective-size was already done via `nwburt`'s direct formula-based computation (harmonisation unit 17's Part I re-audit); **composition/diversity** — the one genuinely-missing piece — is now done too (harmonisation unit 60): `nwaltergen diversity(alter.srcvar)` computes Blau's (1977) index of heterogeneity over ego's alters' attribute values, reusing the existing `calculate_alterstat()`/`calculate_alterstat_hop()` alter-aggregation infrastructure (a new `BlauIndex()` Mata helper, shared by both) rather than needing any subgraph object either. `NWdef::extract_subgraph()` (built in harmonisation unit 59 for `nwcohesion`) remains available as genuine, tested infrastructure for any *future* feature that needs an actual standalone induced-subgraph network object (as opposed to per-node attribute aggregation over a neighbor list, which is all any currently-tracked Stage 3 item ever actually needed) — nothing presently on this roadmap requires it.

## Stage 4 — Network inference

- ✅ `nwqap` `eclass` shell — done (harmonisation unit 19): `ereturn post` of `e(b)`/`e(V)` (the latter a diagonal QAP-permutation-variance matrix, not a classical covariance), plus `e(N)`/`e(permutations)`/`e(cmd)`/`e(title)`/`e(depvar)`/`e(qap_regcmd)`/`e(pvalues)` — `estimates store`/`estimates table`/`test`/`lincom` all verified working. ✅ `predict` subroutine — done (harmonisation unit 61): a native postestimation `predict` genuinely can't work after `nwqap` returns (its `ereturn post` runs against the original node-level dataset, not the transient dyad-level one `type()` actually fit against - a real, correctly-reasoned limitation this package's own docs had already recorded, not an oversight), so a new `predict(newnetname)` option instead captures `type()`'s own default fitted statistic (Pr(y=1) for `logit`/`probit`, the fitted mean for `regress`, etc.) at the one internal point where it's genuinely meaningful - right after the real (non-permuted) observed-data regression runs, before the dyad-level dataset is discarded - and materializes it as a new valued network via a new `transformOutOfLong()` Mata function (the exact inverse of the existing `transformIntoLong()`). **Remaining**: QAPSPP (X-permutation/semi-partialling) as a second inference mode alongside the existing simple Y-permutation; confirm `esttab` compatibility; a possible dedicated `nwregress`/`nwlogit` command pair if a more Stata-native interface is wanted beyond `nwqap`'s current "any regression command via `type()`" design.
- ✅ CUG tests — `nwcug`, wired against `nwrandom`'s existing conditioned-generation capability. Originally density-conditioned only; ✅ dyad-census/reciprocity conditioning added (harmonisation unit 62) via a new `condition(density|census)` option, wired against `nwrandom, census()` (which, on checking, already existed - the "not yet built" premise this line originally carried was about `nwcug`'s own wiring, not `nwrandom`'s underlying capability). `condition(census)` requires a directed network (mutual/asymmetric/null dyad types have no meaning for undirected ties). `stat()` takes a full command template (`##net##` token) rather than a bare command name, after finding that approach breaks on the second random draw for any command with a fixed-name default output variable.

## Stage 5 — Stata-native integration (high priority per project brief)

- ✅ **Alter/neighbor aggregation** (`nwgen exposure = mean(alter.smoking)`-style): `nwaltergen` (new command) + `NWdef::calculate_alterstat()`, supporting `mean`/`sum`/`min`/`max`/`sd`/`count`. `nwgen` dispatches to it automatically via a narrow, isolated `regexm()` pre-check that leaves `nwgenerate.ado`'s fragile legacy parser completely untouched. The single highest-leverage gap found in this audit for Stata-specific competitive differentiation — no comparable one-line syntax exists in igraph/sna's R-based workflows. ✅ `proportion()`-style categorical aggregation — done (harmonisation unit 26): `proportion(alter.srcvar==value)`/`!=value`, a genuine convenience for picking out one category of a multi-level variable without first hand-building a 0/1 indicator (which `mean()` already covered, and still does - `proportion()` is deliberately not offered without a comparison, to keep one unambiguous way to ask for that case). ✅ Lagged/multi-hop exposure — done (harmonisation unit 28): `hop(k)` aggregates over nodes exactly `k` (unweighted) steps away instead of direct neighbors, via a new `NWdef::calculate_alterstat_hop()` Mata method; combines with `proportion()` too. This completes every item originally scoped for `nwaltergen`'s alter-aggregation work.
- ✅ Dyadic dataset export (general, not just dyad-census) and ego/alter comparison variables — both turned out to already be substantially covered by `nwtoedge` (general dyadic edgelist export with `egovars()`/`altervars()` raw-attribute columns, pre-dating this audit) plus a new `comparevars()`/`comparemode()` option (harmonisation unit 63) that adds the missing "compare ego's and alter's values" piece - `same`/`dist`/`absdist`/`distinv`/`absdistinv`/`sender`/`receiver`, reusing `nwexpand`'s own already-certified comparison vocabulary internally rather than reimplementing it. Lagged network exposure was already done too (unit 28, `nwaltergen`'s `hop(k)`) - this line's own "follow-on once the aggregation primitive exists" framing was simply never checked off.

## Stage 6 — Advanced graph functionality

- ✅ Label propagation (Raghavan, Albert & Kumar 2007) — done (harmonisation unit 64): `nwcommunity`'s new `algorithm(louvain|labelprop)` option, built on a new standalone `LabelPropagation()` Mata function reusing Louvain's own `nw_community_kin()`/`nw_community_denserelabel()` helpers. **A genuine, empirically-confirmed finding along the way**: label propagation's randomized sweep order/tie-breaking is load-bearing, not incidental - a first version using Louvain's own fixed-order/deterministic-tiebreak convention (for reproducibility) was found to systematically collapse even trivial, cleanly-separated community structure (two triangles joined by a bridge) into one giant community, because a fixed check order lets whichever community is examined first in a tie keep winning and cascading. Fixed by using genuine randomization (`unorder()`/`runiform()`) plus a new `seed()` option for reproducibility, matching `nwcug`'s own precedent for exposing RNG control on a randomized command. Certified with an honest accounting of the algorithm's own real limitation: label propagation has no guarantee of finding a good partition (confirmed directly - roughly a quarter of seeds tried on the bridge test network converge to one collapsed community rather than the correct two triangles); the test uses a specific seed confirmed (by scanning many) to converge correctly, to certify a correct split CAN be found and is exactly reproducible, not that the algorithm always succeeds. **Remaining**: Leiden (a further refinement of Louvain fixing its own known "badly-connected communities" defect - a larger, separate algorithm, not a cheap addition like label propagation was), motifs beyond triads, flow/cuts/matching (from scratch), spectral analysis (Laplacian construction + the already-proven `symeigensystem()` call pattern from `nwevcent`), random walks, large-network layouts for `nwplot`.

## Stage 7 — Dynamic/multiplex/relational-event functionality

Only after Stage 0-6 mature. Real reusable adjacency already exists (`NWsdef` multi-network storage, `nwcorrelate`, `nwmovie`'s multi-frame animation) — a stability/turnover command is a smaller lift than the "confirmed E" status suggests once those pieces are assembled deliberately.

## Stage 8 — Native ERGM (long-term flagship)

Starts from zero, not from `nwergm.ado` (which is an R-bridge, not native — see audit). Prerequisites, in order: (1) an incremental single-edge sparse-index update path (current `build_sparse_index()` is a full O(N+M) rebuild with no patch capability — unacceptable for an MCMC inner loop toggling edges thousands of times/iteration); (2) a per-node/edge attribute-caching layer in `NWdef` (currently zero attribute storage in Mata — a deliberate design decision needed before `nodematch()`/`nodecov()`/`edgecov()` are possible without a prohibitively slow per-step Stata-dataset round-trip); (3) a reusable common-neighbor/shared-partner primitive (currently computed inline, differently, in two different places, decomposing to neither a per-edge nor an incremental statistic).

## Visualization roadmap (`nwplot` subsystem)

Compiled during the `nwplot` SVG-export modernisation audit (harmonisation unit 33 — see
`docs/CERTIFICATION.md`), which added native `export()`/`replace`/`exportopt()`, fixed several real
crashes in the default large-network layout, and inventoried the whole plotting subsystem
(`nwplot`/`nwplotjs`/`nwplotmatrix`/`nwmovie`/`nwmoviexy`) end to end. Native Stata SVG/PDF export
was directly verified (not assumed) to already produce fully-editable, publication-quality vector
output for everything `nwplot` currently draws — nodes, edges, arrowheads, and labels all render as
real, separate SVG objects (`<circle>`/`<line>`/`<path>`/`<text>`), not a flattened raster. That
sets a high bar: most remaining gaps below are about `nwplot`'s own drawing logic, not about
vector-export quality, which is already solved.

**Already solved, not gaps** (confirmed by direct testing this unit, listed here so they aren't
re-proposed later): publication-quality static vector export (SVG/PDF, `export()`); reusable/fixed
node coordinates across multiple networks or waves (`generate()`/`nodexy()`, pre-existing, now
documented as the intended mechanism). Interactive pan/zoom/hover/drag graph exploration
(`nwplotjs`, sigma.js-based) was also in this category at the time this unit ran, but `nwplotjs`
has since been removed entirely (harmonisation unit 51) - no longer needed now that `nwplot`'s own
native SVG export is the package's one plotting/export path.

- **High value, small-medium effort**: self-loop rendering (currently invisible — a self-loop has
  no visual effect at all, not even a small drawn arc; every other node-link tool in this space
  draws *something* for it, so this is a real, visible gap for any network where self-loops are
  substantively meaningful, e.g. self-citations, autocorrelation-style ties). Automatic two-mode
  visual distinction (color/symbol by mode) — currently a fully-working manual workaround
  (`color(modevar)`), just not automatic; a `bipartite`/`twomode` convenience flag that calls
  `get_modes()` internally and pre-sets a sensible default color/symbol split would remove one
  manual step for a very common use case.
- **Medium value, medium effort**: parallel-edge rendering (two nodes tied by more than one
  distinct relation/network currently overlap visually with no offset — relevant once multiplex
  plotting on a shared layout becomes a real workflow, see Stage 7); a dedicated `nwlayout` command
  separating layout calculation from plotting entirely (assessed this unit: **not** urgent — the
  existing `generate()`/`nodexy()` pair already gives ~90% of the value of a separate command,
  since coordinates are already Stata variables a user can compute once and reuse freely; a
  standalone `nwlayout` would mainly buy a cleaner API surface and the ability to add layout
  algorithms without touching `nwplot.ado`'s own already-large file, not new capability); additional
  layouts beyond the existing mds/mdsclassical/frucht/circle/grid/nodexy set — Kamada-Kawai
  specifically (a genuinely different stress-majorization objective from either MDS variant already
  implemented, commonly expected in this space), Sugiyama/hierarchical (valuable specifically for
  DAG-like directed networks, e.g. citation/influence networks), a dedicated bipartite two-row/
  two-column layout (currently two-mode networks use the same layouts as one-mode, with no
  mode-aware positioning).
- **Lower value or large effort, not recommended soon**: community-hull/convex-region overlays
  (real value for presenting community-detection results visually, but a non-trivial geometry
  problem — convex hull computation plus hull-vs-hull and hull-vs-node overlap avoidance — and
  `nwcommunity`'s own membership output already composes with `color()` today as a partial
  substitute); edge bundling (a genuine large-network readability technique, but a substantial
  algorithm to implement correctly, and this package's layouts are already capped at a few hundred–
  low-thousands of nodes by design, softening the case for it); a custom SVG renderer bypassing
  Stata's own `twoway`/`graph export` pipeline (assessed and explicitly **not justified**: this
  unit's own direct SVG inspection found native Stata output already fully vector, fully editable,
  and correct for every current `nwplot` feature — a custom renderer would only be worth building if
  a *specific*, concrete rendering need genuinely couldn't be met natively, and none of the gaps
  above require it); a browser-based/D3 interactive network explorer (assessed at the time as low
  incremental value since `nwplotjs` already covered the interactive use case - `nwplotjs` has
  since been removed entirely, harmonisation unit 51, so this is now simply out of scope rather
  than redundant); animation of longitudinal networks beyond what `nwmovie`/`nwmoviexy` already do.
  **Correction (harmonisation unit 52)**: at the time this was written, `nwmovie`/`nwmoviexy` were
  assessed as "a separate, already-working raster/GIF pipeline" - this was wrong. Both commands
  unconditionally crashed on every call (`_nwsyntax_other`, their shared netlist-resolution helper,
  referenced two legacy globals that no longer exist in the current storage architecture), and
  `nwmovie.ado` additionally had its own unrelated typo (a stray quote turning `local nxy2 = ...`
  into a local literally named `nxy2'`, breaking any call that didn't supply `nodexys()` - the
  common case). Both fixed in unit 52; a real animated GIF was produced and confirmed to actually
  play, in this same environment ImageMagick was earlier assumed missing from - it is, in fact,
  installed here.

## Two-mode/temporal architecture initiative (in progress)

A large, user-requested architectural initiative: making two-mode/bipartite status a genuine,
compositional property of the network object (already substantially true - see below - but with a
real data-loss bug and several gaps fixed/closed as this progresses), and adding temporal metadata
(snapshot/interval/event) as groundwork for future dynamic-network functionality, without building a
full temporal-network modelling subsystem now. Tracked here across units since the full scope (audit
→ metadata → `nwset` → command migration → `nw2*` compatibility → temporal slicing → full
documentation pass → complete regression) spans many harmonisation units - see `docs/CERTIFICATION.md`
for each unit's own certified row as they land.

**Audit findings (harmonisation unit 38's own investigation, kept here rather than re-derived per
unit)**: two-mode metadata is already real, first-class `NWdef` state (`is2mode`/`modes`/
`get_nodes_mode1()`/`get_nodes_mode2()`/`description_mode1`/`description_mode2`), populated by
`nwset`'s existing `bipartite` option and `nw2fromedge`/`nw2set` - the architecture the user asked
for already substantially exists, contrary to the class's own stale "TODO: modes is not handled yet"
comment (now corrected). The genuine gaps: (1) mode data was silently lost on every `nwsave`/`nwuse`
round-trip (✅ fixed, unit 38); (2) `nwset` has no two-ID-variable edgelist form for declaring a
two-mode network (`nwset person organisation, twomode`) - that shape currently exists only as the
separate `nw2fromedge` command, not inside `nwset` itself; (3) ordinary one-mode commands mostly have
**zero** two-mode awareness - confirmed concretely for `nwdegree` (silently computes a meaningless
one-mode degree on bipartite data, no error; ✅ fixed, unit 40); `NWdef::get_density()` was
**re-audited and found already correct** (✅ closed, unit 41 - see below, not the gap originally
suspected here) - `nwclustering.ado` is the one existing, proven model for the right pattern (auto-redirects to
`nw2clustering` when `is_2mode()` is true, flagged as "Model example" in
`docs/NETWORK_TYPE_MATRIX.md`), not yet replicated elsewhere; (4) `nw2project`'s own `stat()` options
are currently only `min|max|minmax|sum|mean` - no jaccard/cosine/binary/count projection exists yet,
a genuine feature gap, not merely something to audit-and-retain; (5) a projected network's own
metadata does not record its own provenance (which network/mode it was projected from, by what
method) - lost the moment `nw2project` returns; (6) temporal metadata does not exist anywhere in the
package at all (confirmed via a repo-wide grep) - genuinely greenfield, unlike two-mode.
`docs/NETWORK_TYPE_MATRIX.md` already contains close to the exact command-by-command compatibility
table the user's own Part XV/15 asked for (T1-T5/W1-W5 classification, ~20 commands already audited,
~90 flagged "not yet audited") - extend that file as commands are migrated, rather than building a
new one.

**Sequencing** (adapted from the user's own suggested workflow): audit (done) → fix mode-persistence
bug (done, unit 38) → `nwset` two-ID-variable `twomode` syntax (done, unit 39) → migrate
representative commands (`nwdegree` done, unit 40, following the proven `nwclustering` redirect
pattern; `NWdef::get_density()` re-audited, done, unit 41 - see unit 41's own row: turned out to
already be correct, root cause of the apparent gap was a real, much more serious bug found and
fixed in `nw2fromedge` itself, not in density) → `nw2project` extended with the missing projection
methods (`count`/`binary`/`jaccard`/`cosine`) + provenance metadata (done, unit 42 - also surfaced
and fixed two further real, pre-existing bugs found while verifying provenance's save/reload
round-trip: `create_by_name_sparse()` silently wiping a network's own name via its internal
`zap()` call with nothing restoring it afterward, and `nwuse.ado`'s reload loop referencing an
undefined local `` `_nw_netname' `` instead of the already-correct `` `n' ``, silently operating
on "current network" rather than the intended one for every `nwname`-based reload field) →
`nwsummarize` (the package's closest equivalent to a `nwdescribe` command - already displays
two-mode metadata and now provenance too, unit 42) →
temporal metadata fields + `nwset` `time()`/`interval()`/`eventtime()`
+ basic `at()` slicing via the new `nwattime` command (done, unit 43 - `nwsummarize`/`nwname` also
extended for temporal display/returns in the same unit, closing that earlier item too) → full
`docs/NETWORK_TYPE_MATRIX.md` audit pass across every remaining command → full regression sweep →
this section marked complete.

**Still open from unit 43** (not silently dropped, genuine follow-on items): composability between
temporal declaration (`time()`/`interval()`/`eventtime()`) and `twomode`/`bipartite` in the same
`nwset` call - currently an explicit, clear error rather than silently mishandled, but a two-mode
temporal network cannot yet be declared at all; migrating individual existing commands to be
temporal-aware (beyond the generic `nwattime` slice-then-run-anything path) - not attempted, matches
the user's own "basic `at()` slicing on one or two representative commands" scope limit, not full
command migration; windowed/aggregated event slicing (`nwattime` currently only supports an exact-
timestamp match for event networks, no range/window) - deliberately deferred, matches the user's own
"do not overbuild" instruction on windowing.

**Explicitly out of scope for this initiative** (per the user's own instructions): automatic
projection under any circumstance (a command requiring a one-mode network must error or require an
explicit `projection()`-style request, never silently project or silently pick a mode); a full
temporal-network modelling subsystem (SAOMs, temporal ERGMs, relational-event models, dynamic
community detection); a large windowing framework beyond what falls out naturally from the
architecture; lambda sets/factions (separate, already-tracked cohesive-subgroup items, unrelated to
this initiative despite superficial "network property" similarity).

## Top 20 additions ranked by value/effort

1. ✅ `nw2project` (two-mode projection) — Medium value, Small effort, spec already written — done (commits `1ba195e`/`531e018`; the roadmap checkmark was simply never added at the time). Re-verified working (`cscripts/test_nw2project.do` passes) during the harmonisation-phase Part I re-audit; "Supported network types" section added (harmonisation unit 17) — status **A**.
2. ✅ `nwburt` revival — High value, Small effort, proven historical code — done (commit `1ba195e`). Re-verified working (`cscripts/test_nwburt.do` passes) during the harmonisation-phase Part I re-audit; "Supported network types" section added, and a real, subtle math gotcha found and fixed in `nwconstraint`'s own docs while cross-checking the two commands against each other (harmonisation unit 17 — see `docs/CERTIFICATION.md`) — status **A**.
3. ✅ `nwbalance` docs+tests — Medium value, Trivial effort — done, including the zero-closed-triads follow-up (harmonisation unit 14)
4. Fix `nwgenvar`/`nwgenerate` dead code — Low value individually, Trivial effort, correctness hygiene
5. ✅ Alter-aggregation (`mean(alter.x)`) — Very high value, Medium effort, top competitive differentiator — done (`nwaltergen`, `nwgen` shortcut)
6. ✅ Distance-family sparse migration — High value (unblocks 5 commands), Large effort — done (harmonisation unit 49)
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
18. ✅ `nwplot` test coverage — done (harmonisation unit 33: SVG-export modernisation audit). Found and fixed 4 real crashes in the `mdsclassical` default layout (>50-node networks) and the `layout(,lgc)` path along the way — see `docs/CERTIFICATION.md`.
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
9. ✅ `nwplot` — test coverage — done (harmonisation unit 33), see item 18 above
10. ✅ `nwrecode`/`nwbalance` — documentation (real functionality, currently invisible) — done; `nwrecode` also turned out to be completely non-functional (crashed on every call) and is now fixed, not just documented (harmonisation units 13-14)

## ERGM-readiness notes

See Stage 8 and `docs/FEATURE_AUDIT.md`'s AH section. Summary: architecture is closer to ERGM-ready than it looks for read-heavy operations (fast `has_edge`/neighbor lookup exist as of this session), but the MCMC-critical path — incremental edge toggling without a full index rebuild — does not exist yet and is the correct first prerequisite, not attribute storage or common-neighbor counting (those matter too, but toggling cost dominates ERGM runtime by orders of magnitude if unaddressed).

## Open items requiring a follow-up audit pass

- Area J (similarity/homophily/mixing/assortativity) fell between fork assignments this pass — needs a dedicated read of `nwhomophily.ado` and a clean confirmation of assortativity's absence.
- ✅ `nwkatz.ado` correctness audit complete (harmonisation phase): confirmed it computes a shortest-path distance-decay sum, not literature-canonical walk-counting Katz centrality (`(I-alpha*A)^-1`) — documented explicitly rather than silently implied by the name/citation; formula/values unchanged for backwards compatibility. A genuine walk-counting Katz centrality implementation (W5) remains a real gap. Investigating this surfaced and fixed 5 unrelated real bugs that meant the command had never actually worked end to end — see `docs/CERTIFICATION.md`.
- GML/GraphML import paths in `nwimport.ado` have lower test-fixture confidence than Pajek/UCINET — worth a dedicated correctness pass with real sample files.
- **Version-control gap**: several already-shipped, tested, actively-relied-upon commands are not tracked in git at all (confirmed via `git status`/`git log`, discovered while committing harmonisation unit 41). `nw2clustering.ado`/`nw2set.ado`/`nw2toedge.ado` and their `cscripts/` tests were committed alongside unit 41 (they sit directly in the two-mode command family unit 41 was already touching); still outstanding: `nwbridges.ado`, `nwappend.ado`, `nwshared.ado`, `nwsimmelian.ado`, `nwnode.ado`, `nwnoderename.ado`/`.sthlp`, `nwpreserve.ado`, `nwrestore.ado`, and their respective `cscripts/` tests (`nwplotjs.ado`/`.sthlp` dropped from this list - removed entirely, harmonisation unit 51, so there is nothing left to commit for it) — all untracked (`git status` reports them `??`), and `_gnwdegree.ado`/`_growmedian2.ado` (untracked helper files, not yet audited for whether they're still-used or genuinely dead) alongside them. Needs a dedicated pass: confirm each file is genuinely finished/working (not abandoned WIP) via its own test, then commit in a coherent unit — do not `git add -A` blindly, since the working tree also has a large amount of separate scratch/output-artifact noise (generated `.html`/`.dta`/`.nwdta`/log files from running the test suite) that should stay untracked.
- **Compound-drop antipattern**, same class of bug fixed in `nwplot.ado` (harmonisation unit 44 — a single `capture drop A B C` fails and drops *nothing* if even one of A/B/C doesn't exist, since Stata's `drop varlist` is all-or-nothing): `nwmovie.ado`/`nwmoviexy.ado` both have `capture drop _frame_x _frame_y` (two variables). Not fixed in unit 44 — out of scope for that specific bug, and lower risk here since `_frame_x`/`_frame_y` are a matched pair that (on inspection so far) always appear to be created/dropped together, unlike unit 44's `_degree`/`_outdegree`/`_indegree` case where exactly one name is *always* missing depending on directedness, guaranteeing the failure on every call. Worth a dedicated check of `nwmovie`'s/`nwmoviexy`'s own code paths to confirm that pairing genuinely always holds before ruling out the same failure mode there.
