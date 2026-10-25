do unw_core.do

* Native kernels 34 (nwpagerank) and 35 (nwclique) against the Mata code they replace.
* The Mata path is forced with the global NW_NOFASTKERNELS. Cliques: the same matrix row by row (counts and order);
* PageRank: floats to 1e-10 (in practice identical). Runs in well under a minute.
* Prints "k2: n random networks, all equal" on success; without a plugin of generation 8 the comparison is skipped.

mata: st_local("gen", strofreal(nwg_comb_version()))
local skip = (`gen' < 8)
if `skip' di as txt "k2: plugin generation `gen' < 8, kernels 34 and 35 not available: that part SKIPPED"

capture program drop _k2_cmp
program define _k2_cmp
	args net kind
	tempvar pf po cf co
	* pagerank, three parameter sets
	foreach o in "" "damping(.5) tol(1e-6)" "damping(.99) maxiter(7)" {
		global NW_NOFASTKERNELS
		qui nwpagerank `net', generate(`pf') `o' silent replace
		global NW_NOFASTKERNELS 1
		qui nwpagerank `net', generate(`po') `o' silent replace
		global NW_NOFASTKERNELS
		qui gen double __k2d = reldif(`pf', `po')
		qui sum __k2d
		local md = r(max)
		drop __k2d `pf' `po'
		if `md' > 1e-10 {
			di as err "pagerank (`o') differs (`md'): `net' (`kind')"
			exit 9
		}
		if `md' > $k2_maxdiff global k2_maxdiff = `md'
	}
	* cliques at several minimum sizes
	foreach ms in 1 2 3 4 6 {
		global NW_NOFASTKERNELS
		qui nwclique `net', generate(`cf') minsize(`ms') silent replace
		local nf = r(cliques)
		matrix Mf = r(clique_matrix)
		local rf = rowsof(Mf)
		qui gen double `co' = `cf'
		global NW_NOFASTKERNELS 1
		qui nwclique `net', generate(`cf') minsize(`ms') silent replace
		global NW_NOFASTKERNELS
		local no = r(cliques)
		matrix Mo = r(clique_matrix)
		capture assert (`cf' == `co') | (`cf' >= . & `co' >= .)
		local bad = _rc
		drop `cf' `co'
		if `bad' | `nf' != `no' | rowsof(Mf) != rowsof(Mo) | colsof(Mf) != colsof(Mo) {
			di as err "nwclique minsize(`ms') differs (cliques `nf' vs `no', var rc `bad'): `net' (`kind')"
			exit 9
		}
		if mreldif(Mf, Mo) != 0 {
			di as err "nwclique minsize(`ms') matrix differs: `net' (`kind')"
			exit 9
		}
		global k2_ncl = $k2_ncl + `no'
	}
end

if !`skip' {
	set seed 20261026
	global k2_maxdiff 0
	global k2_ncl 0
	local nnet 0
	forvalues r = 1/72 {
		local n = 5 + floor(runiform()^2 * 295)
		local dir = mod(`r', 2)
		local val = (mod(`r', 3) == 0)
		local iso = (mod(`r', 4) < 2)
		local loop = (mod(`r', 8) == 5)
		local m = ceil(`n' * (0.4 + 3 * runiform()))
		if mod(`r', 6) == 0 local m = ceil(`n' * (4 + 6 * runiform()))
		clear
		qui set obs `m'
		qui gen long a = ceil(runiform() * `n')
		qui gen long b = ceil(runiform() * `n')
		if !`loop' qui replace b = mod(b, `n') + 1 if a == b
		qui gen double w = ceil(runiform() * 5) - (runiform() < 0.1) * 3 * `val'
		if !`val' qui replace w = 1
		* multiple edges in the edge list (the constructor keeps one tie per dyad)
		qui expand 2 in 1/3
		local opt = cond(`dir', "directed", "undirected")
		if `val' qui nwfromedge a b w, name(net) `opt'
		else qui nwfromedge a b, name(net) `opt'
		if `iso' qui nwaddnodes net, nodenames(iso_a iso_b iso_c)
		_k2_cmp net "r=`r' n=`n' dir=`dir' val=`val' iso=`iso' loop=`loop'"
		local ++nnet
		nwclear
	}

	* planted cliques: K_12 and K_7 sharing two nodes, plus a path (many maximal cliques of size 2)
	clear
	qui set obs 400
	qui gen long a = .
	qui gen long b = .
	local k 0
	forvalues i = 1/12 {
		forvalues j = `=`i'+1'/12 {
			local ++k
			qui replace a = `i' in `k'
			qui replace b = `j' in `k'
		}
	}
	forvalues i = 11/17 {
		forvalues j = `=`i'+1'/17 {
			local ++k
			qui replace a = `i' in `k'
			qui replace b = `j' in `k'
		}
	}
	forvalues i = 17/30 {
		local ++k
		qui replace a = `i' in `k'
		qui replace b = `=`i'+1' in `k'
	}
	qui keep if a < .
	qui nwfromedge a b, name(planted) undirected
	_k2_cmp planted "planted"
	local ++nnet
	nwclear
	* an empty network and a single node
	qui nwset, mat((0,0,0\0,0,0\0,0,0)) name(emp) undirected
	_k2_cmp emp "empty"
	local ++nnet
	nwclear

	di as txt "k2: `nnet' random networks, all equal (max relative difference of nwpagerank " as res %9.2e $k2_maxdiff as txt "; $k2_ncl cliques compared)"

}

* 2-connectivity search of nwkcomponents (k = 2) inside algorithm 20: the plugin against the Mata flow search
* fast_min_cut_search_edges(), on random graphs with cut vertices, bridges, disconnected parts and no pendant nodes.
mata:
real matrix k2_graph(real scalar n, real scalar kind)
{
	real matrix E, T
	real colvector p, key
	real scalar i, j, c, m, a, b

	E = J(0, 2, 0)
	if (kind == 1) {
		// a cycle with random chords
		for (i = 1; i <= n; i++) E = E \ (i, mod(i, n) + 1)
		for (i = 1; i <= floor(n * runiform(1,1)); i++) E = E \ (ceil(runiform(1,1) * n), ceil(runiform(1,1) * n))
	}
	else if (kind == 2) {
		// a chain of small cycles/cliques glued at single nodes (cut vertices)
		a = 1
		while (a < n - 1) {
			b = min((n, a + 1 + floor(runiform(1,1) * 4)))
			for (i = a; i <= b; i++) for (j = i + 1; j <= b; j++) if (runiform(1,1) < 0.7 | j == i + 1 | (i == a & j == b)) E = E \ (i, j)
			a = b
		}
	}
	else if (kind == 3) {
		// two cycles, joined by a bridge or not, plus isolated triangles
		c = floor(n / 2)
		for (i = 1; i <= c; i++) E = E \ (i, mod(i, c) + 1)
		for (i = c + 1; i <= n; i++) E = E \ (i, c + mod(i - c, n - c) + 1)
		if (runiform(1,1) < 0.5) E = E \ (1, c + 1)
	}
	else {
		E = (ceil(runiform(n * 2, 1) * n), ceil(runiform(n * 2, 1) * n))
	}
	if (rows(E) == 0) E = (1, 2)
	E = select(E, E[., 1] :!= E[., 2])
	if (rows(E) == 0) E = (1, 2)
	// random relabelling, both directions, unique arcs, in a random or a column-by-column order
	p = order(runiform(n, 1), 1)
	E = (p[E[., 1]], p[E[., 2]])
	E = E \ E[., (2, 1)]
	key = uniqrows(E[., 2] :* (n + 1) :+ E[., 1])
	T = (key :- floor((key :- 1) :/ (n + 1)) :* (n + 1), floor((key :- 1) :/ (n + 1)))
	if (runiform(1,1) < 0.5) T = T[order(runiform(rows(T), 1), 1), .]
	return(T)
}

void k2_kcomp_check(real scalar nrep)
{
	real scalar r, n, kind, bad, nfail, k
	real matrix T
	real rowvector a, b

	bad = 0
	nfail = 0
	for (r = 1; r <= nrep; r++) {
		n = 3 + floor(runiform(1,1) * 60)
		kind = mod(r, 4) + 1
		T = k2_graph(n, kind)
		for (k = 2; k <= 3; k++) {
			a = nw_kconn_search_native(n, T[., 1], T[., 2], k)
			b = fast_min_cut_search_edges(n, T[., 1], T[., 2], k)
			if ((a[1] >= k) != (b[1] >= k)) bad = bad + 1
			else if (a[1] < k) {
				if (a != b) bad = bad + 1
				nfail = nfail + 1
			}
		}
	}
	st_local("k2bad", strofreal(bad))
	st_local("k2fail", strofreal(nfail))
}
end
mata: k2_kcomp_check(400)
if `k2bad' {
	di as err "kernel 20 (k = 2) differs from the Mata search in `k2bad' of 800 searches"
	exit 9
}
di as txt "k2: 800 connectivity searches equal (`k2fail' with a pair below the target)"

* the whole command; the signature of the result is written to the file in $K2_SIG (to compare two plugins)
capture erase "$K2_SIG"
if "$K2_SIG" != "" file open k2fh using "$K2_SIG", write text replace
set seed 777
forvalues r = 1/60 {
	local n = 5 + floor(runiform()^2 * 120)
	local m = ceil(`n' * (0.8 + 2.5 * runiform()))
	clear
	qui set obs `m'
	qui gen long a = ceil(runiform() * `n')
	qui gen long b = ceil(runiform() * `n')
	qui drop if a == b
	qui nwfromedge a b, name(kn) undirected
	if mod(`r', 5) == 0 qui nwaddnodes kn, nodenames(ia ib)
	foreach k in 1 2 3 {
		qui nwkcomponents kn, k(`k') generate(kc) silent replace force
		matrix K = r(kcomp_matrix)
		local sig "`r' `k' `=r(kcomponents)' `=rowsof(K)' `=colsof(K)'"
		forvalues i = 1/`=rowsof(K)' {
			local s ""
			forvalues j = 1/`=colsof(K)' {
				if K[`i',`j'] local s "`s',`j'"
			}
			local sig "`sig' |`s'"
		}
		if "$K2_SIG" != "" file write k2fh `"`sig'"' _n
	}
	nwclear
}
if "$K2_SIG" != "" file close k2fh
di as txt "k2: 180 nwkcomponents runs done"
