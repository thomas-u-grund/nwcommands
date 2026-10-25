cscript

do unw_core.do

* nwsave of a two-mode network writes only the ties between the modes (it
* used to write every dyad inside each mode as well: 2.6 GB for a 5,092 x
* 455 network), and nwuse reads it back to an identical network. Old files
* (all dyads) still load; nwtoedge, compress lists only the cross ties.

capture mata: mata drop __snap_*
capture program drop _snap
program _snap
	args n tag
	_nwsyntax `n', other(other)
	nwtomata `n', mat(__M)
	mata: __snap_M_`tag' = __M
	mata: __snap_L_`tag' = `othernetobj'->get_nodenames_string()
	mata: __snap_O_`tag' = `othernetobj'->get_modes_labeled_string()
	mata: mata drop __M
	nwname `n'
	local fl "`r(mode2)' `r(directed)' `r(valued)' `r(nodes)'"
	global snapflags_`tag' `"`fl'"'
end

capture program drop _samesnap
program _samesnap
	args tag1 tag2
	assert `"${snapflags_`tag1'}"' == `"${snapflags_`tag2'}"'
	mata: assert(__snap_L_`tag1' == __snap_L_`tag2')
	mata: assert(__snap_O_`tag1' == __snap_O_`tag2')
	// (a reloaded two-mode network holds 0 where the original held a missing value inside a mode)
	mata: assert(mreldif(editmissing(__snap_M_`tag1', 0), editmissing(__snap_M_`tag2', 0)) == 0)
end

tempfile f1 f2 f3 attr1

* --- a small two-mode network with node attributes
nwclear
clear
input str10 person str10 org
"Thomas" "Oxford"
"Peter" "Oxford"
"Tim" "Oxford"
"Peter" "LiU"
"Tim" "LiU"
"Thomas" "LiU"
"Anna" "Zeta"
"Tim" "Zeta"
end
nwset person org, twomode name(two)
gen double score = _n * 1.5 in 1/7
gen str6 kind = cond(_n <= 4, "human", "place") in 1/7
_snap two A
preserve
keep _nwnode score kind
keep if _nwnode != ""
sort _nwnode
save `attr1'
restore

* nwtoedge, compress lists only the 8 ties
nwtoedge two, compress
assert _N == 8
nwclear
clear
input str10 person str10 org
"Thomas" "Oxford"
"Peter" "Oxford"
"Tim" "Oxford"
"Peter" "LiU"
"Tim" "LiU"
"Thomas" "LiU"
"Anna" "Zeta"
"Tim" "Zeta"
end
nwset person org, twomode name(two)
gen double score = _n * 1.5 in 1/7
gen str6 kind = cond(_n <= 4, "human", "place") in 1/7

* the saved file holds the node rows and the 8 ties, not every dyad
nwsave `f1', replace
use `f1'.nwdta, clear
assert _N == 8   // node rows and tie rows share rows: max(7 nodes, 8 ties)
nwclear
nwuse `f1', nwclear
_snap two B
_samesnap A B
keep _nwnode score kind
keep if _nwnode != ""
sort _nwnode
cf _all using `attr1'

* --- a file with a two-mode and a one-mode network
nwclear
clear
input str10 person str10 org
"Thomas" "Oxford"
"Peter" "Oxford"
"Peter" "LiU"
"Tim" "LiU"
end
nwset person org, twomode name(two)
nwrandom 6, prob(.5) name(one)
_snap two A2
_snap one A1
nwsave `f2', replace
nwclear
nwuse `f2', nwclear
_snap two B2
_snap one B1
_samesnap A2 B2
_samesnap A1 B1

* --- random two-mode networks, several sizes
foreach dims in "5 3 .5" "40 12 .2" "60 60 .05" "30 80 .9" {
	tokenize `dims'
	nwclear
	clear
	set seed 4242
	local n1 `1'
	local n2 `2'
	local p `3'
	set obs `=`n1'*`n2''
	gen int a = mod(_n - 1, `n1') + 1
	gen int b = ceil(_n / `n1')
	keep if runiform() < `p'
	if _N == 0 {
		set obs 1
		replace a = 1
		replace b = 1
	}
	gen str8 pa = "p" + string(a)
	gen str8 ob = "o" + string(b)
	local nt = _N
	nwset pa ob, twomode name(rnd)
	_snap rnd R1
	nwsave `f3', replace
	use `f3'.nwdta, clear
	assert _N <= max(`n1' + `n2', `nt')
	nwclear
	nwuse `f3', nwclear
	_snap rnd R2
	_samesnap R1 R2
}

* --- a file written by the previous nwsave (every dyad) still loads
nwclear
nwuse cscripts/twomode_old_format, nwclear
nwname oldtwo
assert "`r(mode2)'" == "true"
assert r(nodes) == 7
nwtomata oldtwo, mat(__oldM)
mata: assert(sum(editmissing(__oldM, 0)) == 2 * 8)
mata: mata drop __oldM
nwname oldone
assert r(nodes) == 5

* --- the new file is nwappend-able
nwclear
nwset, mat((0,1\1,0)) name(other) undirected labs(a,b)
nwappend using `f1'
nwname two
assert "`r(mode2)'" == "true"

* --- a large two-mode network stays small on disk (all within-mode
* dyads would be 1,000,000+ rows)
nwclear
clear
set seed 11
set obs 4000
gen int a = ceil(runiform() * 1000)
gen int b = ceil(runiform() * 150)
duplicates drop a b, force
gen str8 pa = "p" + string(a)
gen str8 ob = "o" + string(b)
local nt = _N
nwset pa ob, twomode name(big)
nwsave `f3', replace
use `f3'.nwdta, clear
assert _N <= max(1150, `nt')

display "PASS test_twomode_save"
