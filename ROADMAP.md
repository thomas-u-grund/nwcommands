# Roadmap

## Guiding principle

Modern scalable graph algorithms, classical social network analysis, network inference, and
deep Stata integration, all on the existing `nw*` command surface. No new command prefix, no
wholesale rewrites, no silent behavior changes — extend and consolidate before adding exotic new
areas, and preserve compatibility for everything already shipped.

## Recently added

**Statistical network models** — the biggest area of recent growth:

- `nwergm` — exponential-family random graph models (ERGM), with MPLE and MCMC-MLE estimation,
  a substantial term library (dyad-independent covariate/factor terms, the full triangle/k-star
  family, all five geometrically-weighted shared-partner definitions, degree-distribution terms,
  the full bipartite/two-mode term family, curved parameters via a decay map), and an optional
  native (C) MCMC backend for performance.
- `nwsaom` — stochastic actor-oriented models (Snijders-style SAOM), including the full RSiena
  effect catalog for wave 1, multi-wave chaining, standard errors, network/behavior co-evolution,
  composition change, and missing-data handling, with a native (C) backend for the ministep
  sampler.
- `nwrem` — relational event models (Butts 2008), fit via the ordinal partial likelihood, with
  degree, inertia, recency-rank, and covariate effect families.
- `nwdynam` — Dynamic Network Actor Models (Stadtfeld & Block 2017), with separate rate and
  choice sub-models, a broad effect catalog (homophily/similarity, closure, tertius, windowed
  recency effects, two-mode support, a coordination sub-model for undirected tie formation), and
  a native (C) backend for the likelihood/gradient evaluation.

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
network property (including a two-ID-variable `nwset ..., twomode` declaration form); temporal
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
- **DyNAM effect coverage**: most of the reference effect catalog is implemented; a handful of
  effects that need genuinely different internal machinery (`tertiusDiff`, dynamically-evolving
  cross-network effects, two-mode support for a few remaining effect types) are still open.
- **REM effect coverage**: triad/shared-partner effects are the one remaining item before the
  planned v1 effect set is complete.

## Planned / under consideration

- Leiden community detection, refining Louvain's known tendency toward badly-connected
  communities.
- Larger-scale layouts for `nwplot` (current layouts are designed for graphs up to a few hundred
  to low thousands of nodes).
- Faster `nwplot` layout computation — the current (Mata) layout algorithm is noticeably slow;
  a plot should render close to instantaneously. Worth profiling to find the actual bottleneck,
  and likely a candidate for a native (C) kernel alongside the package's existing native
  betweenness/ERGM/SAOM/DyNAM backends, rather than a purely algorithmic fix.
- Self-loop rendering, automatic two-mode color/symbol styling, and parallel-edge rendering in
  `nwplot`.
- Full blockmodeling (image matrices, stochastic block models, goodness-of-fit) building on the
  existing structural-equivalence engine.
- A general induced-subgraph extraction primitive, for any future feature that needs a real
  standalone subgraph object rather than per-node neighbor aggregation.
- A tutorial for writing custom ERGM terms — the term registry already supports this; what
  remains is documentation.

## Known limitations, by design

- Curved ERGM MCMC-MLE (e.g. `gwesp` with an estimated decay parameter) can be genuinely
  statistically degenerate on small, dense networks — this is a property of the likelihood
  surface itself, not an unfixed bug, and is reported as a clear error rather than an unreliable
  fit. Curved MPLE is unaffected.
- General (non-bipartite) matching is out of scope; `nwmatching` covers the bipartite case, where
  a much simpler exact algorithm applies.
- Valued/signed ERGMs and temporal ERGM (TERGM) extensions are not planned — relational-event and
  actor-oriented dynamics are instead covered by `nwrem`/`nwdynam`/`nwsaom`, dedicated engines
  built for exactly that purpose.
- Networks are not automatically re-projected between one-mode and two-mode representations under
  any circumstance; a command that needs a one-mode network will error rather than guess.
