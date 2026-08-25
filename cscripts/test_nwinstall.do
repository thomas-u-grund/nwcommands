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
di "=== nwinstall permanently/remove DATA-LOSS REGRESSION VERIFIED ==="
