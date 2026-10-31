
capture program drop nwmatching
program nwmatching, rclass
	version 12
	syntax [anything(name=netname)], [GENerate(string) replace silent BINary]
	_nwsyntax `netname'
	// a valued network: the matching of largest total tie value (igraph::max_bipartite_match uses the values);
	// binary: the matching of largest size, the values ignored
	local __wtd = ("`valued'" == "true" & "`binary'" == "")

	if "`generate'" == "" {
		di "{err}option {bf:generate()} required."
		error 198
	}
	capture confirm variable `generate'
	if _rc == 0 & "`replace'" == "" {
		di "{err}Variable {bf:`generate'} already exists; use {bf:replace}"
		err 99
	}

	// BUGFIX: the active dataset was never synced to the target network
	// before st_store() below - see nwpagerank.ado's identical fix and
	// comment for the full account; confirmed to crash the same way
	// here via the same adversarial-input probe.
	_nwsetobs `netname'
	tempvar __nw_match_included
	_nwdatasync `netname', generate(`__nw_match_included')

	tempname __nw_match
	if `__wtd' {
		// native Hungarian method (plugin generation 10 or later); a result of the wrong shape (older plugin, no
		// plugin, a kernel failure) leaves the Mata routine.  NW_NOFASTKERNELS forces the Mata routine.
		local __fast 0
		capture mata: `__nw_match' = nw2_fastmatch(`netobj')
		if _rc == 0 {
			mata: st_local("__fast", strofreal(rows(`__nw_match') == `nodes'))
		}
		if !`__fast' {
			capture noisily mata: `__nw_match' = `netobj'->calculate_matching_maxweight()
		}
	}
	else {
		capture noisily mata: `__nw_match' = `netobj'->calculate_bipartite_matching()
	}
	if _rc != 0 {
		exit _rc
	}
	capture confirm new variable `generate'
	if _rc capture drop `generate'
	gen `generate' = .
	mata: st_store((1::`nodes'), "`generate'", `__nw_match')

	mata: st_numscalar("__nwmatching_n", sum(`__nw_match' :> 0))
	if `__wtd' {
		mata: st_local("__mw", strofreal(nw_matchweight(`netobj', `__nw_match'), "%18.12g"))
	}
	mata: mata drop `__nw_match'

	return scalar matched = __nwmatching_n
	if `__wtd' {
		return scalar weight = `__mw'
	}
	return local matchvar "`generate'"

	if "`silent'" == "" {
		di "{hline 40}"
		di "{txt}  Network: {res}`netname'"
		di "{txt}  Matched pairs: {res}`=__nwmatching_n'"
		if `__wtd' di "{txt}  Total tie value of the matching: {res}`__mw'{txt} (largest possible; {bf:binary} maximises the number of pairs instead)"
		di "{hline 40}"
		di "{txt}(`generate' holds each mode-1 node's own matched mode-2 partner's node id, 0 if unmatched; mode-2 nodes always show 0 - read the match off the mode-1 side)"
	}
	scalar drop __nwmatching_n
end

capture mata: mata drop nw_matchweight()
mata:
real scalar nw_matchweight(pointer(class nw_def scalar) scalar p, real colvector match)
{
	real scalar i, t
	t = 0
	for (i = 1; i <= rows(match); i++) if (match[i] > 0) t = t + p->edge_weight(i, match[i])
	return(t)
}
end

capture mata: mata drop nw2_fastmatch()
mata:
// Native maximum-weight matching (kernel 45 of the nwgraph plugin); a 0 x 1 vector when the kernel is not available
real colvector nw2_fastmatch(pointer(class nw_def scalar) scalar p)
{
	real rowvector aux
	real scalar st
	real matrix r
	real colvector md

	if (st_global("NW_NOFASTKERNELS") != "") return(J(0, 1, .))
	if (p->is_2mode_boolean() == 0) return(J(0, 1, .))
	if (nwg_comb_version() < 10) return(J(0, 1, .))
	md = strtoreal(p->get_modes())'
	r = nwg_comb(45, p->get_nodes(), p->edgelist(), md, J(1, 0, .), aux, st)
	if (st != 0 | rows(r) != p->get_nodes() | cols(r) != 1) return(J(0, 1, .))
	return(r)
}
end
