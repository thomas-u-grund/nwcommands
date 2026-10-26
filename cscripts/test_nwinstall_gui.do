* nwinstall: the "Network Analysis" menu and the profile.do line are never created twice.
* Everything runs in scratch folders (PLUS, PERSONAL, path(), cwd); the real profile.do, PLUS and PERSONAL are not touched.
* No download: gui, usermenu and remove work on local files only.
cscript
capture program drop nwinstall
clear all
set linesize 240

tempfile marker
local scratch = subinstr("`marker'", "St", "nwgui_", 1) + "_dir"
capture mkdir "`scratch'"
foreach d in plus personal prof prof2 prof3 run {
	capture mkdir "`scratch'/`d'"
}
local core "`c(pwd)'"
sysdir set PLUS "`scratch'/plus"
sysdir set PERSONAL "`scratch'/personal"
cd "`scratch'/run"
adopath ++ "`core'"

capture program drop tn
program tn, rclass
	// number of lines of a file that equal a string (after strtrim), and the total number of lines
	syntax , file(string) [like(string)]
	tempname h
	local n = 0
	local tot = 0
	capture file open `h' using `"`file'"', read text
	if _rc == 0 {
		file read `h' line
		while r(eof) == 0 {
			local ++tot
			if `"`like'"' != "" & strtrim(`"`line'"') == `"`like'"' local ++n
			file read `h' line
		}
		file close `h'
	}
	return scalar n = `n'
	return scalar tot = `tot'
end
capture program drop tw
program tw
	// write the lines (each a quoted string) to a file
	syntax , file(string) lines(string)
	tempname h
	file open `h' using `"`file'"', write text replace
	foreach l of local lines {
		file write `h' `"`l'"' _n
	}
	file close `h'
end
capture program drop tsum
program tsum, rclass
	syntax , file(string)
	qui checksum `"`file'"'
	return scalar sum = r(checksum)
	return scalar len = r(filelen)
end

* ---- 1. gui twice in a row: exactly one line --------------------------
local p "`scratch'/prof"
nwinstall, gui path("`p'")
nwinstall, gui path("`p'")
nwinstall, usermenu
nwinstall, usermenu
tn, file("`p'/profile.do") like("nwinstall, usermenu")
assert r(n) == 1 & r(tot) == 1

* ---- 2. older line "nwinstall, downloadoff" counts as the same line --
tw, file("`p'/profile.do") lines(`" "nwinstall, downloadoff" "')
tsum, file("`p'/profile.do")
local s0 = r(sum)
nwinstall, gui path("`p'")
tsum, file("`p'/profile.do")
assert r(sum) == `s0'
tn, file("`p'/profile.do")
assert r(tot) == 1

* ---- 3. duplicated lines (both spellings, odd spacing) collapse to one; the rest is kept
tw, file("`p'/profile.do") lines(`" "* mine" "nwinstall,usermenu" "global a 1" "  nwinstall, downloadoff  " "quietly nwinstall, usermenu" "set more off" "')
nwinstall, gui path("`p'")
tn, file("`p'/profile.do")
assert r(tot) == 4
tw, file("`p'/exp.do") lines(`" "* mine" "nwinstall,usermenu" "global a 1" "set more off" "')
tsum, file("`p'/exp.do")
local e = r(sum)
tsum, file("`p'/profile.do")
assert r(sum) == `e'

* ---- 4. unrelated profile.do: kept byte for byte, plus our one line
tw, file("`p'/profile.do") lines(`" "* my profile" "global x "a b"" "display "100%"" "set more off" "')
tw, file("`p'/exp.do") lines(`" "* my profile" "global x "a b"" "display "100%"" "set more off" "nwinstall, usermenu" "')
nwinstall, gui path("`p'")
tsum, file("`p'/exp.do")
local e = r(sum)
tsum, file("`p'/profile.do")
assert r(sum) == `e'
nwinstall, gui path("`p'")
tsum, file("`p'/profile.do")
assert r(sum) == `e'

* ---- 5. remove: our line goes, the rest stays; a second remove changes nothing
nwinstall, remove path("`p'")
tw, file("`p'/exp.do") lines(`" "* my profile" "global x "a b"" "display "100%"" "set more off" "')
tsum, file("`p'/exp.do")
local e = r(sum)
tsum, file("`p'/profile.do")
assert r(sum) == `e'
nwinstall, remove path("`p'")
tsum, file("`p'/profile.do")
assert r(sum) == `e'
capture confirm file "`p'/profile.do.nwinstall_bak"
assert _rc != 0
capture confirm file "`p'/profile_nwinstall.tmp"
assert _rc != 0

* ---- 6. a menu line of another origin: nothing is added (and remove leaves it alone)
local p2 "`scratch'/prof2"
tw, file("`p2'/profile.do") lines(`" "set more off" `"window menu append submenu "stUser" "Network Analysis""' "')
tsum, file("`p2'/profile.do")
local e = r(sum)
nwinstall, gui path("`p2'")
tsum, file("`p2'/profile.do")
assert r(sum) == `e'
nwinstall, remove path("`p2'")
tsum, file("`p2'/profile.do")
assert r(sum) == `e'
tw, file("`p2'/profile.do") lines(`" "nw_menu" "')
tsum, file("`p2'/profile.do")
local e = r(sum)
nwinstall, gui path("`p2'")
tsum, file("`p2'/profile.do")
assert r(sum) == `e'

* ---- 7. the old nwcommands 1.1.x line (that do-file no longer exists): kept, ours added once; remove takes both out
tw, file("`p2'/profile.do") lines(`" "run nwinstall_dlg.do" "')
nwinstall, gui path("`p2'")
nwinstall, gui path("`p2'")
tn, file("`p2'/profile.do") like("nwinstall, usermenu")
assert r(n) == 1 & r(tot) == 2
nwinstall, remove path("`p2'")
tn, file("`p2'/profile.do")
assert r(tot) == 0

* ---- 8. a menu line in ANOTHER profile.do that Stata reads (PERSONAL): no second line, no new file
local p3 "`scratch'/prof3"
tw, file("`scratch'/personal/profile.do") lines(`" "nwinstall, downloadoff" "')
nwinstall, gui path("`p3'")
capture confirm file "`p3'/profile.do"
assert _rc != 0
* with an existing target file lacking the line: also not added
tw, file("`p3'/profile.do") lines(`" "set more off" "')
tsum, file("`p3'/profile.do")
local e = r(sum)
nwinstall, gui path("`p3'")
tsum, file("`p3'/profile.do")
assert r(sum) == `e'
erase "`scratch'/personal/profile.do"
nwinstall, gui path("`p3'")
tn, file("`p3'/profile.do") like("nwinstall, usermenu")
assert r(n) == 1

* ---- 9. a failed edit leaves the original unchanged and the session alive
nwinstall, remove path("`p3'")
tw, file("`p3'/profile.do") lines(`" "set more off" "')
tsum, file("`p3'/profile.do")
local e = r(sum)
mkdir "`p3'/profile_nwinstall.tmp"
nwinstall, gui path("`p3'")
tsum, file("`p3'/profile.do")
assert r(sum) == `e'
rmdir "`p3'/profile_nwinstall.tmp"

* ---- 10. nogui is only for all and everything
capture nwinstall, nogui
assert _rc == 198
capture nwinstall, gui nogui all
assert _rc == 198

* ---- 11. the menu program: every submenu and every item is appended once (static check of nwinstall.ado)
findfile nwinstall.ado
local ado `"`r(fn)'"'
* backticks and apostrophes of the source would be read as macro quotes: replace them in a copy first
tempfile c1 c2
qui filefilter `"`ado'"' `"`c1'"', from("\LQ") to("_") replace
qui filefilter `"`c1'"' `"`c2'"', from("\RQ") to("_") replace
tempname h
file open `h' using `"`c2'"', read text
file read `h' line
local inmenu 0
local nsub 0
local nitem 0
local dupsub ""
local dupitem ""
local subs ""
local items ""
while r(eof) == 0 {
	if `inmenu' & substr(`"`line'"', 1, 3) == "end" local inmenu 0
	if strpos(`"`line'"', "program nwinstall_menu") == 1 local inmenu 1
	if `inmenu' {
		if regexm(`"`line'"', `"window menu append submenu "[^"]+" "([^"]+)""') {
			local t = regexs(1)
			if strpos(`"`subs'"', char(1) + `"`t'"' + char(1)) local dupsub `"`dupsub' `t'"'
			local subs `"`subs'`=char(1)'`t'`=char(1)'"'
			local ++nsub
		}
		if regexm(`"`line'"', `"window menu append item "([^"]+)" "([^"]+)" "([^"]+)""') {
			local k = regexs(1) + "|" + regexs(2)
			if strpos(`"`items'"', char(1) + `"`k'"' + char(1)) local dupitem `"`dupitem' `k'"'
			local items `"`items'`=char(1)'`k'`=char(1)'"'
			local ++nitem
		}
	}
	file read `h' line
}
file close `h'
assert `nsub' > 10 & `nitem' > 100
assert `"`dupsub'"' == "" & `"`dupitem'"' == ""
di "menu: `nsub' submenus, `nitem' fixed items, no title twice"

* ---- 12. the menu is rebuilt, not appended, in the same session (usermenu / update twice: no error, same call path)
nwinstall, usermenu
nwinstall, usermenu menu("stUser")
nwinstall, downloadoff

* ---- 13. dialog duplicates scan finds a planted second copy, and deletes nothing
* (the repository folder itself is taken off the ado path here; nwinstall is already loaded)
adopath - "`core'"
capture mkdir "`scratch'/plus/n"
copy "`core'/nwplot.dlg" "`scratch'/plus/n/nwplot.dlg", replace
nwinstall, dupcheck
assert r(ndup) == 0
copy "`core'/nwplot.dlg" "`scratch'/personal/nwplot.dlg", replace
nwinstall, dupcheck
assert r(ndup) == 1
capture confirm file "`scratch'/personal/nwplot.dlg"
assert _rc == 0
capture confirm file "`scratch'/plus/n/nwplot.dlg"
assert _rc == 0

* the real profile.do was never the target
assert strpos(`"`scratch'"', "Documents/Stata") == 0

display "NWINSTALL_GUI_OK (Stata " c(stata_version) ")"
