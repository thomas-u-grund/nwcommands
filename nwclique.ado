
capture program drop nwclique
program nwclique, rclass
	version 12
	syntax [anything(name=netname)][, GENerate(string) replace minsize(int 3) silent]
	set more off

	if `minsize' < 1 {
		di "{err}minsize() must be a positive integer."
		error 198
	}

	_nwsyntax `netname', max(9999)

	if `networks' > 1 {
		local k = 1
	}

	qui foreach netname_temp in `netname' {
		_nwsyntax `netname_temp'

		if "`generate'" == "" {
			di "{err}option {bf:generate()} required."
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
		_nwsyntax `netname_temp'

		tempname __nw_cliq __nw_sizes __nw_cliqnum
		// native kernel 35 (plugin generation 8 or later): the same Bron-Kerbosch search on the stored ties; an
		// answer of the wrong shape (older plugin, no plugin, a self-loop, a failure) leaves the Mata path. The
		// global NW_NOFASTKERNELS forces the Mata path.
		local __fast 0
		mata: `__nw_cliq' = nw2_fastcliq(`netobj'->edgelist(), `nodes', `minsize')
		mata: st_local("__fast", strofreal(cols(`__nw_cliq') == `nodes'))
		if !`__fast' {
			mata: `__nw_cliq' = `netobj'->calculate_cliques_filtered(`minsize')
		}
		mata: `__nw_sizes' = rowsum(`__nw_cliq')
		mata: st_numscalar("nw_ncliques", rows(`__nw_cliq'))
		mata: st_matrix("nw_cliquematrix", (rows(`__nw_cliq') > 0 ? `__nw_cliq' : J(1, `nodes', 0)))
		mata: `__nw_cliqnum' = (rows(`__nw_cliq') > 0 ? editvalue(colmax(`__nw_cliq' :* `__nw_sizes')', 0, .) : J(`nodes', 1, .))

		capture drop `netgenerate'`k'
		gen `netgenerate'`k' = .
		mata: st_store((1::`nodes'), "`netgenerate'`k'", `__nw_cliqnum')
		mata: mata drop `__nw_cliq' `__nw_sizes' `__nw_cliqnum'

		return scalar cliques = nw_ncliques
		return matrix clique_matrix = nw_cliquematrix
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
end
