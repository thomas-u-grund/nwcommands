# nwcommands Feature Audit

Living document. Last updated: 2026-08-21 (harmonisation phase, unit 16 reconciliation pass), by autonomous development session.

Status legend: **A** fully implemented, tested, certified & documented to current standards · **B** implemented but incomplete · **C** partial/internal machinery, no complete user-facing command · **D** legacy/problematic (dense-matrix-bound, scalability-limited, or otherwise needing rework) · **E** not implemented · **F** implemented (and possibly already functionally correct) but not yet certified/tested/documented to the harmonisation phase's current standards (`NWCOMMANDS_COMMAND_STYLE.md`/`NWCOMMANDS_HELP_STYLE.md`, the certification framework in `docs/CERTIFICATION.md`, an explicit network-type-compatibility classification) — a distinction the original A-E scheme didn't separately track; use this rather than marking something A merely because the code runs.

Methodology: every classification below is based on reading the actual `.ado`/Mata bodies (syntax, options, Mata calls), not inferred from filenames. Conducted via 7 parallel static-analysis passes plus this session's own direct architecture work (sparse backend, community detection, bug fixes) at the audit's original writing; reconciled against the harmonisation phase's own units 1-16 (see `docs/CERTIFICATION.md`) in a later pass — reconciliation updates are marked inline as "**Update (harmonisation unit N)**". Read-only — no functionality is changed by the audit itself, only by the harmonisation/implementation work it documents.

## Executive summary

`nwcommands` has substantially more depth than its help-file surface suggests. The core (`nwset`/`nw_syntax`/`NWdef`) is sound and — as of this session — has a working sparse backend proven to scale to 100,000 nodes / 1,000,000 edges without ever allocating a dense matrix. Centrality, generators, dyad/triad census, I/O, and visualization are all real and mostly complete (B/A). The biggest gaps cluster in exactly the areas the project's own roadmap prioritizes: **full blockmodeling (image matrices, SBM, goodness-of-fit) is almost entirely absent** (E across the board), though discrete core-periphery detection and CONCOR structural-equivalence blockmodeling are now both done (harmonisation units 21-22), and structural equivalence itself is now genuinely functional (harmonisation unit 20 fixed a deep Mata-function-visibility bug that had left the `nwsimilar`/`nwdissimilar`/`nwhierarchy` chain completely non-functional end-to-end), **cohesive subgroups**: k-cores (`nwkcore`), maximal cliques (`nwclique`, harmonisation unit 29), k-plexes (`nwkplex`, harmonisation unit 34), and now n-cliques/n-clans (`nwnclique`/`nwnclan`, harmonisation unit 36) are done; k-components/lambda sets/factions/Moody-White blocks remain absent. **Stata-native alter-aggregation** (`mean(alter.x)`-style, `proportion()`, and `hop(k)` multi-hop exposure - harmonisation units 26/28) is now fully built out.

Several findings deserve special attention:
- **`nw2project`** (one-mode projection from a two-mode network): was a phantom command at the time of the original audit pass. **Update**: built and committed since (`1ba195e`/`531e018`); re-verified working during the Part I re-audit. Status **A** (unit 17 added the "Supported network types" section).
- **`nwburt.ado`**, a complete, well-documented implementation of Burt's structural-holes suite (effective size, efficiency, constraint, hierarchy), existed in the last real git commit (2015) and was deleted during the years of uncommitted work; only a stripped-down, incomplete `nwconstraint.ado` (dyadic constraint matrix only, no per-node aggregation, no help file) survives in the working tree.
- **`nwbalance.ado`** (structural balance / signed triads) is real, correct, and functional. **Update (harmonisation units 1/14)**: now documented (`.sthlp`) and tested, including a genuine zero-closed-triads crash (`collapse` erroring on an empty triad-level dataset) that has since been fixed.
- **`nwergm.ado`** is not a native ERGM implementation — it shells out to R (and even auto-installs R), directly violating this project's own "no external runtime dependencies" principle. Reclassified D; any native ERGM work starts from zero.
- **`nwgenvar.ado`** is dead code: it defines `program nwgenerate` under a mismatched filename, so Stata's ado-loader can never actually load it as `nwgenvar`.
- **`nwgenerate.ado`** has several silently-dead commented-out dispatch branches (`dyadprob`, `homophily`, `lattice`, `path`, `pref`, `ring`, `small`, `transpose`).
- Weighted-network semantics are **mostly** handled deliberately and well (e.g. `nwgeodesic`'s `alpha` exponent correctly distinguishes weight-as-strength from weight-as-cost). Two gaps flagged in the original audit pass — betweenness centrality silently ignoring weights (plain BFS, not Dijkstra, despite the Brandes' algorithm structure) and eigenvector centrality silently dichotomizing — are both now fixed (`nwevcent, weighted`; `nwbetween, weighted alpha()`, harmonisation unit 18), each as an explicit opt-in rather than a change to either command's existing default.

## A. Core network infrastructure

| Feature | Status | Command | Notes |
|---|---|---|---|
| nwset | A | `nwset` | 3 creation modes (varlist-as-matrix, edgelist via `edgelist`→`nwfromedge`, Mata `mat()`). **Correction to a common misreading**: bare `nwset ego alter` (no `edgelist` option) does NOT import an edgelist — it misreads the two variables as adjacency-matrix columns. |
| Network metadata | A | `nwname`/`nwds`/`nwsummarize` | name/label/caption fields on NWdef |
| Network validation | A | `nwvalidate` | auto-renames on collision |
| Multiple/named networks | A | `NWsdef` (core) | fully independent per-network dense storage (or, as of this session, sparse) |
| Copy/rename/delete | A | `nwduplicate`/`nwrename`/`nwdrop` | — |
| Binary/directed/weighted | A | `nwset`, `NWdef` fields | interpretation flags, not storage-shape changes |
| Two-mode/bipartite | B | `nw2set`/`nw2fromedge` | stored as masked square matrix, not true rectangular biadjacency; see area N |
| Isolates | A | most centrality/component commands | — |
| Self-loops | A | `isselfloop` field + diagonal-blanking convention | — |
| Multigraphs/parallel edges | E | — | one scalar per dyad only, structurally impossible today |
| Node attributes (in Mata) | E | — | deliberately live only in the linked Stata dataset (`nw_datasync`) — a reasonable design choice, not an oversight, but a real constraint for future ERGM `nodecov()`/`nodematch()` |
| Edge attributes (beyond one scalar weight) | E | — | `edgetype` field declared but dead/unused |
| Temporal/multiplex | E | — | see area V |
| **Sparse storage** | **A (new this session)** | `NWdef` CSR/CSC index | proven to 100k nodes/1M edges without dense allocation; see `docs/SPARSE_BACKEND.md` |
| Save/load | A | `nwsave`/`nwuse` | native `.nwdta`-style |
| Format conversion | A | `nwtoedge`/`nwfromedge`/`nw2toedge`/`nw2fromedge` | — |

## B. Basic network description

Mostly A: node/edge counts, density, degree distribution, isolates, connectedness (weak only — see G), average path length/diameter (via `nwgeodesic`, D-flagged for dense dependency). **Reciprocity is binary-only** — no weight-matched reciprocity (e.g. correlation of w_ij vs w_ji) exists. **Radius and per-node eccentricity are E** — `nwgeodesic` reports network-level diameter/average-path-length only, never an eccentricity vector.

## C. Centrality

Degree/in/out/strength (A, sparse-migrated this session), betweenness (A, sparse-migrated + bug-fixed this session; **update, harmonisation unit 18**: a genuine weighted/Dijkstra variant, `weighted alpha()`, has since been added alongside the unweighted default), closeness (A via `nwgeodesic`, D-flagged), eigenvector (A, genuine `symeigensystem()` eigen-decomposition, but **dichotomizes weights silently** and dense-only), Katz (**F** — harmonisation unit 2 confirmed and fixed 5 real bugs, then explicitly documented that `nwkatz.ado` computes a shortest-path distance-decay sum, not literature-canonical walk-counting Katz centrality `(I-alpha*A)^-1`; correctly implemented and tested for what it actually is, but a genuine walk-counting Katz remains a real **E** gap, tracked in `docs/ROADMAP.md`), PageRank/Bonacich power/alpha/Hubbell/HITS/eccentricity/information/flow-betweenness/current-flow/bridging/distance-limited/group centrality — all **E**, not implemented. Centralization (network-level) exists for degree/betweenness.

## D. Structural holes and brokerage

| Feature | Status | Command | Notes |
|---|---|---|---|
| Burt constraint (dyadic) | C | `nwconstraint` | returns unaggregated dyadic matrix only; no help file |
| Effective size, efficiency, hierarchy | **A** (was E, recoverable) | `nwburt` | revived and committed since the original audit pass (`1ba195e`); re-verified and given a "Supported network types" section during the Part I re-audit (harmonisation unit 17). Cross-checking it against `nwconstraint` also surfaced a real math gotcha in `nwconstraint`'s own docs, since fixed |
| Gould-Fernandez brokerage roles | **A** (new, harmonisation unit 23) | `nwbrokerage` | new `NWdef::calculate_brokerage()` Mata method, using the sparse `neighbors()`/`neighbors_in()` accessors directly; requires a caller-supplied group() variable (does not detect groups itself - pair with `nwconcor`/`nwcoreperiphery`/`nwcommunity` or a substantive attribute) |
| Bridges (global/local/distance) | A (D-flagged) | `nwbridges` | correct, but depends on the not-yet-sparse-migrated `calculate_distances_without()` |

## E. Structural equivalence, roles and positions

The single most "hidden" area in the audit. `nwsimilar`/`nwdissimilar` (**A**, was B/"undocumented" - now certified and documented, harmonisation unit 20) compute exactly the relational-profile similarity/distance measures (Pearson, matches, Jaccard, Hamming, crossproduct, Euclidean, Manhattan) this literature calls for, with incoming/outgoing/both profile direction options. **Update (unit 20)**: this whole chain was actually completely non-functional before this session (a deep Mata-function-visibility bug - functions defined in one ado-file's trailing `mata:` block are private to that file, invisible to a different ado-file's own `mata:` blocks, so `nwset`'s `mat()` option could never evaluate a (dis)similarity function passed to it from `nwdissimilar`/`nwsimilar` - root-caused with a minimal two-ado-file repro after an earlier, inconclusive investigation), plus a missing-diagonal bug and a node-label-inheritance bug that specifically broke `nwhierarchy`'s default path; all three now fixed and certified. `nwhierarchy` (**A**, was B) chains this into Stata's native `clustermat` for real hierarchical clustering - its default (no `dismat()`/`disnet()`) path, `dismat()`, and `disnet()` forms are all now verified working end-to-end. `nwdendrogram` (A) visualizes the result. `nwconcor` (**A**, new, harmonisation unit 21) implements CONCOR (Breiger, Boorman & Arabie 1975) directly - a new `NWdef::calculate_concor()` Mata method plus recursive multi-level splitting (`splits(k)`, up to 2^k blocks), and it *does* write its result back as a node categorical variable (`_concor` by default), closing part of the "no equivalence-class output" gap noted below for this one technique. **Update (harmonisation unit 35)**: the whole `nwsimilar`/`nwdissimilar`→`nwhierarchy` chain is now packaged as a documented "role/position analysis" workflow - `nwhierarchy` gained `groups()`/`equivgen()`/`replace`, cutting the dendrogram straight into a single per-node role/position-equivalence variable via Stata's native `cluster generate ..., groups()`, mirroring `nwconcor`'s own `_concor`-style output shape (and `nwcomponents`' `_component`). Still confirmed E: **regular equivalence/CATREGE, automorphic equivalence, exact structural equivalence, and MDS-of-positions** — zero grep hits anywhere.

## F. Blockmodelling and core-periphery

**Update (harmonisation unit 22)**: discrete core-periphery is no longer missing - `nwcoreperiphery` (**A**, new) implements the classical Borgatti & Everett (1999) model directly (a new `NWdef::calculate_coreperiphery()` Mata method, greedy local search over the 0/1 core assignment maximizing correlation with the ideal core-periphery pattern). Everything else in this area remains **confirmed E** — no blockmodel, image matrix, block density/mean, goodness-of-fit, SBM (plain or degree-corrected), bipartite/signed blockmodel, or continuous/fuzzy core-periphery variant exists anywhere. The `nwsimilar`/`nwdissimilar` engine (fully functional and certified, harmonisation unit 20 - see area E) is the one reusable asset a future blockmodel-partition step could build on.

## G. Components, cohesion and connectivity

Weak components: A (`nwcomponents`, explicitly undirected-only by design). Strongly-connected components, bicomponents, articulation points, vertex/edge connectivity, min separators, vertex/edge-disjoint paths, min cuts, max flow, dominator trees: **all E**, confirmed via clean grep. Bridges: A but D-flagged (see D above, same dependency).

## H. Paths, distances and reachability

Shortest paths between one pair (`nwpath`, B — unweighted only, no batch/k-shortest-paths mode), all-pairs distances/diameter/average-path-length/weighted-via-alpha (`nwgeodesic`, D-flagged — dense `Brute_dist`/`Dijkstra_dist`, not yet sparse-migrated), reachability/transitive closure (`nwreach`, thin `nwgeodesic` wrapper, same D dependency), 1-step neighbors (`nwneighbor`, D — still dense row/column reads, not yet migrated to this session's sparse accessors despite the primitive existing). k-step reachability, transitive reduction, per-node eccentricity/radius: **E**.

## I. Dyads, triads and motifs

Dyad census with reciprocity (A, `nwdyads`, now tested — harmonisation unit 31, which also found and fixed a genuine null-dyad-count bug, see `docs/CERTIFICATION.md`), full Davis-Leinhardt 16-type triad census (A, `nwtriads`, D-flagged — dense matrix-power algorithm). Simple triangle/transitive/cyclic/open-triple counts: B, derivable from the 16-type census but no dedicated convenience output. Node-level motif participation, arbitrary/4+-node motifs, cycle census beyond triads, signed triad census: **E**.

## J. Similarity, homophily, mixing and assortativity

Not separately audited this pass (fell between fork assignments) — flag for a follow-up targeted pass. Known from adjacent audits: `nwhomophily.ado` exists (a network *generator* from a homophily rule, confirmed unrelated to alter-aggregation per area AF); E-I index exists via `nwtabulate`/`nwmixing`'s permutation routines (each hard-coded to E-I specifically, no general "permute and test an arbitrary statistic" framework). Assortativity (nominal/numeric/degree/directed/weighted): **E**, confirmed absent via cross-cutting grep in area O's audit. Common-neighbor similarity (Jaccard/Dice/cosine/Adamic-Adar/cocitation/bibliographic coupling): not directly audited, presumed E pending confirmation — **open item**.

## K. Cohesive subgroups

**Update**: k-cores/shell numbers (`nwkcore`), maximal cliques (`nwclique`, **A**, harmonisation unit 29 - classical Bron-Kerbosch (1973) enumeration, generates each node's largest-clique-membership size plus the full cliques-by-nodes membership matrix in `r(clique_matrix)`), maximal k-plexes (`nwkplex`, **A**, harmonisation unit 34 - Seidman & Foster (1978) k-plexes via the same Bron-Kerbosch-style backtracking generalized to a whole-induced-submatrix validity check, same `r(kplex_matrix)`/per-node-summary output shape), and maximal n-cliques/n-clans (`nwnclique`/`nwnclan`, **A**, new, harmonisation unit 36 - Luce (1950)/Mokken (1979); an n-clique turned out to be simply an ordinary clique of the "geodesic distance <= n" graph, reusing `BronKerbosch()` completely unmodified rather than a new algorithm) are all done. **Still confirmed E**: clique census, k-components, lambda sets, factions, and Moody-White cohesive blocks — zero real implementation anywhere. `nwsimmelian` (A, Simmelian-tie/triad-embeddedness) is real and complete but is not a substitute for clique detection — a related-but-distinct concept.

## L. Community detection

**A — implemented this session.** `nwcommunity` (Louvain) and `nwmodularity`, both sparse-native, weighted-aware, certified against 3 hand-computable networks. Leiden/Infomap/Walktrap/label-propagation/fast-greedy/edge-betweenness/leading-eigenvector/spinglass/spectral clustering: **E**, not implemented (Louvain is the highest-value single algorithm and a defensible first choice; the others are lower-priority extensions). Partition comparison (adjusted Rand/NMI/variation-of-information/split-join): **E**.

## M. Ego-network analysis

Neighbor listing only (B, `nwneighbor` — binary-only, dense, no induced-subgraph extraction). **Update (harmonisation unit 25)**: ego-network size and density are done - `nwego` (**A**, new), via a new `NWdef::calculate_egostats()` Mata method using the existing sparse `neighbors()`/`neighbors_in()`/`has_edge()` accessors directly. This closes the size/density piece *without* needing a general induced-subgraph-extraction primitive at all - both are computable as scalar summaries straight from the sparse accessors, no persistent subgraph object required. Radius-k ego networks, alter-alter tie listing (as opposed to just density), alter composition/diversity, ego-alter similarity, ego-network effective size/efficiency (though `nwburt`'s existing effective-size/efficiency measures are closely related and may already cover some of this ground - not cross-checked), ego brokerage (though `nwbrokerage`, harmonisation unit 23, could likely be adapted to an ego-restricted computation with modest effort - not attempted here), ego-network change over time: still **E**. A general induced-subgraph-extraction primitive (for use cases that need an actual reusable ego-network *object*, not just scalar summaries of it) remains a real, separate, larger gap - not closed by this unit.

## N. Two-mode/bipartite analysis (high priority)

Core infrastructure real (`is2mode`/`nodesmode1`/`nodesmode2`/`modes` fields on `NWdef`, though storage is masked-square not true rectangular biadjacency). `nw2set`/`nw2fromedge`/`nw2toedge`: A. Bipartite clustering (`nw2clustering`): B, correct 4-path algorithm but D-flagged (Stata reshape/merge/collapse chain, O(N⁴)-shaped, not sparse-migrated). **`nw2project` (one-mode projection): F** — was the highest-value, lowest-ambiguity gap found in the original audit pass (a phantom command despite being fully spec'd); built, tested, and committed since (`1ba195e`/`531e018`), re-verified working during the Part I re-audit; missing only the current-standard "Supported network types" doc section. **Update (harmonisation unit 24)**: two-mode degree centrality is done - `nw2degree` (**A**, new), the Borgatti & Everett (1997) normalization (each node's raw degree divided by the size of the *other* mode, not the usual n-1), via a new `NWdef::calculate_2mode_degree()` Mata method that queries `get_modes()` directly (confirmed empirically that a bipartite network's mode-1/mode-2 node-index ranges are an internal storage detail, not something to hardcode). Two-mode betweenness/eigenvector, bipartite communities/core-periphery/blockmodels, affiliation statistics, bipartite matching remain **E**.

## O. Weighted/valued networks (cross-cutting)

Genuinely weight-aware: degree/strength (Opsahl generalized formula), transitivity/clustering (5 aggregation modes), shortest paths/closeness (`alpha` exponent, deliberately distinguishes strength from cost — a real design strength), community detection. **Confirmed gaps**: density (no weighted-sum variant), reciprocity (binary only), assortativity (doesn't exist at all). Betweenness and eigenvector centrality were flagged here in the original audit pass (plain unweighted BFS / silent dichotomization respectively) — both fixed since (`nwbetween`/`nwevcent`'s `weighted` options).

## P. Signed networks

Structural balance (`nwbalance`, B — genuinely correct Cartwright-Harary triadic balance, D-flagged for its Stata reshape-chain implementation. **Update (harmonisation units 1/14)**: documented and tested, zero-closed-triads crash fixed). Full 16-type signed triad census, frustration index, positive/negative degree or strength, signed communities/assortativity/blockmodels, positive/negative-only paths: **E**.

## Q. Graph transformations and graph algebra

Symmetrization/transpose: A. Dichotomization/recoding (`nwrecode`): A but **fully undocumented** (no `.sthlp`, no inline header) — hidden. Contraction (`nwcollapse`): A but misleadingly named (findable only by reading the body, not by searching "contract"/"merge"). Induced subgraph by condition or node-list (`nwsubset`/`nwkeepnodes`/`nwdropnodes`): A. Reverse/complement/union/intersection/difference: C — all expressible via the general `nwgen`/`nwreplace` algebra engine's elementwise operators, but with no dedicated commands, no validation, no discoverability. Disjoint union, graph composition, graph power, line graph, transitive closure/reduction, sparsification/backbone extraction: **E**.

## R. Graph generation and null models

Erdős-Rényi/Bernoulli, fixed-edge-count, dyad-census-conditioned (a genuine CUG-test building block, unused as such — see S), regular/ring/lattice, Watts-Strogatz, Barabási-Albert preferential attachment: all **A** (`nwrandom`, `nwring`, `nwlattice`, `nwsmall`, `nwpref`). Configuration model / degree-sequence-preserving, degree-preserving rewiring (general), random geometric graph, random dot-product graph, bipartite random graphs: **E**. SBM generation: C (achievable manually via `nwdyadprob`'s arbitrary tie-probability matrix, no dedicated syntax).

## S. Permutation tests and network inference

`nwqap.ado` (**F**, was B) is a real, substantial, generic-estimator QAP regression engine (multiple predictor networks, node-attribute IVs auto-expanded, permutation-based p-values). **Update (harmonisation units 9/15/19)**: was actually completely non-functional (crashed on every call via a deprecated-wrapper bug, a display bug, and a permutation-degeneracy crash) before this session — all three fixed, comprehensive test coverage added, an explicit non-silent warning added for the weighted-DV-vs-binary-outcome gotcha (see area O). **Now `eclass`** (unit 19): `ereturn post` of `e(b)`/`e(V)` (the latter a diagonal QAP-permutation-variance matrix — deliberately not a classical OLS/logit covariance, which would misrepresent dyadic data's non-independence), plus `e(N)`/`e(permutations)`/`e(cmd)`/`e(depvar)`/`e(qap_regcmd)`/`e(pvalues)`; `estimates store`/`estimates table`/`test`/`lincom` all verified working across `regress`/`logit`/`probit`/`cloglog`. Fixing the `logit` case surfaced a genuine `ereturn post` gotcha worth remembering package-wide: `logit`'s own `e(b)` carries an equation-name prefix on its column stripe while `regress`'s does not, and a bare `matrix colnames` call preserves rather than clears a pre-existing equation name — any future command building `e(b)`/`e(V)` from an underlying regression command's own results should blank both matrices' equation names explicitly (`matrix coleq/roweq = _`) before assigning names, not just this one. Reclassified **A** for the core eclass/postestimation piece; still **F** overall pending QAPSPP/`predict`. **Still lacks QAPSPP and `predict`**. MRQAP/QAPSPP (Dekker-Krackhardt-Snijders semi-partialling), QAP-X/independent-X permutation, CUG tests: **E** for MRQAP/QAPSPP/QAP-X, **A** for CUG (`nwcug`, added this session), though `nwrandom, census()` remains a ready-made-but-unused dyad-census-conditioned CUG null-model generator alongside it. `nwpermute` is a solid general node-label-permutation engine.

## T. Network regression (high priority — target `nwregress`/`nwlogit`)

Already covered under S — same command (`nwqap`). The `eclass` shell is now done (unit 19: `e(b)`/`e(V)`/`predict`-less postestimation support). **Remaining as an extension project**: add QAPSPP (X-permutation) as a second inference mode, a `predict` subroutine, and — if a more Stata-native interface is wanted beyond `nwqap`'s current "any regression command via `type()`" design — dedicated `nwregress`/`nwlogit` commands. Medium-to-Large effort. Network autocorrelation/lag/error models: **E**, nothing found.

## U. Network comparison

`nwcorrelate` (A, dyad-by-dyad correlation with permutation inference — genuinely reusable for future longitudinal-stability work) covers matrix/QAP correlation. Hamming distance (via `nwdissimilar`). Graph edit distance, spectral distance, central/consensus graphs: **E**.

## V. Longitudinal, temporal and multiplex networks

**Confirmed E for dedicated commands** — but real reusable adjacency: `NWsdef`'s multi-named-network storage already supports holding e.g. wave1/wave2/wave3 simultaneously; `nwcorrelate` supports permutation-tested comparison between two named networks; `nwmovie`/`nwmoviexy` genuinely support multi-network animation frames (`switchnetwork()` option). No dedicated stability/turnover/Jaccard-stability command exists despite the package bundling genuinely longitudinal sample datasets (`smoke1-3`, `klas12b_wave1-4`). Multiplex/multilayer: zero evidence anywhere, correctly not conflated with two-mode.

## W. Relational event analysis

**Confirmed E, cleanly** — no sender/receiver/timestamp event structure, no REM statistics, nothing adjacent found.

## X. Diffusion and contagion

**Confirmed E, cleanly.** `nwmovie`/`nwmoviexy` (630 lines each) were read in full specifically to rule out hidden simulation logic — confirmed pure visualization (frame interpolation + ImageMagick GIF export) of externally-supplied network snapshots, no state-transition/adoption logic of any kind.

## Y. Flow, optimisation and matching

**Confirmed E, cleanly** across max flow, min cut, MST, bipartite matching, independent sets, vertex covers, graph coloring, separators. No adjacent infrastructure; a future implementation would build BFS/augmenting-path primitives from scratch (on top of the sparse `neighbors()` accessors this session added).

## Z. Spectral analysis

Mostly E, with one real exception: `nwevcent` uses genuine `symeigensystem()` (Mata's real eigen-decomposition), not power-iteration — a proven, reusable call pattern for future Laplacian/spectral-clustering work, though currently dense-only. Laplacian, normalized Laplacian, spectral embedding/clustering, algebraic connectivity, Fiedler vector: **E**.

## AA-AC. Random walks, DAG functionality, isomorphism/graph matching

**All confirmed E, cleanly**, correctly the lowest-priority areas per the project's own stated priorities. No adjacent infrastructure for any of the three beyond the general sparse BFS pattern (reusable as a topological-sort/traversal template for future DAG work).

## AD. Network visualisation

Real layout coverage: Fruchterman-Reingold, metric/classical MDS, circle, grid, manual/nodexy, plus an undocumented `_layoutfunction` extension point (`nwplot`, B — `frucht` was undocumented until harmonisation unit 33 named it in the `.sthlp`/`.dlg`; it was always fully functional). Missing: Kamada-Kawai, Sugiyama/tree, dedicated spectral layout, Davidson-Harel, any genuinely large-network-aware layout (current layouts are O(N²)-shaped with hardcoded node caps of 100-1100 depending on Stata flavor) — see `docs/ROADMAP.md`'s own visualization-roadmap section for the full prioritised list. Node/edge aesthetics (color/size/symbol/width/arrows) are rich and confirmed working with arbitrary Stata variables. Export-coordinates-without-plotting: A (`generate()`/`nodexy()` also double as a fixed-layout-across-networks mechanism, confirmed and documented as such in unit 33). Native SVG/PDF/PNG vector export: A — added in harmonisation unit 33 (`export()`/`replace`/`exportopt()`), confirmed via direct SVG-source inspection to already produce fully-editable, publication-quality vector output. `nwplot.ado` now has real test coverage (unit 33 — `cscripts/test_nwplot.do`, 46 assertions covering directed/weighted/two-mode/large-sparse plots and SVG export specifically), which surfaced and fixed 4 real crashes in the default (`mdsclassical`) large-network layout. JS-based interactive plotting: `nwplotjs` (sigma.js/`linkurious/`-based, including two bespoke custom edge renderers) is the one live, active command — C, real but still unverified maturity (its own `cscripts/test_nwplotjs.do` exists but every actual `nwplotjs` call in it is commented out, found during unit 33's audit — effectively zero real test coverage, a gap worth closing separately). `nwplot_sigmajs.ado` no longer exists as an active file — it was archived to `old/ado/` in an earlier harmonisation pass (a duplicate `nwplotjs` definition, see `LEGACY_FILES.md`); the two other vendored-but-unused JS library dumps found during unit 33 (`d3js/`, plain `sigmajs/`) were archived to `old/js/` in that same unit. Animation (`nwmovie`): B, genuinely supports multi-network frames, zero tests.

## AE. Import/export and interoperability

Import: B, 6 formats (Pajek, matrix, edgelist, compressed, GML, GraphML, UCINET) — Pajek and UCINET genuinely well-evidenced (local sample files, careful `.dl`-format parsing with `nets()`/`diagonal()`/embedded-label handling); GML/GraphML lower-confidence (no local fixtures). Export: B, only 2 formats (Pajek, UCINET) — a real asymmetry against import's 6. CSV/JSON/DOT/Gephi/igraph/NetworkX-native formats: **E** as distinct import/export types (CSV is handled natively via Stata's own `import delimited` + `nwfromedge`, which is a reasonable substitute, not a true gap).

## AF. Stata-native network/data integration (high priority — target `nwgen exposure = mean(alter.smoking)`)

`nwgen`/`nwgenerate` (A for existing scope) already supports `nwgen X = degree(net)`-style node-level-measure-as-variable generation — real precedent for the target pattern. Node-attribute-to-network algebra (`nwgen net = 2*exp(flomarriage)*attr`) is real and documented. **But neighbor/alter aggregation (`mean(alter.x)`-style) does not exist anywhere in the codebase** — confirmed via full read of the expression engine (`nw_expnetexp.ado`). This is the single highest-leverage gap for Stata-native differentiation vs. igraph/sna, and `nwgenerate`'s existing dispatch-table architecture is a natural, well-scoped extension point rather than needing new infrastructure. Two bugs found in the process: `nwgenvar.ado` is dead code (defines `program nwgenerate` under a mismatched filename — Stata's ado-loader can never load it as `nwgenvar`); `nwgenerate.ado` has 8 silently-dead commented-out dispatch branches.

## AG. Programming/API support

Architecturally closer to API-ready than its documentation suggests. `nw_syntax` is a genuine, consistently-used single resolution point; this session's sparse accessors (`neighbors()`, `degree()`, `has_edge()`, etc.) are exactly the composable primitives a stable API needs. **The gap is purely documentation** — `book_programming.tex` documents only the read-only extraction contract (`nwtomata`/`_nwsyntax`), nothing about the `NWdef`/`NWsdef` class hierarchy or how to write a new `nw*` command against it. No `.sthlp` file documents the classes either. Cheap to close relative to its value.

## AH. Future ERGM readiness

`nwergm.ado` is **not** a native implementation — confirmed it shells out to `Rscript` and bundles `nwergm_install_win`/`nwergm_install_osx` programs that install R itself, directly violating this project's own "no external runtime dependencies" principle. Reclassified **D**; any native ERGM work starts from zero, not as an nwergm extension. Architectural readiness assessment: `has_edge()`/neighbor lookup exist (this session); common-neighbor/shared-partner counting does **not** exist as a reusable primitive (computed inline, differently, in `calculate_clustering()` and `calculate_triadcensus()` — neither decomposes to a per-edge statistic); edge toggling would currently force a full sparse-index rebuild (`build_sparse_index()` has no incremental-update path) — a real gap given ERGM's MCMC inner loop toggles single edges thousands of times per iteration; no per-node/edge attribute storage exists in `NWdef` at all, so `nodematch()`/`nodecov()`/`edgecov()` would need a new in-class attribute cache or an unacceptably slow per-step Stata-dataset round-trip — a design decision to make deliberately before any ERGM work starts.
