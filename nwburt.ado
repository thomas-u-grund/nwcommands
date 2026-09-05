
capture program drop nwburt
program nwburt, rclass
	version 12
	syntax [anything(name=netname)] [, dyadredundancy dyadconstraint replace silent]

	_nwsyntax `netname'

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
		tempname __burt
		mata: `__burt' = `netobj'->calculate_burt()
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

	mata: st_store((1::`nodes'), "_effsize", effsize)
	mata: st_store((1::`nodes'), "_efficiency", efficiency)
	mata: st_store((1::`nodes'), "_constraint", constraint)
	mata: st_store((1::`nodes'), "_hierarchy", h)

	mata: mata drop effsize efficiency constraint h

	return scalar nodes = `nodes'

	if "`silent'" == "" {
		di "{hline 40}"
		di "{txt}  Network name: {res}`netname'"
		di "{hline 40}"
		di "{txt}    Burt structural hole measures"
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

capture mata: mata drop dyadicredundancy()
capture mata: mata drop dyadicconstraint()
capture mata: mata drop hierarchy()

mata:
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
