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

### Changed
- Documentation (`README.md`, `help nwintro`) states the measured end-to-end times for `nwfromedge` and the sparse-native commands, and which commands still need the dense matrix (guard at 20,000 nodes), including `nwtoedge` and `nwsave`.

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
