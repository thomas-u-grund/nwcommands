# Releasing the nwcommands packages (master document)

This is the ONE place for the release procedures and policies of all five packages: **nwcommands** (core), **nwsaom**, **nwergm**,
**nwdynam**, **nwrem**. The `RELEASING.md` of each model repository only holds the package-specific part and points here.
Everything below was checked against the repositories (state of `origin/main` on 2026-10-25: core 3.5.0, nwsaom 1.0.7, nwergm 1.2.0,
nwdynam 1.1.0, nwrem 1.0.5). Statements that could not be verified are marked **UNVERIFIED**; open decisions are marked **OPEN**.

Contents: A Where things live | B Standing policies | C Release procedures (C0 test launch, C1 core, C2 model package, C3 lockstep batch,
C4 patch or minor, C5 website, C6 Zenodo and manuals, C7 book, C8 fresh-install smoke test, C9 when something is wrong after a release,
C10 the preflight script) | D Checklists | E Known traps | F Index of related documents.

---

## A. Where things live

### A.1 Repositories, branches, clones

| Package | GitHub repository | Release branch | Work branch | Local clone (released state) |
|---|---|---|---|---|
| nwcommands (core) | `thomas-u-grund/nwcommands` | `main` (`master` = automatic copy) | `develop` | `/Users/tgrund/FILES_NEW/SOFTWARE/nwcommands_main` (on `main`; can lag `origin/main`: `git fetch` first) |
| nwsaom | `thomas-u-grund/nwsaom` | `main` | feature/release branches, merged into `main` | `/Users/tgrund/FILES_NEW/SOFTWARE/nwsaom` |
| nwergm | `thomas-u-grund/nwergm` | `main` | same | `/Users/tgrund/FILES_NEW/SOFTWARE/nwergm` |
| nwdynam | `thomas-u-grund/nwdynam` | `main` | same | `/Users/tgrund/FILES_NEW/SOFTWARE/nwdynam` |
| nwrem | `thomas-u-grund/nwrem` | `main` | same | `/Users/tgrund/FILES_NEW/SOFTWARE/nwrem` |

- The checkout `/Users/tgrund/FILES_NEW/SOFTWARE/nwcommands` is on the old task branch `website-docs` (far behind `develop`). Do not edit there. It
  holds the private `CLAUDE.md` (gitignored) and the shared `docs/` folder (gitignored, internal notes, never published).
- All edits happen in **git worktrees** (`git worktree prune`, then `git worktree add <dir> <branch>`), never in the clones' working trees.
  Scratch worktrees (`..._rel102`, `..._ver`, `...hotfix17` and so on) are temporary; check `git worktree list` before assuming one exists.
- The model packages depend only on the core, never on each other; the core never depends on them. Each model package says which core it
  needs (`d Requires nwcommands (core), version X.Y.Z or later` in `<pkg>.pkg`, and in `README.md`); it is raised only when the package needs it
  (on 2026-10-25 all four said 3.4.0 although the core was 3.5.0).

### A.2 CI workflows (GitHub Actions)

| Repo | Workflow file | Name | What it does |
|---|---|---|---|
| core | `.github/workflows/build-plugins.yml` | Build native plugins | On a push to `develop`/`main`/`master` that touches `native/**`: builds macOS (universal), Windows and Linux binaries of `nwgraph` and `nwedit_viewer`; on `develop` only it then commits them to `lib/plugins/{macos,unix,windows}/` as `github-actions[bot]` with the message `ci: rebuild native plugins [skip ci]` |
| core | `.github/workflows/sync-master.yml` | Keep master in sync with main | On a push to `main`: fast-forwards `master` to `main` (stops with an error if `master` has commits that `main` lacks) |
| core | `.github/workflows/deploy-site.yml` | Deploy documentation site | On a push to `main` that touches `website/**`: builds the Jekyll site and publishes it (nwcommands.org) |
| nwsaom, nwergm, nwdynam | `.github/workflows/build-plugins.yml` | Build native plugins | Same idea for `saom_sim` / `ergm_mcmc` / `dynam_sim`; these repos use `main` only, so the bot commits to **`main`** (and `develop`, `master` if such branches exist) |
| nwrem | none | none | nwrem has no native code and no workflow |

Only the macOS binary can be built locally (`make -C native macos`); the Linux and Windows binaries exist only after the CI run.

### A.3 Other places

- Website: `website/` of the core repo (Jekyll, theme "Just the Docs", domain nwcommands.org, deployed from `main`). It covers all five packages.
  Reference pages of the core are generated from the help files by `website/tools/sthlp_to_markdown.py` (see C5).
- Example data: `data/` of the core; `nwwebuse` downloads from GitHub `main` (not from a tag, not from `develop`).
- Manuals and articles (not git repos; make a backup copy before big edits): `/Users/tgrund/FILES_NEW/RESEARCH/2026 nwsaom/` (Stata Journal article
  `paper/main.tex`, nwsaom manual copy). The nwsaom manual sources are also in the nwsaom repo, `manual/` (PDF `manual/nwsaom_manual.pdf`). The nwergm manual is on the
  unmerged local branches `manual`, `manual2`, `manual3` of the nwergm clone (not on `origin/main`).
- Book (not in git): `/Users/tgrund/FILES_NEW/RESEARCH/2026 Book StataPress/` (`manuscript/`, `tools/`, see C7).
- Handoff notes (not in git): `/Users/tgrund/FILES_NEW/RESEARCH/2026 nwsaom/project_state_2026-10-24/` (`STATUS_2026-10-25.md`, `INSTRUCTIONS.md`, `INDEX_RELEASE_DOCS.md`).
- Zenodo: only the nwsaom manual has a record (all-versions DOI `10.5281/zenodo.23623807`). No other package has one yet.
- Mailing list: Google Group `nwcommands@googlegroups.com` (announcements only). GitHub Discussions are enabled on all five repos.
- Private owner files: `CLAUDE.md` of the core checkout and the memory notes under `~/.claude/projects/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/memory/`.
  They hold the owner's standing rules; section B is the public, complete version of those rules.

---

## B. Standing policies

### B.1 Public actions need the owner's go
Pushing, tagging, creating GitHub releases, changing GitHub settings (visibility, Pages, Discussions, branch policies), posting to the mailing
list, filing issues on other projects and uploading to Zenodo are public actions. Do them only when the owner asked for them in this task.
Never force-push. Never rewrite published history. Never move or delete a published tag. Never make a repo public or private unasked.
Preparing everything locally (commits on branches, notes, checklists) is always fine.

### B.2 Commit messages
Plain commit messages. No `Co-Authored-By` trailer, no `Claude-Session` link, no "generated with" line, in commits or pull requests (owner's instruction of
2026-10-24; this overrides any tool default that asks for such lines). AI assistance is disclosed deliberately in `NOTICE.md`, the article, the manuals and the
website, not in the git history. Existing commits keep their trailers; rewriting them would need a force-push (do not).
Release commit message: `Release X.Y.Z` (optionally followed by a short summary).

### B.3 Branches
- Core: commit on **`develop`**. Release by merging `develop` into `main`. `master` follows `main` through the sync workflow; never commit to it.
  Before the first edit of a session: `git branch --show-current` and `git log --oneline HEAD..develop | wc -l`; if you are not on `develop` and `develop` is ahead, use a worktree
  (the stale `website-docs` checkout cost a whole session on 2026-10-21).
- Models: `main` only. Feature work on branches in worktrees (`ordfix`, `fix2`, `release-X.Y.Z`), merged into `main`; the release commit is on `main`.
- A worktree cannot check out a branch that is checked out elsewhere. `main` is checked out in the clones, so a worktree needs a temporary local branch name (see C1 step 11).
- Docs under `docs/` are gitignored and describe `develop`; if they name something your checkout lacks, you are on the wrong branch.

### B.4 Versioning
- Semantic versioning MAJOR.MINOR.PATCH. MAJOR: incompatible syntax or results. MINOR: new commands, options, terms or features that keep old do-files working
  (the owner has also used MINOR for releases that fix wrong results, e.g. core 3.4.0 and 3.5.0; the CHANGELOG block "Results that change" then comes first).
  PATCH: bug fixes and lockstep rebuilds (see C4).
- Single source of truth: the file `VERSION` (line 1 version, line 2 release date in Stata format, e.g. `25oct2026`).
- Core: `python3 tools/set_version.py X.Y.Z [date]` writes `VERSION`, `nwversion.ado` (constants and first line), the footer of every help file (last lines, marker `{* nwversion}`),
  the header line of the landing help files, all `nwcommands*.pkg` (Distribution-Date, Version), `stata.toc`, `README.md` and `CITATION.cff`; with a version argument it also runs
  `tools/record_release_hash.py`. `python3 tools/check_version.py` verifies all of it, needs the CHANGELOG entry `## [X.Y.Z]`, runs `tools/check_help_index.py`, and prints a
  loud WARNING when the Mata library differs from the recorded release hash.
- Models: `python3 tools/set_version.py X.Y.Z [date]` (also `--check`) updates `VERSION`, first line of every `.ado`, help headers and footers, `<pkg>.pkg`, `stata.toc`, `README.md`, `NOTICE.md`,
  `CITATION.cff`, `e(version)`/`<pkg> version` literals and (nwsaom) the manual's `\pkgversion`. `python3 tools/check_version.py` = `--check` plus, when `NWCORE` is set, the core-library hash check (B.5).
- Never edit generated files by hand: `nwcommands*.pkg`, `stata.toc`, `nwcommands.sthlp` are regenerated from `_pkg_ado.txt`, `_pkg_hlp.txt`, `_pkg_boot.txt` (GOTCHA.md); `.dlg` files of the models are generated.
- CHANGELOG format (Keep a Changelog): `## [X.Y.Z] - YYYY-MM-DD` with Added / Changed / Fixed / Removed. A release that changes results of existing commands starts with
  `### Results that change (read before you re-run old analyses)`. The check fails without the entry. The GitHub release notes are this entry.
- The core's version is in `VERSION`; do not state a "current release" anywhere else by hand except through the website checklist (C5).

### B.5 Lockstep rule and the Mata library hash checks
- The Mata libraries `lib/lnwsaom1.mlib`, `lib/lnwsaom2.mlib` (nwsaom) and `lib/lnwergm.mlib` (nwergm) are compiled against the core library `lib/lnwcommands.mlib` and **contain
  the core class `nw_def`** (their `lib/build.do` needs `NWCORE`). A Mata class carries the time it was compiled, so a rebuilt core library makes old model libraries fail on a fresh
  install with r(3021) "class compiled at different times" (or r(3260)). Core 3.2.0 broke the released models this way on 2026-10-25.
- Every rebuild of a library produces different bytes (class compile time), so the hash changes with every rebuild, not only with source changes. **Rebuild the core library only when `unw_core.do`
  (or another `unw_*.do`) changed.** Do not run `deploy.sh`, not even `--check-only` (its step 1 rebuilds the library, with the hard-coded Stata 18 path, see E.15).
- Owner's decision 2026-10-25: the core Mata library MAY change when it gives real benefit (speed, correctness). The cost is only a **lockstep release**: the models are rebuilt against the new
  core library and released in the same batch (C3). Do not avoid a library change just to dodge this; batch such changes. (An earlier, stricter rule "keep the library byte-identical" and the idea of
  a plain-data API between core and models were dropped; the API idea was rejected as too risky.)
- Core: `lib/lnwcommands.mlib.release.sha256` holds the sha256 at the last release; `tools/record_release_hash.py` writes it (`set_version.py X.Y.Z` calls it; run it again after any later rebuild).
  `tools/check_version.py` warns "Mata library changed: rebuild and re-release nwsaom and nwergm in step" when the library differs.
- Models (all four): `lib/core_mlib.sha256` holds the sha256 of the core library the package was built against (`NWCORE=<core> python3 tools/record_core_lib.py`, run right after `lib/build.do`).
  `NWCORE=<core> python3 tools/check_version.py` fails with "the core Mata library changed since this package's libraries were built" when it differs (it is also the first step of `cscripts/run_tests.sh` when `NWCORE` is set).
- **nwdynam and nwrem (what is true):** their `unw_dynam.do` / `unw_rem.do` contain no reference to `nw_def`, and their `lib/build.do` does not load the core ("the core is not loaded while compiling"),
  so the r(3021) class mismatch cannot come from their libraries. They still carry `lib/core_mlib.sha256` and `check_version.py` still fails on a mismatch. `nwdynam.ado` calls methods of core class objects
  from Mata blocks that are compiled when the ado file loads (e.g. `get_nodes_mode1()`), which uses the installed core. Whether a changed core library can break them in any other way is **UNVERIFIED**.
  Practice so far (core 3.4.0, 3.5.0): rebuild and re-release all four. Minimal alternative if the owner agrees (**OPEN**): run `record_core_lib.py` for nwdynam/nwrem after testing them against the new core, without a new release.
- A core release that does not change the library (ado-only) needs nothing from the models.

### B.6 Build the Mata libraries with the oldest supported Stata (Stata 17)
The owner has Stata 17 BE (`/Applications/Stata 17.0/StataBE.app/Contents/MacOS/StataBE`) and Stata 18 BE (`/Applications/Stata/StataBE.app/Contents/MacOS/StataBE`). Only 17 and 18 are tested; do not claim older versions.
**Build every `.mlib` (`lnwcommands`, `lnwsaom1`, `lnwsaom2`, `lnwergm`, `lnwdynam`, `lnwrem`) with Stata 17, never with 18**: a library built by Stata 18 is silently ignored by Stata 17 (`nws_create() not found`, r(3499)). This broke every
release of 2026-10-25 for Stata 17 users (core 3.5.0 and the four models); the fix is a lockstep patch release (the 3.5.1 hotfix, in preparation when this was written; it adds a build guard to `lib/build.do` that stops when the Stata
version is above 17, with `NW_ALLOW_NEWER_STATA=1` as an override for experiments; **UNVERIFIED** until it is on `main`). Run the test suites and the smoke test (C8) under BOTH 17 and 18 before a release. The C plugins do not depend on the Stata version
but must also be exercised under 17.

### B.7 Native plugins: generations and kernel codes
- Core plugin `nwgraph`: `native/nwcomb.h` defines `NWCOMB_VERSION` (the "generation"; 8 at core 3.5.0) and publishes it as the scalar `__nwg_ver` on a probe call (algorithm code 100). The Mata dispatcher `nwg_comb_ok()` / `nwg_comb_version()` in `unw_core.do` use the kernels only when the
  platform's binary reports a generation that is high enough, and keep the older (slow) Mata code otherwise: for example `nwg_comb_version() >= 3` for triad balance and bipartite matching, `>= 4` for Louvain, `>= 5` for distance sums. **A new kernel therefore needs:** a new code outside every existing range
  (3-9, 22-31, 34-39 and 99-100 are combinatorial kernels, 20 = vertex connectivity, 21 = Kamada-Kawai; use 40 and up), a raised `NWCOMB_VERSION`, the gate in the Mata/ado caller, and a CI build before release so that Linux and Windows have it.
  Locally built macOS binaries are committed by hand; the Linux and Windows binaries exist only after CI.
- Model plugins: `saom_sim` has a protocol number (`SAOM_NATIVE_VERSION`, scalar `__saom_native_version`); new nwsaom effects are native-only and stop with "needs the native plugin (protocol N or later)" instead of falling back to Mata.
  `ergm_mcmc` and `dynam_sim` have their own natives; the nwergm operator terms run in the plugin only, so a changed plugin has to be rebuilt for every platform.
- Plugin protocol numbers and kernel codes are internal: they never appear in user-facing text (B.12).
- Native over Mata: new model code goes into the C plugin; no slow Mata fallback for new effects. The existing Mata engines stay as the reference implementation. (Relaxation of 2026-10-25: the core Mata library itself may change, see B.5.)
- Never `cp` a rebuilt plugin over one a running Stata has loaded (macOS kills Stata with "Code Signature Invalid"): `rm` first.

### B.8 Match R as closely as possible
Rule 0 for nwsaom (RSiena), nwergm (statnet ergm), and the others (nwdynam: goldfish; nwrem: Butts 2008, cross-checked with relevent): terms and effects, features, defaults, numbers, output and error behaviour follow the R original; deliberate deviations are documented. Target for nwergm: 90% or more of ergm's terms and features.
New work is validated against the R package. Put this rule at the top of every agent brief.

### B.9 Data licence rule
Example data live in `data/`. Every data set needs: source and citation; its licence statement if it has one (e.g. "licensed under CC BY 4.0": say so, with the DOI/URL, and attribute); if the source has **no** licence statement, write that no licence is asserted: "they are facts, not covered by the GPL-3 of this package, and are
redistributed with citation of the source". Where to record a new data set: `data/<name>.nwdta`, `NOTICE.md` ("Data sets"), `netexample.sthlp` and `website/reference/netexample.md`, `website/datasets.md`, `README.md` if it lists data, `CHANGELOG.md`, and a test (`cscripts/test_signed_data.do` is the pattern). `nwwebuse` can only be tested for a new data set after the push to GitHub `main` (E.4).

### B.10 Manual versioning and Zenodo
The owner finds a Zenodo upload for every patch weird (2026-10-25). A manual is labelled by the minor series ("Manual for version 1.2", valid for 1.2.x). Upload a new Zenodo version only for a new minor or major release whose documented behaviour changed (new features, terms, chapters, changed
defaults, e.g. nwergm 1.2.0 with R's MCMC defaults). Never for patch releases or lockstep rebuilds. Cite the manual by the all-versions DOI plus the exact package version printed by `<package> version`. The nwsaom manual on Zenodo (concept DOI 10.5281/zenodo.23623807) says "Manual for version 1.0.3" and stays until nwsaom 1.1.0.
**Decision 2026-10-25:** at the next nwsaom manual update (nwsaom 1.1.0) retitle it "Manual for version 1.1", upload ONE new Zenodo version, and fix the citation texts that say "Manual for version 1.0.3" (website `citing.md`, `nwsaom/citation.md`, `literature.md`, nwsaom `README`/`NOTICE`/`CITATION.cff`, the article, the book bib entry). The other packages are cited by repository and version.
The nwergm manual (97 pages) waits for its own Zenodo record (website "Manual" menu entries for nwergm/nwdynam/nwrem are added only when a manual exists; a dead link is worse than no entry). nwdynam and nwrem have no manual.

### B.11 nwsaom effect counts and the effects inventory
Effect counts quoted for nwsaom must name the RSiena version they come from: **1.6.6** for the 1,201 / 1,121 rows (1.6.6 is the CRAN version; the reference for numerical behaviour is now 1.6.14, and numbers can silently differ). After each new nwsaom effect: add an entry to `UPDATES` in `docs/inventory_tools/update_inventory.py`,
run it (regenerates `docs/SAOM_EFFECTS_INVENTORY.md/.csv`), tick `docs/SAOM_EFFECTS_TODO.md`. `manual/build_effects.py` generates the manual's effect tables from the inventory CSV and must scrub internal notes.

### B.12 No internal references in user-facing text
Manual, help files, website, article and book never cite internal files (DECISIONS, GOTCHA, the inventory, any `.md` of the repos), plugin protocol numbers, kernel codes, "the developer's log" or verification notes ("checked for this manual"). State the behaviour and its reason in user terms; history goes into `docs/` (gitignored).
The syntax rule for nwsaom: a property of the data (two-mode, non-directed) is detected; a model or fit choice is an option; a different job is a subcommand or `estat`. The free website tutorials for ERGM/SAOM/REM/DNAM stay conceptual with a minimal example and a pointer to the forthcoming book (do not undercut it).

### B.13 Licence and attribution
All five packages are GPL-3; Thomas U. Grund is the sole author of nwcommands (and may license it separately); do not say redistribution needs permission. Affiliation in CITATION files: RWTH Aachen University. AI assistance is disclosed in `NOTICE.md`, article, manual and website. Credit third parties properly (RSiena/Siena, multiSiena, ergm, goldfish, relevent, Nick Cox's tabplot behind `_nwtabplot`).

### B.14 ROADMAP.md and ARCHITECTURE.md
The core root has public, curated, short `ROADMAP.md` and `ARCHITECTURE.md`; the detailed internal versions are in `docs/`. When a change touches roadmap direction (feature added, completed, re-prioritised) or architecture (native-plugin / Mata / sparse-backend structure, which packages exist), update the internal `docs/` file AND check whether the root files need a matching update.

### B.15 Running Stata (see C0 for the launch wrapper)
`-e`, never `-b`; never `pkill`/`killall` Stata; never run `nwinstall` with `gui`, `permanently` or `remove` against the real profile (use `path("<scratch dir>")`); a test with no log counts as NOT RUN; at most two or three Stata processes at a time on the shared machine; no slow empirical checks
when a static answer from the code is enough.

---

## C. Release procedures

### C0. The test launch (used by every test run)
Why each part: the owner's `profile.do` loads a stale `nwinstall` (hence `capture program drop nwinstall`); a stale plugin in the real PLUS shadows the repo build (hence an empty scratch PLUS and the repo plugin first on the adopath); core tests use relative paths (`do unw_core.do`, `nwuse data/...`),
so the do-file must `cd` to the repo root; Stata `-e` writes the log into the directory named by the environment variable `PWD` (the directory you start from, not the one you `cd` to inside Stata), so start Stata from a scratch directory per test; macOS has no `timeout`.

Core test, one file (this is the wrapper that was used for the 3.3.x to 3.5.0 suites; adjust `W` and `STATA`):

    S=<scratch dir>; W=<core worktree>; OUT=$S/suite; STATA="/Applications/Stata 17.0/StataBE.app/Contents/MacOS/StataBE"   # then repeat with Stata 18
    mkdir -p $OUT/plus $OUT/logs
    t=$W/cscripts/test_xxx.do; b=${t:t:r}; d=$OUT/work_$b; mkdir -p $d
    printf 'capture program drop nwinstall\nsysdir set PLUS "%s/plus"\nadopath ++ "%s"\nadopath ++ "%s/lib"\nadopath ++ "%s/lib/plugins/macos"\ncd "%s"\ndo "%s"\n' $OUT $W $W $W $W $t > $d/run.do
    (cd $d && perl -e 'alarm 1500; exec @ARGV' "$STATA" -e do run.do >/dev/null 2>&1 </dev/null)
    cp $d/run.log $OUT/logs/$b.log                      # no log or an empty log = NOT RUN, never "passed"
    grep -E '^r\([0-9]+\);' $OUT/logs/$b.log | head -1  # an r() error = FAIL; no error = "no error" (most older tests print no PASS marker)

Full core suite: loop over `$W/cscripts/test_*.do`, skip `test_external_links.do` (it needs the internet and is not part of the "0 errors" bar), two files at a time, and write one summary line per test (`name | pass-lines=N | no-error` or the first `r()` line, or `NOT RUN`).
At the 3.5.0 release the suite was about 177 files. The core repo has no checked-in runner (**the wrapper above lives only in session scratch directories**; **OPEN:** check a runner into `tools/`).

Model packages have a checked-in runner: `NWCORE=<core dir> cscripts/run_tests.sh [quick|full for nwsaom] [plugin_dir] [jobs]` (nwsaom: `quick|full [plugin_dir] [jobs]`; nwergm, nwdynam, nwrem: `[jobs]`). It runs `tools/check_version.py` first, runs every test in its own `-e` process, and prints `PASS lines` and `errors` per test.
`NWCORE` must be the core checkout whose `lib/lnwcommands.mlib` is the final one. Note the runner uses the Stata path `/Applications/Stata/StataBE.app/...` unless you set `STATA`; set `STATA` to the Stata 17 binary for the first pass. Models' tests find the core through `adopath ++ NWCORE`; to test a freshly built model plugin pass `plugin_dir`
(nwsaom) or put the plugin on the adopath in a scratch copy. A repo copy with its own `lib/plugins/` shadows a scratch plugin (E.2).

### C1. Core release (nwcommands), step by step
Preconditions: owner has said to release; nothing is pushed or tagged before step 9. Assume version `X.Y.Z`, worktree `W` of `develop`.

1. **Worktree of develop.** `git -C /Users/tgrund/FILES_NEW/SOFTWARE/nwcommands_main fetch origin` and `git -C <clone> worktree add <W> develop` (create a local `develop` from `origin/develop` if needed: `git worktree add -b develop <W> origin/develop`). Merge the finished feature branches with `git merge --no-ff` ("Merge ordfix" style).
2. **Decide the version** (B.4, C4). If `native/` changed, a new plugin generation may be needed (B.7); if `unw_core.do` changed, this is a lockstep batch: read C3 first.
3. **Library (only if a `unw_*.do` source changed):** `cd <W>; "/Applications/Stata 17.0/StataBE.app/Contents/MacOS/StataBE" -e do lib/build.do` from the repository root (B.6; `lib/build.do` stops if `unw_core.do` is not in the current directory). Do not rebuild otherwise.
4. **CHANGELOG** entry `## [X.Y.Z] - YYYY-MM-DD` (with "Results that change" first when results of existing commands change). Help files and dialogs of changed commands, data-set registrations (B.9), `README.md`, and ROADMAP/ARCHITECTURE (B.14) are part of the same release. If commands were added or removed: edit `_pkg_ado.txt` / `_pkg_hlp.txt` / `_pkg_boot.txt` and regenerate the manifests through `_nwdeploy` (never by hand; never `deploy.sh`, E.15).
5. **Versions:** `python3 tools/set_version.py X.Y.Z [date]` (also records the library hash: do this AFTER step 3). Then `python3 tools/check_version.py`.
6. **Tests** (C0): the full core suite with Stata 17 and Stata 18; plugin from `lib/plugins/macos`. Zero `r()` errors, zero NOT RUN. Plus `cscripts/test_xxx.do` for new work.
7. **Website** (C5) in the same series of commits on `develop`: news, versions, citation pages, data sets. Commit `Release X.Y.Z: ...` (B.2).
8. **Preflight:** `python3 tools/release_preflight.py` (C10). Fix every FAIL. (If you are not on the branch it expects, or have not pushed, read the message.)
9. **Push develop** (public action): `git push origin develop`. If `native/` changed, the workflow "Build native plugins" runs (`gh run list --repo thomas-u-grund/nwcommands --limit 3`, `gh run watch <id>`). When it is green it adds the commit `ci: rebuild native plugins [skip ci]` on `develop`; `git pull --rebase origin develop` (or `git pull --ff-only` if you have nothing new). Never push over the bot commit.
10. **Key tests with the CI-built macOS plugin.** The CI-built macOS binary is not byte-identical to the local build (E.7). Re-run the plugin-dependent tests (`test_fastkernels`, `test_brokerage_kernels`, `test_combinatorial_scale`, `test_k2`, `test_matafast`, plus everything you changed) and the smoke test (C8) on the pulled commit. Preflight again with `--require-pushed`.
11. **Promote `develop` to `main`.** `./promote.sh --tag` does everything (checks versions, merges `origin/develop`, pushes `develop`, merges `develop` into `main`, pushes `main`, tags `vX.Y.Z` and pushes the tag), but **it fails when `main` is checked out in another worktree**
    (its `git switch -C main origin/main` is refused: "'main' is already used by worktree at .../nwcommands_main", verified). In that case do by hand, on a clean `develop` worktree, with a temporary branch name:

        git fetch origin && git merge --no-edit origin/develop && git push origin develop      # nothing to merge if already pushed
        tmp=$(mktemp -d) && git worktree add --detach "$tmp" origin/main
        (cd "$tmp" && git switch -C promote-tmp origin/main && git merge --no-ff -m "Merge develop into main" develop && git push origin promote-tmp:main)
        # conflicts only in lib/plugins/* (binaries rebuilt by the bot): git checkout --theirs -- <file>; git add <file>; git commit; any other conflict: stop
        git worktree remove --force "$tmp" && git branch -D promote-tmp

    Then `sync-master.yml` fast-forwards `master`, and `deploy-site.yml` publishes the website when `website/` changed.
12. **Tag** (on the `develop` tip, as `promote.sh` does; the tag is then contained in `main`): first `git tag -l vX.Y.Z` must be empty (E.3), then `git tag -a vX.Y.Z -m "nwcommands vX.Y.Z"` and `git push origin vX.Y.Z` (this one tag only, never `--tags`).
13. **GitHub release:** `awk -v v=X.Y.Z '$0 ~ "^## \\[" v "\\]" {f=1; next} /^## \[/ {f=0} f' CHANGELOG.md > notes.md` then `gh release create vX.Y.Z --title "nwcommands X.Y.Z" --notes-file notes.md --repo thomas-u-grund/nwcommands` (the notes are the CHANGELOG entry, "Results that change" first).
14. **Deploy check:** `gh run list --repo thomas-u-grund/nwcommands --limit 5`: "Deploy documentation site" and "Keep master in sync with main" succeeded; `git ls-remote origin refs/heads/master refs/heads/main` shows the same commit; open https://nwcommands.org/news/ . Run the link check on `website/` (C5).
15. **Post-release:** `python3 tools/release_preflight.py --post`; fresh-install smoke test from GitHub (C8); book harness (C7); mailing-list announcement if user-visible (owner posts); update the clone `nwcommands_main` (`git pull --ff-only`, owner's working tree) so that it can serve as `NWCORE`.

### C2. Model package release (nwsaom, nwergm, nwdynam, nwrem)
The package-specific facts are in each repo's `RELEASING.md`. Steps (all four packages are alike; nwrem has no plugin and no workflow):

1. **Branch in a worktree:** `git -C <clone> worktree add <dir> -b release-X.Y.Z main`; merge the finished feature branches (`git merge --no-ff`, "Merge ordfix" style).
2. **Core requirement:** if this release needs a newer core, raise `d Requires nwcommands (core), version A.B.C or later` in `<pkg>.pkg` and the statement in `README.md`. Otherwise leave it.
3. **Library:** only if `unw_<pkg>.do` changed or the core library changed (lockstep, C3): `NWCORE=<core> "/Applications/Stata 17.0/StataBE.app/Contents/MacOS/StataBE" -e do lib/build.do` from the repo root (nwdynam, nwrem: no `NWCORE` needed); then `NWCORE=<core> python3 tools/record_core_lib.py`.
4. **CHANGELOG** `## [X.Y.Z] - YYYY-MM-DD`, then `python3 tools/set_version.py X.Y.Z [date]`, then `NWCORE=<core> python3 tools/check_version.py`.
5. **Tests:** `NWCORE=<core> cscripts/run_tests.sh ...` (C0) under Stata 17 and 18. nwsaom: `quick` after every change, `full` (including the RSiena regression tests, 35 minutes serial) before a MINOR or lockstep release. nwergm: also keep the R-validation notes (`docs/VALIDATED_AGAINST_R.md`) current when terms change.
6. **Commit** `Release X.Y.Z` on `release-X.Y.Z`. Check `git tag -l vX.Y.Z` (legacy tags, E.3).
7. **Publish** (public actions): `git push origin release-X.Y.Z:main` (fast-forward onto `main`, the branch name trick of C1 step 11). If `native/` changed, "Build native plugins" runs and the bot commits to **`main`**: wait, then `git pull --rebase`; **tag after the bot commit** (nwdynam v1.1.0 sits on the bot commit). Then `git tag -a vX.Y.Z -m "<pkg> X.Y.Z"` and `git push origin vX.Y.Z` (the one tag; **never `git push origin main --tags`**: nwergm, nwsaom, nwdynam hold old local tags that never existed on GitHub, E.3).
8. **GitHub release:** `gh release create vX.Y.Z --title "<pkg> X.Y.Z" --notes-file <CHANGELOG excerpt> --repo thomas-u-grund/<pkg>`.
9. **Website, Zenodo, smoke test, book:** C5, C6, C8, C7. Install lines: `net install <pkg>, from(https://raw.githubusercontent.com/thomas-u-grund/<pkg>/main/) replace`; a given release `.../<pkg>/vX.Y.Z/`.

### C3. Lockstep batch (the core Mata library changes)
Order, as run for 3.3.0, 3.4.0, 3.5.0:
1. Finish all core library and code changes on `develop`. Rebuild `lib/lnwcommands.mlib` ONCE, with Stata 17 (B.6). Push `develop`; if `native/` changed wait for the CI plugin commit and pull. This is now the **final** core state: any later rebuild invalidates everything below.
2. For nwsaom and nwergm (mandatory) and nwdynam and nwrem (practice, B.5): in each repo, `NWCORE=<core worktree> <Stata 17> -e do lib/build.do`, then `NWCORE=<core> python3 tools/record_core_lib.py`. Do not edit libraries in the core after this point.
3. Raise `Requires nwcommands (core), version X.Y.Z or later` in `<pkg>.pkg` and `README.md` (the new core version, since an old core with the new model library fails).
4. CHANGELOGs ("Rebuilt for nwcommands X.Y.Z; requires core X.Y.Z or later" is the wording used), `set_version.py` in every repo, `NWCORE=<core> check_version.py` in every repo, `python3 tools/record_release_hash.py` in the core after the final library.
5. Test all five packages under Stata 17 and 18 (C0), key tests with the CI-built plugin, and `tools/smoke_fresh_install.sh` (with `SMOKE_STALE=1` as well) (C8).
6. Website commit for all five (C5). Preflight (C10) with `--models-parent` pointing at the model worktrees.
7. **Release the core first**, then the models (the models require the new core). Between the core release and the model releases the installed models of users break: do the models immediately.
8. Afterwards: smoke test from GitHub, book harness, announcement.

### C4. Patch or minor?
- PATCH: bug fixes, help or website text, lockstep rebuilds ("Rebuilt for nwcommands X.Y.Z"), no new documented behaviour. No Zenodo upload.
- MINOR: new commands, options, terms, effects, kernels, data sets, or changed defaults; a release that fixes wrong results of existing commands is announced with the "Results that change" block (the owner has used MINOR for these). A new minor of a package with a manual: the manual is updated and re-labelled (B.10).
- MAJOR: incompatible syntax or results (core 3.0.0 split the models off).
- A core PATCH that rebuilds the library is still a lockstep batch (C3), and the models get a PATCH too.

### C5. Website update checklist (after EVERY release of any of the five packages)
On `develop` of the core, then promote (C1 step 11 without a tag). Done before the tag for coordinated releases (3.4.0 and 3.5.0: one commit "Release X.Y.Z: version, changelog date, website versions and news for the five packages").
1. `website/news.md`: new dated entry at the top: package(s) and version(s), one line each from the CHANGELOG, link `https://github.com/thomas-u-grund/<pkg>/releases/tag/vX.Y.Z`.
2. Version numbers: packages table in `website/index.md` (`| 3.5.0 |`); core: `website/nwcommands/index.md` (two places: "version X.Y.Z" in the intro and "The core is version X.Y.Z (D Month YYYY)" in the status line; **the status line shows the literal placeholder "DD October 2026" on `main` at 3.5.0, fix it with the real date**),
   `website/nwcommands/install.md` ("for example `.../nwcommands/vX.Y.Z/`"), `website/citing.md` (`(version X.Y.Z)`); model: `website/<pkg>/index.md` ("Version" row), `website/<pkg>/install.md` ("For version X.Y.Z" tag example and the `<pkg> version` transcript with its date), `website/<pkg>/citation.md`, `website/citing.md`; statements like "added in version X" in the package's pages; reference pages when commands or options changed.
3. Data sets: `website/datasets.md` and `website/reference/netexample.md` for new data (B.9).
4. Reference pages of the core: `python3 website/tools/sthlp_to_markdown.py <core dir> <out dir>` writes `<out dir>/reference/*.md` and an `index.md` from the `.sthlp` files; copy the changed pages into `website/reference/` and review the diff (the converter drops SMCL markup). The reference pages `nwsaom.md`, `nwergm.md` (and the dynam/rem stubs) in `website/reference/` are separate hand-curated stubs (`nav_exclude: true`); how
   the nwsaom page was last regenerated from `nwsaom.sthlp` is not recorded in the repo (**UNVERIFIED**: the converter reads `*.sthlp` of a directory, so it can be pointed at a model repo and the result merged by hand).
5. Tutorials/book companion pages that show output: regenerate against the release candidate when output changed (3.4.0 did this); keep the model tutorials shallow (B.12).
6. Link check: a checker exists only as a session script (`linkcheck.py <website dir>` in the scratch directory; **not in the repo, OPEN**); `cscripts/test_external_links.do` checks the external URLs that ado and help files mention (needs the internet). After the deploy confirm that https://nwcommands.org loads and the news entry is there.
7. `python3 tools/release_preflight.py` (checks items 1 and 2 above for the core and for any model clone it finds).
8. Zenodo and manual (C6), mailing list (owner), `CITATION.cff`/`NOTICE.md` version text (done by `set_version.py`).

### C6. Zenodo and manual procedure
Only nwsaom has a Zenodo record; the rule is B.10. When a new minor of nwsaom changes documented behaviour: rebuild the manual (`manual/nwsaom_manual.tex`; `\pkgversion`/`\pkgdate` come from `set_version.py`; the effect tables from `python3 manual/build_effects.py <inventory csv>`; build with pdflatex as the owner does; **UNVERIFIED**: the exact LaTeX command is not recorded in the repo),
commit `manual/nwsaom_manual.pdf`, then the OWNER uploads the PDF as a NEW VERSION of the existing record (never a new record; the all-versions DOI stays), fills the version field (the first record's version field is empty), and the citation texts are updated (B.10). `\manualdoi` in the manual is the only place the DOI is defined.
For a new package manual (nwergm): create a record, tell the DOI to the agent, fill `\manualdoi`, add the website "Manual" menu entry (copy of `website/nwsaom/manual.md`, own `nav_order`, permalink `/<name>/manual/`).

### C7. Book (harness run after each release)
The book code harness in `/Users/tgrund/FILES_NEW/RESEARCH/2026 Book StataPress/tools/` (README there) re-runs every code listing against the software and never edits the manuscript.
After each release: `cd "/Users/tgrund/FILES_NEW/RESEARCH/2026 Book StataPress" && tools/run_book_code.sh --core <core worktree of main> --jobs 2` (models default to `/Users/tgrund/FILES_NEW/SOFTWARE/{nwsaom,nwergm,nwdynam,nwrem}`: use the released checkouts of `main`;
`--fast` skips ch22-ch25; about 8 minutes; never more than 2 jobs; `--models <parent>`/`BK_MODELS` to point elsewhere). Read `tools/book_code_report.md`: classes FAIL, ERROR_CHANGED, STALE_NUMBER (numbers quoted in prose are NOT updated by the tool), TEXT_CHANGED, REORDERED, NOT_RUN. Exit status 1 = something fails or differs.
Update the manuscript from `--regenerate` copies by hand (review the diffs, copy accepted hunks). Add known acceptable differences to `tools/book_code_ignore.txt` with a reason. `net install`/`nwinstall` listings (preface, Appendix A) are skipped by the harness: test them by hand once per release into an empty PLUS (C8).
Things that change with releases: version numbers in chapters and Appendix A, "Results that change" fixes (3.4.0: node-level results landing on the wrong nodes changed chapter 9 numbers), chapters 22-25 model output, the size guide (Appendix H) after scaling changes. The scaling audit harness `tools/scale_audit/` of the core
(`python3 tools/scale_audit/run_audit.py --sizes 1000` or `5000,20000,100000`, resumable, two Stata processes at most) is the tool behind the size-limits page and Appendix H; re-run it when a change touches performance of core commands and update `website/nwcommands/size-limits.md` and the book.

### C8. Fresh-install smoke test
**Scripted (local folders):** `tools/smoke_fresh_install.sh [core_dir [model_parent_dir]]` installs the core and the four model packages from local folders into an empty PLUS (Stata `-e`, one process per step), then runs one real fit of each in a NEW process (nwsaom on `glasgow`, nwergm on `mesa` (needs internet: `nwwebuse`), nwdynam and nwrem on the `calls` events from `website/nw*/data/calls_events.csv`)
and prints PASS/FAIL/NOT RUN per step; exit 1 on a failure. `model_parent_dir` must hold working trees `nwsaom nwergm nwdynam nwrem` **at the release state** (check out the release commit in worktrees and pass their parent: the folder names must be exactly the package names). `STATA="/Applications/Stata 17.0/StataBE.app/Contents/MacOS/StataBE"` runs it with Stata 17;
repeat with Stata 18. `SMOKE_STALE=1` also starts every fit session with a Mata library index that does not yet know the model libraries (the state of a real user session, E.9).
**Manual variant, from GitHub after the release** (this is what was checked for 3.4.0; the commands are the ones the script uses, with the GitHub URL; **UNVERIFIED** that `nwinstall, all models` with only `path()` fetches the models from GitHub `main`): in a new empty scratch directory use a do-file with
`capture program drop nwinstall`, `sysdir set PLUS "<empty dir>"`, `sysdir set PERSONAL "<empty dir>"`, `net install nwcommands, from("https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main/") replace`, `capture program drop nwinstall`, `nwinstall, all models path("<scratch dir>")`;
then, each in a NEW `-e` process: `nwversion` (shows all five versions), `nwwebuse glasgow, nwclear` + a short `nwsaom ...` fit, `nwwebuse mesa, nwclear` + `nwergm mesa, edges nodematch(grade)`, `nwwebuse davis, nwclear` (any data set that is new). Run it under Stata 17 and 18. A passing "install, restart, run" test alone is not proof (E.9).
Also pin-check an old tagged install once in a while: `net install nwcommands, from("https://raw.githubusercontent.com/thomas-u-grund/nwcommands/vX.Y.Z/") replace`.

### C9. When something is wrong after a release
- Never move or delete a published tag, never force-push, never rewrite `main`. Fix forward with a PATCH release (`X.Y.(Z+1)`) through the normal procedure; add the fix to a regression test and a GOTCHA entry. Examples: core 3.2.0 broke the models (r(3021)) and was repaired by 3.3.0 / 1.0.4 / 1.1.2; 3.3.1 added self-healing library indexing; 3.5.1 repairs the Stata-18-built libraries (B.6).
- If a release is dangerous to install, tell the owner at once; the owner decides on a GitHub release edit (mark as pre-release or add a warning to the notes: public action, `gh release edit`; **UNVERIFIED** option choice), the mailing-list notice and the website news entry. The patch release is the real remedy.
- If only the website is wrong: a normal `develop` commit and promote; no release.
- If a bot commit or a promote conflicts: stop; take `--theirs` only for files under `lib/plugins/` (C1 step 11); anything else is a real conflict for a human.
- A model release that broke because the core library changed under it: do not hot-patch the library file; rebuild against the final core state (C3) and re-release.

### C10. The preflight script: `tools/release_preflight.py`
Read-only (no fetch, no writes, no Stata). `python3 tools/release_preflight.py` before a release (run on `develop`); `--require-pushed` after the push; `--post` after the release (branch `main`, tag present and inside `origin/main`); `--models-parent DIR [--model-pattern 'rd_{name}']` to find the model clones (default: next to the core checkout, folder = package name);
`--no-network` skips `git ls-remote`; `--skip-website`. It prints PASS/FAIL/SKIP per item and exits 1 on any FAIL. Items: VERSION file; CHANGELOG top entry equals VERSION and its date; `tools/check_version.py`; `tools/check_help_index.py`; library hash equals `lib/lnwcommands.mlib.release.sha256`; tag `vX.Y.Z` absent locally and on GitHub (present with `--post`);
working tree clean (tracked files); branch is `develop` (`main` with `--post`) and relative to its remote (behind or diverged fails, ahead is allowed unless `--require-pushed`); plugin generation (`NWCOMB_VERSION` in `native/nwcomb.h` is not below any `nwg_comb_version() >= k` in the code; the macOS, Linux and Windows binaries were last committed at or after the last commit that touched `native/`);
the website shows the core version (packages table, core page, news, citation) and has no "DD Month" placeholder; each model clone found: `lib/core_mlib.sha256` equals the core library's hash, and the website shows the model's `VERSION`. It cannot check which Stata version built a library (B.6), nor the compiled generation inside a binary.
On the state of 2026-10-25 (`origin/main`): `--post` passes everything except the branch (when run from a scratch branch) and the website placeholder (E.14).

---

## D. Checklists (copy and tick)

### D1. Core release X.Y.Z
- [ ] owner said release; worktree of `develop`, clean
- [ ] features merged; `unw_*.do` changed? yes -> do D3 instead
- [ ] CHANGELOG entry (Results that change first); data sets/help/dialogs/README/ROADMAP/ARCHITECTURE done
- [ ] `python3 tools/set_version.py X.Y.Z [date]`; `python3 tools/check_version.py`
- [ ] full core suite, Stata 17: 0 errors, 0 NOT RUN; Stata 18: same
- [ ] website: news, packages table, core page (+ real date), install.md, citing.md, datasets, reference pages
- [ ] commit "Release X.Y.Z ..."; `python3 tools/release_preflight.py` all PASS
- [ ] `git push origin develop`; if `native/` changed: CI green, bot commit pulled, key tests with CI plugin, `--require-pushed`
- [ ] promote to `main` (`./promote.sh`, or the temporary-branch recipe if `main` is checked out elsewhere)
- [ ] `git tag -l vX.Y.Z` empty; `git tag -a vX.Y.Z -m "nwcommands vX.Y.Z"`; `git push origin vX.Y.Z`
- [ ] `gh release create vX.Y.Z --title "nwcommands X.Y.Z" --notes-file notes.md`
- [ ] deploy and master-sync workflows green; https://nwcommands.org/news/ shows it; links checked
- [ ] `--post` preflight; fresh-install smoke from GitHub (17 and 18); book harness; announcement (owner)

### D2. Model package release X.Y.Z (nwsaom, nwergm, nwdynam, nwrem)
- [ ] worktree `release-X.Y.Z` from `main`; features merged
- [ ] core requirement raised only if needed (`.pkg`, `README.md`)
- [ ] library rebuilt only if needed (Stata 17, `NWCORE=<core>`), `record_core_lib.py`
- [ ] CHANGELOG; `set_version.py`; `NWCORE=<core> check_version.py`
- [ ] `NWCORE=<core> cscripts/run_tests.sh` under Stata 17 and 18 (nwsaom: full for minor)
- [ ] commit "Release X.Y.Z"; `git tag -l vX.Y.Z` empty
- [ ] `git push origin release-X.Y.Z:main`; if `native/` changed: CI, `git pull --rebase`
- [ ] `git tag -a vX.Y.Z -m "<pkg> X.Y.Z"`; `git push origin vX.Y.Z` (never `--tags`)
- [ ] `gh release create vX.Y.Z --title "<pkg> X.Y.Z" --notes-file ...`
- [ ] website C5; Zenodo/manual per B.10 (minor only); smoke test; book harness

### D3. Lockstep batch (core library changed)
- [ ] D1 up to the tests, library rebuilt ONCE with Stata 17; `develop` pushed, CI done, pulled -> final core state
- [ ] for each of nwsaom, nwergm, nwdynam, nwrem: `lib/build.do` (Stata 17, `NWCORE`), `record_core_lib.py`, "Requires core X.Y.Z", CHANGELOG, `set_version.py`, `check_version.py`
- [ ] `python3 tools/record_release_hash.py` in the core; all five suites under 17 and 18; smoke test with and without `SMOKE_STALE=1`
- [ ] one website commit for all five; preflight with `--models-parent`
- [ ] release core (D1 from promote), then each model (D2 from push)

### D4. Patch release
- [ ] reproduce the problem with a regression test that fails first
- [ ] fix, GOTCHA entry if non-obvious, CHANGELOG, `set_version.py`, tests, then D1 or D2 (D3 if the library changes)
- [ ] no Zenodo upload, no manual change

### D5. Website-only change
- [ ] `develop` commit under `website/`, link check, `./promote.sh` (no tag, no release), deploy workflow green

### D6. nwsaom minor release with manual
- [ ] D2 plus: manual rebuilt and re-labelled "Manual for version X.Y", effects inventory current (B.11), citation texts updated, PDF committed
- [ ] owner uploads the new Zenodo version of the existing record; website manual link checked

---

## E. Known traps (details in the GOTCHA.md of each repo)

1. **Stale plugin in the real PLUS shadows the repo build** (all repos' GOTCHA, "A stale installed plugin in PLUS ..."). Always a scratch PLUS and the repo's `lib/plugins/macos` on the adopath (C0). A repo copy with its own `lib/plugins/` shadows a scratch plugin (nwsaom GOTCHA); the lookup prefers the plugin next to the loaded `.ado`.
2. **Copying a rebuilt plugin over a loaded one kills Stata silently** (macOS "Code Signature Invalid"): `rm` first. A run that just stops with no `end of do-file` and no `r()` is a plugin crash: read `~/Library/Logs/DiagnosticReports/StataBE-*.ips`.
3. **Legacy tags clash with new versions and `--tags` would publish them.** Local-only tags found on 2026-10-25: nwergm has 81 (`v1.0.5`, `v1.1.5` ... `v1.2.1` ... `v1.6.3C`, `v2.0.0`; none exists on GitHub), nwsaom and nwdynam have `v2.0.0`, nwdynam and nwrem have `pre-split-2026-10-24`. Check `git tag -l vX.Y.Z` before tagging; delete a clashing purely local tag (as v1.1.2/v1.1.3 of nwergm were); push one tag by name. A future nwergm 1.2.1 ... or any 2.0.0 collides: **OPEN:** owner may delete or rename the legacy tags.
4. **`nwwebuse` reads GitHub `main`** (not `develop`, not a tag): a new data set is testable through `nwwebuse` only after the push to `main`; before, use `nwuse data/<name>` from the repo (what `nwwebuse` does after prepending the path).
5. **Mata `sort()` / `order()` and Stata `sort` break ties by the random-number state:** add the row number as last key whenever tied rows reach a result (`cscripts/test_ordfix.do`). Equality tests against an older implementation need `set sortseed` and explicit sorting.
6. **A worktree cannot check out `main` while another worktree has it:** `promote.sh` fails at `git switch -C main origin/main`; use the temporary branch recipe (C1 step 11).
7. **The CI-built macOS plugin differs from the local build:** re-run the key tests with the pulled CI binary. Linux and Windows binaries exist only from CI; a release with a changed `native/` and no CI run ships stale binaries (preflight item "plugin is newer than native/").
8. **The CI bot commits to `develop` (core) and to `main` (models):** `git pull --rebase` before the next push, tag after the bot commit. `[skip ci]` is in its message.
9. **`mata mlib index` does not persist:** a library installed by `net install` can be missing from a session's Mata library list (r(3499) / r(3000)). All entry programs of the models start with `_<pkg>_libcheck`; test with `SMOKE_STALE=1 tools/smoke_fresh_install.sh`. A simple "install, restart, run" test hides it. Smoke tests that change PLUS after Stata started see a stale list: not a real-user failure.
10. **Stata `-e` puts the log in the directory named by the environment variable `PWD`,** not the process cwd: start Stata from the scratch directory (`cd $d && ... -e do run.do`); from Python pass `env PWD=d`. Relative export paths in batch graphs resolve against the log directory: use absolute paths. `"$NAME"` does not read an environment variable in `-e`; use `local v : environ NAME`.
11. **`lib/build.do`, `deploy_nw_build.do` and the model `lib/build.do` run from the repository root** (the core's stops if `unw_core.do` is not found there). `NWCORE` must be the core whose library is final.
12. **`quietly` swallows `display as error`;** `capture quietly cmd` leaves rc 999 with no message. `syntax` flag options starting with "no" lose the prefix; an option declared lowercase `noxxx` sets local `xxx`.
13. **Program size limits:** one ado program larger than about 133-141 KB fails to load ("system limit exceeded", nwsaom.ado); `.dlg` programs have a limit too (r(1001)); the interactive help Viewer has a size limit (the nwsaom help is split into `nwsaom.sthlp` + `nwsaom_remarks.sthlp`). Subcommands live in their own ado files.
14. **Website placeholders:** `website/nwcommands/index.md` on `main` at 3.5.0 still reads "The core is version 3.5.0 (DD October 2026)". The preflight flags it.
15. **`deploy.sh` is dangerous:** it rebuilds the Mata library with a hard-coded `/Applications/Stata/StataBE.app` (Stata 18), regenerates manifests, `git add -u`, commits and pushes to `develop`. Do not use it for releases (even `--check-only` does the library rebuild). Use `python3 tools/check_help_index.py` and `_pkg_*.txt` + `_nwdeploy` knowledge from GOTCHA.md.
16. **Test results:** most older tests print no PASS marker; failure is an `r()` error; no log = NOT RUN; `test_external_links.do` needs the internet and is not part of the bar. Do not run every option in the slow Mata engine to build a list; derive it from the code and say so.
17. **Generated artifacts:** `.pkg`, `stata.toc`, `nwcommands.sthlp` (core manifests); the `.dlg` files of the models; manual tables from the inventory. Edit the sources, not the outputs.
18. **A repo copy for another purpose in the same folder:** many scratch worktrees (`nwergm_fix`, `nwsaom_ver`, ...) sit next to the clones in `/Users/tgrund/FILES_NEW/SOFTWARE/`; `--models-parent` and `tools/smoke_fresh_install.sh` need folders named exactly after the packages, on the release commit.
19. **`nwversion`/`<pkg> version` before `nwinstall, all`:** "core package: not found" is expected, not a bug.

---

## F. Index of related documents and who maintains what

| Document | Where | Content | Maintainer |
|---|---|---|---|
| **This file** | core repo, `RELEASING.md` (GitHub: https://github.com/thomas-u-grund/nwcommands/blob/main/RELEASING.md) | master procedures and policies | owner + agent sessions; update it with every change of procedure |
| Model `RELEASING.md` (4) | each model repo | package-specific part and a link to this file | same |
| `tools/release_preflight.py`, `set_version.py`, `check_version.py`, `record_release_hash.py`, `check_help_index.py`, `smoke_fresh_install.sh`, `promote.sh` | core repo | the release tooling (C10, B.4, B.5, C8) | same |
| `tools/set_version.py`, `check_version.py`, `record_core_lib.py`, `cscripts/run_tests.sh` | each model repo | per-package tooling | same |
| `CHANGELOG.md` | each repo | release notes source | agent writes, owner approves |
| `GOTCHA.md` | each repo | diagnosed pitfalls (section E points here) | add an entry whenever something non-obvious is resolved |
| `NOTICE.md`, `CITATION.cff`, `LICENSE` | each repo | licence, AI disclosure, data licences, citation | `set_version.py` for versions, owner for text |
| `README.md`, `ROADMAP.md`, `ARCHITECTURE.md` | core root | public summaries | B.14 |
| `docs/` (gitignored) | core checkout; nwsaom/nwergm repos have tracked `docs/` | detailed internal notes, effects inventory, STATUS copies, SIZE_LIMITS, BOOK_NOTES | agent sessions |
| `CLAUDE.md` (private, gitignored) | `/Users/tgrund/FILES_NEW/SOFTWARE/nwcommands/CLAUDE.md` | the owner's standing rules, short, pointing to this file | owner |
| Memory notes | `~/.claude/projects/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/memory/` | feedback and project decisions behind section B | agent sessions |
| `STATUS_2026-10-25.md`, `INSTRUCTIONS.md`, `INDEX_RELEASE_DOCS.md` | `/Users/tgrund/FILES_NEW/RESEARCH/2026 nwsaom/project_state_2026-10-24/` | where each package stands; how the pieces map | agent sessions |
| Book harness README, `tools/scale_audit/` | `/Users/tgrund/FILES_NEW/RESEARCH/2026 Book StataPress/tools/README.md`; core `tools/scale_audit/` | book code check (C7); scaling audit | agent sessions |
| Website | core `website/` | all public docs; news and versions per C5 | agent sessions after every release |
| Zenodo record | https://doi.org/10.5281/zenodo.23623807 | nwsaom manual (all versions) | owner |
