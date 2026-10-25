# Changelog

All notable changes to the nwcommands core package. The format follows [Keep a Changelog](https://keepachangelog.com/);
versions follow [Semantic Versioning](https://semver.org/). The model families have their own packages and changelogs
(`nwsaom`, `nwergm`, `nwdynam`, `nwrem`).

## [Unreleased]
### Fixed
- `nwfromedge` (and everything that builds a network from an edge list: `nwset ..., edgelist`, `nwimport ..., type(edgelist)`) now works at the scale the documentation promises. A directed network with 100,000 nodes and 1,000,000 ties builds in a few seconds in Stata/BE; before, it stopped with `r(920)` (macro substitution results in line that is too long) from about 40,000 nodes on, with the dense-matrix refusal `r(484)` at 25,000 nodes, and took 7 s at 10,000 nodes. Causes: (1) `_nwsyntax` exported every node label in one macro (`labs`) and `nwname` in `r(labs)`, which overflows Stata/BE's 264,408-character macro limit; both are now empty once the string would be longer than 200,000 characters (`_nwnodelab`/`_nwnodeid` read the labels from Mata); (2) `nwfromedge` built the label list with a Stata loop over a macro and checked for duplicate labels with an all-pairs comparison; labels now stay in Mata and the duplicate check sorts; (3) the automatic symmetric/directed detection and `nwsym` allocated the dense N x N matrix; `check_symmetry()` and `symmetrize()` now work on the sparse triplets when the dense matrix was never built; (4) `nwload`, `nwsync`, `nwname` (`get_missing_edges()`, `get_selfloops_number()`) touched the dense matrix or built a macro of all node names; (5) `get_modes_labeled_string()` built its result by repeated string concatenation (quadratic, 1.5 s per `nwname` call at 40,000 nodes).
- `nwcomponents` is no longer quadratic: the breadth-first search copied its queue on every step (27 s at 100,000 nodes / 1,000,000 ties, now 0.5 s).
- Duplicate rows (same ego and alter) in an edge list now give one tie, the last row given winning, in the stored sparse index too; before, the adjacency matrix had one tie but `nwdegree`/`nwclustering` counted the duplicate rows.
- Node labels of string identifiers that contain a space or a comma are kept as given (the old macro route split them into several labels and could drop a node's label).

- `nwtoedge, compress`, `nwsave`, `nwuse` and `nwappend` work for a single big network (tested to 100,000 nodes / 1,000,000 ties). `nwtoedge, compress` lists the stored ties instead of building the N x N list of dyads (new `get_edgelist_sparse()`; the output is identical, including the blanked diagonal). The isolates note it stores in the edge list (a Stata characteristic, 67,784 characters at most) falls back to the isolated nodes only when all node names do not fit. `nwsave` writes the mode list from Mata into a strL variable and `nwuse` reads it back through Mata (a macro of all modes was longer than Stata/BE allows from about 40,000 nodes), and `set_modes_from_labeled_string()` no longer scans the string character by character (28 s at 25,000 nodes, now under 1 s).
- `nwimport` of a `.dta` edge list passed `directed` on under a misspelled name, so it was ignored.
- Commands that took O(N^2) time and memory on the whole network now scale with the number of ties (Stata/BE, 10 ties per node, 1,000 nodes before -> after; larger sizes in the help files): `nwtoedge` (all dyads) 4.7 -> 0.5 s (the list is written straight into variables; refused above 50,000,000 rows with advice to use `compress`); `nwexport` (edge list, Pajek, UCINET, GML) 4.7 -> 0.1 s (from the sparse tie list, files written in blocks; 20,000 nodes 1.4 s, before out of memory); `nwtabulate` of one network 4.7 s -> 0.01 s (dyads counted, not listed); `nw2toedge` 8.3 s and 1.3 GB -> 0.7 s (only the dyads between the modes; `compress` uses the ties); `nwrecode` and `nwdichotomize` 16 s -> 0.03 s (recode of the distinct values, then of the stored ties); `nwkcomponents` 25 s -> 0.05 s (vertex-cut search in the native plugin, edge list built from the sparse index; 20,000 nodes 31 s); `nwplot, layout(kk)` 16 s -> 4 s (distances and stress iterations in the native plugin, bit-identical coordinates; 5,000 nodes 127 s -> 21 s); `nwplotmatrix` 16 s -> 5 s (box data built in Mata; no variable per column, so no 2,048-variable limit; refused above 2,500 nodes). `nwduplicate` copies a sparse-native network without building its matrix.
- `nwrecode` (and `nwdichotomize`, `generate()`/`prefix()`) gave the wrong matrix when the node labels were not in alphabetical order (default labels n1..n12 sort as n1, n10, n11, n12, n2, ...): the result was a permutation of the recoded matrix under the old labels. It also lost the values of self-loops, and rounded non-integer values to single precision. All three are fixed.
- `nwexport` to Pajek, UCINET and GML wrote the ties of one alter in an arbitrary order; they are now ordered by alter label, then ego label. `nwtabulate` no longer prints a stray "(N real changes made)" line.
- Native plugin `nwgraph` has two new kernels (vertex-connectivity search, Kamada-Kawai iterations). The macOS plugin is rebuilt; the Linux and Windows plugins must be rebuilt by CI before a release (the Makefile now compiles with -ffp-contract=off so the coordinates are bit-identical to the Mata code); without a plugin the Mata code runs, only slower.
### Changed
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
