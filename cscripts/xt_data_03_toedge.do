* xt_data_03_toedge.do
* nwtoedge and the round trip nwtoedge -> nwfromedge: directed, undirected, valued with negative and
* non-integer values, labels with blanks and non-ASCII letters, isolates, complete and empty networks, 1 and
* 2 nodes, a 2,001-node ring; the three routes (compress, full listing, full + compress); row counts of the
* listing; upper/full/numeric/egovars; several networks at once.
* Round trips compare node sets, flags and the matrix after putting the rebuilt network into the original node
* order by label (xt_reorder). Expected counts are derived by hand.
clear all
set more off
run cscripts/xt_data_00_helpers.do
xt_init xt_data_03_toedge
set seed 20261112

* xt_rt src route : rebuilds src from its edge list as network __xt_back and compares
*   route 1: nwtoedge, compress   (one row per undirected tie) + nwfromedge [undirected]
*   route 2: nwtoedge             (every dyad)                 + keep the ties + nwfromedge [undirected]
*   route 3: nwtoedge, full compress (both directions)         + nwfromedge without a direction option
capture program drop xt_rt
program xt_rt
	args src route pol
	quietly nwname `src'
	local labs0 `"`r(labs)'"'
	local dir0 "`r(directed)'"
	local val0 "`r(valued)'"
	local n0 = r(nodes)
	xt_mat `src' __xt_rt0
	if `route' == 1 capture noisily nwtoedge `src', compress
	if `route' == 2 capture noisily nwtoedge `src'
	if `route' == 3 capture noisily nwtoedge `src', full compress
	local rc = _rc
	* a 1-node network: nwtoedge, compress stops in Mata with r(3200)
	xt_chk `=(`rc' == 0)' "`src' route `route': nwtoedge runs (got `rc')" // was bug N2 (1-node network) (fixed)
	if `rc' != 0 {
		capture mata: mata drop __xt_rt0
		exit
	}
	quietly keep if `src' < . & `src' != 0
	local fe ""
	if "`dir0'" == "false" & `route' != 3 local fe "undirected"
	* a symmetric matrix declared directed (full) cannot be told from an undirected one by the edge list
	* (nwtoedge keeps no direction flag), so the directed flag is passed explicitly
	if "`dir0'" == "true" local fe "directed"
	if "`val0'" == "false" local fe "`fe' unvalued"
	capture noisily nwfromedge _ego _alter `src', name(__xt_back) `fe' replace
	local rc = _rc
	xt_chk `=(`rc' == 0)' "`pol'`src' route `route': rebuilt without error (got `rc')"
	if `rc' != 0 {
		capture mata: mata drop __xt_rt0
		exit
	}
	quietly nwname __xt_back
	local labs1 `"`r(labs)'"'
	xt_chk `=(r(nodes) == `n0')' "`src' route `route': `n0' nodes kept (got `r(nodes)')"
	xt_chk `=("`r(directed)'" == "`dir0'")' "`src' route `route': directed flag kept (`dir0', got `r(directed)')"
	xt_chk `=("`r(valued)'" == "`val0'")' "`src' route `route': valued flag kept (`val0', got `r(valued)')"
	mata: st_local("same", strofreal(xt_sorteq(st_local("labs0"), st_local("labs1"))))
	xt_chk `=("`same'" == "1")' "`src' route `route': same node labels"
	xt_mat __xt_back __xt_rt1
	mata: __xt_rt1 = xt_reorder(__xt_rt1, st_local("labs1"), st_local("labs0"))
	mata: st_local("eq", strofreal(__xt_rt1 == __xt_rt0))
	xt_chk `=("`eq'" == "1")' "`src' route `route': same ties and values"
	mata: mata drop __xt_rt0 __xt_rt1
	nwdrop __xt_back
end

* --- A. the networks
nwclear
mata: __xt_D = (runiform(10, 10) :< .3), J(10, 2, 0) \ J(2, 12, 0)
mata: _diag(__xt_D, 0)
nwset, mat(__xt_D) name(dir)
nwset, mat((0,-2,.5,0\-2,0,1.25,0\.5,1.25,0,0\0,0,0,0)) name(uval) undirected
nwset, mat((0,1,0,0\0,0,1,0\0,0,0,1\1,0,0,0)) name(lab) labs(Anna Maria,Zoë,Bob Smith,Ünal)
nwset, mat(J(5,5,1)) name(full)
nwset, mat(J(4,4,0)) name(empty)
nwset, mat((0,1\0,0)) name(two)
nwset, mat(0) name(one)
nwring 2001, k(1) undirected name(bigring)
foreach net in dir uval lab full two bigring {
	foreach route in 1 2 3 {
		if "`net'" == "bigring" & `route' == 2 continue
		xt_rt `net' `route'
	}
}
* networks without any tie: the isolates are only in the characteristic _dta[nwtoedge_nodes] of the edge
* list, which then has no rows. [policy] nwfromedge stops with r(2000) on an edge list without rows before it
* reads that node list; a failure of the checks below is that item.
foreach net in empty one {
	xt_rt `net' 1 "[policy] "
}
di "PASS A round trips"

* --- B. row counts of the full listing (no compress)
nwclear
nwset, mat((0,1,1\1,0,0\0,0,0)) name(d3)
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,0\1,0,0,0)) name(u4) undirected
nwtoedge d3
* the full listing has one row for every ordered pair incl. the diagonal (help: 1,000 nodes = 1,000,000 rows)
xt_chk `=(_N == 9)' "directed 3 nodes: n^2 = 9 rows (got `=_N')"
quietly summarize d3
xt_chk `=(r(sum) == 3)' "directed 3 nodes: 3 ties listed"
nwtoedge u4
xt_chk `=(_N == 10)' "undirected 4 nodes: one row per dyad incl. the diagonal, n(n+1)/2 = 10 (got `=_N')"
quietly summarize u4
xt_chk `=(r(sum) == 3)' "undirected 4 nodes: each of the 3 edges once"
nwtoedge u4, full
xt_chk `=(_N == 16)' "undirected 4 nodes, full: 16 rows (got `=_N')"
quietly summarize u4
xt_chk `=(r(sum) == 6)' "undirected, full: each edge twice"
nwtoedge d3, upper
xt_chk `=(_N == 9)' "upper on a directed network is suppressed: still 9 rows (got `=_N')"
nwtoedge d3, compress
quietly count if d3 < . & d3 != 0
xt_chk `=(r(N) == 3)' "compress: the 3 ties are listed"
quietly count if d3 == 0
xt_chk `=(r(N) == 0)' "compress: no row with value 0"
* two networks at once: one is directed, so full is forced for both
nwset, mat((0,0,1\0,0,1\1,1,0)) name(u3) undirected
nwtoedge d3 u3
xt_chk `=(_N == 9)' "d3 and u3 together: full forced, 9 rows (got `=_N')"
gen __lo = cond(_ego < _alter, _ego, _alter)
gen __hi = cond(_ego < _alter, _alter, _ego)
bysort __lo __hi (u3): gen byte __bad = (u3[_N] != u3[1])
quietly count if __bad
xt_chk `=(r(N) == 0)' "d3 and u3 together: the undirected values agree in both directions"
di "PASS B row counts"

* --- C. egovars/altervars carry the right node's attribute
nwclear
nwset, mat((0,1,1\1,0,0\0,0,0)) name(d3)
gen x = 10 * _n
quietly nwname d3
local labs `"`r(labs)'"'
nwtoedge d3, egovars(x) altervars(x)
gen __ie = .
gen __ia = .
local i 0
foreach l in `=subinstr(`"`labs'"', ",", " ", .)' {
	local ++i
	quietly replace __ie = `i' if _ego == "`l'"
	quietly replace __ia = `i' if _alter == "`l'"
}
quietly count if x_ego != 10 * __ie | x_alter != 10 * __ia
xt_chk `=(r(N) == 0)' "egovars/altervars: x_ego and x_alter belong to the ego and alter of the row"
di "PASS C egovars"

* --- D. numeric: ego and alter numbers agree with the tie value of the row
foreach net in d3 u4 {
	nwclear
	if "`net'" == "d3" nwset, mat((0,1,1\1,0,0\0,0,0)) name(d3)
	if "`net'" == "u4" nwset, mat((0,2,0,1\2,0,3,0\0,3,0,0\1,0,0,0)) name(u4) undirected
	nwtomata `net', mat(__xt_M)
	mata: __xt_M = editmissing(__xt_M, 0)
	nwtoedge `net', numeric
	capture confirm numeric variable _ego _alter
	xt_chk `=(_rc == 0)' "`net' numeric: _ego and _alter are numbers"
	mata: __xt_E = st_data(., ("_ego", "_alter", "`net'"))
	mata: st_local("bad", strofreal(xt_edgebad(__xt_M, __xt_E)))
	xt_chk `=("`bad'" == "0")' "`net' numeric: every row's value is the cell (ego, alter) (`bad' rows differ)" // was bug S9 (fixed)
}
* numeric with two networks is refused; the refusal must come before the data are replaced
nwclear
nwset, mat((0,1,1\1,0,0\0,0,0)) name(d3)
nwset, mat((0,0,1\0,0,1\1,1,0)) name(u3) undirected
gen keepme = _n
xt_snap d1
capture noisily nwtoedge d3 u3, numeric
xt_chk `=(_rc == 198)' "numeric with two networks: r(198) (got `=_rc')"
xt_same d1 "numeric with two networks" // was bug S9 (fixed)
di "PASS D numeric"

* --- E. nwtoedge leaves no stray r() and keeps e()
nwclear
nwset, mat((0,1\1,0)) name(e2)
xt_emark
xt_rmark
nwtoedge e2
xt_nostray "nwtoedge"
xt_chk `=(e(xtmark) == 17)' "nwtoedge: e() kept"
di "PASS E r()"

capture mata: mata drop __xt_D __xt_M __xt_E
xt_end
di "ALL PASS"
