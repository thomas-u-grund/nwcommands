
capture program drop nwclique
program nwclique, rclass
	version 12
	syntax [anything(name=netname)][, GENerate(string) replace minsize(int 3) NOMatrix silent]
	set more off

	if `minsize' < 1 {
		di "{err}minsize() must be a positive integer."
		error 198
	}

	_nwsyntax `netname', max(9999)

	if `networks' > 1 {
		local k = 1
	}

	local __vnquiet = cond(c(noisily) == 0 | "`silent'" != "", "quiet", "")
	local __vndone 0
	qui foreach netname_temp in `netname' {
		_nwsyntax `netname_temp'
		if `__vndone' == 0 {
			_nwvaluednote `netname_temp', `__vnquiet'
			if r(shown) == 1 {
				noi di `"`r(msg)'"'
				local __vndone 1
			}
		}

		if "`generate'" == "" {
			noi di "{err}option {bf:generate()} required."
			error 198
		}
		local netgenerate "`generate'"

		capture confirm variable `netgenerate'`k', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`netgenerate'`k'} already exists; specify {bf:replace}"
			err 99
		}

		mata: st_rclear()
		qui if _N < `nodes' {
			set obs `nodes'
		}
		// align row i of the data set with node i of this network before the
		// positional st_store() below (a data set that was sorted or reordered, or
		// synced to another network such as a two-mode projection, would otherwise
		// receive the values on the wrong rows)
		_nwsyncrows `netname_temp'
		mata: st_rclear()
		_nwsyntax `netname_temp'

		tempname __nw_cliq __nw_sizes __nw_cliqnum
		// native kernel 35 (plugin generation 8 or later): the same Bron-Kerbosch search on the stored ties; an
		// answer of the wrong shape (older plugin, no plugin, a self-loop, a failure) leaves the Mata path. The
		// global NW_NOFASTKERNELS forces the Mata path.
		local __fast 0
		if "`nomatrix'" != "" {
			// no cliques-by-nodes matrix (Stata stores it in time growing with the square of the number of
			// nodes: about a minute at 100,000 nodes): the per-node variable and the count come from the list of
			// (clique, node) pairs of the kernel, without the dense matrix
			mata: `__nw_cliqnum' = nw2_fastcliqnum(`netobj'->edgelist(), `nodes', `minsize')
			mata: st_local("__fast", strofreal(rows(`__nw_cliqnum') == `nodes' + 1))
			if `__fast' {
				mata: st_numscalar("nw_ncliques", `__nw_cliqnum'[`nodes' + 1])
				mata: `__nw_cliqnum' = `__nw_cliqnum'[|1 \ `nodes'|]
			}
		}
		if !`__fast' {
			mata: `__nw_cliq' = nw2_fastcliq(`netobj'->edgelist(), `nodes', `minsize')
			mata: st_local("__fast", strofreal(cols(`__nw_cliq') == `nodes'))
			if !`__fast' {
				mata: `__nw_cliq' = `netobj'->calculate_cliques_filtered(`minsize')
			}
			mata: `__nw_sizes' = rowsum(`__nw_cliq')
			mata: st_numscalar("nw_ncliques", rows(`__nw_cliq'))
			if "`nomatrix'" == "" {
				mata: st_matrix("nw_cliquematrix", (rows(`__nw_cliq') > 0 ? `__nw_cliq' : J(1, `nodes', 0)))
			}
			mata: `__nw_cliqnum' = (rows(`__nw_cliq') > 0 ? editvalue(colmax(`__nw_cliq' :* `__nw_sizes')', 0, .) : J(`nodes', 1, .))
			mata: mata drop `__nw_cliq' `__nw_sizes'
		}

		capture confirm new variable `netgenerate'`k'
		if _rc capture drop `netgenerate'`k'
		gen `netgenerate'`k' = .
		mata: st_store((1::`nodes'), "`netgenerate'`k'", `__nw_cliqnum')
		mata: mata drop `__nw_cliqnum'

		return scalar cliques = nw_ncliques
		if "`nomatrix'" == "" {
			return matrix clique_matrix = nw_cliquematrix
		}
		local lcliques = nw_ncliques

		// see nwbrokerage.ado's own header comment: the "already
		// exists" probe above leaves _rc stale even after a fully
		// successful run - reset explicitly and silently.
		capture confirm variable `netgenerate'`k', exact

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Maximal cliques (size >= `minsize'): {res}`lcliques'"
			noi sum `netgenerate'`k'
			noi di " "
		}
		local k = `=`k' + 1'
	}
end

capture mata: mata drop nw2_fastcliq()
mata:
// Native maximal cliques (kernel 35 of the nwgraph plugin): the same matrix as calculate_cliques_filtered(minsize),
// one 0/1 row per maximal clique of at least minsize members, in the same order. el = edgelist() (the stored ties,
// taken as undirected). Returns a 0 x 0 matrix when the kernel is not available or does not cover the network.
real matrix nw2_fastcliq(real matrix el, real scalar n, real scalar minsize)
{
	real rowvector aux
	real scalar st, nc, k
	real matrix r, out, info

	if (st_global("NW_NOFASTKERNELS") != "") return(J(0, 0, .))
	if (n < 1) return(J(0, 0, .))
	if (nwg_comb_version() < 8) return(J(0, 0, .))
	r = nwg_comb(35, n, el, J(0, 1, .), (minsize), aux, st)
	if (st != 0 | cols(r) != 2) return(J(0, 0, .))
	nc = aux[1]
	if (rows(r) == 0) return(J(0, n, 0))
	info = panelsetup(r[., 1], 1)
	if (rows(info) != nc) return(J(0, 0, .))
	out = J(nc, n, 0)
	for (k = 1; k <= nc; k++) out[k, r[|info[k, 1], 2 \ info[k, 2], 2|]'] = J(1, info[k, 2] - info[k, 1] + 1, 1)
	return(out)
}

// The per-node clique number (size of the largest maximal clique of the node, missing for a node in none) and, as
// element n + 1, the number of cliques, straight from the (clique, node) pairs of the kernel: the numbers the dense
// matrix gives, without the matrix. A 0 x 0 matrix when the kernel is not available (the caller then takes the
// dense route).
real colvector nw2_fastcliqnum(real matrix el, real scalar n, real scalar minsize)
{
	real rowvector aux
	real scalar st, nc
	real matrix r, info
	real colvector sz, cid, sr, o, nd, out

	if (st_global("NW_NOFASTKERNELS") != "") return(J(0, 0, .))
	if (n < 1) return(J(0, 0, .))
	if (nwg_comb_version() < 8) return(J(0, 0, .))
	r = nwg_comb(35, n, el, J(0, 1, .), (minsize), aux, st)
	if (st != 0 | cols(r) != 2) return(J(0, 0, .))
	nc = aux[1]
	out = J(n, 1, .)
	if (rows(r) == 0) return(out \ nc)
	info = panelsetup(r[., 1], 1)
	if (rows(info) != nc) return(J(0, 0, .))
	sz = info[., 2] - info[., 1] :+ 1
	cid = J(rows(r), 1, 0)
	cid[info[., 1], 1] = J(nc, 1, 1)
	// (a column subscript: a 1 x 1 vector indexed by a vector would come back as a row)
	sr = sz[runningsum(cid), 1]
	// the largest size per node: sort by (node, size) and take the last pair of every node
	o = order((r[., 2], sr), (1, 2))
	nd = r[o, 2]
	sr = sr[o]
	info = panelsetup(nd, 1)
	out[nd[info[., 1], 1], 1] = sr[info[., 2], 1]
	return(out \ nc)
}
end
