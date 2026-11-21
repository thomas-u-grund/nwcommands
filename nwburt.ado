
capture program drop nwburt
program nwburt, rclass
	version 12
	syntax [anything(name=netname)] [, dyadredundancy dyadconstraint BINary replace silent DIRection(string)]

	_nwsyntax `netname'

	// direction(both|out|in): which ties of a directed network count as the ties of ego (both: Burt's convention,
	// z_ij + z_ji; out: the ties ego sends; in: the ties ego receives). No effect on an undirected network.
	if "`direction'" == "" local direction both
	if !inlist("`direction'", "both", "out", "in") {
		di "{err}direction() must be {bf:both}, {bf:out} or {bf:in}"
		exit 198
	}
	local __onedir = ("`directed'" == "true" & "`direction'" != "both")
	local __indir = ("`direction'" == "in")

	// The Valued flag of the network (set when it was created, see nwset/nwfromedge) decides, as for every command
	// with a weighted form in R: a valued network gets Burt's (1992) weighted measures (native kernel 40) unless
	// binary is given, which treats every positive value as a tie of value 1; an unvalued network is binary.
	// __kind (from the stored ties): 0 = every tie has the value 1, 1 = other positive values, 2 = a negative or
	// missing value (refused).
	local __kind 0
	mata: st_local("__kind", strofreal(nw_burtkind(`netobj')))
	if `__kind' == 2 {
		di "{err}nwburt is not defined for networks with negative or missing tie values"
		exit 198
	}
	local __weighted = ("`valued'" == "true" & "`binary'" == "")
	if `__weighted' & ("`dyadredundancy'" != "" | "`dyadconstraint'" != "") {
		di "{err}{p 0 0 2}The network is valued: dyadredundancy and dyadconstraint are defined for ties that are present or absent.{p_end}"
		di "{err}{p 0 0 2}Add the option {bf:binary} (every positive value counts as a tie) or dichotomize the network first.{p_end}"
		exit 198
	}

	foreach v in _effsize _efficiency _constraint _hierarchy {
		capture confirm variable `v'
		if _rc == 0 & "`replace'" == "" {
			di "{err}Variable {bf:`v'} already exists; use {bf:replace}"
			exit 110
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
		if `__onedir' {
			// one direction only: out reproduces the out-ties-only kernel 29 of versions before 3.33.0; in is the same
			// on the transposed ties; a valued network (weighted) goes through nw_burtdir() (the kernels of the weighted
			// measures symmetrize)
			if `__weighted' {
				mata: `__burt' = nw_burtdir(`netobj', `__indir', 0)
			}
			else {
				mata: `__burt' = nw_fastburt(`netobj', `__kind', `__indir')
				mata: st_local("__fast", strofreal(rows(`__burt') == `nodes' & cols(`__burt') == 4))
				if !`__fast' mata: `__burt' = nw_burtdir(`netobj', `__indir', 1)
			}
		}
		else if `__weighted' {
			// weighted Burt measures: native kernel 40 (plugin generation 9 or later), no Mata fallback
			mata: `__burt' = nw_fastburtw(`netobj', ("`binary'" != ""))
			mata: st_local("__fast", strofreal(rows(`__burt') == `nodes' & cols(`__burt') == 4))
			if !`__fast' {
				di "{err}{p 0 0 2}Weighted Burt measures need the native plugin of nwcommands >= 3.6.0; use the {bf:binary} option for the unweighted measures{p_end}"
				exit 198
			}
		}
		else if "`directed'" == "true" & `__kind' < 2 {
			// A directed binary network: Burt's measures use both directions of a tie (the proportions
			// p_ij = (z_ij + z_ji) / sum_k (z_ik + z_ki), as igraph::constraint() and the weighted measures below), so the
			// weighted kernel runs on the ties set to 1; the out-ties-only kernel 29 would ignore the incoming ties.
			mata: `__burt' = nw_fastburtw(`netobj', 1)
			mata: st_local("__fast", strofreal(rows(`__burt') == `nodes' & cols(`__burt') == 4))
			if !`__fast' {
				di "{err}{p 0 0 2}The Burt measures of a directed network need the native plugin of nwcommands >= 3.6.0{p_end}"
				exit 198
			}
		}
		else {
			mata: `__burt' = nw_fastburt(`netobj', `__kind')
			mata: st_local("__fast", strofreal(rows(`__burt') == `nodes' & cols(`__burt') == 4))
			if !`__fast' & `__kind' == 1 {
				di "{err}{p 0 0 2}The {bf:binary} option for a valued network needs the native plugin of nwcommands >= 3.6.0{p_end}"
				exit 198
			}
			if !`__fast' {
				mata: `__burt' = `netobj'->calculate_burt()
			}
		}
		mata: __nwburt_effsize = `__burt'[.,1]
		mata: __nwburt_efficiency = `__burt'[.,2]
		mata: __nwburt_constraint = `__burt'[.,3]
		mata: __nwburt_h = `__burt'[.,4]
		mata: mata drop `__burt'
	}
	else {
		tempname onenet __burt
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

		// one direction only (direction(out|in)): the dense formulas of versions before 3.33.0 on the out-ties (in: on
		// the transposed network); the dyadic networks and the node summaries come from them
		if `__onedir' & `__indir' mata: `onenet' = `onenet''

		if "`directed'" == "true" & !`__onedir' {
			// a directed network: both directions of a tie count (Burt's symmetrised tie strength z_ij + z_ji, as the
			// summary measures); the dyadic networks and the node summaries come from the same weighted formulas
			mata: __nwburt_dr = dyadicredundancy_dir(`onenet')
			mata: __nwburt_dc = dyadicconstraint_dir(`onenet')
		}
		else {
			mata: __nwburt_dr = dyadicredundancy(`onenet')
			mata: __nwburt_dc = dyadicconstraint(`onenet')
		}

		if "`dyadredundancy'" != "" {
			capture nwdrop dyadredundancy
			nwset, name(dyadredundancy) mat(__nwburt_dr)
			_nwsyntax `netname'
		}
		if "`dyadconstraint'" != "" {
			capture nwdrop dyadconstraint
			nwset, name(dyadconstraint) mat(__nwburt_dc)
			_nwsyntax `netname'
		}

		if "`directed'" == "true" & !`__onedir' {
			// the node summaries of a directed network from the weighted kernel on the symmetrised ties (as without the dyadic options)
			mata: `__burt' = nw_fastburtw(`netobj', 1)
			mata: st_local("__fast", strofreal(rows(`__burt') == `nodes' & cols(`__burt') == 4))
			if !`__fast' {
				di "{err}{p 0 0 2}The Burt measures of a directed network need the native plugin of nwcommands >= 3.6.0{p_end}"
				exit 198
			}
			mata: __nwburt_effsize = `__burt'[.,1]
			mata: __nwburt_efficiency = `__burt'[.,2]
			mata: __nwburt_constraint = `__burt'[.,3]
			mata: __nwburt_h = `__burt'[.,4]
			mata: mata drop `__burt'
		}
		else {
			mata: __nwburt_effsize = rowsum(`onenet') - rowsum(__nwburt_dr)
			mata: __nwburt_efficiency = __nwburt_effsize :/ rowsum(`onenet')
			mata: __nwburt_constraint = rowsum(__nwburt_dc)
			mata: __nwburt_h = hierarchy(`onenet', __nwburt_dc)
		}
		mata: mata drop __nwburt_dr __nwburt_dc
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

	mata: st_store((1::`nodes'), "_effsize", __nwburt_effsize)
	mata: st_store((1::`nodes'), "_efficiency", __nwburt_efficiency)
	mata: st_store((1::`nodes'), "_constraint", __nwburt_constraint)
	mata: st_store((1::`nodes'), "_hierarchy", __nwburt_h)

	mata: mata drop __nwburt_effsize __nwburt_efficiency __nwburt_constraint __nwburt_h

	return scalar nodes = `nodes'
	return scalar weighted = `__weighted'
	return local direction "`direction'"

	if "`silent'" == "" {
		di "{hline 40}"
		di "{txt}  Network name: {res}`netname'"
		di "{hline 40}"
		di "{txt}    Burt structural hole measures"
		if `__weighted' di "{txt}{p 4 4 2}(valued ties: Burt's weighted measures; both directions of a directed tie count){p_end}"
		else if "`directed'" == "true" & "`direction'" == "out" di "{txt}{p 4 4 2}(directed network: ties sent by ego only){p_end}"
		else if "`directed'" == "true" & "`direction'" == "in" di "{txt}{p 4 4 2}(directed network: ties received by ego only){p_end}"
		else if "`directed'" == "true" di "{txt}{p 4 4 2}(directed network: both directions of a tie count){p_end}"
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
	capture mata: mata drop __nwburt_*
	capture confirm number 0
end

capture mata: mata drop nw_fastburt()
capture mata: mata drop nw_fastburtw()
capture mata: mata drop nw_burtdir()
capture mata: mata drop nw_burtkind()
capture mata: mata drop dyadicredundancy()
capture mata: mata drop dyadicredundancy_dir()
capture mata: mata drop dyadicconstraint_dir()
capture mata: mata drop dyadicconstraint()
capture mata: mata drop hierarchy()

mata:
// Native Burt measures (kernel 29 of the nwgraph plugin): the n x 4 matrix of calculate_burt() (effective size,
// efficiency, constraint, hierarchy), or a 0 x 0 matrix when the kernel is not available. The global
// NW_NOFASTKERNELS forces the Mata method.
real matrix nw_fastburt(pointer (class nw_def scalar) scalar p, real scalar kind, | real scalar indir)
{
	real rowvector aux
	real scalar st, n
	real matrix r, el
	real colvector h

	if (st_global("NW_NOFASTKERNELS") != "") return(J(0, 0, .))
	if (nwg_comb_version() < 7) return(J(0, 0, .))
	n = p->get_nodes()
	el = p->edgelist()
	// direction(in): the ties ego receives are the ties of ego in the transposed network
	if (indir != . & indir != 0) el = el[., (2, 1, 3)]
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
real matrix nw_fastburtw(pointer (class nw_def scalar) scalar p, | real scalar bin)
{
	real rowvector aux
	real scalar st, n
	real matrix r, el
	real colvector h

	if (st_global("NW_NOFASTKERNELS") != "") return(J(0, 0, .))
	if (nwg_comb_version() < 9) return(J(0, 0, .))
	n = p->get_nodes()
	el = p->edgelist()
	// bin: every positive value is a tie of value 1
	if (bin != . & bin != 0) {
		el = select(el, el[., 3] :> 0)
		if (rows(el) > 0) el[., 3] = J(rows(el), 1, 1)
	}
	r = nwg_comb(40, n, el, J(0, 1, .), J(1, 0, .), aux, st)
	if (st != 0 | rows(r) != n | cols(r) != 5) return(J(0, 0, .))
	h = r[., 4] :+ editvalue(r[., 5], 1, .)
	return((r[., 1], r[., 2], r[., 3], h))
}

// Burt's measures from ONE direction of the ties of a directed network (direction(out) or direction(in) of nwburt;
// in: the ties of the transposed network). The contacts of ego i are the nodes j with z_ij > 0, p_ij = z_ij / sum_k z_ik,
// the constraint of i is sum_j (p_ij + sum_q p_iq p_qj)^2, the redundancy of the contact j is sum_q p_iq m_qj with
// m_qj = z_qj / max_k z_qk (for 0/1 ties m_qj = z_qj: the formulas of kernel 29, which this reproduces), efficiency =
// effective size / number of contacts, hierarchy as kernel 40. bin: every positive value is a tie of value 1.
// Columns as nw_fastburt(); a node without contacts has 0, 0, 0 and a missing hierarchy.
real matrix nw_burtdir(pointer (class nw_def scalar) scalar p, real scalar indir, real scalar bin)
{
	real scalar n, m, i, k, kk, a, d, q, jn, jp, piq, es, con, avgc, z, h, j
	real matrix el, res
	real colvector cnt, start, s, mx, posn, ind, red, c, c2

	n = p->get_nodes()
	el = p->edgelist()
	if (rows(el) > 0) el = select(el, el[., 1] :!= el[., 2] :& el[., 3] :> 0 :& el[., 3] :< .)
	if (indir != 0) el = el[., (2, 1, 3)]
	if (bin != 0 & rows(el) > 0) el[., 3] = J(rows(el), 1, 1)
	if (rows(el) > 0) el = sort(el, (1, 2))
	m = rows(el)
	cnt = J(n, 1, 0); s = J(n, 1, 0); mx = J(n, 1, 0)
	for (k = 1; k <= m; k++) {
		i = el[k, 1]
		cnt[i] = cnt[i] + 1
		s[i] = s[i] + el[k, 3]
		if (el[k, 3] > mx[i]) mx[i] = el[k, 3]
	}
	start = runningsum(cnt) - cnt :+ 1
	posn = J(n, 1, 0)
	res = J(n, 4, .)
	for (i = 1; i <= n; i++) {
		d = cnt[i]
		if (d == 0) {
			res[i, .] = (0, 0, 0, .)
			continue
		}
		a = start[i]
		ind = J(d, 1, 0); red = J(d, 1, 0)
		for (k = a; k < a + d; k++) posn[el[k, 2]] = k - a + 1
		for (k = a; k < a + d; k++) {
			q = el[k, 2]
			piq = el[k, 3] / s[i]
			for (kk = start[q]; kk < start[q] + cnt[q]; kk++) {
				jn = el[kk, 2]
				jp = posn[jn]
				if (jp > 0) {
					ind[jp] = ind[jp] + piq * (el[kk, 3] / s[q])
					red[jp] = red[jp] + piq * (el[kk, 3] / mx[q])
				}
			}
		}
		c = el[|a, 3 \ a + d - 1, 3|] :/ s[i] + ind
		c2 = c :* c
		es = d - sum(red)
		con = sum(c2)
		avgc = con / d
		z = sum((c2 :/ avgc) :* ln(c2 :/ avgc))
		if (d == 1) h = 1
		else {
			h = z / (d * ln(d))
			if (h >= . | h > 1e300 | h < -1e300) h = 1
		}
		res[i, .] = (es, es / d, con, h)
		for (k = a; k < a + d; k++) posn[el[k, 2]] = 0
	}
	return(res)
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

// Directed networks: Z = A + A' (both directions), p_ij = z_ij / sum_k z_ik, m_jq = z_jq / max_k z_jk. The redundancy of the tie
// i-j is sum over q (not i, not j) of p_iq m_jq; the constraint of the tie is (p_ij + sum_q p_iq p_qj)^2.
real matrix dyadicredundancy_dir(real matrix net){
	real matrix Z, U, P, Mx

	Z = net + net'
	U = (Z :> 0)
	P = Z :/ rowsum(Z)
	_editmissing(P, 0)
	Mx = Z :/ rowmax(Z)
	_editmissing(Mx, 0)
	return(U :* (P * Mx'))
}

real matrix dyadicconstraint_dir(real matrix net){
	real matrix Z, U, P, c, dc

	Z = net + net'
	U = (Z :> 0)
	P = Z :/ rowsum(Z)
	_editmissing(P, 0)
	c = P + P * P
	dc = U :* (c :* c)
	_diag(dc, 0)
	return(dc)
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
