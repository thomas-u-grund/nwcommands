# Legacy / Archived Files

Living document, part of the interface/syntax/network-type/documentation/dialog/repository
harmonisation phase (2026-08-21). Tracks every file moved out of the active package tree, why,
and what (if anything) replaces it. See `docs/COMMAND_AUDIT.md` for the full command-language
audit these decisions are drawn from.

## Policy

Per the harmonisation brief: **archive rather than delete** whenever a file might have historical
or technical value; delete only exact junk (temp files, broken generated artefacts). Archived
files live under `old/` and are never on Stata's active search path — `old/` is a subdirectory of
the repo root, and Stata's default `adopath` does not recurse into subdirectories, so nothing here
can shadow or conflict with an active command.

## `old/ado/` — dead-on-arrival duplicate `.ado` files

Every file below defines a Stata `program` whose name **does not match its own filename**. Since
Stata's ado-file mechanism requires filename and program name to match for a file to be reachable
as a command (`nwbetween2.ado` can only ever be invoked as `nwbetween2`, never as `nwbetween`),
every file in this group was **structurally unreachable** the moment a differently-named,
filename-matching sibling already existed and became the one Stata actually resolves. None are
referenced by any other `.ado` file in the repository (grepped repo-wide), none appear in the
package manifests (`_pkg_ado.txt`, `_pkg_hlp.txt`, `nwcommands-ado.pkg`, `nwcommands-hlp.pkg`),
none have a matching `.sthlp` or `.dlg`, and none have `cscripts/` test coverage — found via a
dedicated audit fork that checked all of this evidence for every file before classifying it.

| File | Defines program | Shadows (active file) | Reason archived |
|---|---|---|---|
| `nwbetween2.ado` | `nwbetween2` (own name — not a filename mismatch, but see note) | — | Abandoned, incomplete alternate betweenness algorithm (path-enumeration, not Brandes). No doc header, no return step, writes loose `edge_list.dta`/`adj_list.dta` to the working directory (the same pollution hazard class fixed in `nwbalance` earlier this session). Never finished. |
| `nwgenerate_old.ado` | `nwgenerate` (mismatch) | `nwgenerate.ado` | Pre-`nw_syntax` draft of the current `nwgenerate.ado`. Superseded. |
| `nwplotjs2.ado` | `nwplotjs` (mismatch) | `nwplotjs.ado` (removed entirely, unit 51 - see below) | Smaller, earlier revision (missing `nodeborder()` and other options present in the once-active file). Superseded even before `nwplotjs.ado` itself was removed. |
| `nwplotjs_old.ado` | `nwplotjs` (mismatch) | `nwplotjs.ado` (removed entirely, unit 51 - see below) | Earliest revision found of the three `nwplotjs`-defining files. Superseded even before `nwplotjs.ado` itself was removed. |
| `nwplot_sigmajs.ado` | `nwplotjs` (mismatch) | `nwplotjs.ado` (removed entirely, unit 51 - see below) | A third, differently-named draft that also defines `nwplotjs`. Superseded even before `nwplotjs.ado` itself was removed. |
| `nwplotmatrix_new.ado` | `nwplotmatrix` (mismatch) | `nwplotmatrix.ado` | Near-identical to the active file, missing a `lab` flag; the "_new" name is misleading — it is not the one actually shipped. Superseded. |
| `nwsimmelian2.ado` | `nwsimmelian` (mismatch) | `nwsimmelian.ado` | 24-line abandoned stub. Superseded. |
| `nwuse_new.ado` | `nwuse_new` (own name) | — | Abandoned prototype of an alternate `.dta`-metadata-column serialization format for saved networks, unrelated to how `nwuse.ado` actually stores things. Not a predecessor of `nwuse.ado` — a parallel experiment that was never finished or adopted. |
| `nwuse_old.ado` | `nwuse_old` (own name) | — | Legacy architecture (`unw_defs`-era), superseded by `nwuse.ado`. Kept under git history (was tracked) — moved with `git mv` to preserve it. |
| `nwuse_old2.ado` | `nwuse_old2` (own name) | — | Near-identical to `nwuse_old.ado` (59 diff lines) — an earlier draft of the same legacy approach. |
| `nwvalue2.ado` | `nwvalue` (mismatch) | `nwvalue.ado` | Near-identical to the active file (identical header date). Superseded. |
| `unknown_nw2clustering.ado` | `nw2clustering` (mismatch) | `nw2clustering.ado` | The "unknown_" prefix appears to be exactly what it says — a previously-flagged, unidentified stray file. Not a simple duplicate: it lacks `nw2clustering.ado`'s `binary`-measure dichotomization branch, but adds two extra `r()` returns (`r(C_global)`, `r(measure)`) the active file doesn't have. **Follow-up worth doing**: port those two extra returns into `nw2clustering.ado` proper (tracked as a Pending item in `docs/CERTIFICATION.md`), since they appear to be a genuine improvement, not accidental drift. |

## `old/js/` — vendored JavaScript libraries no longer referenced by any command

Not `.ado` files, so the `old/ado/` convention above doesn't fit directly - a parallel `old/js/`
subdirectory (same non-adopath-recursed root, same "archive rather than delete" policy) holds
these instead. Found during the `nwplot` SVG-export modernisation audit (harmonisation unit 33):
`nwplotjs.ado` (the package's interactive graph-exploration command, still active and NOT
superseded by native Stata SVG export - see `docs/CERTIFICATION.md`'s own row for that unit) loads
its JavaScript from `linkurious/` (a sigma.js fork, kept in place at the repo root, unarchived,
because it is a genuine, live runtime dependency) via literal relative-path `file write` calls in
`nwplotjs.ado` - confirmed by direct grep. `d3js/` and `sigmajs/` are two *separate*, earlier/
parallel vendorings (plain D3.js, and a plain, non-fork copy of sigma.js) that are not referenced
by any `.ado`/`.do` file anywhere in the repository (confirmed by a repo-wide grep for both
directory names before archiving) and not referenced from inside `linkurious/` itself either
(checked directly). Both were untracked in git (confirmed via `git ls-files`), so this move is a
plain filesystem relocation, not a `git mv`.

| Directory | Size | Referenced by | Reason archived |
|---|---|---|---|
| `d3js/` (now `old/js/d3js/`) | ~924K | Nothing - confirmed via repo-wide grep | Vendored D3.js (`d3.js`/`d3.min.js` plus upstream docs and a `hello.html` smoke file) from an early/parallel visualization experiment. No `.ado`/`.do` file ever loaded it. Superseded in practice by `nwplotjs`'s own sigma.js-based (`linkurious/`) interactive renderer, which is the one command actually shipped and tested. |
| `sigmajs/` (now `old/js/sigmajs/`) | ~4.3M | Nothing - confirmed via repo-wide grep | Vendored plain (non-fork) sigma.js, distinct from the `linkurious/` fork `nwplotjs.ado` actually uses - includes its own early experiment artefacts (`nwcommands-net.gexf`/`nwcommands-net2.gexf` GEXF exports, `nwcommands.html`, `hello.html`/`test*.html`). Superseded by `linkurious/`, which has custom package-specific extensions (`sigma.nwcommands.extensions/`) this plain copy never gained. |

**Update (2026-08-22, harmonisation unit 51)**: `nwplotjs.ado` itself has since been removed
entirely (not archived - deleted, along with its `.sthlp` and the stale `nwplotjs.do` duplicate),
per an explicit request now that native Stata SVG export (added in the unit 33 work referenced
above) covers vector export without it. `linkurious/` - the sigma.js fork `nwplotjs.ado` loaded
its JavaScript from - was checked at removal time and no longer exists anywhere in the repository
(confirmed via direct search); whatever happened to it predates this unit and was not investigated
further, since it is moot either way now that its only caller is gone. `d3js/`/`sigmajs/` (below)
remain archived under `old/js/` unchanged - they were never referenced by `nwplotjs.ado` or
anything else regardless.

## Root-folder cleanup (harmonisation unit 53) — deleted outright, not archived

Per the policy above ("delete only exact junk"), not moved to `old/`. Two categories, each file
checked individually for live references before removal (grep across every `.ado`/`.do`/`.sthlp`
in the repository) - `keep the subfolders` from the same instruction was interpreted literally:
`demo/`'s own already-pending file deletions and `data/~$excel_example.xlsx` (an Office lock-file
artifact) were left untouched, since they sit inside subfolders this pass was not scoped to touch.

**Genuine scratch/temp artifacts** (untracked, so no `git rm` needed - they simply no longer
appear in `git status`): `dijkstra.do`, `dump.smcl`, `log.smcl`, `priorityQueue.do`/`priorityQueue2.do`/
`priorityQueue3.do`/`priorityQueueMin.do`/`priorityQueueTest.do` (only `priorityQueue.do` was ever
referenced, by `dijkstra.do` itself - both scratch, neither referenced by any live command),
`savetrial.do`, `speedtest.do`, `test.svg` (an orphaned old file - `cscripts/test_nwplot.do`'s own
`"test.svg"` substring match is coincidental, it actually builds `relative_export_test.svg`),
`nwclusteringTEMP.do`, `net.dta`/`ego_list.dta`/`paths.dta`/`potential_4paths.dta`/`alter_list.dta`
(unreferenced scratch data), `nws_preserve` (unreferenced), and two files with a stray Private Use
Area Unicode character (U+F009) appended to an otherwise-ordinary name - `nwset.sthlp`/
`nwvalue.sthlp` (9507/1431 bytes, dated Jul 2016) - stale duplicates of the real, current,
tracked `nwset.sthlp`/`nwvalue.sthlp` (16478/939 bytes), never referenced by name anywhere (nothing
could reference an invisible-character filename on purpose).

**Already-tracked, already-pending-deletion files, checked and confirmed safe to finalize** (these
existed as uncommitted `git status` deletions from earlier, unrelated work - each verified rather
than blindly committed, since committing a bad deletion here would be indistinguishable from
introducing a regression): `.!2045!nwqap.sthlp`/`.!2050!nwqap.sthlp` (editor atomic-save temp
artifacts - the "`.!NNNN!name`" pattern - superseded by the real, current `nwqap.sthlp`);
`__v1nws_cls.mo` (an old compiled Mata object for the "Version 1" `NWs`/`NWsder` classes now
defined inline in `unw_core.do` - zero references); `compressed_example.txt`/`glasgow.dta`/
`klas12b.dta` (redundant root-level duplicates - proper copies already exist under `data/`, and
`nwimport.ado`'s own apparent reference to `compressed_example.txt` is dead code, a misspelled
local - `` `anyting' `` for `` `anything' `` - that has never actually done anything); `kapmine.dat`
(its only apparent reference in `netexample.sthlp` is a coincidental filename match inside a
worked example that fetches from an external URL, not the local file); `nwsave_old.ado`,
`nwsort.ado`/`.sthlp`, `nwvalidvars.ado`/`.sthlp` (each confirmed byte-identical, via direct diff
against `git show HEAD:<path>`, to an already-archived `deprecated/` counterpart - the deletion
finalizes a move that had already happened in substance; `nwvalidvars.ado` in particular is the
missing command already tracked in `docs/CERTIFICATION.md`'s own Pending table as breaking
`nwlattice.ado` - restoring it to the root would partially undo an already-made, already-documented
archival decision, so the real fix stays scoped to `nwlattice.ado` itself, as that Pending row
already says); `index.html`, `junk.txt`, `madrid.dat`, `mmm.mmat`, `mycc.mmat`, `mydata.dta`,
`myfile.dta`, `mynets.ddd`, `mynets.mmat`, `nwcommands.txt`, `sociomatrix10.eps`, `stata.toc`,
`wiring.dat` (zero references anywhere, generic scratch/example names); `test.do` (a scratch runner
only ever invoked by `nw_deployfile.ado`, itself unreferenced author-only release tooling, not a
shipped package command); `test.dta` (its only reference, in `cscripts/test_nwbalance.do`, is a
comment describing an already-fixed bug where an earlier version of `nwbalance.ado` used to write
this exact file as an unwanted side effect - not a real dependency).

**Deliberately left alone, needs its own dedicated pass**: `nwcommands-dlg.pkg`/`nwcommands-ext.pkg`/
`nwcommands-ext1.pkg`/`nwcommands-hlp.pkg` are also pending, uncommitted root-level deletions, but
unlike everything above they are package-distribution manifests `nwinstall.ado` references by name
(`net install "nwcommands-hlp", all`, etc.) - whether they're safe to finalize depends on
understanding the release/publish process behind them (are they meant to be regenerated from a
`_pkg_dlg.txt`-style source list the way `nwcommands-ado.pkg` is from `_pkg_ado.txt`, or are they
themselves the source of truth uploaded to nwcommands.org on release?) well enough to be sure
finalizing the deletion doesn't break `nwinstall`'s own distribution mechanism - not established
here, so left untouched rather than guessed at.

## `old/data/` — stray root-level example-dataset duplicates (legacy format)

Found while chasing a real bug during the harmonisation phase's `nwuse.ado` fix (2026-08-23):
root-level `florentine.dta`/`gang.dta` are NOT copies of the active `data/florentine.dta`/
`data/gang.dta` files (confirmed via `diff` - they genuinely differ), but an older, edgelist-plus-
metadata legacy format (`_format`/`_nets`/`_name`/`_size`/... columns) tied to the deprecated
`nwuse_old.ado`/`nwuse_old2.ado` mechanism already archived under `old/ado/`. Their presence at the
repo root (outside `data/`, the actual, current example-dataset directory) was actively harmful,
not just clutter: a bug fix that made `nwuse`'s local-file path fall back from `.nwdta` to `.dta`
when no saved-network file exists (needed for several genuine plain-`.dta` example datasets - see
`docs/CERTIFICATION.md`) started silently picking up this stray root `florentine.dta` instead of
the intended `data/florentine.nwdta`, breaking `cscripts/test_nwplot.do`/`test_nwdegree.do`'s own
bare `nwuse florentine` calls. Fixed by moving both files to `old/data/` (git mv, preserving
history) and pointing the affected tests at `nwwebuse florentine` instead (now genuinely working
end to end - see the same certification entry), matching the convention every other test file in
`cscripts/` already used.

## Two more stray root-level files, found during the GitHub-public-release cleanup pass (2026-08-23)

- `old/ado/lnwsub.do` (was `lnwsub.do`) - a v1-era draft of the Mata class architecture (`v1NWs`/`v1NWdef`/`v1NWsdef` structures), from the "Setup of development branch for v2.0" commit, predating the current, active `NWdef` class entirely. Not referenced by any live file.
- `old/example_tabclass_output.do` (was `example_tabclass_output.do`) - defines `program difmh`, an unrelated stratified-analysis command with no connection to network analysis at all. Not referenced by any live file; almost certainly an accidental inclusion rather than package history worth keeping alongside the actual code, but archived rather than deleted per this document's own policy.

## Not archived (checked and ruled out as duplicates)

- `_growmedian2.ado` — no sibling `_growmedian.ado` exists; just an oddly-named singleton helper, not a version duplicate.
- `nwtab1.sthlp` / `nwtab2.sthlp` / `nwtab3.sthlp`, `nwtabulate1.dlg` / `nwtabulate2net.dlg` / `nwtabulate2var.dlg` — each is a distinct, legitimate sub-topic/mode help page or dialog, not a version duplicate.

## Manifest gaps found (not archival, but related — fixed separately)

Two ACTIVE, tested, documented commands were found missing from all four package manifests during
this same audit pass: `nwplotjs` and `nwsimmelian`. Fixed in the commit that also performed this
archival — see `docs/CERTIFICATION.md` for detail.

## Open, not yet actioned

- `nwbetween2.ado`'s underlying alternate algorithm was never finished; if a genuinely different
  betweenness variant (e.g. weighted/Dijkstra-based, already on the roadmap) is built later, this
  archived file is not a useful starting point (incomplete, non-Brandes approach) — build fresh.
