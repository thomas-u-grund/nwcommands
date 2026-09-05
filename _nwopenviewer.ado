*! _nwopenviewer: shared internal helper (not a public documented command,
*! matching this package's leading-underscore convention for internal-only
*! infrastructure) that opens a self-contained local HTML file
*! in the chromeless native viewer (nwedit_viewer, see unw_core.do's
*! NweditViewerAvailable()/NweditViewerPath()), falling back to
*! `view browse` when the native binary isn't available for the current
*! platform or fails to launch.
*!
*! Factored out of nwplot.ado's own `interactive` block (which had this
*! exact winexec/space-in-path staging dance inline) so nwmovie's new
*! Cytoscape-based movie player can reuse the IDENTICAL, already-debugged
*! launch logic - including the macOS winexec fix (Stata's winexec does a
*! naive whitespace split with no quote-stripping, so both the viewer
*! binary's own path and its argument must be staged into c(tmpdir),
*! which is guaranteed space-free, before calling winexec - a normal
*! net-installed copy under the default PLUS ado directory,
*! `~/Library/Application Support/Stata/ado/plus/`, has a space in it and
*! hit this every time before the fix).

capture program drop _nwopenviewer
program _nwopenviewer, rclass
	syntax anything(name=htmlpath)

	// REAL BUG FOUND AND FIXED: `anything' captures the caller's raw
	// argument text VERBATIM, including any literal double quotes typed
	// at the call site - confirmed directly via `set trace on': calling
	// `_nwopenviewer "/tmp/x.html"' left `htmlpath' holding the
	// 13-character string ""/tmp/x.html"" (quotes included), not the
	// 11-character path. Unlike a `string'/`varname' syntax element,
	// `anything' does no quote-stripping of its own - by design, its
	// whole purpose is to accept unparsed freeform text. Left
	// un-stripped, those embedded quote characters silently became part
	// of the literal argument text `winexec' below hands to the
	// launched viewer (`winexec' does its own naive whitespace split
	// with no quote-stripping of its own either - see this file's own
	// header comment): the viewer process launches, but the "file" it
	// is told to open does not exist (the real path plus two stray
	// quote characters glued on), so its window opens and never renders
	// anything - the exact "winexec is open and does not close" symptom
	// reported for both `nwmovie' and `nwplot, interactive' once both
	// started routing through this shared helper. Strip one matching
	// pair of enclosing double quotes here, once, rather than at every
	// later use site.
	if substr(`"`htmlpath'"', 1, 1) == char(34) & substr(`"`htmlpath'"', -1, 1) == char(34) {
		local htmlpath = substr(`"`htmlpath'"', 2, length(`"`htmlpath'"') - 2)
	}

	mata: st_local("_nwov_viewerpath", NweditViewerAvailable() ? NweditViewerPath() : "")
	local _nwov_usedviewer = 0
	if "`_nwov_viewerpath'" != "" {
		// Stage BOTH the viewer binary AND the html file it is told to
		// open into c(tmpdir) (guaranteed space-free) before calling
		// `winexec'. Staging the binary alone (the original fix) is not
		// enough: `nwplot, interactive' already writes its own html into
		// c(tmpdir) directly, so this second copy is a same-directory
		// no-op for that caller, but `nwmovie' writes its movie file
		// into the user's current working directory instead (a real,
		// persistent deliverable meant to survive after viewing, not a
		// throwaway) - which can just as easily contain a space (e.g.
		// inside "Documents") and would silently corrupt the same
		// `winexec' call the same way. Staging unconditionally here, for
		// every caller, is simpler and safer than asking each caller to
		// separately guarantee its own path is space-free.
		local _nwov_viewercopy = "`c(tmpdir)'" + "nwedit_viewer_" + strofreal(int(runiform()*1000000))
		local _nwov_htmlcopy = "`c(tmpdir)'" + "nwedit_view_" + strofreal(int(runiform()*1000000)) + ".html"
		capture erase "`_nwov_viewercopy'"
		capture erase "`_nwov_htmlcopy'"
		capture copy "`_nwov_viewerpath'" "`_nwov_viewercopy'", replace
		local _nwov_copyrc1 = _rc
		capture copy "`htmlpath'" "`_nwov_htmlcopy'", replace
		local _nwov_copyrc2 = _rc
		if `_nwov_copyrc1' == 0 & `_nwov_copyrc2' == 0 {
			capture shell chmod +x "`_nwov_viewercopy'"
			capture winexec `_nwov_viewercopy' `_nwov_htmlcopy'
			if _rc == 0 local _nwov_usedviewer = 1
		}
	}
	if !`_nwov_usedviewer' {
		view browse "`htmlpath'"
	}
	return local usedviewer = `_nwov_usedviewer'
end
