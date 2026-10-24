cscript

do unw_core.do

* nwinstall's `permanently'/`remove' path had no test coverage at all
* before this (understandably harder to test given real filesystem
* side effects) - and the alpha audit found a real, critical bug hiding
* behind that gap: on Mac (and, since no Unix branch existed at all,
* presumably Linux), `nwinstall, remove' (which internally forces
* `permanently') PERMANENTLY DELETED the user's profile.do without ever
* writing the filtered replacement back. Root cause: the temp file was
* opened with a literal backslash in its path ("`path'\profile_temp.do"
* - not a path separator on Mac/Linux, so this actually created a
* stray, wrongly-named file one directory ABOVE `path'), and the
* subsequent `mv' sourced from c(sysdir_stata) - a completely different
* location than where the temp file was actually written - so the move
* always failed silently (via `shell', which does not propagate the
* underlying command's own exit code to _rc) after the original
* profile.do had already been unconditionally erased. Net effect:
* silent, total data loss, with rc=0 throughout.
*
* This test exercises the full permanently -> remove cycle entirely
* inside a throwaway scratch directory (never touching the real Stata
* profile.do), confirming the file survives with its correctly-filtered
* content, matching what `remove' is actually supposed to produce (the
* only line ever written by `permanently' - "nwinstall, usermenu" - is
* the one line `remove' is meant to filter back out, so the correctly
* fixed result is an existing, empty profile.do, not a missing one).

tempfile scratchmarker
local scratchdir = subinstr("`scratchmarker'", "S_", "nwinstall_test_", 1)
capture mkdir "`scratchdir'"
assert _rc == 0

nwinstall, permanently path("`scratchdir'")
capture confirm file "`scratchdir'/profile.do"
assert _rc == 0

nwinstall, remove path("`scratchdir'")
assert _rc == 0

* the real regression guard: profile.do must still EXIST after remove
* (previously: permanently deleted, never recreated).
capture confirm file "`scratchdir'/profile.do"
assert _rc == 0

* and its content must be correctly filtered - the one line permanently
* wrote ("nwinstall, usermenu") is exactly the line remove is meant to
* strip back out, so the file should now be empty.
tempname fh
file open `fh' using "`scratchdir'/profile.do", read
file read `fh' line
assert r(eof) == 1
file close `fh'

erase "`scratchdir'/profile.do"
capture rmdir "`scratchdir'"

capture program drop tcountlines
program tcountlines, rclass
	syntax , file(string)
	tempname h
	local n = 0
	capture file open `h' using `"`file'"', read text
	return scalar rc = _rc
	if _rc == 0 {
		file read `h' line
		while r(eof) == 0 {
			local ++n
			file read `h' line
		}
		file close `h'
	}
	return scalar n = `n'
end

* ---- second data-loss mode (fixed in 3.1.1) --------------------------
* The Mac/Unix edit used `shell ... PATH="...`c(adopath)'..."; mv ...'.
* c(adopath) holds compound-quoted entries after `adopath ++ "dir"',
* which unbalanced the shell quote ("zsh: unmatched \""), mv never ran,
* and the original profile.do had already been erased. The edit no longer
* uses the shell. Reproduce the trigger (quoted adopath entry, a path with
* spaces), and check that an existing profile.do with the user's own
* content survives, that `gui' and `permanently' give the same result, and
* that a failing edit leaves the original untouched.
local base "`scratchdir'_sp ace"
capture mkdir "`base'"
assert _rc == 0
adopath ++ "`base'"
assert strpos(`"`c(adopath)'"', char(96) + char(34)) > 0
local pf "`base'/profile.do"

* the user's own profile.do with content that is awkward for macros
tempname fh
file open `fh' using "`pf'", write text replace
file write `fh' `"* my profile"' _n `"global x "a b""' _n `"display "100%""' _n
file write `fh' `"nwinstall, usermenu"' _n `"set more off"' _n
file close `fh'

nwinstall, remove path("`base'")
capture confirm file "`pf'"
assert _rc == 0
tcountlines, file("`pf'")
assert r(rc) == 0 & r(n) == 4
file open `fh' using "`pf'", read text
file read `fh' line
assert `"`line'"' == "* my profile"
file read `fh' line
assert `"`line'"' == `"global x "a b""'
file read `fh' line
assert `"`line'"' == `"display "100%""'
file read `fh' line
assert `"`line'"' == "set more off"
file close `fh'
capture confirm file "`base'/profile_nwinstall.tmp"
assert _rc != 0
capture confirm file "`pf'.nwinstall_bak"
assert _rc != 0

* gui and permanently give the same result (appended once, not twice)
copy "`pf'" "`base'/orig.do", replace
nwinstall, gui path("`base'")
copy "`pf'" "`base'/gui.do", replace
copy "`base'/orig.do" "`pf'", replace
nwinstall, permanently path("`base'")
copy "`pf'" "`base'/perm.do", replace
tcountlines, file("`base'/gui.do")
assert r(n) == 5
tcountlines, file("`base'/perm.do")
assert r(n) == 5
nwinstall, permanently path("`base'")
tcountlines, file("`pf'")
assert r(n) == 5
nwinstall, gui remove path("`base'")
tcountlines, file("`pf'")
assert r(n) == 4

* a failing edit must leave the original byte-for-byte as it was:
* block the temp file name with a directory
copy "`pf'" "`base'/before.do", replace
nwinstall, permanently path("`base'")
copy "`pf'" "`base'/before.do", replace
mkdir "`base'/profile_nwinstall.tmp"
nwinstall, remove path("`base'")
capture confirm file "`pf'"
assert _rc == 0
tcountlines, file("`pf'")
assert r(n) == 5
rmdir "`base'/profile_nwinstall.tmp"

* missing profile.do: remove does nothing and creates nothing
foreach f in profile.do orig.do gui.do perm.do before.do {
	capture erase "`base'/`f'"
}
nwinstall, remove path("`base'")
capture confirm file "`pf'"
assert _rc != 0
adopath - "`base'"
capture rmdir "`base'"

di "=== nwinstall permanently/remove DATA-LOSS REGRESSION VERIFIED ==="
