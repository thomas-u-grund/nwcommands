cscript
nwclear

do unw_core.do

* nwfromedge at scale, and exact agreement with the dense definition.
*
* Part 1: a 60,000-node / ~300,000-tie directed edge list must build, and be
* analysed by the sparse-native commands, WITHOUT ever allocating the dense
* N x N matrix and without any over-long macro (Stata/BE caps a macro at
* 264,408 characters; 60,000 node labels alone are ~400,000).  The dense
* guard refuses networks above 20,000 nodes, so a dense build would also
* show up as r(484).
* Part 2: for random small edge lists (isolates only seen in self-loops,
* self-loops, duplicate rows, zero and valued weights, symmetric and
* asymmetric input) the sparse construction, the symmetric-detection and
* the symmetrization give exactly the adjacency a plain cell-by-cell dense
* fill (the pre-sparse definition) gives.

* ---------------------------------------------------------------- Part 1
local n 60000
clear
set seed 20261024
set obs `=5*`n''
gen long from = ceil(runiform()*`n')
gen long to = ceil(runiform()*`n')
drop if from == to
duplicates drop from to, force
local ties = _N
* distinct node ids that occur
preserve
stack from to, into(id) clear
bysort id: keep if _n == 1
local distinct = _N
restore
* expected undirected pair count
preserve
gen long lo = min(from, to)
gen long hi = max(from, to)
duplicates drop lo hi, force
local pairs = _N
restore

timer clear 1
timer on 1
nwfromedge from to, name(big) directed
timer off 1
quietly timer list 1
display "nwfromedge, `distinct' nodes, `ties' ties: " r(t1) " s"
assert r(t1) < 60

mata: bigp = __nw.nws.pdefs[__nw.nws.get_index_of("big")]
mata: st_numscalar("isdense", bigp->is_dense_built())
assert scalar(isdense) == 0
mata: st_numscalar("bn", bigp->get_nodes())
assert scalar(bn) == `distinct'

* degrees / components / neighbours / clustering-free checks, all sparse-native
nwdegree big, generate(od id) silent
quietly summarize od
assert r(sum) == `ties'
quietly summarize id
assert r(sum) == `ties'
nwcomponents big, generate(comp) silent
assert r(components) >= 1
nwneighbor big, ego(n1) generate(nb) replace
mata: st_numscalar("isdense", bigp->is_dense_built())
assert scalar(isdense) == 0
display "name/label commands on a big network (no long macro):"
nwname big
assert r(nodes) == `distinct'
assert `"`r(labs)'"' == ""
_nwnodelab big, nodeid(2)
assert `"`r(nodelab)'"' != ""
mata: st_numscalar("isdense", bigp->is_dense_built())
assert scalar(isdense) == 0

* default (no directed option) detection on an asymmetric list keeps it
* directed, still without a dense matrix
clear
set seed 20261024
set obs `=5*`n''
gen long from = ceil(runiform()*`n')
gen long to = ceil(runiform()*`n')
drop if from == to
duplicates drop from to, force
nwfromedge from to, name(big2)
nwname big2
assert "`r(directed)'" == "true"
mata: bigp2 = __nw.nws.pdefs[__nw.nws.get_index_of("big2")]
mata: st_numscalar("isdense", bigp2->is_dense_built())
assert scalar(isdense) == 0

* forceundirected symmetrizes on the sparse triplets
clear
set seed 20261024
set obs `=5*`n''
gen long from = ceil(runiform()*`n')
gen long to = ceil(runiform()*`n')
drop if from == to
duplicates drop from to, force
nwfromedge from to, name(big3) forceundirected
nwname big3
assert "`r(directed)'" == "false"
mata: bigp3 = __nw.nws.pdefs[__nw.nws.get_index_of("big3")]
mata: st_numscalar("isdense", bigp3->is_dense_built())
assert scalar(isdense) == 0
nwdegree big3, generate(deg) silent
quietly summarize deg
assert r(sum) == 2*`pairs'
nwclear

* ---------------------------------------------------------------- Part 2
capture mata: mata drop nwfe_ref()
mata:
// reference: plain dense fill, last row wins, 0 = no tie, diagonal blanked
real matrix nwfe_ref(real colvector a, real colvector b, real colvector w, real colvector ids, real scalar mode)
{
	real matrix A
	real scalar n, k, i, j
	n = rows(ids)
	A = J(n, n, 0)
	for (k = 1; k <= rows(a); k++) {
		i = selectindex(ids :== a[k])
		j = selectindex(ids :== b[k])
		A[i, j] = w[k]
	}
	_diag(A, .)
	return(A)
}
// elementwise max symmetrization with the dense package formula
real matrix nwfe_symmax(real matrix A0)
{
	real matrix A, d
	A = A0
	d = diagonal(A)
	A = (A :>= A') :* A + (A' :> A) :* A'
	_diag(A, d)
	return(A)
}
end

local bad 0
forvalues rep = 1/40 {
	clear
	set seed `=3000+`rep''
	local n = 2 + floor(runiform()*14)
	local m = 1 + floor(runiform()*3*`n')
	set obs `m'
	gen long a = 10 + ceil(runiform()*`n')*3
	gen long b = 10 + ceil(runiform()*`n')*3
	gen double w = cond(runiform() < .2, 0, ceil(runiform()*3))
	if `rep' > 20 {
		* unvalued input
		replace w = 1
	}
	if mod(`rep', 4) == 0 {
		* symmetric input: append the mirror image (same weights)
		expand 2
		gen long tmp = a
		replace a = b if _n > `m'
		replace b = tmp if _n > `m'
		drop tmp
		* deterministic weights per unordered pair: make mirrored pair equal
		gen long lo = min(a, b)
		gen long hi = max(a, b)
		bysort lo hi: replace w = w[_N]
		drop lo hi
	}
	* include a node that only appears in a self-loop (isolate)
	local m2 = _N + 1
	set obs `m2'
	replace a = 7 in `m2'
	replace b = 7 in `m2'
	replace w = 1 in `m2'
	tempfile base
	save `base'

	mata: ids = uniqrows(st_data(., "a") \ st_data(., "b"))
	mata: ref = nwfe_ref(st_data(., "a"), st_data(., "b"), st_data(., "w"), ids, 0)
	mata: st_numscalar("issym", all(ref :== ref'))
	local issym = scalar(issym)

	* (1) valued edge list, automatic directed/undirected detection
	nwclear
	use `base', clear
	nwfromedge a b w, name(t1)
	nwname t1
	local isdir = ("`r(directed)'" == "true")
	mata: tp = __nw.nws.pdefs[__nw.nws.get_index_of("t1")]
	mata: expect = (st_numscalar("issym") ? nwfe_symmax(ref) : ref)
	mata: st_numscalar("same", all(tp->get_matrix_copy() :== expect) & rows(expect) == tp->get_nodes())
	if scalar(same) != 1 | `isdir' != (1 - `issym') {
		display as error "rep `rep': detection/adjacency mismatch (valued, auto)"
		local ++bad
	}

	* (2) forcedirected keeps the matrix as is
	nwclear
	use `base', clear
	nwfromedge a b w, name(t2) forcedirected
	mata: tp = __nw.nws.pdefs[__nw.nws.get_index_of("t2")]
	mata: st_numscalar("same", all(tp->get_matrix_copy() :== ref))
	if scalar(same) != 1 {
		display as error "rep `rep': forcedirected adjacency mismatch"
		local ++bad
	}

	* (3) forceundirected: elementwise max symmetrization
	nwclear
	use `base', clear
	nwfromedge a b w, name(t3) forceundirected
	nwname t3
	mata: tp = __nw.nws.pdefs[__nw.nws.get_index_of("t3")]
	mata: st_numscalar("same", all(tp->get_matrix_copy() :== nwfe_symmax(ref)))
	if scalar(same) != 1 | "`r(directed)'" != "false" {
		display as error "rep `rep': forceundirected adjacency mismatch"
		local ++bad
	}

	* (4) node order, labels and the dense/sparse index agree
	nwclear
	use `base', clear
	nwfromedge a b w, name(t4) directed labprefix(q)
	mata: tp = __nw.nws.pdefs[__nw.nws.get_index_of("t4")]
	mata: st_numscalar("same", all(tp->get_nodenames() :== ("q" :+ strofreal(ids')))) 
	if scalar(same) != 1 {
		display as error "rep `rep': node labels/order mismatch"
		local ++bad
	}
	* out-degrees from the sparse index equal row counts of the dense matrix
	mata: od = J(rows(ids), 1, 0)
	mata: for (i = 1; i <= rows(ids); i++) od[i] = rows(tp->neighbors(i))
	mata: st_numscalar("same", all(od :== rowsum(ref :!= 0 :& ref :!= .)))
	if scalar(same) != 1 {
		display as error "rep `rep': sparse degrees differ from dense row counts"
		local ++bad
	}
}
assert `bad' == 0
display "test_nwfromedge_large: all checks passed"
nwclear
