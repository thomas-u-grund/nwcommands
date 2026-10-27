capture program drop nwexpand	
program nwexpand
	// BUGFIX: `noreplace' was accepted by syntax but never referenced
	// anywhere in this file's body - a complete no-op - while the actual
	// collision error raised further below (via the `nwset' call this
	// delegates to) told the caller to "Specify option replace", an
	// option nwexpand itself never exposed at all, so that instruction
	// was impossible to follow. Replaced `noreplace' with a real,
	// working `replace', forwarded to the underlying `nwset' call.
	syntax varlist(min=1 max=1) [if],[ mode(string) network(string) nodes(integer 0) xvars name(string) labs(string) replace force]
	
	unw_defs
	
	if "`network'" != "" {
		// BUGFIX: an unrecognized network() used to fall through to a
		// raw, uninformative Mata "subscript invalid" crash somewhere
		// downstream rather than a clean, immediate error - confirmed
		// directly via this .sthlp's own worked example, which passed
		// "glasgow" (nwwebuse's own multi-network dataset actually
		// creates glasgow1/glasgow2/glasgow3, never a network literally
		// named "glasgow" - the .sthlp's own example has been corrected
		// to use glasgow1).
		capture _nwsyntax `network', other(_check) max(1)
		if _rc != 0 {
			di "{err}Network {bf:`network'} not found."
			error `errNWsNotFound'
		}
		_nwsyntax `network', max(1)
		// the node names of the network go to nwset in a Mata variable: a long Stata option string gets a blank
		// inserted every 5,292 characters, which damaged the names of networks above about 900 nodes
		mata: __nwx_names = `netobj'->get_nodenames()
		local nodenamesopt "nodenames(__nwx_names)"
	}
	
	if "`if'" != "" {
		qui keep `if'
	}
	
	local varname `varlist'
	
	// get important parameters
	if ("`mode'" == ""){
		local mode = "same"
	}
	
	_opts_oneof "same dist absdist distinv absdistinv sender receiver" "mode" "`mode'" 6556
	
	// BUGFIX: `nodes(integer 1)''s own default value was also 1, so an
	// explicit `nodes(1)' (a genuine, deliberate request for a 1-node
	// network) was indistinguishable from "nodes() not specified at
	// all" - both silently expanded to use every observation instead.
	// Changed the not-given sentinel to 0 (never a legal node count),
	// so `nodes(1)' is now honored exactly as requested.
	if `nodes' == 0 {
		local nodes = `=_N'
	}
	if (`nodes' > `=_N' | `=_N' == 0) {
		di "{err}Not enough observations for variable {bf:`varlist'}."
		error 6200
	}
	_nwdenseguard, command(nwexpand) nodes(`nodes') copies(2) alternative(The result is a network with a tie for every pair of nodes. Expand a part of the nodes (option nodes() or if).) `force'
	
	capture confirm numeric variable `varlist'
	if _rc != 0 {
		tempvar varnum
		encode `varlist', generate(`varnum')
		local varlist `varnum'
	}
		
	// generate valid network name and valid varlist
	// BUGFIX: an unspecified name() has always been documented/expected
	// to auto-rename on collision (`mode'_`varname'', `mode'_`varname'_1,
	// ...) rather than require replace() - see nwrandom.ado's/
	// nwpref.ado's own identical fix (harmonisation unit 126/129/130)
	// for the full root cause. Resolved the same way: only when the
	// caller did NOT supply name(), pre-resolve the actual (possibly
	// auto-incremented) target name via nwvalidate before nwset ever
	// sees it.
	local name_was_given = ("`name'" != "")
	if "`name'" == "" {
		local name "`mode'_`varname'"
	}
	if !`name_was_given' {
		nwvalidate `name'
		local name = r(validname)
	}

	// generate network
	mata: __nwexpand_attr = st_data((1::`nodes'),"`varlist'")
	if "`mode'" == "" {
		di "{txt}Option {it:mode(same)} selected."
		local mode = "same"
	}
	// the expanded matrix is built row by row (one n x n matrix, not the five of the matrix-product version)
	mata: __nwexpand_expnet = nwexpand_matrix(__nwexpand_attr, "`mode'")
	if inlist("`mode'", "absdist", "absdistinv", "same") {
		local undirected "undirected"
	}

    capture confirm variable `nw_nodename'
	if _rc != 0 {
		gen `nw_nodename' = "          "
		tempname z
		mata: `z' = (J(rows(__nwexpand_expnet),1,"`cDftNodepref'") + strofreal((1::rows(__nwexpand_expnet))))
		mata: st_sstore((1::rows(__nwexpand_expnet)),"`nw_nodename'", `z')

	}
	nwset, mat(__nwexpand_expnet) name(`name') labs(`labs') `nodenamesopt' `undirected' `replace'
	if "`xvars'" == "" {
		nwload, xvars
	}
	else {
		nwload
	}
	
	capture mata: mata drop __nwexpand_expnet 
	capture mata: mata drop __nwexpand_attr
	if "`nodenamesopt'" != "" {
		mata: mata drop __nwx_names
	}
	capture mata: mata drop __nwexpand_*
	capture confirm number 0
end
	
capture mata mata drop distMat()
capture mata mata drop simMat()
capture mata mata drop senderMat()
capture mata mata drop receiverMat()
capture mata mata drop nwexpand_matrix()

mata:
// The dyad matrix of an attribute, one row at a time:
//   same      1 where the two values are equal
//   dist      value of the ego minus value of the alter
//   distinv   the negative of dist
//   absdist   absolute distance
//   absdistinv  largest absolute distance minus the absolute distance
//   sender    value of the ego;  receiver   value of the alter
// A missing value gives missing (0 in "same"), exactly as the earlier matrix-product construction did.
real matrix nwexpand_matrix(real matrix attr, string scalar mode)
{
	real scalar n, i, mx
	real matrix E
	real rowvector at

	n = rows(attr)
	at = attr'
	E = J(n, n, .)
	for (i = 1; i <= n; i++) {
		if (mode == "same") E[i, .] = ((attr[i] :- at) :== 0)
		else if (mode == "sender") E[i, .] = J(1, n, attr[i])
		else if (mode == "receiver") E[i, .] = at
		else if (mode == "distinv") E[i, .] = (attr[i] :- at) :* (-1)
		else if (mode == "absdist" | mode == "absdistinv") E[i, .] = abs(attr[i] :- at)
		else E[i, .] = attr[i] :- at
	}
	if (mode == "absdistinv") {
		mx = max(E)
		for (i = 1; i <= n; i++) E[i, .] = mx :- E[i, .]
	}
	return(E)
}
end
