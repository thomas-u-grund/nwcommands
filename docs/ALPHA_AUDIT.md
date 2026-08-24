# nwcommands Alpha Audit

Tracking document for the pre-release alpha pass: feature/optimization work is frozen (see
`docs/CERTIFICATION.md`'s own harmonisation-phase log for that prior work) in favor of stress-testing
every command and option, verifying every help file, and hardening design/syntax coherence across the
package, with the goal of one publishable release.

Scope, per the user's own explicit direction:
1. Every command, every documented option: actually run, edge cases included, not just read.
2. Every `.sthlp` file: syntax diagram matches the real `syntax` line, every option documented, worked
   examples actually run.
3. The Dialog (`.dlg`) UI audit (previously a separate, deferred Pending item - folded in here).
4. The help-file network-type restructuring (previously a separate, deferred Pending item - folded in
   here where it overlaps with per-command help review; the full ~90-command classification audit is
   still its own large sub-effort).
5. Design/syntax/command-logic coherence: option naming, error-code conventions, `replace`/`generate()`
   patterns, etc., consistent across sibling commands. Inconsistencies found are fixed as we go, matching
   this project's own established harmonisation-phase methodology (root-cause, validate against the
   original behavior, regression-test, document, commit) - not just flagged for later.

Findings are fixed inline when low-risk; anything touching shared core files (`unw_core.do`) or carrying
real correctness/compatibility risk gets the same rigor as every harmonisation unit before it: cross-
validated against the original implementation, full `cscripts/` regression sweep, documented, committed.

## Pre-audit findings (found while scoping this pass, already fixed)

| Finding | Status |
|---|---|
| 14 commands (`nw2set`, `nw2toedge`, `nwappend`, `nwbridges`, `nwdendrogram`, `nwgenvar`, `nwnode`, `nwnoderename`, `nwpreserve`, `nwrestore`, `nwshared`, plus `nw2clustering`/`nwmixing`/`nwmoviexy` - the last 3 also missing help) existed as working `.ado` files but were never registered in `_pkg_ado.txt`/`_pkg_hlp.txt`/`nwcommands-ado1-2.pkg`/`nwcommands-hlp1-2.pkg` - a fresh install would have silently omitted them | Fixed: 10 with existing docs registered in all 4 manifests (alpha unit 1) |
| `nwrestore` had no doc header / no `.sthlp` (its sibling `nwpreserve.ado` documented both in its own header, but only generated `nwpreserve.sthlp`) | Fixed: added its own header, generated `nwrestore.sthlp` |
| `nwmoviexy.ado` was a byte-for-byte functional duplicate of `nwmovie.ado` (confirmed via diff after name-normalization) - even its own internal helper subprograms were still named `nwmovie_install_win`/`nwmovie_install_osx`, a live program-redefinition collision with `nwmovie.ado`'s own identically-named helpers | Fixed: replaced with a 1-line alias (`nwmoviexy` &rarr; `nwmovie \`0'\`), removing the duplicate ~660 lines and the collision; new `.sthlp` documents it as an alias |
| `nw2clustering` has no `.sthlp` and a previously-documented, unfixed bug (`dev/benchmark_suite.do`'s own comment: "Type reshape error", r9, on any bipartite network) | Not fixed yet - assigned to `positions_equivalence` group below |
| `nwmixing` has no `.sthlp` despite being functionally fixed in an earlier harmonisation unit (118) | Not fixed yet - assigned to `stat_models` group below |
| `nwvalidvars` is called by `nwlattice.ado` but the `.ado` file itself doesn't exist anywhere in the repo (pre-existing, already tracked in `docs/CERTIFICATION.md`'s own Pending list) | Not fixed yet - assigned to `generators_structural` group below |
| `nwcentrality.sthlp` exists with no corresponding `.ado` - confirmed to be a legitimate umbrella/overview topic page (points to `nwdegree`/`nwbetween`/etc.), not a missing command | No fix needed - noted so it isn't mistakenly re-flagged |

## Command groups (Phase 1 audit)

Each group below is one audit unit. Status: ⬜ not started · 🔶 in progress / findings pending review · ✅ audited (fixes applied where needed, regression-clean)

| # | Group | Commands | Status |
|---|---|---|---|
| 1 | import_export | nw2fromedge, nw2set, nw2toedge, nwappend, nwexport, nwfromedge, nwimport, nwsave, nwset, nwtoedge, nwuse, nwwebuse | ✅ (moderate-severity pass, unit 1) |
| 2 | generators_structural | nwrandom, nwpref, nwlattice, nwring, nwsmall, nwpermute, nwduplicate | ✅ (moderate-severity pass, unit 2) |
| 3 | generators_derived | nwdyadprob, nwhomophily, nwexpand, nwdissimilar, nwsimilar, nwtranspose, nwsubset, nwshared | ✅ (moderate-severity pass, unit 3) |
| 4 | paths_distance | nwgeodesic, nwpath, nwreach, nwbridges, nwneighbor, nwego, nwaltergen | ✅ (moderate-severity pass, unit 4) |
| 5 | information_census | nwcurrent, nwdyads, nwissymmetric, nwname, nwsummarize, nwtabulate, nwtriads | ✅ (moderate-severity pass, unit 5) |
| 6 | manipulation_subset | nwaddnodes, nwdrop, nwdropnodes, nwkeep, nwkeepnodes, nwnoderename, nwpreserve, nwrestore | ✅ (moderate-severity pass, unit 6) |
| 7 | manipulation_transform | nw2project, nwattime, nwcollapse, nwrecode, nwrename, nwreplace, nwreplacemat, nwsym | ✅ (moderate-severity pass, unit 7) |
| 8 | centrality | nw2degree, nwbetween, nwcloseness, nwdegree, nwevcent, nwkatz | ✅ (moderate-severity pass, unit 8) |
| 9 | cohesion_subgroups | nwclique, nwcomponents, nwkcomponents, nwkcore, nwkplex, nwnclan, nwnclique, nwsimmelian, nwcohesion | ✅ (moderate-severity pass, unit 9) |
| 10 | community_spectral | nwcommunity, nwmodularity, nwspectral, nwhierarchy | ✅ (moderate-severity pass, unit 10) |
| 11 | positions_equivalence | nwassortativity, nwbalance, nwbrokerage, nwburt, nwconcor, nwconstraint, nwcoreperiphery, nwsimindex, nwclustering, nw2clustering | ✅ (moderate-severity pass, unit 11) |
| 12 | stat_models | nwcorrelate, nwcug, nwergm, nwergm_estat, nwqap, nwutility, nwmixing | ✅ (moderate-severity pass, unit 12) |
| 13 | misc_analysis | nwcontext, nwgen, nwgenerate, nwgenvar, nwnode, nwturnover, nwvalue, nwds | ✅ (moderate-severity pass, unit 13) |
| 14 | utilities_state | nwclear, nworder, nwsync, nwtomata, nwtomatafast, nwtostata, nwunab, nwvalidate, nwinstall, nwload | ✅ (moderate-severity pass, unit 14) |
| 15 | visualization | nwdendrogram, nwmovie, nwmoviexy, nwplot, nwplotmatrix | ✅ (moderate-severity pass, unit 15) |
| 16 | programming | nwcompressobs | 🔶 (1 minor finding only, no critical-fix unit needed) |

118 commands total across 16 groups (every `nw*`-prefixed `.ado` file in the repo, excluding internal
`nw_*` helpers and the `nwcentrality`/concept-page overview topics, which aren't real commands).

## Phase 1 results

Completed via a 16-agent parallel workflow (one agent per group above, read-only - each actually ran
every documented option against real test networks, not just read code). **231 findings**: 50 critical,
83 moderate, 98 minor (85 bug, 64 help_mismatch, 37 consistency, 24 missing_test, 14 missing_doc, 7
other). Raw findings: `/tmp/alpha_findings.json` (not committed - regenerable from the workflow journal
if needed) and a filterable triage view was published as an Artifact for browsing.

Now working through fixes group by group, critical severity first, using the same methodology as every
harmonisation unit before this pass: reproduce, root-cause, fix, validate against original behavior where
applicable, full `cscripts/` regression sweep, document as a numbered unit in `docs/CERTIFICATION.md`,
commit. Status column above tracks progress per group (🔶 = findings in from Phase 1, fixes not yet
applied; ✅ = fixes applied and regression-clean for that group).

**Critical-severity sweep complete** (alpha units 2-16, `docs/CERTIFICATION.md`): all 50 critical findings
across all 16 groups are fixed and regression-tested. 181 moderate/minor findings remain (83 moderate + 98
minor - the "133" figure previously here was stale/incorrect), tracked per group in the table above (🔶 =
critical fixes done, moderate/minor still pending; ✅ = moderate-severity pass also done for that group) -
now in progress, group by group (moderate-severity pass unit 1 = `import_export`, see
`docs/CERTIFICATION.md`).

## Later phases

- **Phase 2**: Dialog (`.dlg`) UI audit - 57 `.dlg` files + 3 `.idlg` includes, each checked against its
  command's current option set. Explicitly skipped for this release (user-requested).
- **Phase 3**: Help-file network-type restructuring - ✅ done, see `docs/CERTIFICATION.md`'s "Phase 3"
  entry. All 92 previously-undocumented commands (plus `nwaltergen`, found missing during the final
  sweep) now have a "Supported network types" section; `docs/NETWORK_TYPE_MATRIX.md` and the new
  `nw_networktypes.sthlp` shared topic capture the full picture. Per-command section consolidation
  into a shared-link-only reference remains a deliberately separate, not-yet-started later step.
- **Phase 4**: Cross-cutting consistency sweep once all 16 groups have individually reported - patterns
  that only become visible once every group's findings are in one place (e.g. a naming convention that's
  inconsistent *across* groups, not just within one).

## How to resume this audit

Each group's own findings (once its workflow agent reports back) get folded into `docs/CERTIFICATION.md`
as a normal harmonisation unit (numbered, following the existing convention) for anything that gets fixed;
this file just tracks which groups have been covered and stays a thin index - the actual fix history lives
in `docs/CERTIFICATION.md` and `git log`, same as every other unit.
