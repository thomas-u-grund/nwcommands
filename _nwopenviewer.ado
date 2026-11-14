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
	syntax anything(name=htmlpath) [, OUTput(string)]
	// output(): unattended export (nwmovie's export() option). The path is
	// passed to the viewer as its second argument; the page then exports by
	// itself, the viewer writes the file there and closes. It must be
	// space-free (winexec splits on blanks), so callers pass a c(tmpdir) path.

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
	// Linux: the viewer needs the GTK/WebKit libraries. When ldd reports one as missing, say how to install it
	// (the commands are only shown, never run) and go on without the viewer.
	if "`c(os)'" == "Unix" & "`_nwov_viewerpath'" != "" {
		tempfile _nwov_lddout
		capture shell ldd "`_nwov_viewerpath'" 2>/dev/null | grep "not found" > "`_nwov_lddout'"
		tempname _nwov_lddh
		capture file open `_nwov_lddh' using "`_nwov_lddout'", read text
		if _rc == 0 {
			file read `_nwov_lddh' _nwov_lddline
			local _nwov_lddline = strtrim(subinstr(`"`_nwov_lddline'"', char(9), " ", .))
			local _nwov_lddmissing = (r(eof) == 0)
			file close `_nwov_lddh'
			if `_nwov_lddmissing' {
				di as text "{p 0 0 2}the native viewer cannot start: a WebKit library it needs is missing (`_nwov_lddline'). Install it with your package manager, for example{p_end}"
				di as text "{p 4 4 2}Debian/Ubuntu: {cmd:sudo apt install libwebkit2gtk-4.1-0}{p_end}"
				di as text "{p 4 4 2}Fedora/RHEL: {cmd:sudo dnf install webkit2gtk4.1}{p_end}"
				di as text "{p 4 4 2}Arch: {cmd:sudo pacman -S webkit2gtk-4.1}{p_end}"
				local _nwov_viewerpath ""
			}
		}
	}
	if "`output'" != "" & "`_nwov_viewerpath'" == "" {
		di as error "{p 0 0 2}the native viewer for this platform was not found; export() needs it. Reinstall the package.{p_end}"
		exit 601
	}
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
		// Random file names without disturbing the user's random-number
		// stream (a seed set before nwplot or nwmovie must still hold after).
		local _nwov_rngstate = c(rngstate)
		local _nwtd "`c(tmpdir)'"
		if substr("`_nwtd'", -1, 1) != "/" & substr("`_nwtd'", -1, 1) != "\" local _nwtd "`_nwtd'/"
		local _nwov_viewercopy = "`_nwtd'" + "nwedit_viewer_" + strofreal(int(runiform()*1000000))
		local _nwov_htmlcopy = "`_nwtd'" + "nwedit_view_" + strofreal(int(runiform()*1000000)) + ".html"
		set rngstate `_nwov_rngstate'
		// Windows: keep the .exe extension. CreateProcess appends ".exe" to a
		// name without an extension, so a copy without it is never found.
		if "`c(os)'" == "Windows" local _nwov_viewercopy "`_nwov_viewercopy'.exe"
		capture erase "`_nwov_viewercopy'"
		capture erase "`_nwov_htmlcopy'"
		capture copy "`_nwov_viewerpath'" "`_nwov_viewercopy'", replace
		local _nwov_copyrc1 = _rc
		capture copy "`htmlpath'" "`_nwov_htmlcopy'", replace
		local _nwov_copyrc2 = _rc
		if `_nwov_copyrc1' == 0 & `_nwov_copyrc2' == 0 {
			capture shell chmod +x "`_nwov_viewercopy'"
			capture winexec `_nwov_viewercopy' `_nwov_htmlcopy' `output'
			if _rc == 0 local _nwov_usedviewer = 1
		}
	}
	if !`_nwov_usedviewer' {
		// console Stata has no -view-: say where the file is
		if "`c(console)'" != "" {
			di as text "{p 0 0 2}open this file in a web browser: {it:`htmlpath'}{p_end}"
		}
		else view browse "`htmlpath'"
	}
	return local usedviewer = `_nwov_usedviewer'
	// the staged copy of the viewer binary, so that the caller can stop exactly this process (nwmovie export())
	if `_nwov_usedviewer' return local viewercopy `"`_nwov_viewercopy'"'
end
