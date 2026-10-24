# Changelog

All notable changes to the nwcommands core package. The format follows [Keep a Changelog](https://keepachangelog.com/);
versions follow [Semantic Versioning](https://semver.org/). The model families have their own packages and changelogs
(`nwsaom`, `nwergm`, `nwdynam`, `nwrem`).

## [Unreleased]
### Fixed
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
