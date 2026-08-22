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
