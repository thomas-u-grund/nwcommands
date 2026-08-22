capture program drop nwsimilar
program nwsimilar
	syntax [anything(name=netname)] [, type(string) name(string) mode(string) xvars]
	// _nwsyntax is a deprecated pure wrapper around nw_syntax (re-exports
	// only 4 of its locals) - this file's own syntax line has no option
	// named the same as any of nw_syntax's other exports, so calling it
	// directly is a safe, direct simplification.
	nw_syntax `netname'
	
	if "`mode'" == "" {
		local mode = "both"
	}
	if "`type'" == "" {
		local type = "pearson"
	}

	_opts_oneof "pearson matches jaccard hamming crossproduct" "type" "`type'" 6556
	_opts_oneof "incoming outgoing both" "mode" "`mode'" 6556
	
	if "`name'" == "" {
		local name = "_similar"
	}

	nwvalidate `name'
	local name = "`r(validname)'"

	local dtype = 0
	if "`mode'" == "incoming" {
		local dtype = 1
	}
	if "`mode'" == "outgoing" {
		local dtype = 2
	}
	
	nwtomatafast `netname'
	// r(mata) is captured into a local immediately - nwname below is
	// itself r-class and would otherwise overwrite it before it gets
	// used further down (the exact same r()-pollution bug class fixed
	// in nwqap.ado's harmonisation unit 19: r(Var) there, r(mata) here).
	local srcmata "`r(mata)'"
	// Default the similarity network's own node labels to the source
	// network's labels, rather than nwset's generic n1/n2/... fallback
	// - see nwdissimilar.ado's identical fix for the full explanation
	// (a label mismatch makes nwcommands' master dataset treat the
	// source and derived networks as having disjoint node sets).
	nwname `netname'
	local netlabs "`r(labs)'"

	if "`type'" == "pearson" {
		qui nwcorrelate `netname', name(`name')
	}
	// Mata functions defined in an ado-file's trailing mata: block are
	// private to that ado-file, not visible to a *different* ado-file's
	// own mata: blocks - nwset's mat() option evaluates its argument
	// inside nwset.ado's own private scope, so it could never see this
	// file's private *_similarity() functions, regardless of
	// adopath/timing (previously investigated inconclusively as a
	// nwset/mat() "Mata-function-visibility" issue - this is the root
	// cause; see nwdissimilar.ado's identical fix for the full
	// explanation and a minimal confirming repro). Interactive mata
	// *workspace variables* persist across ado-files' private scopes,
	// unlike function definitions - fixed by evaluating the similarity
	// function here (within its own defining file) into such a
	// variable first, then passing the already-computed matrix's name
	// to nwset instead of an unevaluated function call.
	if "`type'" == "matches" {
		mata: __nwsim = matches_similarity(`srcmata', `dtype')
	}
	if "`type'" == "jaccard" {
		mata: __nwsim = jaccard_similarity(`srcmata', `dtype')
	}
	if "`type'" == "hamming" {
		mata: __nwsim = hamming_similarity(`srcmata', `dtype')
	}
	if "`type'" == "crossproduct" {
		// Was dispatching to hamming_similarity() (copy-paste from the
		// line above) - crossproduct_similarity() itself was defined
		// but dead, never actually reachable through any type() value.
		mata: __nwsim = crossproduct_similarity(`srcmata', `dtype')
	}
	if inlist("`type'", "matches", "jaccard", "hamming", "crossproduct") {
		// selfloop: a similarity matrix has a genuine, meaningful
		// diagonal (a node is maximally similar to itself), unlike an
		// ordinary relational network's diagonal, which defaults to
		// missing (no self-ties) when selfloop is not given. See
		// nwdissimilar.ado's identical fix for the full explanation.
		nwset, mat(__nwsim) name(`name') selfloop labs(`netlabs')
		capture mata mata drop __nwsim
	}
	if "`xvars'" == "" {
		nwload `name'
	}
end

capture mata mata drop matches_similarity()
capture mata mata drop jaccard_similarity()
capture mata mata drop hamming_similarity()
capture mata mata drop crossproduct_similarity()

mata:
real matrix matches_similarity(real matrix net,real scalar dtype){
	real matrix S, i_outvec, i_invec, j_outvec, j_invec
	real scalar i, j

	S = J(rows(net), cols(net), 0)
	for(i = 1; i<= rows(S); i++){
		for(j = 1; j<= cols(S); j++){
			i_outvec = net[i,.]
			i_invec = net[.,i]	
			j_outvec = net[j,.]
			j_invec = net[.,j]
			i_outvec[i] = 0
			i_outvec[j] = 0
			i_invec[i] = 0
			i_invec[j] = 0
			j_outvec[i] = 0
			j_outvec[j] = 0
			j_invec[i] = 0
			j_invec[j] = 0	
			
			i_outvec = (i_outvec :!= 0)
			j_outvec = (j_outvec :!= 0)
			i_invec = (i_invec :!= 0)
			j_invec = (j_invec :!= 0)
			
			if (dtype == 0 ) {
				S[i,j] = (sum(i_outvec :== j_outvec) + sum(i_invec :== j_invec) - 4) / ((cols(i_outvec) - 2) + (rows(i_invec) - 2))
			}
			if (dtype == 1 ) {
				S[i,j] = (sum(i_invec :== j_invec) - 2) / (cols(i_outvec) - 2) 
			}
			if (dtype == 2 ) {
				S[i,j] = (sum(i_outvec :== j_outvec) - 2) / (rows(i_invec) - 2)
			}
		}
	}
	return(S)
}

real matrix jaccard_similarity(real matrix net,real scalar dtype){
	real matrix S, i_outvec, i_invec, j_outvec, j_invec
	real scalar i, j

	S = J(rows(net), cols(net), 0)
	for(i = 1; i<= rows(S); i++){
		for(j = 1; j<= cols(S); j++){
			i_outvec = net[i,.]
			i_invec = net[.,i]	
			j_outvec = net[j,.]
			j_invec = net[.,j]
			i_outvec[i] = 0
			i_outvec[j] = 0
			i_invec[i] = 0
			i_invec[j] = 0
			j_outvec[i] = 0
			j_outvec[j] = 0
			j_invec[i] = 0
			j_invec[j] = 0	
			
			i_outvec = (i_outvec :!= 0)
			j_outvec = (j_outvec :!= 0)
			i_invec = (i_invec :!= 0)
			j_invec = (j_invec :!= 0)
			
			if (dtype == 0 ) {
				S[i,j] = (sum((i_outvec :== j_outvec) :* (i_outvec :!= 0)) + sum((i_invec :== j_invec) :* (i_invec :!= 0))) / ((sum(i_outvec:!=0)) + (sum(i_invec:!=0)))
			}
			if (dtype == 1 ) {
				S[i,j] = (sum((i_invec :== j_invec) :* (i_invec:!=0))) / (sum((i_invec :+ j_invec) :!=0))
			}
			if (dtype == 2 ) {
					S[i,j] = (sum((i_outvec :== j_outvec) :* (i_outvec:!=0))) / (sum((i_outvec :+ j_outvec):!=0))
			}
		}
	}
	return(S)
}

real matrix hamming_similarity(real matrix net,real scalar dtype){
	real matrix S, i_outvec, i_invec, j_outvec, j_invec
	real scalar i, j

	S = J(rows(net), cols(net), 0)
	for(i = 1; i<= rows(S); i++){
		for(j = 1; j<= cols(S); j++){
			i_outvec = net[i,.]
			i_invec = net[.,i]	
			j_outvec = net[j,.]
			j_invec = net[.,j]
			i_outvec[i] = 0
			i_outvec[j] = 0
			i_invec[i] = 0
			i_invec[j] = 0
			j_outvec[i] = 0
			j_outvec[j] = 0
			j_invec[i] = 0
			j_invec[j] = 0	
			
			i_outvec = (i_outvec :!= 0)
			j_outvec = (j_outvec :!= 0)
			i_invec = (i_invec :!= 0)
			j_invec = (j_invec :!= 0)
			
			if (dtype == 0 ) {
				S[i,j] = (sum(i_outvec :== j_outvec) + sum(i_invec :== j_invec))
			}
			if (dtype == 1 ) {
				S[i,j] = (sum(i_invec :== j_invec))
			}
			if (dtype == 2 ) {
				S[i,j] = (sum(i_outvec :== j_outvec))
			}
		}
	}
	return(S)
}

real matrix crossproduct_similarity(real matrix net,real scalar dtype){
	real matrix S, i_outvec, i_invec, j_outvec, j_invec
	real scalar i, j

	S = J(rows(net), cols(net), 0)
	for(i = 1; i<= rows(S); i++){
		for(j = 1; j<= cols(S); j++){
			i_outvec = net[i,.]
			i_invec = net[.,i]	
			j_outvec = net[j,.]
			j_invec = net[.,j]
			i_outvec[i] = 0
			i_outvec[j] = 0
			i_invec[i] = 0
			i_invec[j] = 0
			j_outvec[i] = 0
			j_outvec[j] = 0
			j_invec[i] = 0
			j_invec[j] = 0	
			
			i_outvec = (i_outvec :!= 0)
			j_outvec = (j_outvec :!= 0)
			i_invec = (i_invec :!= 0)
			j_invec = (j_invec :!= 0)
			
			if (dtype == 0 ) {
				S[i,j] = (sum(i_outvec :* j_outvec) + sum(i_invec :* j_invec))
			}
			if (dtype == 1 ) {
				S[i,j] = (sum(i_invec :* j_invec))
			}
			if (dtype == 2 ) {
				S[i,j] = (sum(i_outvec :* j_outvec))
			}
		}
	}
	return(S)
}
end




*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
