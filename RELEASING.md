# Releasing nwcommands (core)

1. Decide the version (Semantic Versioning: MAJOR for incompatible changes, MINOR for new commands/options, PATCH for fixes).
2. `python3 tools/set_version.py <version> [<date, Stata format e.g. 24oct2026>]` writes the version into VERSION, `nwversion.ado`,
   the landing help pages, all package files, `stata.toc` and `CITATION.cff`.
3. Add an entry to `CHANGELOG.md` (the check fails without it).
4. Regenerate the package files if commands were added or removed (`_nwdeploy`), rebuild `lib/lnwcommands.mlib` (`lib/build.do`).
5. `python3 tools/check_version.py` and the core tests (`cscripts/`).
6. Commit ("Release X.Y.Z"), tag `vX.Y.Z` (annotated), push the branch and the tag, create the GitHub release
   (`gh release create vX.Y.Z --notes-file ...`).
Installing a given release: `net install nwcommands, from("https://raw.githubusercontent.com/thomas-u-grund/nwcommands/vX.Y.Z/") replace`.
