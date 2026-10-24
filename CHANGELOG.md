# Changelog

All notable changes to the nwcommands core package. The format follows [Keep a Changelog](https://keepachangelog.com/);
versions follow [Semantic Versioning](https://semver.org/). The model families have their own packages and changelogs
(`nwsaom`, `nwergm`, `nwdynam`, `nwrem`).

## [Unreleased]
### Fixed
- The combinatorial commands now run at the network sizes people use; they used to stop at a few hundred nodes (`tools/scale_audit`, Stata/BE, random network with 10 ties drawn per node, seconds before -> after at 300 / 1,000 / 5,000 nodes): `nwcohesion` 21.5 / >60 / - -> 0.02 / 0.10 / 1.4; `nwfactions` 37.9 / >60 / - -> 0.02 / 0.02 / 0.05; `nwlambda` >60 / >60 / - -> 0.02 / 0.09 / 1.9 (1.4 GB at 5,000 nodes: the result is a dense N x N network); `nwmotifs` >60 / >60 / - -> 0.006 / 0.014 / 0.05; `nw2clustering` (two-mode, N and N/2 nodes) 58 / >60 / - -> 0.09 / 0.24 / 1.4; `nwinduced, measure(degree)` 11.2 / >60 / - -> 0.02 / 0.03 / 0.09; `nwkplex` 16.9 s and 6.6 GB at 300 nodes, >60 s and 1.6 GB at 1,000 -> 2.1 s at 300 (0.04 s with `nomatrix`), 0.2 s at 1,000 and 2.9 s at 5,000 with `nomatrix` (the default now stops with a clear message once there are more than 100,000 sets); `nwnclan` (n = 2) >60 s and 6.6 GB at 100 nodes, killed at 20 GB at 1,000 -> 0.006 / 2.0 / 1.8 s at 100 / 300 / 1,000 nodes and 2.5 s for the 165,097 clans of 5,000 nodes with `nomatrix` (the 165,097 x 5,000 matrix is refused); `nwnclique` used 5.3 GB at 100 nodes and did not finish (46,580,136 maximal 2-cliques there, up to 64 nodes each): it now stops at once with a message that names the option to raise the limit, and `countonly` counts them in 33 s. The old Mata code is the reference: `cscripts/test_combinatorial_scale.do` and the comparison run for this change gave identical sets (in the same order), counts, variables and `r()` values on 40 random networks per command (undirected, directed, valued, signed, with isolates), `nwfactions` fitness to 1e-12.
  Causes and fixes: `nwcohesion` ran a Mata Edmonds-Karp for each of the n queries of every connectivity search, copying an N x N flow matrix per query; now a compiled search on the sparse ties (bidirectional breadth-first augmentation, each query stopped at the best value found so far, a block certified by the parent's step carries its exact connectivity to the next level). `nwfactions` recomputed an N x N correlation for every candidate move; the fitness is now updated from the within-group tie weight and the number of same-group pairs. `nwlambda` ran n(n-1)/2 maximum flows on dense N x N matrices; now n-1 flows (Gusfield's equivalent-flow tree) on the sparse graph. `nwmotifs` listed every 4-node set (O(n^4)); the counts now come from degrees, triangles per tie and common neighbours (O(m x largest degree)). `nw2clustering` copied a neighbour list per 4-path to test the closing 6-cycle. `nwinduced, measure(degree)` rebuilt a subnetwork and reran `nwdegree` n times; it now uses the closed form 2 x (stored ties of the node). `nwkplex`, `nwnclique` and `nwnclan` built the N x N distance matrix and an N x N indicator row per candidate; they now use bitset adjacency in compiled code with the same search order, and `nwnclan` drops a branch as soon as a member is more than n steps from the newest one inside the candidate set instead of listing all maximal n-cliques first.
- `nwmotifs` returned its counts rounded to 9 significant digits above 999,999,999 (every 4-node count from about 800 nodes on) and printed larger counts over each other.
- `nwfactions` gave a different partition on identical calls when two nodes had the same degree: the starting order was sorted with Mata's `sort()`, which breaks ties at random. Equal degrees are now taken in node order (documented in the help file).
- `nwfromedge` (and everything that builds a network from an edge list: `nwset ..., edgelist`, `nwimport ..., type(edgelist)`) now works at the scale the documentation promises. A directed network with 100,000 nodes and 1,000,000 ties builds in a few seconds in Stata/BE; before, it stopped with `r(920)` (macro substitution results in line that is too long) from about 40,000 nodes on, with the dense-matrix refusal `r(484)` at 25,000 nodes, and took 7 s at 10,000 nodes. Causes: (1) `_nwsyntax` exported every node label in one macro (`labs`) and `nwname` in `r(labs)`, which overflows Stata/BE's 264,408-character macro limit; both are now empty once the string would be longer than 200,000 characters (`_nwnodelab`/`_nwnodeid` read the labels from Mata); (2) `nwfromedge` built the label list with a Stata loop over a macro and checked for duplicate labels with an all-pairs comparison; labels now stay in Mata and the duplicate check sorts; (3) the automatic symmetric/directed detection and `nwsym` allocated the dense N x N matrix; `check_symmetry()` and `symmetrize()` now work on the sparse triplets when the dense matrix was never built; (4) `nwload`, `nwsync`, `nwname` (`get_missing_edges()`, `get_selfloops_number()`) touched the dense matrix or built a macro of all node names; (5) `get_modes_labeled_string()` built its result by repeated string concatenation (quadratic, 1.5 s per `nwname` call at 40,000 nodes).
- `nwcomponents` is no longer quadratic: the breadth-first search copied its queue on every step (27 s at 100,000 nodes / 1,000,000 ties, now 0.5 s).
- Duplicate rows (same ego and alter) in an edge list now give one tie, the last row given winning, in the stored sparse index too; before, the adjacency matrix had one tie but `nwdegree`/`nwclustering` counted the duplicate rows.
- Node labels of string identifiers that contain a space or a comma are kept as given (the old macro route split them into several labels and could drop a node's label).

- `nwtoedge, compress`, `nwsave`, `nwuse` and `nwappend` work for a single big network (tested to 100,000 nodes / 1,000,000 ties). `nwtoedge, compress` lists the stored ties instead of building the N x N list of dyads (new `get_edgelist_sparse()`; the output is identical, including the blanked diagonal). The isolates note it stores in the edge list (a Stata characteristic, 67,784 characters at most) falls back to the isolated nodes only when all node names do not fit. `nwsave` writes the mode list from Mata into a strL variable and `nwuse` reads it back through Mata (a macro of all modes was longer than Stata/BE allows from about 40,000 nodes), and `set_modes_from_labeled_string()` no longer scans the string character by character (28 s at 25,000 nodes, now under 1 s).
- `nwimport` of a `.dta` edge list passed `directed` on under a misspelled name, so it was ignored.
### Changed
- `nwkplex`, `nwnclique` and `nwnclan` no longer run until memory is exhausted: they stop with r(484) and a message once more than `maxplexes()` / `maxcliques()` maximal sets (default 100,000; for `nwnclan` the number of maximal n-cliques examined, default 1,000,000) have been found, when the sets-by-nodes result matrix would have more than 50 million numbers, or after `maxtime()` seconds of search (default 60). New options: `countonly` (count the sets and tabulate them by size without storing them: `r(size_table)`, `r(maxsize)`) and `nomatrix` (no sets-by-nodes matrix, only the per-node variable and the counts).
- The kernels are in the existing plugin (`native/nwcomb.h`, `native/nwcomb2.h`, included by `native/nwgraph.c`); the macOS binary is rebuilt, and the Linux and Windows binaries are rebuilt by the plugin workflow (`native/Makefile` now links `-lm` on Linux). Until those are in place, a platform without the new binary keeps using the older Mata code, with the same results and the old speed.
- Help files of the nine commands state the measured limits; `help nwintro` has a section on the combinatorial commands.
- Documentation (`README.md`, `help nwintro`) states the measured end-to-end times for `nwfromedge` and the sparse-native commands, and which commands still need the dense matrix (guard at 20,000 nodes), including `nwtoedge` and `nwsave`.
- Every help file ends with the package version (and a link to `nwversion`) instead of showing it at the top of four landing pages.
- `nwtopical` and `nwalphabetical` list `animate`, `nwcohesion` and `nwversion`, and a new section "Statistical models (separate packages)" (nwsaom, nwergm, nwdynam, nwrem) with web links and the `nwinstall, models` line.

## [3.1.1] - 2026-10-24
### Fixed
- The help text for the `s50` example data now describes it correctly: the 50-girl excerpt of the Teenage Friends and Lifestyle Study that is distributed as `s50` with RSiena (the same networks as the Glasgow data), not a university-freshmen panel.
- `nwinstall, remove` (and `gui`/`permanently` when a `profile.do` already exists) could delete the user's `profile.do` on Mac and Linux. The edit ran `shell ... PATH="...c(adopath)..."; mv ...`; `c(adopath)` contains quote characters once a directory was added with `adopath ++ "dir"`, the shell command became unbalanced, `mv` never ran, and the original had already been erased. The edit no longer uses the shell: the new content is written to a temporary file and verified, a backup is made, the file is replaced with Stata's `copy`, and on any failure the original is left untouched (or restored) with a message. Same code on Mac, Linux and Windows. `remove` also strips the `nwinstall, downloadoff` line, and `gui`/`permanently` append `nwinstall, usermenu` (the line `remove` looks for).
- `cscripts/test_nwinstall.do` covers this case (quoted adopath entry, path with spaces, content of the user's profile.do preserved, failing edit leaves the file untouched, `gui` equals `permanently`).

## [3.1.0] - 2026-10-24
### Added
- `nwinstall, gui` installs the "Network Analysis" menu and the dialog boxes (the older option `permanently` still works).
- `nwcommands` help topic lists the model packages and the license.
### Fixed
- Neighbor lists are returned in sorted order independent of earlier session state. `neighbors(i)`, `neighbors_in(i)` and `edgelist()` of a network built through `set_edge_from_triplets()` (`nwfromedge`, `nwset` from an edge list, `nw2project`, `nwattime`) now always list the nodes in ascending order; before, the order of tied sort keys varied with the session, which changed seeded results of MCMC-based commands.
### Changed
- License: nwcommands is now distributed under the GNU General Public License, version 3 (previously a use-only license). `LICENSE` is the GPL-3 text; `NOTICE.md` states the copyright.

## [3.0.0] - 2026-10-24
### Changed
- The model commands `nwsaom`, `nwergm`, `nwdynam` and `nwrem` are no longer part of this package. They are separate packages
  (GPL-3) in their own repositories. Install them with `nwinstall, models` (or `net install <name>`); updating `nwcommands`
  never overwrites them. **Scripts that call these commands need the model packages installed.** This is a breaking change, hence the new major version.
- The core Mata library `lnwcommands.mlib` contains only the core (717 KB instead of 1.7 MB).
- `lib/build.do`, `native/Makefile` and the CI workflow build only the core (`nwgraph`, `nwedit_viewer`).
### Added
- `nwinstall, models` (also `modelpkg()`, `release()`, `modelsfrom()`): install, update to a given release, or remove the
  four model packages.
- `nwversion`: shows the version of the core and of the installed model packages. Version files: `VERSION`,
  `tools/set_version.py`, `tools/check_version.py`, `CITATION.cff`, `RELEASING.md`.
### Fixed
- `_nwrowalign.ado`, which `nwset` needs, was missing from the package lists.
- Help topic pages mention the moved commands as "moved to its own package".

## [2.0.0] - 2026-08-25
Last release that contained the four model families (git tag `v2.0.0`; the final unsplit state is `pre-split-2026-10-24`).

## [1.x] - 2014-2015
The original releases (`v1.0.2-beta3` to `v1.6.3C`).
