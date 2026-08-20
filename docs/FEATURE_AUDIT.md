# nwcommands Feature Audit

Living document. Last updated: 2026-08-21, by autonomous development session.

Status legend: **A** fully implemented & reasonably complete · **B** implemented but incomplete · **C** partial/internal machinery, no complete user-facing command · **D** legacy/problematic (dense-matrix-bound, scalability-limited, or otherwise needing rework) · **E** not implemented.

Methodology: every classification below is based on reading the actual `.ado`/Mata bodies (syntax, options, Mata calls), not inferred from filenames. Conducted via 7 parallel static-analysis passes plus this session's own direct architecture work (sparse backend, community detection, bug fixes). Read-only — no functionality was changed by the audit itself.

## Executive summary

`nwcommands` has substantially more depth than its help-file surface suggests. The core (`nwset`/`nw_syntax`/`NWdef`) is sound and — as of this session — has a working sparse backend proven to scale to 100,000 nodes / 1,000,000 edges without ever allocating a dense matrix. Centrality, generators, dyad/triad census, I/O, and visualization are all real and mostly complete (B/A). The biggest gaps cluster in exactly the areas the project's own roadmap prioritizes: **structural equivalence/blockmodeling/core-periphery are almost entirely absent** (E across the board except a genuinely useful but unlabeled `nwsimilar`/`nwdissimilar`/`nwhierarchy` chain), **cohesive subgroups (cliques/k-cores/k-plexes) are completely absent**, and **Stata-native alter-aggregation (`mean(alter.x)`-style) does not exist anywhere** despite being architecturally straightforward to add.

Several findings deserve special attention:
- **`nw2project`** (one-mode projection from a two-mode network) is fully documented in three separate `.sthlp` files with a complete worked spec, but **the `.ado` file does not exist**. A phantom command.
- **`nwburt.ado`**, a complete, well-documented implementation of Burt's structural-holes suite (effective size, efficiency, constraint, hierarchy), existed in the last real git commit (2015) and was deleted during the years of uncommitted work; only a stripped-down, incomplete `nwconstraint.ado` (dyadic constraint matrix only, no per-node aggregation, no help file) survives in the working tree.
- **`nwbalance.ado`** (structural balance / signed triads) is real, correct, and functional — with zero documentation and zero tests.
- **`nwergm.ado`** is not a native ERGM implementation — it shells out to R (and even auto-installs R), directly violating this project's own "no external runtime dependencies" principle. Reclassified D; any native ERGM work starts from zero.
- **`nwgenvar.ado`** is dead code: it defines `program nwgenerate` under a mismatched filename, so Stata's ado-loader can never actually load it as `nwgenvar`.
- **`nwgenerate.ado`** has several silently-dead commented-out dispatch branches (`dyadprob`, `homophily`, `lattice`, `path`, `pref`, `ring`, `small`, `transpose`).
- Weighted-network semantics are **mostly** handled deliberately and well (e.g. `nwgeodesic`'s `alpha` exponent correctly distinguishes weight-as-strength from weight-as-cost), but **betweenness centrality silently ignores weights** (plain BFS, not Dijkstra, despite the Brandes' algorithm structure) and **eigenvector centrality silently dichotomizes** — both real, precisely-located, fixable gaps.

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

Degree/in/out/strength (A, sparse-migrated this session), betweenness (A, sparse-migrated + bug-fixed this session, but **unweighted only**), closeness (A via `nwgeodesic`, D-flagged), eigenvector (A, genuine `symeigensystem()` eigen-decomposition, but **dichotomizes weights silently** and dense-only), Katz (B — `nwkatz.ado` does NOT do genuine eigen-computation despite typical Katz-centrality expectations; just `rowsum`/`colsum`, worth auditing further), PageRank/Bonacich power/alpha/Hubbell/HITS/eccentricity/information/flow-betweenness/current-flow/bridging/distance-limited/group centrality — all **E**, not implemented. Centralization (network-level) exists for degree/betweenness.

## D. Structural holes and brokerage

| Feature | Status | Command | Notes |
|---|---|---|---|
| Burt constraint (dyadic) | C | `nwconstraint` | returns unaggregated dyadic matrix only; no help file |
| Effective size, efficiency, hierarchy | **E in working tree, recoverable** | historical `nwburt.ado` | complete, documented, working implementation exists in git history (`git show master:nwburt.ado`), deleted during uncommitted-years drift |
| Gould-Fernandez brokerage roles | E | — | confirmed absent |
| Bridges (global/local/distance) | A (D-flagged) | `nwbridges` | correct, but depends on the not-yet-sparse-migrated `calculate_distances_without()` |

## E. Structural equivalence, roles and positions

The single most "hidden" area in the audit. `nwsimilar`/`nwdissimilar` (B, undocumented as "structural equivalence" anywhere) compute exactly the relational-profile similarity/distance measures (Pearson, matches, Jaccard, Hamming, crossproduct, Euclidean, Manhattan) this literature calls for, with incoming/outgoing/both profile direction options. `nwhierarchy` (B) chains this into Stata's native `clustermat` for real hierarchical clustering. `nwdendrogram` (A) visualizes the result. But: no command packages this as "role/position analysis," no equivalence-class output is ever written back as a node categorical variable, and **CONCOR, regular equivalence/CATREGE, automorphic equivalence, exact structural equivalence, and MDS-of-positions are all confirmed E** — zero grep hits anywhere.

## F. Blockmodelling and core-periphery

**Confirmed E across the entire area** — no blockmodel, image matrix, block density/mean, goodness-of-fit, SBM (plain or degree-corrected), bipartite/signed blockmodel, or core-periphery (any variant) functionality exists anywhere. The `nwsimilar`/`nwdissimilar` engine is the one reusable asset a future blockmodel-partition step could build on.

## G. Components, cohesion and connectivity

Weak components: A (`nwcomponents`, explicitly undirected-only by design). Strongly-connected components, bicomponents, articulation points, vertex/edge connectivity, min separators, vertex/edge-disjoint paths, min cuts, max flow, dominator trees: **all E**, confirmed via clean grep. Bridges: A but D-flagged (see D above, same dependency).

## H. Paths, distances and reachability

Shortest paths between one pair (`nwpath`, B — unweighted only, no batch/k-shortest-paths mode), all-pairs distances/diameter/average-path-length/weighted-via-alpha (`nwgeodesic`, D-flagged — dense `Brute_dist`/`Dijkstra_dist`, not yet sparse-migrated), reachability/transitive closure (`nwreach`, thin `nwgeodesic` wrapper, same D dependency), 1-step neighbors (`nwneighbor`, D — still dense row/column reads, not yet migrated to this session's sparse accessors despite the primitive existing). k-step reachability, transitive reduction, per-node eccentricity/radius: **E**.

## I. Dyads, triads and motifs

Dyad census with reciprocity (A, `nwdyads`, **zero test coverage** — a real gap for an otherwise-solid command), full Davis-Leinhardt 16-type triad census (A, `nwtriads`, D-flagged — dense matrix-power algorithm). Simple triangle/transitive/cyclic/open-triple counts: B, derivable from the 16-type census but no dedicated convenience output. Node-level motif participation, arbitrary/4+-node motifs, cycle census beyond triads, signed triad census: **E**.

## J. Similarity, homophily, mixing and assortativity

Not separately audited this pass (fell between fork assignments) — flag for a follow-up targeted pass. Known from adjacent audits: `nwhomophily.ado` exists (a network *generator* from a homophily rule, confirmed unrelated to alter-aggregation per area AF); E-I index exists via `nwtabulate`/`nwmixing`'s permutation routines (each hard-coded to E-I specifically, no general "permute and test an arbitrary statistic" framework). Assortativity (nominal/numeric/degree/directed/weighted): **E**, confirmed absent via cross-cutting grep in area O's audit. Common-neighbor similarity (Jaccard/Dice/cosine/Adamic-Adar/cocitation/bibliographic coupling): not directly audited, presumed E pending confirmation — **open item**.

## K. Cohesive subgroups

**Confirmed E across the entire area** — maximal cliques, clique census, n-cliques, n-clans, k-plexes, k-cores/shell numbers, k-components, lambda sets, factions, and Moody-White cohesive blocks: zero real implementation anywhere. `nwsimmelian` (A, Simmelian-tie/triad-embeddedness) is real and complete but is not a substitute for clique detection — a related-but-distinct concept, and the one piece of adjacent reusable machinery (shares the mutual-tie-matrix intersection pattern a k-plex/clique implementation could reuse).

## L. Community detection

**A — implemented this session.** `nwcommunity` (Louvain) and `nwmodularity`, both sparse-native, weighted-aware, certified against 3 hand-computable networks. Leiden/Infomap/Walktrap/label-propagation/fast-greedy/edge-betweenness/leading-eigenvector/spinglass/spectral clustering: **E**, not implemented (Louvain is the highest-value single algorithm and a defensible first choice; the others are lower-priority extensions). Partition comparison (adjusted Rand/NMI/variation-of-information/split-join): **E**.

## M. Ego-network analysis

Neighbor listing only (B, `nwneighbor` — binary-only, dense, no induced-subgraph extraction). Radius-k ego networks, ego-network size/density, alter-alter ties, alter composition/diversity, ego-alter similarity, ego-network effective size/efficiency, ego brokerage, ego-network change over time: **all E**. No general induced-subgraph-extraction primitive exists at all (not ego-specific).

## N. Two-mode/bipartite analysis (high priority)

Core infrastructure real (`is2mode`/`nodesmode1`/`nodesmode2`/`modes` fields on `NWdef`, though storage is masked-square not true rectangular biadjacency). `nw2set`/`nw2fromedge`/`nw2toedge`: A. Bipartite clustering (`nw2clustering`): B, correct 4-path algorithm but D-flagged (Stata reshape/merge/collapse chain, O(N⁴)-shaped, not sparse-migrated). **`nw2project` (one-mode projection): E in the working tree despite being fully spec'd in three `.sthlp` cross-references — a phantom command, and the highest-value, lowest-ambiguity gap found in this entire audit.** Two-mode centrality/betweenness/eigenvector, bipartite communities/core-periphery/blockmodels, affiliation statistics, bipartite matching: **E**.

## O. Weighted/valued networks (cross-cutting)

Genuinely weight-aware: degree/strength (Opsahl generalized formula), transitivity/clustering (5 aggregation modes), shortest paths/closeness (`alpha` exponent, deliberately distinguishes strength from cost — a real design strength), community detection. **Confirmed gaps**: betweenness (plain unweighted BFS despite Brandes' structure), eigenvector centrality (silently dichotomizes), density (no weighted-sum variant), reciprocity (binary only), assortativity (doesn't exist at all).

## P. Signed networks

Structural balance (`nwbalance`, B — genuinely correct Cartwright-Harary triadic balance, D-flagged for its Stata reshape-chain implementation, **zero documentation, zero tests** — a hidden-functionality finding). Full 16-type signed triad census, frustration index, positive/negative degree or strength, signed communities/assortativity/blockmodels, positive/negative-only paths: **E**.

## Q. Graph transformations and graph algebra

Symmetrization/transpose: A. Dichotomization/recoding (`nwrecode`): A but **fully undocumented** (no `.sthlp`, no inline header) — hidden. Contraction (`nwcollapse`): A but misleadingly named (findable only by reading the body, not by searching "contract"/"merge"). Induced subgraph by condition or node-list (`nwsubset`/`nwkeepnodes`/`nwdropnodes`): A. Reverse/complement/union/intersection/difference: C — all expressible via the general `nwgen`/`nwreplace` algebra engine's elementwise operators, but with no dedicated commands, no validation, no discoverability. Disjoint union, graph composition, graph power, line graph, transitive closure/reduction, sparsification/backbone extraction: **E**.

## R. Graph generation and null models

Erdős-Rényi/Bernoulli, fixed-edge-count, dyad-census-conditioned (a genuine CUG-test building block, unused as such — see S), regular/ring/lattice, Watts-Strogatz, Barabási-Albert preferential attachment: all **A** (`nwrandom`, `nwring`, `nwlattice`, `nwsmall`, `nwpref`). Configuration model / degree-sequence-preserving, degree-preserving rewiring (general), random geometric graph, random dot-product graph, bipartite random graphs: **E**. SBM generation: C (achievable manually via `nwdyadprob`'s arbitrary tie-probability matrix, no dedicated syntax).

## S. Permutation tests and network inference

`nwqap.ado` (B) is a real, substantial, generic-estimator QAP regression engine (multiple predictor networks, node-attribute IVs auto-expanded, permutation-based p-values) — but **simple/Y-permutation QAP only**, not `eclass`, zero test coverage. MRQAP/QAPSPP (Dekker-Krackhardt-Snijders semi-partialling), QAP-X/independent-X permutation, CUG tests: **E**, though `nwrandom, census()` is a ready-made CUG null-model generator sitting unused. `nwpermute` is a solid general node-label-permutation engine.

## T. Network regression (high priority — target `nwregress`/`nwlogit`)

Already covered under S — same command (`nwqap`). **This is an extension project, not a from-scratch build**: wrap the existing long-format/permutation machinery in a proper `eclass` shell with own `e(b)`/`e(V)`/`predict` support, add QAPSPP (X-permutation) as a second inference mode, certify with tests. Medium-to-Large effort. Network autocorrelation/lag/error models: **E**, nothing found.

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

Real layout coverage: Fruchterman-Reingold, metric/classical MDS, circle, grid, manual/nodexy, plus an undocumented `_layoutfunction` extension point (`nwplot`, B). Missing: Kamada-Kawai, Sugiyama/tree, dedicated spectral layout, Davidson-Harel, any genuinely large-network-aware layout (current layouts are O(N²)-shaped with hardcoded node caps of 100-1100 depending on Stata flavor). Node/edge aesthetics (color/size/symbol/width/arrows) are rich and confirmed working with arbitrary Stata variables. Export-coordinates-without-plotting: A. **`nwplot.ado` — the single largest file in the package — has zero test coverage.** JS-based interactive plotting (`nwplotjs`/`nwplot_sigmajs`): C, real but unverified maturity. Animation (`nwmovie`): B, genuinely supports multi-network frames, zero tests.

## AE. Import/export and interoperability

Import: B, 6 formats (Pajek, matrix, edgelist, compressed, GML, GraphML, UCINET) — Pajek and UCINET genuinely well-evidenced (local sample files, careful `.dl`-format parsing with `nets()`/`diagonal()`/embedded-label handling); GML/GraphML lower-confidence (no local fixtures). Export: B, only 2 formats (Pajek, UCINET) — a real asymmetry against import's 6. CSV/JSON/DOT/Gephi/igraph/NetworkX-native formats: **E** as distinct import/export types (CSV is handled natively via Stata's own `import delimited` + `nwfromedge`, which is a reasonable substitute, not a true gap).

## AF. Stata-native network/data integration (high priority — target `nwgen exposure = mean(alter.smoking)`)

`nwgen`/`nwgenerate` (A for existing scope) already supports `nwgen X = degree(net)`-style node-level-measure-as-variable generation — real precedent for the target pattern. Node-attribute-to-network algebra (`nwgen net = 2*exp(flomarriage)*attr`) is real and documented. **But neighbor/alter aggregation (`mean(alter.x)`-style) does not exist anywhere in the codebase** — confirmed via full read of the expression engine (`nw_expnetexp.ado`). This is the single highest-leverage gap for Stata-native differentiation vs. igraph/sna, and `nwgenerate`'s existing dispatch-table architecture is a natural, well-scoped extension point rather than needing new infrastructure. Two bugs found in the process: `nwgenvar.ado` is dead code (defines `program nwgenerate` under a mismatched filename — Stata's ado-loader can never load it as `nwgenvar`); `nwgenerate.ado` has 8 silently-dead commented-out dispatch branches.

## AG. Programming/API support

Architecturally closer to API-ready than its documentation suggests. `nw_syntax` is a genuine, consistently-used single resolution point; this session's sparse accessors (`neighbors()`, `degree()`, `has_edge()`, etc.) are exactly the composable primitives a stable API needs. **The gap is purely documentation** — `book_programming.tex` documents only the read-only extraction contract (`nwtomata`/`_nwsyntax`), nothing about the `NWdef`/`NWsdef` class hierarchy or how to write a new `nw*` command against it. No `.sthlp` file documents the classes either. Cheap to close relative to its value.

## AH. Future ERGM readiness

`nwergm.ado` is **not** a native implementation — confirmed it shells out to `Rscript` and bundles `nwergm_install_win`/`nwergm_install_osx` programs that install R itself, directly violating this project's own "no external runtime dependencies" principle. Reclassified **D**; any native ERGM work starts from zero, not as an nwergm extension. Architectural readiness assessment: `has_edge()`/neighbor lookup exist (this session); common-neighbor/shared-partner counting does **not** exist as a reusable primitive (computed inline, differently, in `calculate_clustering()` and `calculate_triadcensus()` — neither decomposes to a per-edge statistic); edge toggling would currently force a full sparse-index rebuild (`build_sparse_index()` has no incremental-update path) — a real gap given ERGM's MCMC inner loop toggles single edges thousands of times per iteration; no per-node/edge attribute storage exists in `NWdef` at all, so `nodematch()`/`nodecov()`/`edgecov()` would need a new in-class attribute cache or an unacceptably slow per-step Stata-dataset round-trip — a design decision to make deliberately before any ERGM work starts.
