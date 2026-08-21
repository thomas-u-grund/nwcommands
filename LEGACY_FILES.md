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
| `nwplotjs2.ado` | `nwplotjs` (mismatch) | `nwplotjs.ado` | Smaller, earlier revision (missing `nodeborder()` and other options present in the active file). Superseded. |
| `nwplotjs_old.ado` | `nwplotjs` (mismatch) | `nwplotjs.ado` | Earliest revision found of the three `nwplotjs`-defining files. Superseded. |
| `nwplot_sigmajs.ado` | `nwplotjs` (mismatch) | `nwplotjs.ado` | A third, differently-named draft that also defines `nwplotjs`. Superseded. |
| `nwplotmatrix_new.ado` | `nwplotmatrix` (mismatch) | `nwplotmatrix.ado` | Near-identical to the active file, missing a `lab` flag; the "_new" name is misleading — it is not the one actually shipped. Superseded. |
| `nwsimmelian2.ado` | `nwsimmelian` (mismatch) | `nwsimmelian.ado` | 24-line abandoned stub. Superseded. |
| `nwuse_new.ado` | `nwuse_new` (own name) | — | Abandoned prototype of an alternate `.dta`-metadata-column serialization format for saved networks, unrelated to how `nwuse.ado` actually stores things. Not a predecessor of `nwuse.ado` — a parallel experiment that was never finished or adopted. |
| `nwuse_old.ado` | `nwuse_old` (own name) | — | Legacy architecture (`unw_defs`-era), superseded by `nwuse.ado`. Kept under git history (was tracked) — moved with `git mv` to preserve it. |
| `nwuse_old2.ado` | `nwuse_old2` (own name) | — | Near-identical to `nwuse_old.ado` (59 diff lines) — an earlier draft of the same legacy approach. |
| `nwvalue2.ado` | `nwvalue` (mismatch) | `nwvalue.ado` | Near-identical to the active file (identical header date). Superseded. |
| `unknown_nw2clustering.ado` | `nw2clustering` (mismatch) | `nw2clustering.ado` | The "unknown_" prefix appears to be exactly what it says — a previously-flagged, unidentified stray file. Not a simple duplicate: it lacks `nw2clustering.ado`'s `binary`-measure dichotomization branch, but adds two extra `r()` returns (`r(C_global)`, `r(measure)`) the active file doesn't have. **Follow-up worth doing**: port those two extra returns into `nw2clustering.ado` proper (tracked as a Pending item in `docs/CERTIFICATION.md`), since they appear to be a genuine improvement, not accidental drift. |

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
