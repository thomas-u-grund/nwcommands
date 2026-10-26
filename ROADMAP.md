# Roadmap

## Guiding principle

Modern scalable graph algorithms, classical social network analysis, network inference, and
deep Stata integration, all on the existing `nw*` command surface. No new command prefix, no
wholesale rewrites, no silent behavior changes — extend and consolidate before adding exotic new
areas, and preserve compatibility for everything already shipped.

## Recently added

**Statistical network models** now live in their own packages (all GPL-3, each requiring this
core): `nwergm` (ERGM), `nwsaom` (stochastic actor-oriented models), `nwrem` (relational event
models) and `nwdynam` (Dynamic Network Actor Models). Their roadmaps are kept in their own
repositories. The core keeps the temporal/two-mode groundwork they build on.

**Cohesive subgroups and graph structure**: k-cores, cliques, k-plexes, n-cliques/n-clans,
k-components, and a full multi-level Moody-White cohesive-blocking hierarchy (`nwcohesion`);
lambda sets (edge connectivity, `nwlambda`); classical factions/blockmodeling (`nwfactions`,
`nwcoreperiphery`); CONCOR (`nwconcor`).

**Centrality, similarity, and inference**: common-neighbor similarity indices (Jaccard, Dice,
cosine, Adamic-Adar); walk-counting Katz/Bonacich centrality; PageRank and random-walk hitting
times; assortativity (Newman 2002); induced/endogenous/exogenous centrality decomposition
(Everett & Borgatti 2010) for degree, betweenness, closeness, and eigenvector centrality; max-flow,
minimum cuts, and bipartite matching; a 4-node undirected motif/graphlet census; spectral graph
analysis (Laplacian eigenstructure, algebraic connectivity, spectral bipartitioning); label
propagation as a second community-detection algorithm alongside Louvain; tie turnover/stability
between two waves of a network.

**Stata-native integration**: alter/neighbor attribute aggregation directly in `nwgen`
(`mean(alter.x)`-style, with categorical proportions and multi-hop lagged exposure); dyadic
dataset export with ego/alter comparison variables; `nwqap`'s full `eclass` integration
(`estimates table`, `test`, `lincom`, `esttab`, double semi-partialling, `predict`).

**Visualization**: native SVG/PDF vector export for every plot element; Kamada-Kawai,
hierarchical (Sugiyama-style), and dedicated bipartite layouts.

**Two-mode and temporal groundwork**: two-mode/bipartite status as a first-class, compositional
network property (a declaration that every derived network keeps, commands that use their two-mode form automatically on a two-mode network (`onemode` for the other), one shared refusal for the commands that cannot work on a
two-mode network, Barber's bipartite modularity, nestedness, the bipartite motifs and node positions of `bmotif` (`nwmotifs`), a within-mode null model, export and import in all four formats; see the page
on two-mode networks); temporal
metadata (`time()`/`interval()`/`eventtime()`) and slicing (`nwattime`) — the foundation the
relational-event and actor-oriented models above are built on.

**Performance**: a sparse (CSR/CSC) graph backend across the core structural commands, proven at
100,000 nodes / 1,000,000 edges with no external dependencies, with lazy, size-guarded dense
materialization as a compatibility fallback; a bespoke native (C) kernel for betweenness
centrality, roughly two to three orders of magnitude faster than the Mata implementation at
scale.

## In progress

- **Two-mode/temporal architecture**: the core metadata and a first slicing command
  (`nwattime`) are in place; migrating more existing commands to be temporal-aware, and
  windowed/ranged (rather than exact-timestamp) event slicing, remain open.
- **Two-mode kernels**: the bipartite Louvain search runs in Mata; native kernels for it and for the module search of
  `bipartite::computeModules`, faster tie swapping and a two-mode null model for `nwcug` remain open.

## Planned / under consideration

- Leiden community detection, refining Louvain's known tendency toward badly-connected
  communities.
- Larger-scale layouts for `nwplot` (current layouts are designed for graphs up to a few hundred
  to low thousands of nodes).
- Faster `nwplot` layout computation — the current (Mata) layout algorithm is noticeably slow;
  a plot should render close to instantaneously. Worth profiling to find the actual bottleneck,
  and likely a candidate for a native (C) kernel alongside the package's existing native
  betweenness backend, rather than a purely algorithmic fix.
- Self-loop rendering, automatic two-mode color/symbol styling, and parallel-edge rendering in
  `nwplot`.
- Full blockmodeling (image matrices, stochastic block models, goodness-of-fit) building on the
  existing structural-equivalence engine.
- A general induced-subgraph extraction primitive, for any future feature that needs a real
  standalone subgraph object rather than per-node neighbor aggregation.

## Known limitations, by design

- General (non-bipartite) matching is out of scope; `nwmatching` covers the bipartite case, where
  a much simpler exact algorithm applies.
- Networks are not automatically re-projected between one-mode and two-mode representations under
  any circumstance; a command that needs a one-mode network will error rather than guess.
