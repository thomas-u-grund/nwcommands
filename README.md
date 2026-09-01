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
- **Dialog boxes**: ~120 GUI dialogs covering nearly every command, reachable via Stata's own
  "Network Analysis" menu after `nwinstall, permanently` (or `db <command>` directly) — for
  users who prefer point-and-click to typing syntax.

Every command works alongside ordinary Stata variables — a network can be loaded as Stata
variables when you want to (`nwload`, or the `xvars` option many generators accept), but this
is opt-in, not automatic, so building and analyzing a network never has to spend Stata's own
variable budget unless you ask it to.

## Installation

```stata
. net from "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/develop"
. net install nwcommands
. nwinstall, all
```

The first two lines install just `nwinstall` itself and the landing help topics; `nwinstall,
all` then downloads everything else — every command, all help files, and all ~120 dialog
boxes — and installs them permanently. Add `nwinstall, permanently` to also add a "Network
Analysis" menu to Stata's own User menu, so every command is reachable through a dialog box,
not just the command line. See `help nwinstall` for the full option reference.

**No internet access or admin rights?** `nwinstall, localcopy` installs by copying files
directly from an nwcommands folder you already have (zip, USB drive, shared network drive) into
your own PERSONAL ado directory — no download, no admin rights needed. See the "Computers
without internet access or admin rights" section of `help nwinstall`.

Or, to track the repository directly (recommended during active development — `net install`
snapshots a point in time, an `adopath` addition always reflects the latest commit):

```stata
. adopath + "/path/to/nwcommands"
```

```sh
git clone https://github.com/thomas-u-grund/nwcommands.git
```

The repository's own top level *is* the Stata package directory — every `.ado`/`.sthlp` file
sits at the root, deliberately, matching how a plain `net install`-able Stata package is laid
out (one flat directory Stata's own `adopath` can point at directly) rather than a
`src/`-style layout. `help nw_topical` (once on your `adopath`) is the full, organized command
index; `help nw_intro` covers general concepts, conventions, and — importantly — realistic
guidance on what network sizes are actually feasible for which commands.

**Branches**: `master` is the current, tested release — install/point at this by default.
`develop` is where active work happens and is merged into `master` once a batch of changes is
regression-tested; day to day the two are kept in sync.

## Performance

Two backends exist for the commands where it matters, chosen automatically and transparently —
there is nothing to configure, and results are identical either way:

- **A sparse-native Mata graph representation** for the core structural commands (components,
  degree, clustering, neighbor traversal, unweighted distances) — proven at 100,000 nodes /
  1,000,000 edges with no external dependencies.
- **Compiled native (C) kernels** (Stata plugins, source in `native/`) for the specific
  operations where Stata's own Mata interpreter is the actual bottleneck, not the algorithm:
  `nwergm`'s own MCMC sampler and betweenness centrality. Falls back to an equivalent,
  fully-supported pure-Mata implementation on any platform without a compiled plugin for it.

`help nw_intro` (section "Limitations and feasible network sizes") is the practical,
evidence-based summary of what to expect at various network sizes.

## Development

- `cscripts/` — 140+ regression tests, one per command family, run in both "dev mode" (against
  the Mata source directly, `do unw_core.do`) and "production mode" (against the compiled
  `lib/lnwcommands.mlib`, mirrored under `lib/cscripts_prod/`, a gitignored build artifact).
- `native/` — C sources for the two native plugins (`ergm_mcmc.c`, `nwgraph.c`) and their own
  `Makefile`; `.github/workflows/build-plugins.yml` builds and commits all three platforms'
  binaries on push.
- `dev/` — benchmark scripts (including R-vs-Stata comparisons for `nwergm`) and other
  development-only utilities not part of the shipped package.

## License

Free to install and use, including for commercial research — see `LICENSE`. Redistribution,
modification, and commercial licensing require permission; contact thomas.u.grund@gmail.com.
