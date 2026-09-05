capture program drop nwexpand	
program nwexpand
	// BUGFIX: `noreplace' was accepted by syntax but never referenced
	// anywhere in this file's body - a complete no-op - while the actual
	// collision error raised further below (via the `nwset' call this
	// delegates to) told the caller to "Specify option replace", an
	// option nwexpand itself never exposed at all, so that instruction
	// was impossible to follow. Replaced `noreplace' with a real,
	// working `replace', forwarded to the underlying `nwset' call.
	syntax varlist(min=1 max=1) [if],[ mode(string) network(string) nodes(integer 0) xvars name(string) labs(string) replace]
	
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
		qui nwsummarize `netname'
		local labs "`r(labs)'"
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
	mata: attr = st_data((1::`nodes'),"`varlist'")
	if "`mode'" == "" {
		di "{txt}Option {it:mode(same)} selected."
		local mode = "same"
	}
	if( "`mode'" == "dist"){
		mata: distMat(attr)
		mata: expnet = distMat(attr)
	}
	if ("`mode'" == "distinv"){
		mata: expnet = distMat(attr)
		mata: expnet = expnet :* (-1)
	}
	if ("`mode'" == "absdist"){
		mata: expnet = distMat(attr)
		mata: expnet = ((expnet:<0) :* (expnet :* -2)) + expnet
		local undirected "undirected"
	}
	if("`mode'" == "absdistinv") {
		mata: expnet = distMat(attr)
		mata: expnet = ((expnet:<0) :* (expnet :* -2)) + expnet
		// BUGFIX: was `J(`nodes',`nodes',-max(expnet)) - expnet' - the
		// stray negative sign on `max(expnet)' made every resulting
		// value negative (max_dist=4 on x=1..5 gave -5..-8, not the
		// intended "closer pairs score higher" inverse-distance
		// transform). This is a bounded max-minus-distance inversion,
		// not a literal 1/|diff| reciprocal (nwhomophily.sthlp's own
		// prose used to describe it as one, since fixed) - deliberately
		// NOT switched to a true reciprocal, which would reintroduce
		// the very blowup-for-near-equal-values problem this bounded
		// transform avoids (confirmed as the actual cause of a
		// downstream nwhomophily crash - see its own CERTIFICATION.md
		// entry).
		mata: expnet = J(`nodes',`nodes',max(expnet)) - expnet
		local undirected "undirected"
	}
	if "`mode'" == "same" {
		mata: expnet = simMat(attr)
		local undirected "undirected"
	}
	if "`mode'" == "sender" {
		mata: expnet = senderMat(attr)		
	}
	if "`mode'" == "receiver" {
		mata: expnet = receiverMat(attr)		
	}

    capture confirm variable `nw_nodename'
	if _rc != 0 {
		gen `nw_nodename' = "          "
		tempname z
		mata: `z' = (J(rows(expnet),1,"`cDftNodepref'") + strofreal((1::rows(expnet))))
		mata: st_sstore((1::rows(expnet)),"`nw_nodename'", `z')

	}
	nwset, mat(expnet) name(`name') labs(`labs') `undirected' `replace'
	if "`xvars'" == "" {
		nwload, xvars
	}
	else {
		nwload
	}
	
	capture mata: mata drop expnet 
	capture mata: mata drop attr
end
	
capture mata mata drop distMat()
capture mata mata drop simMat()
capture mata mata drop senderMat()
capture mata mata drop receiverMat()

mata:	
real matrix senderMat(real matrix attr){
	real scalar nsize
	real matrix temp, rowMat
	
	nsize = rows(attr)
	temp = attr :* I(nsize)
	rowMat = temp * J(nsize,nsize,1)
	return(rowMat)
}
real matrix receiverMat(real matrix attr){
	real scalar nsize
	real matrix temp, rowMat, colMat
	
	nsize = rows(attr)
	temp = attr :* I(nsize)
	rowMat = temp * J(nsize,nsize,1)
	colMat = rowMat'
	return(colMat)
}
real matrix distMat(real matrix attr){
	real scalar nsize
	real matrix temp, rowMat, colMat, distMat
	
	nsize = rows(attr)
	temp = attr :* I(nsize)
	rowMat = temp * J(nsize,nsize,1)
	colMat = rowMat'
	distMat = rowMat :- colMat
	return(distMat)
}
real matrix simMat(real matrix attr){
	real scalar nsize
	real matrix temp, rowMat, colMat, distMat, simMat
	
	nsize = rows(attr)
	temp = attr :* I(nsize)
	rowMat = temp * J(nsize,nsize,1)
	colMat = rowMat'
	distMat = rowMat :- colMat
	simMat = (distMat:==0) :* J(nsize,nsize,1) 
	return(simMat)
}
end
