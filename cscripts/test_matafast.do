cscript

do unw_core.do

* Speed-ups of the core Mata library and the shared ado plumbing (nw_rowptr(), set_edge_from_triplets() without the sort
* of an ascending list, the deferred in-neighbour index, panel sums for the degrees, the BFS of the components, nwkcore,
* the Mata route of nwfromedge, the fast routes of _nwdatasync, nwclique and nwkcomponents with nomatrix) against the
* routes they replace, which are still in the code. Runs in about 30 seconds. Prints "matafast: all equal" on success.

capture mata: mata drop mf_rowptr_loop()
capture mata: mata drop mf_snap()
capture mata: mata drop mf_kcore_ref()
capture mata: mata drop mf_bfs()
capture mata: mata drop mf_degchk()
capture mata: mata drop mf_incheck()
mata:
real colvector mf_rowptr_loop(real colvector r, real scalar n)
{
	real colvector rp
	real scalar pos, i, nnz
	nnz = rows(r)
	rp = J(n + 1, 1, 0)
	pos = 1
	for (i = 1; i <= n; i++) {
		rp[i] = pos
		while (pos <= nnz) {
			if (r[pos] != i) break
			pos = pos + 1
		}
	}
	rp[n + 1] = pos
	return(rp)
}
// everything the index holds, as one row vector
real rowvector mf_snap(pointer(class nw_def scalar) scalar p)
{
	if (rows(p->colidx) > 0) (void) p->neighbors_in(1)
	return((p->rowptr', p->colidx', p->cweight', p->rowptr_in', p->colidx_in', p->edgeid_in', p->isvalued))
}
// k-core numbers by the plain definition (repeated removal of nodes of degree < k), undirected networks
real colvector mf_kcore_ref(pointer(class nw_def scalar) scalar p)
{
	real scalar n, k, i, changed
	real colvector core, alive, d
	real matrix nb
	n = p->get_nodes()
	core = J(n, 1, 0)
	alive = J(n, 1, 1)
	for (k = 1; k <= n; k++) {
		changed = 1
		while (changed) {
			changed = 0
			for (i = 1; i <= n; i++) {
				if (alive[i]) {
					nb = p->neighbors(i)
					if (rows(nb) > 0) d = sum(alive[nb])
					else d = 0
					if (d < k) {
						alive[i] = 0
						changed = 1
					}
				}
			}
		}
		if (sum(alive) == 0) break
		core = core :+ alive
	}
	return(core)
}
real colvector mf_bfs(pointer(class nw_def scalar) scalar p)
{
	real scalar n, ncomp, start, cur, j, qn
	real matrix visited, comp, queue, nb
	n = p->get_nodes()
	visited = J(n,1,0)
	comp = J(n,1,0)
	ncomp = 0
	for (start=1; start<=n; start++) {
		if (visited[start,1]==0) {
			ncomp = ncomp + 1
			queue = start
			visited[start,1] = 1
			comp[start,1] = ncomp
			while (rows(queue) > 0) {
				cur = queue[1,1]
				qn = rows(queue)
				if (qn > 1) queue = queue[(2::qn),1]
				else queue = J(0,1,0)
				nb = p->neighbors(cur)
				if (p->is_directed_boolean()) nb = nb \ p->neighbors_in(cur)
				for (j=1; j<=rows(nb); j++) {
					if (visited[nb[j,1],1]==0) {
						visited[nb[j,1],1] = 1
						comp[nb[j,1],1] = ncomp
						queue = queue \ nb[j,1]
					}
				}
			}
		}
	}
	return(comp)
}
// out- and in-degree (alpha 0) and strengths against counts and sums over the tie list
real scalar mf_degchk(pointer(class nw_def scalar) scalar p)
{
	real scalar n, j, ok
	real matrix el
	real colvector o, i_, so, si
	n = p->get_nodes()
	el = p->edgelist()
	o = J(n,1,0); i_ = J(n,1,0); so = J(n,1,0); si = J(n,1,0)
	for (j = 1; j <= rows(el); j++) {
		o[el[j,1]] = o[el[j,1]] + 1
		i_[el[j,2]] = i_[el[j,2]] + 1
		so[el[j,1]] = so[el[j,1]] + el[j,3]
		si[el[j,2]] = si[el[j,2]] + el[j,3]
	}
	ok = all(p->get_outdegree(0) :== o) & all(p->get_indegree(0) :== i_)
	// alpha = 1: k * (s / k) = s, up to rounding
	ok = ok & all(abs(p->get_outdegree(1) :- so) :< 1e-9) & all(abs(p->get_indegree(1) :- si) :< 1e-9)
	return(ok)
}
// the in-neighbour index (built on first use) against the counts of the tie list
real scalar mf_incheck(pointer(class nw_def scalar) scalar p)
{
	real scalar n, j
	real matrix el
	real colvector cnt, din
	n = p->get_nodes()
	el = p->edgelist()
	cnt = J(n, 1, 0)
	din = J(n, 1, 0)
	for (j = 1; j <= rows(el); j++) cnt[el[j,2]] = cnt[el[j,2]] + 1
	for (j = 1; j <= n; j++) din[j] = p->degree_in(j)
	return(all(cnt :== din))
}
end

* ---- 1. nw_rowptr() against the loop it replaced ------------------------------------------------------------------
mata:
bad = 0
for (t = 1; t <= 300; t++) {
	n = 1 + floor(runiform(1,1) * 40)
	nnz = floor(runiform(1,1) * 3 * n)
	if (t <= 3) nnz = 0
	r = sort(ceil(runiform(nnz,1) :* n), 1)
	if (t == 4) r = J(0,1,0)
	if (t == 5) r = J(7, 1, n)
	if (any(nw_rowptr(r, n) :!= mf_rowptr_loop(r, n))) bad = bad + 1
}
// a single entry, in the first, a middle and the last row
for (t = 1; t <= 3; t++) {
	r = J(1, 1, (1, 3, 5)[t])
	if (any(nw_rowptr(r, 5) :!= mf_rowptr_loop(r, 5))) bad = bad + 1
}
// an unsorted list and a row outside 1..n keep the loop
r = (2 \ 1 \ 3)
if (any(nw_rowptr(r, 3) :!= mf_rowptr_loop(r, 3))) bad = bad + 1
r = (1 \ 4)
if (any(nw_rowptr(r, 3) :!= mf_rowptr_loop(r, 3))) bad = bad + 1
st_numscalar("mf_bad", bad)
end
assert scalar(mf_bad) == 0

* ---- 2. set_edge_from_triplets(): ascending list (sort skipped) against the same ties shuffled, with duplicates -------
nwset, mat(J(30, 30, 0)) name(mf1)
mata:
bad = 0
p = __nw.nws.pdefs[__nw.nws.get_index_of("mf1")]
for (t = 1; t <= 60; t++) {
	n = 30
	m = 2 + floor(runiform(1,1) * 200)
	e = ceil(runiform(m,1) :* n)
	a = ceil(runiform(m,1) :* n)
	w = ceil(runiform(m,1) :* 4)
	if (mod(t, 3) == 0) w = w :* (runiform(m,1) :< 0.8)
	dir = (mod(t, 2) == 0)
	p->set_selfloop(mod(t, 4) < 2)
	// unique ascending list from the random one: last row wins, sorted
	key = e :* (n + 1) :+ a
	o = order((key, (1::m)), (1, 2))
	sk = key[o]
	o = o[colshape(selectindex((sk[|1 \ m-1|] :!= sk[|2 \ m|]) \ 1), 1)]
	e1 = e[o]; a1 = a[o]; w1 = w[o]
	p->set_edge_from_triplets(e1, a1, w1, dir)
	s1 = mf_snap(p)
	// the same ties in random order
	sh = order(runiform(rows(e1), 1), 1)
	p->set_edge_from_triplets(e1[sh], a1[sh], w1[sh], dir)
	s2 = mf_snap(p)
	if (cols(s1) != cols(s2)) bad = bad + 1
	else if (any(s1 :!= s2)) bad = bad + 1
	// the in-neighbour index agrees with the ties
	if (dir & rows(p->colidx) > 0) {
		cnt = J(n, 1, 0)
		for (j = 1; j <= rows(p->colidx); j++) cnt[p->colidx[j]] = cnt[p->colidx[j]] + 1
		din = J(n, 1, 0)
		for (j = 1; j <= n; j++) din[j] = p->degree_in(j)
		if (any(cnt :!= din)) bad = bad + 1
	}
}
st_numscalar("mf_bad", bad)
end
assert scalar(mf_bad) == 0

* ---- 3. random edge lists: nwfromedge (Mata route) against noclear (the Stata route); _nwdatasync fast against force ----
capture program drop _mf_netsig
program define _mf_netsig, rclass
	* a signature of a network: node names, directedness, the tie list
	args net
	unw_defs
	_nwsyntax `net'
	mata: el_ = `netobj'->edgelist(); st_local("sig", (rows(el_) > 0 ? invtokens(strofreal(vec(el_)', "%21x")) : ""))
	mata: st_local("labs", invtokens(`netobj'->get_nodenames()))
	return local sig `"`sig'"'
	return local labs `"`labs'"'
	return local directed `"`directed'"'
	return scalar nodes = `nodes'
end

local bad 0
forvalues t = 1/40 {
	clear
	nwclear, all
	set seed `=700 + `t''
	local n = 5 + floor(runiform()*60)
	local m = 1 + floor(runiform()*`n'*3)
	local gap = (mod(`t', 3) == 0) * 2
	quietly set obs `m'
	quietly gen long e = ceil(runiform()*`n')*(1+`gap')
	quietly gen long a = ceil(runiform()*`n')*(1+`gap')
	quietly gen double w = ceil(runiform()*4)
	if mod(`t', 4) == 0 quietly expand 2 if runiform() < 0.3
	if mod(`t', 5) == 0 quietly replace e = . if runiform() < 0.05
	if mod(`t', 7) == 0 {
		quietly tostring e a, replace force
		quietly replace e = "" if e == "."
		quietly replace a = "" if a == "."
		quietly replace e = "n " + e if e != ""
		quietly replace a = "n " + a if a != ""
	}
	tempfile el
	quietly save `el'
	local opt = cond(mod(`t', 2) == 0, ", undirected", "")
	local v = cond(mod(`t', 3) == 0, "w", "")
	capture noisily nwfromedge e a `v' `opt' name(fastnet)
	local rc1 = _rc
	use `el', clear
	capture noisily nwfromedge e a `v' `opt' name(slownet) noclear
	local rc2 = _rc
	if `rc1' != `rc2' {
		di as err "case `t': return codes differ (`rc1' `rc2')"
		local bad = `bad' + 1
		continue
	}
	if `rc1' continue
	_mf_netsig fastnet
	local s1 `"`r(sig)'"'
	local l1 `"`r(labs)'"'
	local d1 `"`r(directed)'"'
	_mf_netsig slownet
	if `"`s1'"' != `"`r(sig)'"' | `"`l1'"' != `"`r(labs)'"' | `"`d1'"' != `"`r(directed)'"' {
		di as err "case `t': nwfromedge routes differ"
		local bad = `bad' + 1
	}
}
assert `bad' == 0

* degenerate lists: one row, one node with a self-loop, two identical rows
foreach pat in 1 2 3 {
	clear
	nwclear, all
	if `pat' == 1 {
		quietly set obs 1
		quietly gen long e = 3
		quietly gen long a = 4
	}
	if `pat' == 2 {
		quietly set obs 1
		quietly gen long e = 5
		quietly gen long a = 5
	}
	if `pat' == 3 {
		quietly set obs 2
		quietly gen long e = 1
		quietly gen long a = 2
	}
	tempfile el
	quietly save `el'
	quietly nwfromedge e a, name(f1)
	use `el', clear
	quietly nwfromedge e a, name(f2) noclear
	_mf_netsig f1
	local s1 `"`r(sig)'"'
	local n1 = r(nodes)
	_mf_netsig f2
	assert `"`s1'"' == `"`r(sig)'"' & `n1' == r(nodes)
}

* _nwdatasync: fast routes against option force (the full merge)
local bad 0
forvalues t = 1/20 {
	clear
	nwclear, all
	set seed `=900 + `t''
	local n = 5 + floor(runiform()*80)
	quietly nwrandom `n', prob(0.1) name(sn)
	forvalues k = 1/2 {
		* k = 1: the data are empty; k = 2: the data hold the node names already
		clear
		if `k' == 2 {
			quietly nwload sn, labelonly
		}
		capture noisily _nwdatasync sn, generate(inc_a)
		local ra = _rc
		quietly describe, short
		local Na = r(N)
		local ka = r(k)
		quietly summarize inc_a
		local sa = r(sum)
		quietly levelsof _nwnode, local(la)
		clear
		if `k' == 2 {
			quietly nwload sn, labelonly
		}
		capture noisily _nwdatasync sn, generate(inc_a) force
		local rb = _rc
		quietly describe, short
		local Nb = r(N)
		local kb = r(k)
		quietly summarize inc_a
		local sb = r(sum)
		quietly levelsof _nwnode, local(lb)
		if `ra' != `rb' | `Na' != `Nb' | `ka' != `kb' | `sa' != `sb' | `"`la'"' != `"`lb'"' {
			di as err "datasync case `t'/`k' differs"
			local bad = `bad' + 1
		}
	}
}
assert `bad' == 0

* ---- 4. degrees, components, k-cores, in-neighbour index on random networks ---------------------------------------
local bad 0
forvalues t = 1/30 {
	clear
	nwclear, all
	set seed `=1100 + `t''
	local n = 5 + floor(runiform()*150)
	local dir = cond(mod(`t', 2) == 0, "directed", "undirected")
	local dopt = cond("`dir'" == "undirected", "undirected", "")
	quietly nwrandom `n', prob(`=0.5/`n'*(1+mod(`t',5))') `dopt' name(rn)
	_nwsyntax rn
	unw_defs
	mata: p = `netobj'
	* components (BFS of the library against the plain BFS), k-core (against the definition)
	mata: st_numscalar("mf_c", all(p->calculate_components() :== mf_bfs(p)))
	if scalar(mf_c) != 1 {
		di as err "components differ, case `t'"
		local bad = `bad' + 1
	}
	if "`dir'" == "undirected" {
		mata: st_numscalar("mf_c", all(p->calculate_kcore() :== mf_kcore_ref(p)))
		if scalar(mf_c) != 1 {
			di as err "kcore differs, case `t'"
			local bad = `bad' + 1
		}
	}
	* degrees: out- and in-degree and strengths against the tie list
	mata: st_numscalar("mf_c", mf_degchk(p))
	if scalar(mf_c) != 1 {
		di as err "degrees differ, case `t'"
		local bad = `bad' + 1
	}
}
assert `bad' == 0

* ---- 5. a network above 2,000 nodes: sparse route of nwconstraint, kernel against the Mata triplets -----------------
clear
nwclear, all
set seed 4711
quietly nwrandom 2300, prob(0.002) name(big)
global NW_NOFASTKERNELS
quietly nwconstraint big, name(c1)
global NW_NOFASTKERNELS 1
quietly nwconstraint big, name(c2)
global NW_NOFASTKERNELS
mata: pa = __nw.nws.pdefs[__nw.nws.get_index_of("c1")]; pb = __nw.nws.pdefs[__nw.nws.get_index_of("c2")]
mata: ea = pa->edgelist(); eb = pb->edgelist()
mata: st_numscalar("mf_c", rows(ea) == rows(eb) & all(ea[.,1::2] :== eb[.,1::2]) & max(abs(ea[.,3] :- eb[.,3])) < 1e-12)
assert scalar(mf_c) == 1
* the in-neighbour index of the deferred route against the counts of the tie list
mata: st_numscalar("mf_c", mf_incheck(pa))
assert scalar(mf_c) == 1

* ---- 6. nwclique and nwkcomponents with nomatrix: the same variable and count ---------------------------------------
local bad 0
forvalues t = 1/15 {
	clear
	nwclear, all
	set seed `=1300 + `t''
	local n = 8 + floor(runiform()*80)
	quietly nwrandom `n', prob(`=2.5/`n'') undirected name(cq)
	quietly nwclique cq, generate(cl1) silent
	local nc1 = r(cliques)
	matrix M1 = r(clique_matrix)
	quietly nwclique cq, generate(cl2) silent nomatrix replace
	local nc2 = r(cliques)
	capture confirm matrix r(clique_matrix)
	local hasm = (_rc == 0)
	quietly count if cl1 != cl2 & !(missing(cl1) & missing(cl2))
	local ndiff = r(N)
	if `nc1' != `nc2' | `ndiff' > 0 | `hasm' {
		di as err "nwclique nomatrix differs, case `t'"
		local bad = `bad' + 1
	}
	* the matrix of the default route has one row per clique
	if rowsof(M1) < `nc1' {
		di as err "nwclique matrix rows, case `t'"
		local bad = `bad' + 1
	}
	if `t' <= 5 {
		quietly nwkcomponents cq, generate(kc1) silent k(2) replace
		local k1 = r(kcomponents)
		quietly nwkcomponents cq, generate(kc2) silent k(2) nomatrix replace
		local k2 = r(kcomponents)
		capture confirm matrix r(kcomp_matrix)
		local hasm = (_rc == 0)
		quietly count if kc1 != kc2 & !(missing(kc1) & missing(kc2))
		local ndiff = r(N)
		if `k1' != `k2' | `ndiff' > 0 | `hasm' {
			di as err "nwkcomponents nomatrix differs, case `t'"
			local bad = `bad' + 1
		}
	}
}
assert `bad' == 0

di as txt "matafast: all equal"
