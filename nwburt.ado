
capture program drop nwburt
program nwburt, rclass
	version 12
	syntax [anything(name=netname)] [, dyadredundancy dyadconstraint BINary replace silent]

	_nwsyntax `netname'

	// The Valued flag of the network (set when it was created, see nwset/nwfromedge) decides, as for every command
	// with a weighted form in R: a valued network gets Burt's (1992) weighted measures (native kernel 40) unless
	// binary is given, which treats every positive value as a tie of value 1; an unvalued network is binary.
	// __kind (from the stored ties): 0 = every tie has the value 1, 1 = other positive values, 2 = a negative or
	// missing value (refused).
	local __kind 0
	mata: st_local("__kind", strofreal(nw_burtkind(`netobj')))
	if `__kind' == 2 {
		di "{err}nwburt is not defined for networks with negative or missing tie values"
		err 198
	}
	local __weighted = ("`valued'" == "true" & "`binary'" == "")
	if `__weighted' & ("`dyadredundancy'" != "" | "`dyadconstraint'" != "") {
		di "{err}The network is valued: dyadredundancy and dyadconstraint are defined for ties that are present or absent."
		di "{err}Add the option {bf:binary} (every positive value counts as a tie) or dichotomize the network first."
		err 198
	}

	foreach v in _effsize _efficiency _constraint _hierarchy {
		capture confirm variable `v'
		if _rc == 0 & "`replace'" == "" {
			di "{err}Variable {bf:`v'} already exists; use {bf:replace}"
			err 99
		}
	}

	// PERFORMANCE FIX: dyadredundancy()/dyadconstraint() below both
	// compute matrix products (net*net, p*p) after materializing the
	// whole network via nwtomata - O(n^3) regardless of sparsity,
	// confirmed as one of the nwtomata-dependent family excluded from
	// the n=10,000 benchmark tier (docs/PERFORMANCE_BENCHMARKS.md).
	// calculate_burt() (unw_core.do) computes the exact same four
	// per-node summary measures directly from the sparse network, in
	// O(sum of out-degree^2) instead - the common case (no
	// dyadredundancy()/dyadconstraint() option, which asks for the
	// full n-by-n dyadic NETWORKS themselves, not just the per-node
	// summaries). Those two options remain on the original dense path
	// unchanged - a disclosed, deliberate scope limit: they are a far
	// less commonly used feature, and producing a new dyadic-level
	// NETWORK output is a different problem from summarizing it per
	// node.
	if "`dyadredundancy'" == "" & "`dyadconstraint'" == "" {
		local __fast 0
		tempname __burt
		// native kernel 29 (plugin generation 7 or later) from the stored ties; an n x 4 result is used, anything else
		// (older plugin, failure, NW_NOFASTKERNELS) leaves the Mata method
		if `__weighted' {
			// weighted Burt measures: native kernel 40 (plugin generation 9 or later), no Mata fallback
			mata: `__burt' = nw_fastburtw(`netobj')
			mata: st_local("__fast", strofreal(rows(`__burt') == `nodes' & cols(`__burt') == 4))
			if !`__fast' {
				di "{err}Weighted Burt measures need the native plugin of nwcommands >= 3.6.0; use the {bf:binary} option for the unweighted measures"
				err 198
			}
		}
		else {
			mata: `__burt' = nw_fastburt(`netobj', `__kind')
			mata: st_local("__fast", strofreal(rows(`__burt') == `nodes' & cols(`__burt') == 4))
			if !`__fast' & `__kind' == 1 {
				di "{err}The {bf:binary} option for a valued network needs the native plugin of nwcommands >= 3.6.0"
				err 198
			}
			if !`__fast' {
				mata: `__burt' = `netobj'->calculate_burt()
			}
		}
		mata: effsize = `__burt'[.,1]
		mata: efficiency = `__burt'[.,2]
		mata: constraint = `__burt'[.,3]
		mata: h = `__burt'[.,4]
		mata: mata drop `__burt'
	}
	else {
		tempname onenet
		nwtomata `netname', mat(`onenet')
		// nwtomata returns the diagonal as missing (this codebase's
		// standard no-self-loop convention). dyadicredundancy()/
		// dyadicconstraint() below both compute matrix products
		// (net*net, p*p) - a SINGLE missing entry anywhere in a real
		// matrix multiplication poisons its entire dot-product sum to
		// missing (verified directly: onenet*onenet on a missing-
		// diagonal input returns an all-missing matrix), which
		// _editmissing() then silently zeros, corrupting effsize/
		// efficiency/constraint/hierarchy to trivial (no-redundancy)
		// values on EVERY network. A true self-loop contributes
		// nothing to a two-step-via-q path count either way, so 0 (the
		// correct additive identity) is what belongs on the diagonal
		// for this computation, not missing.
		if `__kind' == 1 mata: `onenet' = (`onenet' :> 0) :* (`onenet' :< .)
		mata: _diag(`onenet', J(`nodes',1,0))

		mata: dr = dyadicredundancy(`onenet')
		mata: dc = dyadicconstraint(`onenet')

		if "`dyadredundancy'" != "" {
			capture nwdrop dyadredundancy
			nwset, name(dyadredundancy) mat(dr)
			_nwsyntax `netname'
		}
		if "`dyadconstraint'" != "" {
			capture nwdrop dyadconstraint
			nwset, name(dyadconstraint) mat(dc)
			_nwsyntax `netname'
		}

		mata: effsize = rowsum(`onenet') - rowsum(dr)
		mata: efficiency = effsize :/ rowsum(`onenet')
		mata: constraint = rowsum(dc)
		mata: h = hierarchy(`onenet', dc)
		mata: mata drop dr dc
	}

	capture drop _effsize
	capture drop _efficiency
	capture drop _constraint
	capture drop _hierarchy
	qui gen _effsize = .
	qui gen _efficiency = .
	qui gen _constraint = .
	qui gen _hierarchy = .
	// align row i of the data set with node i of the network before the positional
	// read/write below (see nwcommunity.ado)
	_nwsyncrows `netname'

	mata: st_store((1::`nodes'), "_effsize", effsize)
	mata: st_store((1::`nodes'), "_efficiency", efficiency)
	mata: st_store((1::`nodes'), "_constraint", constraint)
	mata: st_store((1::`nodes'), "_hierarchy", h)

	mata: mata drop effsize efficiency constraint h

	return scalar nodes = `nodes'
	return scalar weighted = `__weighted'

	if "`silent'" == "" {
		di "{hline 40}"
		di "{txt}  Network name: {res}`netname'"
		di "{hline 40}"
		di "{txt}    Burt structural hole measures"
		if `__weighted' di "{txt}    (valued ties: Burt's weighted measures; both directions of a directed tie count)"
		sum _effsize _efficiency _constraint _hierarchy
	}
	// Drive-by fix (found while writing this command's own Examples
	// section, moderate-severity pass): several `capture'd probes above
	// (the per-variable collision-guard `confirm variable' loop, and the
	// four `capture drop' calls) each fail harmlessly on the ordinary,
	// no-collision case - and neither `return scalar' nor `sum' actually
	// refresh `_rc' the way a plain, un-quietly-prefixed command
	// normally would, so an entirely successful `nwburt' call could
	// still leak a stale nonzero `_rc' to its own caller (confirmed
	// directly: a fresh call returned `_rc==111'). Reset explicitly as
	// the last step, matching this package's own established idiom for
	// exactly this situation.
	capture confirm number 1
end

capture mata: mata drop nw_fastburt()
capture mata: mata drop nw_fastburtw()
capture mata: mata drop nw_burtkind()
capture mata: mata drop dyadicredundancy()
capture mata: mata drop dyadicconstraint()
capture mata: mata drop hierarchy()

mata:
// Native Burt measures (kernel 29 of the nwgraph plugin): the n x 4 matrix of calculate_burt() (effective size,
// efficiency, constraint, hierarchy), or a 0 x 0 matrix when the kernel is not available. The global
// NW_NOFASTKERNELS forces the Mata method.
real matrix nw_fastburt(pointer (class nw_def scalar) scalar p, real scalar kind)
{
	real rowvector aux
	real scalar st, n
	real matrix r, el
	real colvector h

	if (st_global("NW_NOFASTKERNELS") != "") return(J(0, 0, .))
	if (nwg_comb_version() < 7) return(J(0, 0, .))
	n = p->get_nodes()
	el = p->edgelist()
	// binary option on a valued network: every positive value is a tie of value 1
	if (kind == 1) {
		el = select(el, el[., 3] :> 0)
		if (rows(el) > 0) el[., 3] = J(rows(el), 1, 1)
	}
	r = nwg_comb(29, n, el, J(0, 1, .), J(1, 0, .), aux, st)
	if (st != 0 | rows(r) != n | cols(r) != 5) return(J(0, 0, .))
	h = r[., 4] :+ editvalue(r[., 5], 1, .)
	return((r[., 1], r[., 2], r[., 3], h))
}

// Weighted Burt measures (kernel 40 of the nwgraph plugin, plugin generation 9 or later): the n x 4 matrix of effective
// size, efficiency, constraint and hierarchy, or a 0 x 0 matrix when the kernel is not available. No Mata fallback.
real matrix nw_fastburtw(pointer (class nw_def scalar) scalar p)
{
	real rowvector aux
	real scalar st, n
	real matrix r
	real colvector h

	if (st_global("NW_NOFASTKERNELS") != "") return(J(0, 0, .))
	if (nwg_comb_version() < 9) return(J(0, 0, .))
	n = p->get_nodes()
	r = nwg_comb(40, n, p->edgelist(), J(0, 1, .), J(1, 0, .), aux, st)
	if (st != 0 | rows(r) != n | cols(r) != 5) return(J(0, 0, .))
	h = r[., 4] :+ editvalue(r[., 5], 1, .)
	return((r[., 1], r[., 2], r[., 3], h))
}

// 0 = every stored tie has the value 1, 1 = some other positive value, 2 = a negative or missing value
real scalar nw_burtkind(pointer (class nw_def scalar) scalar p)
{
	real matrix el
	real colvector w

	el = p->edgelist()
	if (rows(el) == 0) return(0)
	w = el[., 3]
	if (any(w :>= .) | any(w :< 0)) return(2)
	return(any(w :> 0 :& w :!= 1))
}

real matrix hierarchy(real matrix net, real matrix dc){
	real matrix N, avgc, z, H, M

	N = rowsum(net)
	avgc = rowsum(dc) :/ N
	z = rowsum(net :* (dc :/ avgc) :* log(dc :/ avgc))
	H = z :/ (N :* log(N))
	_editmissing(H, 1)
	M = (N :== 0)
	_editvalue(M,1,.)
	H = H :+ M
	return(H)
}

real matrix dyadicconstraint(real matrix net){
	real matrix p, p2, c, dyadcon

	p = net :/ rowsum(net)
	_editmissing(p, 0)
	p2 = p * p
	c = p + p2
	dyadcon = (net :* (c :* c))
	_editmissing(dyadcon,0)
	_diag(dyadcon, 0)
	return(dyadcon)
}

real matrix dyadicredundancy(real matrix net){
	real matrix net2, outdeg, dyadred

	net2 = net * net
	outdeg = rowsum(net)
	dyadred = (net :* (net2 :/ outdeg))
	_editmissing(dyadred,0)
	return(dyadred)
}
end
