* deploy_nw_build.do -- the Stata half of deploy_nw.sh (see that file's own
* header for the full pipeline). Two steps, run in this order because the
* second one writes files relative to the repo root, and the first one
* temporarily cd's into lib/:
*   1. Rebuild lib/lnwcommands.mlib from every unw_*.do source file
*      (lib/build.do's own job - this is the step that silently went stale
*      for a while;  lib/build.do itself is the single
*      source of truth for which unw_*.do files are compiled in, not
*      duplicated here).
*   2. Regenerate the package manifests (nwcommands-ado1.pkg/-ado2.pkg,
*      nwcommands-hlp1.pkg/-hlp2.pkg, nwcommands-dlg1.pkg/-dlg2.pkg,
*      stata.toc, nwcommands.sthlp) from _pkg_ado.txt/_pkg_hlp.txt (and a
*      live directory glob for .dlg/.idlg) via _nwdeploy.ado - this is the
*      step that was never run at all for _nwsyntax.ado and 9 other real,
*      documented commands until 2026-09-02, leaving them silently absent
*      from every net install despite being fully implemented and indexed
*      in nwalphabetical.sthlp.
*
* version() below is cosmetic (stamped into nwcommands.sthlp's own footer
* and each chunked .pkg's own "d" description line) - kept in sync with
* whatever nwcommands.sthlp already has rather than force-bumped on every
* run, since this package does not follow strict semver.
* run from the repository root
version 14
local root_nw "`c(pwd)'"
clear all
cd "`root_nw'"

do "lib/build.do"

cd "`root_nw'"
do "_nwdeploy.ado"
_nwdeploy, version("2.0")

di as result "DEPLOY_NW_BUILD_DONE"
