# nwcommands

**Version 3.13.0** (31 October 2026)

Network analysis for Stata — 134 commands for importing, generating, describing,
analyzing, and visualizing networks, alongside Stata's own regular
data commands.

```stata
. nwwebuse florentine, nwclear
. nwplot flomarriage, label(_nwnode)
. nwbetween flomarriage
. sum _between
```

## Native plugins

The core and the model packages `nwsaom`, `nwergm` and `nwdynam` ship compiled plugins for macOS, Linux and Windows, and the C source: `net get nwcommands, from(https://nwcommands.org/net/)` (or `net get <package>` for a model package) copies it, and it is in `native/` of each repository. If a shipped plugin is missing for a platform, is older than the `.ado` files or does not load, `nwinstall, buildplugin(all)` compiles the plugins on your computer (macOS and Linux; needs a C compiler and `make`).

## What's here

- **Import / export**: edgelists, adjacency matrices, UCINET/Pajek-style formats
  (`nwfromedge`, `nwimport`, `nwset`, `nwexport`, ...).
- **Generators**: random, small-world, preferential-attachment, lattice, and expression-based
  networks (`nwrandom`, `nwsmall`, `nwpref`, `nwlattice`, `nwgenerate`, ...).
- **Structural analysis**: centrality, components, cliques/k-plexes/k-cores, cohesive
  subgroups, community detection, structural equivalence, QAP, and more (see
  `help nwtopical` once installed for the full, organized command index).
- **No external packages.** The core commands need nothing but Stata (17 or later; tested with Stata 17 and 18, see the Installation section) and this package: no SSC
  packages (`gsample`, `moremata`, `labellist` and `tabplot` are replaced by built-in code; they used to be
  installed silently on first use), no internet after installation, and nothing is written to your PLUS directory.
- **Statistical network models** live in separate packages that build on this one (all GPL-3):
  `nwergm` (exponential-family random graph models), `nwsaom` (stochastic actor-oriented
  models), `nwrem` (relational event models) and `nwdynam` (Dynamic Network Actor Models).
  Install each with `net install <name>, from(https://raw.githubusercontent.com/thomas-u-grund/<name>/main/)`.
  They are separate packages, so they are not part of the core: installing or updating `nwcommands`
  never replaces them.
- **Example data**: real networks to try the commands on, loaded with `nwwebuse` (list: `help netexample`;
  sources and licences: the website page "Data sets"). They include two two-mode
  data sets: `davis` (Davis, Gardner and Gardner 1941, the Southern women: 18 women, 14 events, 89 ties;
  no licence stated for the data) and `ftdirectors_se` (Swedish company directors, a subset of
  Evtushenko and Gastner, doi:10.5281/zenodo.3553442, CC BY 4.0: 5,092 directors, 455 companies, 5,669 ties).
  There are also three signed networks (positive and negative ties): `senate114` and `senate93` (US Senate
  co-sponsorship networks of the 114th and 93rd Congress, Neal 2020, doi:10.6084/m9.figshare.8096429, CC BY 4.0;
  the signs are inferred by a statistical model, not observed likes) and `gahuku` (Read 1954: alliances and
  enmities among 16 tribes of New Guinea; no licence stated for the data
  The US airport networks `usair` (50 busiest airports) and `usair_full` (all 549 airports with a domestic
  route, 5,450 directed routes, three components) are derived from the OpenFlights airport and route
  databases (route data of about 2014) and stay under their Open Database License (ODbL 1.0), not the GPL-3.
- **Visualization**: static plots and network movies (`nwplot`, `nwmovie`).
- **Dialog boxes**: 120 dialogs covering nearly every command, reachable via Stata's own
  "Network Analysis" menu (set up by `nwinstall, all` and `nwinstall, everything`, or later by `nwinstall, gui`; or `db <command>` directly) — for
  users who prefer point-and-click to typing syntax.

Every command works alongside ordinary Stata variables — a network can be loaded as Stata
variables when you want to (`nwload`, or the `xvars` option many generators accept), but this
is opt-in, not automatic, so building and analyzing a network never has to spend Stata's own
variable budget unless you ask it to.

## Installation

```stata
. net install nwcommands, from(https://nwcommands.org/net/) replace
. nwinstall, all
```

**Requirements.** Stata 17 or later (Stata/BE is enough). Tested with Stata 17 and Stata 18. The Mata library is built with Stata 17, the oldest tested version, because a library built by a newer Stata is ignored by older ones; Stata 16 and older have not been tested and are not expected to work.

The first line installs just `nwinstall` itself and the landing help topics; `nwinstall,
all` then downloads everything else — every command, all help files, and all 120 dialog
boxes — and sets up a "Network Analysis" menu in Stata's own User menu (one line in your
`profile.do`, written only once), so every command is reachable through a dialog box, not just
the command line. Add `nogui` to leave the menu out. `nwinstall, everything` does the same for
the core and the four model packages. See `help nwinstall` for the full option reference.

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
`src/`-style layout. `help nwtopical` (once on your `adopath`) is the full, organized command
index; `help nwintro` covers general concepts, conventions, and — importantly — realistic
guidance on what network sizes are actually feasible for which commands.

**Branches**: `main` is the current, tested release — install/point at this by default (the
model packages nwsaom, nwergm, nwdynam and nwrem also use `main`). `develop` is where active work
happens and is merged into `main` once a batch of changes is regression-tested. `master` is an
exact copy of `main`, kept so that older install lines and links keep working; it is updated
automatically.

## Performance

Two backends exist for the commands where it matters, chosen automatically and transparently —
there is nothing to configure, and results are identical either way:

- **A sparse-native Mata graph representation** for the core structural commands (`nwfromedge`,
  `nwcomponents`, `nwdegree`, `nwneighbor`, `nwclustering`, and the other traversal commands listed
  in `help nwintro`), with no external dependencies. Measured end to end in Stata/BE (not MP) on a
  shared Mac, random directed network with 10 ties per node, seconds:

  | nodes / ties | `nwfromedge` | `nwdegree` | `nwcomponents` | `nwneighbor` (1 node) | `nwclustering` |
  |---|---|---|---|---|---|
  | 10,000 / 100,000 | 0.3 | 0.05 | 0.05 | 0.06 | 0.8 |
  | 25,000 / 250,000 | 0.8 | 0.13 | 0.12 | 0.13 | 2.0 |
  | 40,000 / 400,000 | 1.2 | 0.16 | 0.16 | 0.14 | 3.6 |
  | 100,000 / 1,000,000 | 3.7 | 0.5 | 0.5 | 0.4 | 16 |

  Building with automatic directed/undirected detection (no `directed` option) took 8.8 s at
  100,000 nodes, `forceundirected` 14 s. None of these builds the dense N x N matrix.
  Saving and exchanging a big network also works (same random networks, same machine, load average
  about 5, seconds; `nwtoedge, compress` and `nwsave` list only the stored ties):

  | nodes | `nwtoedge, compress` | `nwfromedge` of that list | `nwsave` (file) | `nwuse` | `nwappend` |
  |---|---|---|---|---|---|
  | 25,000 | 2.0 | 3.3 | 2.7 (30 MB) | 4.4 | 4.0 |
  | 40,000 | 2.9 | 5.6 | 6.4 (49 MB) | 10.4 | 10.4 |
  | 100,000 | 14.7 | 20.2 | 14.8 (124 MB) | 28.1 | 36.4 |

  Commands that still need the full adjacency matrix (for example the all-pairs `nwgeodesic`,
  uncompressed `nwtoedge`, `nwsimilar`, two-mode networks, most weighted-distance commands) are
  refused above 20,000 nodes (or earlier, when their matrices would not fit in 12 GB) with a
  message that names an alternative; the other commands were audited at 100,000 nodes.
- **Compiled native (C) kernels** (Stata plugins, source in `native/`) for the specific
  operations where Stata's own Mata interpreter is the actual bottleneck, not the algorithm:
  betweenness centrality. Falls back to an equivalent,
  fully-supported pure-Mata implementation on any platform without a compiled plugin for it.

`help nwintro` (section "Limitations and feasible network sizes") is the practical,
evidence-based summary of what to expect at various network sizes.

## Development

- `cscripts/` — 140+ regression tests, one per command family, run in both "dev mode" (against
  the Mata source directly, `do unw_core.do`) and "production mode" (against the compiled
  `lib/lnwcommands.mlib`, mirrored under `lib/cscripts_prod/`, a gitignored build artifact).
- `native/` — C sources for the native plugin `nwgraph.c` and the `nwedit_viewer` launcher, with
  their own `Makefile`; `.github/workflows/build-plugins.yml` builds and commits all three
  platforms' binaries on push.
- `lib/build.do` — rebuilds `lib/lnwcommands.mlib` from `unw_core.do` (run from the repository root).

## License

nwcommands is free software under the GNU General Public License, version 3 (see `LICENSE` and `NOTICE.md`). The model packages nwsaom, nwergm, nwdynam and nwrem are separate packages under the same license.
