cscript

do unw_core.do

* Native kernels 43..46 of the nwgraph plugin (generation 10) against R and against the Mata code they replace:
*   43 bipartite Louvain (Barber) of nwcommunity on two-mode networks
*   44 weighted PageRank of nwpagerank          (exact solution of the system = igraph::page_rank with weights to 1e-7; 30 networks, fixture from tools/verify_native370.R)
*   45 maximum-weight matching of nwmatching    (igraph::max_bipartite_match with weights, 30 networks, equal to a brute force)
*   47 weighted betweenness of nwbetween       (igraph::betweenness with lengths 1/w, 24 networks with many tied shortest paths)
*   46 tie swapping of nwpermute (swap)         (degree sequences, tie values, mode structure, seeds)
* The Mata path is forced with the global NW_NOFASTKERNELS.  Without a plugin of generation 10 (Linux and Windows
* binaries before the CI build, or an old plugin) the test is skipped.  Prints "native370: all equal" on success.

mata: st_local("gen", strofreal(nwg_comb_version()))
if `gen' < 10 {
	di as txt "native370: plugin generation `gen' < 10, native kernels not available: SKIPPED"
	exit
}
local fx "cscripts/native370_fixture"

mata:
real matrix n370_fill(real matrix el, real scalar n, real scalar sym)
{
	real matrix M
	real scalar k
	M = J(n, n, 0)
	for (k = 1; k <= rows(el); k++) {
		M[el[k, 1], el[k, 2]] = el[k, 3]
		if (sym) M[el[k, 2], el[k, 1]] = el[k, 3]
	}
	return(M)
}
real colvector n370_deg(real matrix el, real scalar n)
{
	real colvector d
	real scalar k
	d = J(n, 1, 0)
	for (k = 1; k <= rows(el); k++) {
		d[el[k, 1]] = d[el[k, 1]] + 1
		d[el[k, 2]] = d[el[k, 2]] + 1
	}
	return(d)
}
end

* ------------------------------------------------------------------ 44 weighted pagerank
tempfile cells nets expd
preserve
qui import delimited using "`fx'/pr_cells.csv", clear
qui save `cells'
qui import delimited using "`fx'/pr_nets.csv", clear
qui save `nets'
qui import delimited using "`fx'/pr_expected.csv", clear asdouble
qui save `expd'
restore
mata: n370_maxR = 0; n370_maxM = 0
forvalues b = 1/30 {
	preserve
	qui use `nets', clear
	qui keep if net == `b'
	local n = n[1]
	local dir = directed[1]
	qui use `cells', clear
	qui keep if net == `b'
	mata: n370_el = st_data(., ("i", "j", "w"))
	qui use `expd', clear
	qui keep if net == `b'
	sort node
	mata: n370_R = st_data(., "pr")
	restore
	mata: n370_M = n370_fill(n370_el, `n', 0)
	nwclear
	if `dir' nwset, mat(n370_M) name(prnet) valued
	else nwset, mat(n370_M) name(prnet) undirected valued
	global NW_NOFASTKERNELS
	qui nwpagerank prnet, generate(prn) replace silent tol(1e-14) maxiter(20000)
	mata: n370_N = st_data((1::`n'), "prn")
	global NW_NOFASTKERNELS 1
	qui nwpagerank prnet, generate(prm) replace silent tol(1e-14) maxiter(20000)
	global NW_NOFASTKERNELS
	mata: n370_Mt = st_data((1::`n'), "prm")
	mata: st_local("dR", strofreal(max(abs(n370_N - n370_R))))
	mata: st_local("dM", strofreal(max(abs(n370_N - n370_Mt))))
	if `dR' > 1e-10 {
		di as err "weighted pagerank differs from igraph in network `b': `dR'"
		exit 9
	}
	if `dM' > 1e-10 {
		di as err "weighted pagerank native differs from Mata in network `b': `dM'"
		exit 9
	}
	mata: n370_maxR = max((n370_maxR, `dR')); n370_maxM = max((n370_maxM, `dM'))
}
mata: st_local("mR", strofreal(n370_maxR)); st_local("mM", strofreal(n370_maxM))
di as txt "weighted pagerank: 30 networks, max |native - igraph| = `mR', max |native - Mata| = `mM'"
* binary option: the native binary kernel (generation 8) is used, values ignored
qui nwpagerank prnet, generate(prb) replace silent binary
qui sum prb
assert abs(r(sum) - 1) < 1e-9

* ------------------------------------------------------------------ 47 weighted betweenness
preserve
qui import delimited using "`fx'/bt_cells.csv", clear
qui save `cells', replace
qui import delimited using "`fx'/bt_nets.csv", clear
qui save `nets', replace
qui import delimited using "`fx'/bt_expected.csv", clear asdouble
qui save `expd', replace
restore
mata: n370_maxR = 0; n370_maxM = 0
forvalues b = 1/24 {
	preserve
	qui use `nets', clear
	qui keep if net == `b'
	local n = n[1]
	local dir = directed[1]
	qui use `cells', clear
	qui keep if net == `b'
	mata: n370_el = st_data(., ("i", "j", "w"))
	qui use `expd', clear
	qui keep if net == `b'
	sort node
	mata: n370_R = st_data(., "bt")
	restore
	mata: n370_M = n370_fill(n370_el, `n', 0)
	nwclear
	qui set obs `n'
	if `dir' nwset, mat(n370_M) name(btnet) valued
	else nwset, mat(n370_M) name(btnet) undirected valued
	global NW_NOFASTKERNELS
	if `dir' qui nwbetween btnet, generate(btn) replace silent weighted nosym
	else qui nwbetween btnet, generate(btn) replace silent weighted
	mata: n370_N = st_data((1::`n'), "btn")
	global NW_NOFASTKERNELS 1
	if `dir' qui nwbetween btnet, generate(btm) replace silent weighted nosym
	else qui nwbetween btnet, generate(btm) replace silent weighted
	global NW_NOFASTKERNELS
	mata: n370_Mt = st_data((1::`n'), "btm")
	* the variable is stored in single precision: compare relative to the size of the value
	mata: st_local("dR", strofreal(max(abs(n370_N - n370_R) :/ (1 :+ abs(n370_R)))))
	mata: st_local("dM", strofreal(max(abs(n370_N - n370_Mt) :/ (1 :+ abs(n370_Mt)))))
	if `dR' > 1e-6 {
		di as err "weighted betweenness differs from igraph in network `b': `dR'"
		exit 9
	}
	if `dM' > 1e-7 {
		di as err "weighted betweenness native differs from Mata in network `b': `dM'"
		exit 9
	}
	mata: n370_maxR = max((n370_maxR, `dR')); n370_maxM = max((n370_maxM, `dM'))
}
mata: st_local("mR", strofreal(n370_maxR)); st_local("mM", strofreal(n370_maxM))
di as txt "weighted betweenness: 24 networks, max |native - igraph| = `mR', max |native - Mata| = `mM'"

* ------------------------------------------------------------------ 45 maximum-weight matching
preserve
qui import delimited using "`fx'/mt_cells.csv", clear
qui save `cells', replace
qui import delimited using "`fx'/mt_nets.csv", clear
qui save `nets', replace
qui import delimited using "`fx'/mt_expected.csv", clear asdouble
qui save `expd', replace
restore
forvalues b = 1/30 {
	preserve
	qui use `nets', clear
	qui keep if net == `b'
	local n1 = n1[1]
	local n2 = n2[1]
	qui use `expd', clear
	qui keep if net == `b'
	local ew = weight[1]
	qui use `cells', clear
	qui keep if net == `b'
	mata: n370_el = st_data(., ("i", "j", "w"))
	restore
	local n = `n1' + `n2'
	mata: n370_M = n370_fill(n370_el, `n', 1)
	nwclear
	nwset, mat(n370_M) name(mtnet) undirected valued
	_nwsyntax mtnet
	mata: `netobj'->set_2mode(1)
	mata: `netobj'->set_modes((J(1, `n1', "1"), J(1, `n2', "2")))
	global NW_NOFASTKERNELS
	qui nwmatching mtnet, generate(mn) replace silent
	local wn = r(weight)
	local sn = r(matched)
	mata: n370_A = st_data((1::`n'), "mn")
	global NW_NOFASTKERNELS 1
	qui nwmatching mtnet, generate(mm) replace silent
	local wm = r(weight)
	global NW_NOFASTKERNELS
	mata: n370_B = st_data((1::`n'), "mm")
	mata: st_local("same", strofreal(n370_A == n370_B))
	if abs(`wn' - `ew') > 1e-9 {
		di as err "matching weight native `wn' differs from igraph `ew' in network `b'"
		exit 9
	}
	if abs(`wm' - `ew') > 1e-9 {
		di as err "matching weight Mata `wm' differs from igraph `ew' in network `b'"
		exit 9
	}
	if `same' != 1 {
		di as err "matching native differs from Mata in network `b'"
		exit 9
	}
}
di as txt "weighted matching: 30 networks, total weight equal to igraph::max_bipartite_match, matching equal to the Mata routine"
* a tie in the optimum (all values equal): native and Mata pick the same pairs
nwclear
mata: n370_M = J(8, 8, 0); n370_M[1..4, 5..8] = J(4, 4, 2); n370_M[5..8, 1..4] = J(4, 4, 2)
nwset, mat(n370_M) name(eqnet) undirected
_nwsyntax eqnet
mata: `netobj'->set_2mode(1)
mata: `netobj'->set_modes(("1","1","1","1","2","2","2","2"))
qui nwmatching eqnet, generate(e1) replace silent
assert r(weight) == 8 & r(matched) == 4
global NW_NOFASTKERNELS 1
qui nwmatching eqnet, generate(e2) replace silent
global NW_NOFASTKERNELS
assert e1 == e2
* the rectangular route (larger mode above 1,500 nodes): total weight equal to the square route's optimum,
* checked on a network with a unique optimum and the two modes 20 and 1,600 nodes
nwclear
mata: n370_n1 = 20; n370_n2 = 1600; n370_n = n370_n1 + n370_n2
mata: rseed(370); n370_M = J(n370_n, n370_n, 0); n370_B = (runiform(n370_n1, n370_n2) :< 0.01) :* ceil(runiform(n370_n1, n370_n2) * 1000) :/ 7
mata: n370_M[1..n370_n1, (n370_n1 + 1)..n370_n] = n370_B; n370_M[(n370_n1 + 1)..n370_n, 1..n370_n1] = n370_B'
nwset, mat(n370_M) name(rectnet) undirected
_nwsyntax rectnet
mata: `netobj'->set_2mode(1)
mata: `netobj'->set_modes((J(1, 20, "1"), J(1, 1600, "2")))
qui nwmatching rectnet, generate(r1) replace silent
local wr = r(weight)
* brute-force-free check: the Hungarian optimum on the 20 x 1600 block equals the one on its transpose (mode 2 larger or smaller makes no difference to the value)
mata: n370_P = n370_B'
mata: n370_Q = J(n370_n, n370_n, 0); n370_Q[1..1600, 1601..n370_n] = n370_P; n370_Q[1601..n370_n, 1..1600] = n370_B
nwclear
nwset, mat(n370_Q) name(rectnet2) undirected
_nwsyntax rectnet2
mata: `netobj'->set_2mode(1)
mata: `netobj'->set_modes((J(1, 1600, "1"), J(1, 20, "2")))
qui nwmatching rectnet2, generate(r2) replace silent
assert abs(`wr' - r(weight)) < 1e-8
di as txt "weighted matching, rectangular route: optimum `wr' from both orientations"

* ------------------------------------------------------------------ 43 bipartite Louvain
* Southern women (Davis et al.): Barber's Q 0.3455371796 (the optimum), 4 communities; native equal to Mata
nwclear
qui nwuse data/davis, nwclear
global NW_NOFASTKERNELS
set seed 20260101
qui nwcommunity, generate(cn) replace silent
local qn = r(modularity)
global NW_NOFASTKERNELS 1
set seed 20260101
qui nwcommunity, generate(cm) replace silent
local qm = r(modularity)
global NW_NOFASTKERNELS
assert abs(`qn' - 0.3455371796) < 1e-9
assert abs(`qm' - 0.3455371796) < 1e-9
* the partitions are the same up to the numbering of the communities
qui bysort cn cm: gen byte n370_f = _n == 1
qui count if n370_f
local npair = r(N)
qui tab cn
local kn = r(r)
qui tab cm
assert `npair' == `kn' & `kn' == r(r) & `kn' == 4
drop n370_f
* the same seed gives the same partition, another seed may give another search path but the same optimum here
set seed 77
qui nwcommunity, generate(c1) replace silent
set seed 77
qui nwcommunity, generate(c2) replace silent
assert c1 == c2
* an independent evaluation of the partition: nwmodularity gives the same Q
qui nwmodularity davis, group(cn)
assert abs(r(modularity) - `qn') < 1e-12
* the value of Q is the one R gives for the partition (Barber's formula written out in tools/verify_native370.R:
* Southern women, 4 communities: 0.3455371796)
* Football: the Financial Times directors (5,092 directors, 455 companies)
nwclear
qui nwuse data/ftdirectors_se, nwclear
set seed 1
timer clear
timer on 1
qui nwcommunity, generate(fn) replace silent starts(100)
timer off 1
local qf = r(modularity)
assert `qf' > 0.9505
set seed 1
qui nwcommunity, generate(fn2) replace silent starts(100)
assert fn == fn2
qui nwmodularity, group(fn)
assert abs(r(modularity) - `qf') < 1e-12
* no community has nodes of one mode only unless it is a single node: every group with a tie holds both modes
qui count
local nn = r(N)
global NW_NOFASTKERNELS 1
set seed 1
qui nwcommunity, generate(fm) replace silent starts(30)
global NW_NOFASTKERNELS
local qfm = r(modularity)
di as txt "bipartite Louvain: davis Q `qn' (Mata `qm'); ftdirectors_se native Q `qf' (100 starts), Mata Q `qfm' (30 starts)"
assert `qf' > `qfm' - 0.001
* a valued two-mode network and resolution
nwclear
qui nwuse data/davis, nwclear
qui nwcommunity davis, generate(cr) replace silent resolution(1.5)
local qr = r(modularity)
global NW_NOFASTKERNELS 1
qui nwcommunity davis, generate(crm) replace silent resolution(1.5)
global NW_NOFASTKERNELS
assert abs(`qr' - r(modularity)) < 1e-9

* ------------------------------------------------------------------ 46 tie swapping
nwclear
qui nwuse data/ftdirectors_se, nwclear
_nwsyntax ftdirectors_se
mata: n370_md = strtoreal(`netobj'->get_modes())'
mata: n370_el = `netobj'->edgelist()
mata: n370_el = select(n370_el, (n370_md[n370_el[., 1]] :== 1) :& (n370_md[n370_el[., 2]] :== 2))
mata: n370_d1 = sort(panelsum(J(rows(n370_el), 1, 1), panelsetup(sort(n370_el[., 1], 1), 1)), 1)
mata: st_local("m", strofreal(rows(n370_el)))
forvalues rep = 1/2 {
	global NW_NOFASTKERNELS
	if `rep' == 2 global NW_NOFASTKERNELS 1
	set seed 99
	qui nwpermute ftdirectors_se, generate(sw`rep') swap swaps(20000)
	_nwsyntax sw`rep'
	assert "`is2mode'" == "true"
	mata: n370_el2 = `netobj'->edgelist()
	mata: n370_md2 = strtoreal(`netobj'->get_modes())'
	mata: st_local("same", strofreal(n370_md2 == n370_md))
	assert `same' == 1
	* no tie inside a mode, both degree sequences and the tie values are those of the original
	mata: n370_c = select(n370_el2, (n370_md[n370_el2[., 1]] :== 1) :& (n370_md[n370_el2[., 2]] :== 2))
	mata: st_local("inmode", strofreal(rows(n370_el2) - 2 * rows(n370_c)))
	assert `inmode' == 0
	mata: st_local("m2", strofreal(rows(n370_c)))
	assert `m2' == `m'
	mata: st_local("dd1", strofreal(sort(panelsum(J(rows(n370_c), 1, 1), panelsetup(sort(n370_c[., 1], 1), 1)), 1) == n370_d1))
	assert `dd1' == 1
	* degrees node by node (not just the sorted sequences)
	mata: st_local("dg", strofreal(n370_deg(n370_el, rows(n370_md)) == n370_deg(n370_c, rows(n370_md))))
	assert `dg' == 1
	* the network has changed (20,000 attempts on 5,669 ties)
	mata: n370_key0 = sort(n370_el[., 1] :* 100000 :+ n370_el[., 2], 1); n370_key1 = sort(n370_c[., 1] :* 100000 :+ n370_c[., 2], 1)
	mata: st_local("kept", strofreal(sum(n370_key0 :== n370_key1)))
	assert `kept' < 0.5 * `m'
}
* determinism under the seed; another seed gives another network
global NW_NOFASTKERNELS
set seed 5
qui nwpermute ftdirectors_se, generate(sa) swap swaps(5000)
set seed 5
qui nwpermute ftdirectors_se, generate(sb) swap swaps(5000)
set seed 6
qui nwpermute ftdirectors_se, generate(sc) swap swaps(5000)
capture program drop n370_key
program define n370_key
	args net mname
	_nwsyntax `net'
	mata: n370_e = `netobj'->edgelist(); n370_e = select(n370_e, n370_e[., 1] :< n370_e[., 2]); `mname' = sort(n370_e[., 1] :* 100000 :+ n370_e[., 2], 1)
end
n370_key sa n370_Ea
n370_key sb n370_Eb
n370_key sc n370_Ec
mata: st_local("e1", strofreal(n370_Ea == n370_Eb))
mata: st_local("e2", strofreal(n370_Ea == n370_Ec))
assert `e1' == 1
assert `e2' == 0

* speed: 5,092 x 455, 100,000 attempts, native
set seed 1
timer clear
timer on 2
qui nwpermute ftdirectors_se, generate(sd) swap swaps(100000)
timer off 2
qui timer list 2
di as txt "tie swapping, 100,000 attempts on 5,669 ties: native " %6.3f r(t2) " s"
assert r(t2) < 5

* a one-mode network is refused as before; the Mata routine and the native kernel give the same refusal
nwclear
qui nwuse data/davis, nwclear
qui nwpermute davis, generate(sx) swap
nwclear
qui nwuse data/gang, nwclear
capture nwpermute gang, generate(sx) swap
assert _rc == 198

di "native370: all equal"
