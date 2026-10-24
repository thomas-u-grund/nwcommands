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

## After every release of any package: update the website

The website lives in this repository (`website/`) and covers all five packages, so a release of nwsaom, nwergm, nwdynam or nwrem also means a commit here:

1. `website/news.md`: add a dated entry at the top (version, one line from the CHANGELOG, link to the GitHub release).
2. Version numbers on the site: the packages table in `website/index.md`; the "Version" row of the package's `index.md`; the "For version X.Y.Z" tag example and the `<package> version` transcript in its `install.md`; the citation pages (`website/citing.md` and the package's `citation.md`); for a core release also `website/nwcommands/`; statements like "added in version X" in the package's pages.
3. Run the link check, commit on `develop`, `./promote.sh`, and confirm that the "Deploy documentation site" workflow succeeded.
4. nwsaom only: upload the rebuilt manual PDF as a new version of the Zenodo record (the all-versions DOI stays the same).
5. Announce user-visible releases on the nwcommands mailing list (announcements only).
