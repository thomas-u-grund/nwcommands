# nwcommands

Network analysis for Stata — over 130 commands for importing, generating, describing,
analyzing, visualizing, and statistically modeling networks, alongside Stata's own regular
data commands.

```stata
. nwwebuse florentine, nwclear
. nwplot flomarriage, label(_nwnode)
. nwbetween flomarriage
. sum _between
```

## What's here

- **Import / export**: edgelists, adjacency matrices, UCINET/Pajek-style formats
  (`nwfromedge`, `nwimport`, `nwset`, `nwexport`, ...).
- **Generators**: random, small-world, preferential-attachment, lattice, and expression-based
  networks (`nwrandom`, `nwsmall`, `nwpref`, `nwlattice`, `nwgenerate`, ...).
- **Structural analysis**: centrality, components, cliques/k-plexes/k-cores, cohesive
  subgroups, community detection, structural equivalence, QAP, and more (see
  `help nw_topical` once installed for the full, organized command index).
- **Statistical network models**: `nwergm` — exponential-family random graph models (ERGM),
  with maximum pseudolikelihood and MCMC maximum likelihood estimation, a substantial term
  library, and an optional native (C) MCMC backend for performance (see
  `docs/ERGM_ARCHITECTURE.md`).
- **Visualization**: static plots and network movies (`nwplot`, `nwmovie`).

Every command works alongside ordinary Stata variables — a network can be loaded as Stata
variables when you want to (`nwload`, or the `xvars` option many generators accept), but this
is opt-in, not automatic, so building and analyzing a network never has to spend Stata's own
variable budget unless you ask it to.

## Installation

This package is not yet distributed via `net install` (see `docs/CERTIFICATION.md`'s own
Pending items for why — the underlying `.pkg`-generation tooling has a known, unfixed bug).
Until that's resolved, install by adding the repository to Stata's own `adopath`:

```stata
. adopath + "/path/to/nwcommands"
```

or, from the shell, clone it directly:

```sh
git clone https://github.com/thomas-u-grund/nwcommands.git
```

The repository's own top level *is* the Stata package directory — every `.ado`/`.sthlp` file
sits at the root, deliberately, matching how a plain `net install`-able Stata package is laid
out (one flat directory Stata's own `adopath` can point at directly) rather than a
`src/`-style layout. `help nw_topical` (once on your `adopath`) is the full, organized command
index; `help nw_intro` covers general concepts, conventions, and — importantly — realistic
guidance on what network sizes are actually feasible for which commands.

**Active development branch**: `develop`. `master` is a stale, pre-modernization snapshot
(the last commit on it predates most of what's described below) — point at `develop` until a
release branch is cut.

## Performance

Two backends exist for the commands where it matters, chosen automatically and transparently —
there is nothing to configure, and results are identical either way:

- **A sparse-native Mata graph representation** for the core structural commands (components,
  degree, clustering, neighbor traversal, unweighted distances) — proven at 100,000 nodes /
  1,000,000 edges with no external dependencies. See `docs/SPARSE_BACKEND.md`.
- **Compiled native (C) kernels** (Stata plugins, source in `native/`) for the specific
  operations where Stata's own Mata interpreter is the actual bottleneck, not the algorithm:
  `nwergm`'s own MCMC sampler (`docs/ERGM_ARCHITECTURE.md`) and betweenness centrality
  (`docs/NATIVE_GRAPH_LIBRARIES.md`, which also documents the licence-audited investigation
  into adopting a third-party graph library instead — igraph/NetworKit/GraphBLAS/LEMON/Boost
  Graph Library/SNAP were all surveyed — and why a small, bespoke kernel won out on the
  evidence). Falls back to an equivalent, fully-supported pure-Mata implementation on any
  platform without a compiled plugin for it.

`help nw_intro` (section "Limitations and feasible network sizes") is the practical, evidence-
based summary of what to expect at various network sizes; the two documents above are the full
technical accounts.

## Development

- `cscripts/` — 140+ regression tests, one per command family, run in both "dev mode" (against
  the Mata source directly, `do unw_core.do`) and "production mode" (against the compiled
  `lib/lnwcommands.mlib`, mirrored under `lib/cscripts_prod/`, a gitignored build artifact).
- `native/` — C sources for the two native plugins (`ergm_mcmc.c`, `nwgraph.c`) and their own
  `Makefile`; `.github/workflows/build-plugins.yml` builds and commits all three platforms'
  binaries on push.
- `docs/` — architecture and certification records, including `docs/CERTIFICATION.md`, a
  detailed, chronological log of every feature added, bug found, and decision made across this
  project's own modernization effort, and `docs/ROADMAP.md` for what's still open.
- `dev/` — benchmark scripts (including R-vs-Stata comparisons for `nwergm`) and other
  development-only utilities not part of the shipped package.

## License

MIT — see `LICENSE`.
