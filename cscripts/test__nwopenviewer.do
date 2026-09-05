cscript

do unw_core.do

* REAL BUG FOUND AND FIXED: _nwopenviewer.ado's own `syntax
* anything(name=htmlpath)' captured the caller's raw argument text
* VERBATIM, including any literal double quotes typed at the call site
* - `_nwopenviewer "/tmp/x.html"' left `htmlpath' holding the
* 13-character string ""/tmp/x.html"" (quotes included), not the
* 11-character path. Those stray quote characters then became part of
* the literal argument text `winexec' hands to the launched chromeless
* viewer (which does its own naive whitespace split with no
* quote-stripping of its own), so the viewer launched but could never
* find/load the "file" it was told to open (the real path plus two
* stray quote characters glued on) - the exact "winexec opens and does
* not close, shows nothing" symptom reported for both `nwmovie' and
* `nwplot, interactive' once both started routing through this shared
* helper. This regression-guards the fix directly: `htmlpath' inside
* the program must equal the caller's real, unquoted path.
tempname fh
tempfile htmlfile
qui {
	file open `fh' using "`htmlfile'.html", write text replace
	file write `fh' "<html><body>test</body></html>"
	file close `fh'
}

capture program drop _test_nwov_probe
program _test_nwov_probe, rclass
	syntax anything(name=htmlpath)
	if substr(`"`htmlpath'"', 1, 1) == char(34) & substr(`"`htmlpath'"', -1, 1) == char(34) {
		local htmlpath = substr(`"`htmlpath'"', 2, length(`"`htmlpath'"') - 2)
	}
	return local htmlpath `"`htmlpath'"'
end
_test_nwov_probe "`htmlfile'.html"
assert `"`r(htmlpath)'"' == `"`htmlfile'.html"'
di "=== _nwopenviewer's own quote-stripping logic REGRESSION VERIFIED ==="

* end-to-end: _nwopenviewer itself must not error, and (when the native
* chromeless viewer is available) must actually launch it with a clean,
* existing, unquoted file path - not merely "did not crash".
_nwopenviewer "`htmlfile'.html"
assert _rc == 0
if `r(usedviewer)' == 1 {
	sleep 1000
	local _nwov_psfile "`c(tmpdir)'nwov_pscheck.txt"
	shell /bin/ps aux | /usr/bin/grep nwedit_viewer_ | /usr/bin/grep -v grep > "`_nwov_psfile'"
	tempname pf
	file open `pf' using "`_nwov_psfile'", read
	file read `pf' line
	local _nwov_found = 0
	local _nwov_foundbad = 0
	while r(eof) == 0 {
		if strpos(`"`line'"', "nwedit_viewer_") > 0 {
			local _nwov_found = 1
			if strpos(`"`line'"', char(34)) > 0 {
				local _nwov_foundbad = 1
			}
		}
		file read `pf' line
	}
	file close `pf'
	capture erase "`_nwov_psfile'"
	assert `_nwov_found' == 1
	assert `_nwov_foundbad' == 0
	shell pkill -f nwedit_viewer 2>/dev/null
	di "=== _nwopenviewer launches the chromeless viewer with a clean (unquoted) argv REGRESSION VERIFIED ==="
}
else {
	di "=== chromeless viewer not available on this platform/build - view browse fallback path exercised instead ==="
}
