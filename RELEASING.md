# Releasing nwcommands (core)

1. Decide the version (Semantic Versioning: MAJOR for incompatible changes, MINOR for new commands/options, PATCH for fixes).
2. `python3 tools/set_version.py <version> [<date, Stata format e.g. 24oct2026>]` writes the version into VERSION, `nwversion.ado`,
   the version footer of every help file (last two lines, marker `{* nwversion}`), all package files, `stata.toc` and `CITATION.cff`.
3. Add an entry to `CHANGELOG.md` (the check fails without it).
4. Regenerate the package files if commands were added or removed (`_nwdeploy`), rebuild `lib/lnwcommands.mlib` (`lib/build.do`).
5. `python3 tools/check_version.py` (also runs `tools/check_help_index.py`: every command is in nwtopical and nwalphabetical) and the core tests (`cscripts/`).
6. Commit ("Release X.Y.Z"), tag `vX.Y.Z` (annotated), push the branch and the tag, create the GitHub release
   (`gh release create vX.Y.Z --notes-file ...`).
Installing a given release: `net install nwcommands, from("https://raw.githubusercontent.com/thomas-u-grund/nwcommands/vX.Y.Z/") replace`.

## Branches and the deploy sequence

- Work and commits happen on `develop` (in a worktree if the checked-out branch is something else).
- `main` is the release branch. Users install from it (`net from "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main"`), `nwwebuse` reads the example data from it, and the website is deployed from it. The four model packages (nwsaom, nwergm, nwdynam, nwrem) also use `main`.
- `master` is an exact copy of `main`. It is updated automatically by `.github/workflows/sync-master.yml` (fast-forward only). It exists so that every older install line and link in articles, books and tutorials keeps working. Do not commit to it.
- To release: on a clean `develop` run `./promote.sh` (add `--tag` to tag the version in `VERSION`). It checks the version consistency, merges `origin/develop` into `develop`, pushes `develop`, merges `develop` into `main` and pushes `main`. The sync workflow then updates `master` and the deploy workflow publishes the site.
- Order for a numbered release: 1. update `CHANGELOG.md` and run `python3 tools/set_version.py X.Y.Z [date]`; 2. run the tests; 3. commit on `develop`; 4. `./promote.sh --tag`; 5. `gh release create vX.Y.Z --title "nwcommands X.Y.Z" --notes-file <changelog excerpt>`.
- The CI plugin-rebuild bot commits to `develop` and `main` after pushes that touch `native/`; `git pull --rebase` before the next push.

## Build the Mata libraries with the oldest supported Stata

**Rule: build every Mata library (`.mlib`) with the OLDEST supported Stata, currently Stata 17, never with a newer one.** A library
compiled by a newer Stata is silently ignored by older Stata versions ("compiled by Stata 18.0, is too new to be run by this version of
Stata and so was ignored"), and then every function is "not found" (r(3499)); this broke a fresh install in Stata 17 after the
2026-10-25 releases. Stata 18 reads libraries built by Stata 17. The tested versions are 17 and 18 (older versions are untested); raise
the build version in the build guard only when support for Stata 17 is dropped on purpose.

- Build with `/Applications/Stata 17.0/StataBE.app/Contents/MacOS/StataBE -e do lib/build.do` (core: `lib/build.do` from the repository
  root; models: `NWCORE=<core> ... -e do lib/build.do`, see below). Run it in a scratch PLUS (see CLAUDE.md).
- Every `lib/build.do` has a build guard: it stops with a clear message when `c(stata_version)` is higher than 17. The environment
  variable `NW_ALLOW_NEWER_STATA=1` overrides it for experiments whose library is never released.
- Before a release run a command of the package in Stata 17 against the built library (the suites in `cscripts/` mostly load the
  Mata source with `do unw_core.do` and so do NOT test the library; use `tools/smoke_fresh_install.sh` with Stata 17, or a test that
  does not load the source).
- The core command `_nwlibcheck` (called from `unw_defs`) prints a clear message and exits 3499 when the library is missing or unusable.

## Whenever the core Mata library changes

The Mata libraries of nwsaom, nwergm, nwdynam and nwrem are compiled against `lib/lnwcommands.mlib` and must be rebuilt and released in
step with every core release that changes it (otherwise a fresh install fails with r(3021)). `lib/lnwcommands.mlib.release.sha256` holds
the sha256 of the library at the last release. `python3 tools/record_release_hash.py` writes it (`tools/set_version.py X.Y.Z` calls it, but
run it again after the final library build of step 4). `tools/check_version.py` prints a loud WARNING ("Mata library changed: rebuild and
re-release nwsaom and nwergm in step") when the library differs from the recorded hash; follow "Whenever the core library changes" in the
RELEASING.md of each model package, then record the new hash after the core release. All of these libraries are built with Stata 17 (see the rule above).

## Fresh-install smoke test

`tools/smoke_fresh_install.sh [core_dir model_parent_dir]` installs the core and the four model packages from local folders into an
empty PLUS directory (Stata `-e`) and then runs one real fit of each package in a new Stata process. Run it before a release of any
package (`SMOKE_STALE=1` additionally starts every fit session with a Mata library index that does not yet know the model libraries).

## After every release of any package: update the website

The website lives in this repository (`website/`) and covers all five packages, so a release of nwsaom, nwergm, nwdynam or nwrem also means a commit here:

1. `website/news.md`: add a dated entry at the top (version, one line from the CHANGELOG, link to the GitHub release).
2. Version numbers on the site: the packages table in `website/index.md`; the "Version" row of the package's `index.md`; the "For version X.Y.Z" tag example and the `<package> version` transcript in its `install.md`; the citation pages (`website/citing.md` and the package's `citation.md`); for a core release also `website/nwcommands/`; statements like "added in version X" in the package's pages.
3. Run the link check, commit on `develop`, `./promote.sh`, and confirm that the "Deploy documentation site" workflow succeeded.
4. nwsaom only: upload the rebuilt manual PDF as a new version of the Zenodo record (the all-versions DOI stays the same).
5. Announce user-visible releases on the nwcommands mailing list (announcements only).
