cscript

* small370: (a) nwexport/nwimport keep the level labels of a two-mode network (Pajek, edge list, GML),
* (b) nwmixing prints no stray "invalid name" lines, (c) the help of nwsaom names no plugin protocol numbers (see the nwsaom repository).
* Run from the repository root.
clear all
set more off
qui do unw_core.do
global S_FAILS 0
capture program drop _chk
program _chk
	args ok label
	if `ok' {
		di "  ok:   `label'"
	}
	else {
		di as err "  FAIL: `label'"
		global S_FAILS = $S_FAILS + 1
	}
end

di "(a) level labels through the export formats"
clear
input str4 w str6 e
"anna" "party"
"anna" "dance"
"bob" "party"
"cleo" "dance"
"cleo" "choir"
end
tempfile affdata
save `affdata'
nwclear
use `affdata', clear
nw2fromedge w e, name(aff)
nwname aff, newmode1desc("women") newmode2desc("events")
nwsummarize aff
_chk `=("`r(mode1_desc)'" == "women" & "`r(mode2_desc)'" == "events")' "start: labels women / events"
tempfile base
foreach t in pajek edgelist gml ucinet {
	local ext = cond("`t'" == "pajek", "net", cond("`t'" == "ucinet", "dl", cond("`t'" == "gml", "gml", "txt")))
	nwexport aff, type(`t') fname("`base'_`t'") replace
	nwimport "`base'_`t'.`ext'", type(`t') name(b_`t') nwappend
	nwsummarize b_`t'
	_chk `=("`r(mode2)'" == "true" & r(edges) == 5 & r(nodes1) == 3 & r(nodes2) == 3)' "`t': two-mode, 5 ties, 3 + 3 nodes"
	if "`t'" != "ucinet" {
		_chk `=("`r(mode1_desc)'" == "women" & "`r(mode2_desc)'" == "events")' "`t': the level labels come back"
	}
	else {
		* UCINET DL has no place for the names of the modes: the defaults
		_chk `=("`r(mode1_desc)'" == "rows" & "`r(mode2_desc)'" == "columns")' "ucinet: the default level labels rows / columns (the format carries none)"
	}
}
* the file contents
file open fh using "`base'_pajek.net", read text
file read fh line
file close fh
_chk `=(strpos(`"`line'"', "women") > 0 & substr(`"`line'"', 1, 1) == "%")' "Pajek: a comment line with the labels comes first"
file open fh using "`base'_gml.gml", read text
local found 0
file read fh line
while r(eof) == 0 {
	if strpos(`"`line'"', "nwmodelabel2") & strpos(`"`line'"', "events") local found 1
	file read fh line
}
file close fh
_chk `found' "GML: graph attribute nwmodelabel2"
import delimited using "`base'_edgelist.txt", clear delimiter(tab) varnames(nonames) stringcols(_all)
_chk `=(v4[1] == "women" & v5[1] == "events")' "edge list: the columns mode_ego and mode_alter hold the level labels"
* default labels ("mode 1" / "mode 2", as a network read from a file that carries none): the numbers 1 and 2
nwname aff, newmode1desc("mode 1") newmode2desc("mode 2")
nwexport aff, type(edgelist) fname("`base'_def") replace
import delimited using "`base'_def.txt", clear delimiter(tab) varnames(nonames)
_chk `=(v4[1] == 1 & v5[1] == 2)' "edge list: default labels are written as the numbers 1 and 2"

di "(b) nwmixing: no stray 'invalid name'"
nwclear
clear
set seed 1
nwrandom 8, prob(.3) undirected name(g)
gen grp = mod(_n, 2)
log using "`c(tmpdir)'/small370_mix.log", text replace
nwmixing g, attribute(grp) permutations(20)
log close
mata: st_local("bad", strofreal(any(regexm(cat("`c(tmpdir)'/small370_mix.log"), "invalid name"))))
_chk `=(`bad' == 0)' "nwmixing prints no 'invalid name'"

if $S_FAILS > 0 {
	di as err "test_small370: $S_FAILS check(s) failed"
	exit 9
}
di "test_small370: all passed"
