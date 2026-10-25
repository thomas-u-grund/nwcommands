capture program drop nwsimmelian
program nwsimmelian
	syntax [anything(name=netname)] [, name(string) nwreplace]
	unw_defs
	_nwsyntax `netname'
	_nwvaluednote `netname'
	if r(shown) == 1 {
		noi di `"`r(msg)'"'
	}
	
	if "`name'" == "" {
		local name "_simmelian"
	}
	nwvalidate `name'
	if "`r(exists)'" == "true" & "`nwreplace'" == "" {
		// BUGFIX: was `error 3000' - a bare Stata error code with its
		// own, unrelated built-in meaning ("Mata compile-time error"),
		// so Stata prints ITS OWN generic canned text for that alongside
		// this command's own custom message, confusingly implying an
		// actual crash rather than a deliberate name-collision guard.
		// Error-code coherence pass: this situation ("network already
		// exists") is exactly what `errNWsExists' (483, unw_defs.ado)
		// already names and documents - several sibling commands
		// (nwset/nwfromedge/nwshared/nwtranspose/nwgenerate/nwuse) had
		// independently drifted onto an undocumented ad-hoc `6099'
		// instead of this already-established constant; all now
		// consolidated onto `errNWsExists'.
		noi di "{err}No, network {bf:`name'} already exists; use differentname or option {bf:nwreplace}."
		error `errNWsExists'
	}
	capture nwdrop `name'

	nwduplicate `netname', name(`name')
	_nwsyntax
	// mutual ties with a mutual neighbour in common (for a network held as stored ties they are found from the tie
	// list, without the n x n matrices of the dense route)
	mata: nw_simmelian_fast(`netobj')
end

capture mata: mata drop nw_simmelian_fast()
mata:
// Native Simmelian ties (kernel 31 of the nwgraph plugin) for a network held as stored ties without loops, as the
// sparse branch of nw_simmelian_net(); every other case, and a kernel that is not available (plugin generation
// older than 7, a failure), goes to nw_simmelian_net(). The global NW_NOFASTKERNELS forces that function.
void nw_simmelian_fast(pointer(class nw_def scalar) scalar p)
{
	real matrix el, r
	real rowvector aux
	real scalar n, wasvalued, st

	if (st_global("NW_NOFASTKERNELS") == "" & nwg_comb_version() >= 7) {
		if (nw_ties_only(p) & p->is_selfloop_boolean() != 1) {
			n = p->get_nodes()
			el = p->edgelist()
			el = select(el, (el[., 3] :!= 0) :& (el[., 3] :!= .) :& (el[., 1] :!= el[., 2]))
			if (rows(el) > 0) {
				r = nwg_comb(31, n, el[., (1, 2)], J(0, 1, .), J(1, 0, .), aux, st)
				if (st == 0 & cols(r) == 2) {
					wasvalued = p->is_valued_boolean()
					p->set_edge_from_triplets(r[., 1], r[., 2], J(rows(r), 1, 1), p->is_directed_boolean())
					p->set_valued(wasvalued)
					return
				}
			}
		}
	}
	nw_simmelian_net(p)
}
end
