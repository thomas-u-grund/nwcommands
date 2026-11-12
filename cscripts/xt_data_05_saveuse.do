* xt_data_05_saveuse.do
* nwsave / nwuse: round trip of a mixed set of networks (directed binary with isolates, undirected valued with
* negative and non-integer values, two-mode valued, labels with blanks and non-ASCII letters, one node,
* self-loops, a title) and of a node attribute; nwsave must not change the data or the networks in memory;
* the error paths of nwuse (data in memory, missing file, name in use) and of nwsave (file exists) must
* leave everything as it was; nwappend and force; set varabbrev off.
clear all
set more off
run cscripts/xt_data_00_helpers.do
xt_init xt_data_05_saveuse
set seed 20261112
tempfile f1 f2
local f1 = subinstr(`"`f1'"', ".tmp", "", .) + "_xtsave"
local f2 = subinstr(`"`f2'"', ".tmp", "", .) + "_xtsave2"

* --- A. build the set (xt_05_build noone: the same set without the 1-node network)
mata: __xt_D = (runiform(8, 8) :< .3), J(8, 2, 0) \ J(2, 10, 0)
mata: _diag(__xt_D, 0)
capture program drop xt_05_build
program xt_05_build
	args noone
	nwclear
	nwset, mat(__xt_D) name(dir)
	nwset, mat((0,-2,.5,0\-2,0,1.25,0\.5,1.25,0,0\0,0,0,0)) name(uval) undirected
	nwset, mat((0,1,0,0\0,0,1,0\0,0,0,1\1,0,0,0)) name(lab) labs(Anna Maria,Zoë,Bob Smith,Ünal)
	if "`noone'" == "" nwset, mat(0) name(one)
	nwset, mat((1,1\0,1)) name(loops) selfloop
	nwname dir, newtitle(My title)
	preserve
	clear
	* (input does not work inside a program)
	quietly set obs 3
	gen str8 person = cond(_n == 1, "Thomas", cond(_n == 2, "Peter", "Tim"))
	gen str8 org = cond(_n < 3, "Oxford", "LiU")
	gen v = _n
	nwset person org v, twomode name(aff)
	restore
	* restore undid the node rows that nwset added for aff; nwsave would add them again (via nwload), so the
	* rows are brought in line with the networks before the snapshot
	foreach n in dir uval lab loops aff {
		quietly nwload `n', labelonly
	}
	xt_snap a0
end
xt_05_build
* --- B. nwsave changes nothing in memory
capture noisily nwsave `"`f1'"', replace
* with a two-mode network in memory every network goes through nwtoedge, compress on its own, which stops in
* Mata (r(3200)) on the 1-node network one
xt_chk `=(_rc == 0)' "nwsave of the set with a two-mode and a 1-node network works (got `=_rc')" // was bug N2 (fixed)
if _rc != 0 {
	xt_same a0 "failed nwsave leaves the data as they were" // was bug N2 (fixed)
	describe, short
	xt_05_build noone
	nwsave `"`f1'"', replace
}
xt_same a0 "nwsave"
di "PASS B nwsave leaves memory alone"

* --- C. nwuse gives back the same networks
nwclear
nwuse `"`f1'"', nwclear
quietly nwset
local back "`r(nets)'"
xt_chk `=("`back'" == "${XT_a0_nets}")' "nwuse: the same networks in the same order (`back')"
local i 0
foreach n of global XT_a0_nets {
	local ++i
	xt_hasnet `n'
	if !`has' continue
	quietly nwname `n'
	local labs1 `"`r(labs)'"'
	local flags1 `"`r(nodes)'|`r(directed)'|`r(valued)'|`r(mode2)'|`r(selfloop)'|`r(nodes1)'"'
	local m0 `"${XT_a0_m`i'}"'
	local cut = strrpos(`"`m0'"', "|")
	local labs0 = substr(`"`m0'"', `cut' + 1, .)
	local flags0 = substr(`"`m0'"', 1, `cut' - 1)
	xt_chk `=(`"`flags1'"' == `"`flags0'"')' "nwuse `n': nodes and flags as saved (saved `flags0', got `flags1')"
	mata: st_local("same", strofreal(xt_sorteq(st_local("labs0"), st_local("labs1"))))
	xt_chk `=("`same'" == "1")' "nwuse `n': the same node labels"
	xt_chk `=(`"`labs1'"' == `"`labs0'"')' "[policy] nwuse `n': the nodes in the saved order (rows of node attributes depend on it; saved `labs0', got `labs1')"
	nwtomata `n', mat(__xt_X)
	mata: __xt_X = xt_reorder(__xt_X, st_local("labs1"), st_local("labs0"))
	mata: st_local("eq", strofreal(xt_od(__xt_X) == xt_od(__xt_a0_`i')))
	xt_chk `=("`eq'" == "1")' "nwuse `n': same ties and values"
}
* the diagonal of the selfloop network
xt_hasnet loops
if `has' {
	nwtomata loops, mat(__xt_X)
	mata: st_local("d", strofreal(__xt_X[1,1]) + "," + strofreal(__xt_X[2,2]))
	xt_chk `=("`d'" == "1,1")' "nwuse: the self-loops of a selfloop network are kept (got `d')" // was bug N5 (fixed)
}
quietly nwname dir
xt_chk `=("`r(title)'" == "My title")' "nwuse: title kept"
di "PASS C round trip"

* --- D. a node attribute survives
nwclear
nwset, mat((0,1,0\0,0,1\1,0,0)) name(cyc) labs(a,b,c)
gen double w = 1.5 * _n
nwsave `"`f2'"', replace
nwclear
nwuse `"`f2'"', nwclear
quietly summarize w
xt_chk `=(r(N) == 3 & r(sum) == 9)' "attribute w saved and loaded (3 values, sum 9)"
quietly count if (_nwnode == "a" & w != 1.5) | (_nwnode == "b" & w != 3) | (_nwnode == "c" & w != 4.5)
xt_chk `=(r(N) == 0)' "attribute w stays with its node"
di "PASS D attribute"

* --- E. error paths
nwclear
nwset, mat((0,1\1,0)) name(cyc)
gen keepme = _n
xt_snap e1
capture noisily nwuse `"`f2'"'
xt_chk `=(_rc == 999)' "nwuse with networks in memory and neither nwclear nor nwappend: r(999) (got `=_rc')"
xt_same e1 "nwuse refused (999)"
capture noisily nwuse `"`f2'_nosuchfile"', nwappend
xt_chk `=(_rc == 601)' "nwuse of a missing file: r(601) (got `=_rc')"
xt_same e1 "nwuse of a missing file with nwappend"
capture noisily nwuse `"`f2'"', nwappend
xt_chk `=(_rc == 483)' "nwuse nwappend, a network of the file is in memory: r(483) (got `=_rc')"
xt_same e1 "nwuse nwappend with a name in use"
capture noisily nwuse `"`f2'_nosuchfile"', nwclear
xt_chk `=(_rc == 601)' "nwuse nwclear of a missing file: r(601) (got `=_rc')"
xt_same e1 "[policy] nwuse nwclear of a missing file: nothing cleared before the file is found"
nwclear
nwset, mat((0,1\1,0)) name(cyc)
gen keepme = _n
xt_snap e2
capture noisily nwsave `"`f2'"'
xt_chk `=(_rc == 602)' "nwsave onto an existing file without replace: r(602) (got `=_rc')"
xt_same e2 "nwsave refused (602)"
di "PASS E errors"

* --- F. nwappend and force
nwclear
nwset, mat((0,1\0,0)) name(cyc)
nwuse `"`f2'"', nwappend force
quietly nwset
xt_chk `=(r(networks) == 2)' "nwappend force: both networks (got `r(nets)')"
xt_hasnet cyc_1
xt_chk `has' "nwappend force: the loaded network is renamed cyc_1"
nwclear
nwset, mat((0,1\0,0)) name(other)
nwuse `"`f2'"', nwappend
quietly nwset
xt_chk `=(strtrim("`r(nets)'") == "other cyc")' "nwappend: the loaded network is added after the one in memory"
di "PASS F nwappend"

* --- G. set varabbrev off (the code abbreviates _nw_selfloops to _nw_selfloop)
nwclear
nwset, mat((0,1\1,0)) name(va)
local vab = c(varabbrev)
set varabbrev off
capture noisily nwsave `"`f2'"', replace
local rc1 = _rc
capture noisily nwuse `"`f2'"', nwclear
local rc2 = _rc
set varabbrev `vab'
xt_chk `=(`rc1' == 0)' "nwsave works with set varabbrev off (got `rc1')" // was bug S22 (fixed)
xt_chk `=(`rc2' == 0)' "nwuse works with set varabbrev off (got `rc2')" // was bug S22 (fixed)
di "PASS G varabbrev"

capture erase `"`f1'.nwdta"'
capture erase `"`f2'.nwdta"'
capture mata: mata drop __xt_D __xt_X
xt_end
di "ALL PASS"
