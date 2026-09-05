capture program drop _nwexpnetexp
program _nwexpnetexp
	syntax [anything] [, nodes(string) print force]
	unw_defs
	local mynodes = "`nodes'"
	local nnodes = "`nodes'"
	local netexp = `"`anything'"'
	
	// prepare netexp and perform basic syntax check
	local netexp = trim(`"`netexp'"')
	local lnet = length(`"`netexp'"') 
	local netexp = substr(`"`netexp'"', 1, `lnet')
	local netexp_raw = `"`netexp'"'
	
	local parenthesisBalance = 0
	forvalues i = 1/`lnet'{
		local charAt = substr(`"`netexp'"',`i',1)
		if (`"`charAt'"' == "(") local parenthesisBalance = `parenthesisBalance' + 1
		if (`"`charAt'"' == ")") local parenthesisBalance = `parenthesisBalance' - 1
	}
	if (`"`netexp'"' == "" | `parenthesisBalance' != 0){a
		di "{err}{it:netexp} empty or contains unmatched parentheses"
		error 6077
	}
	
	// left-align parenthesis
	forvalues k = 1/10 {
		local nonet = subinstr(`"`netexp'"',"( ", "(",.)
	}
		
	// Deal with operators in netexp expression 
	local exp `"`netexp'"'
	local stataVars = 0
	local netexp_mata ""
	
	// replace all operators
	local exp = subinstr(`"`exp'"',"**"," matmult ",.)
	local exp = subinstr(`"`exp'"',"^"," :^ ",.)
	local exp = subinstr(`"`exp'"',"=="," :== ",.)
	local exp = subinstr(`"`exp'"',">="," :grequ ",.)
	local exp = subinstr(`"`exp'"',"<="," :smequ ",.)	
	local exp = subinstr(`"`exp'"',">"," :> ",.)
	local exp = subinstr(`"`exp'"',"<"," :< ",.)	
	local exp = subinstr(`"`exp'"',":grequ"," :>= ",.)
	local exp = subinstr(`"`exp'"',":smequ"," :<= ",.)	
	local exp = subinstr(`"`exp'"',"*"," :* ",.)
	local exp = subinstr(`"`exp'"',"/"," :/ ",.)
	local exp = subinstr(`"`exp'"',"(-"," (J(matanodes , matanodes , mataminus1) * ",.)
	local exp = subinstr(`"`exp'"',"- "," :- ",.)
	local exp = subinstr(`"`exp'"',"mataminus1","-1",.)
	local exp = subinstr(`"`exp'"',"+"," :+ ",.)
	local exp = subinstr(`"`exp'"',"&"," :& ",.)
	local exp = subinstr(`"`exp'"',"|"," :| ",.)
	local exp = subinstr(`"`exp'"',"("," ( ",.)
	local exp = subinstr(`"`exp'"',")"," ) ",.)
	local exp = subinstr(`"`exp'"',"["," [ ",.)
	local exp = subinstr(`"`exp'"',"]"," ] ",.)
	local exp = subinstr(`"`exp'"',"::"," :: ",.)
	local exp = subinstr(`"`exp'"',","," , ",.)
	local exp = subinstr(`"`exp'"',"!="," :!= ",.)
	local exp = subinstr(`"`exp'"'," matmult "," * ",.)
	
	// cycle through words in netexp
	local exp = subinstr(`"`exp'"', "matanodes", "`nodes'",.)
	local exp_words = wordcount(`"`exp'"')
	local exp_net = `"`exp'"'
	
	tokenize `"`exp_net'"'

	forvalues i = 1/`exp_words' {
		local x `"``i''"'
		local operators = "op round( exp( abs( sqrt( log( ln( J , * :^ :!= :: [ ] :& :| :> :< :>= :<= :* :/ :== & | :- :+ ( )"
		local isoperator_match : list operators & x
		local isoperator = wordcount("`isoperator_match'")		
		
		//(strpos("`operators'", "`x'") > 0)
		local subnet = "[(1::`nodes'),(1::`nodes')]"
		
		// word is not a number or operator
		if (real(`"`x'"')== . & `isoperator' != 1 ){		
			local found = 0
			
			// word is a network
			capture _nwsyntax `x'
			if (_rc == 0){	
				local found = 1
				local exp = subinword(`"`exp'"', `"`x'"', "(*`netobj'->get_matrix()) ",1)
				local last_netobj `netobj'
			}
			if "`nnodes'" == "" {
				local nnodes `nodes'
			}
			else if "`nodes'" != "`nnodes'" & "`force'" == "" {
				// Error-code coherence pass: was the bare Stata code `1'
				// (reserved for low-level system conditions, not a
				// domain validation failure - confusingly implies a
				// crash rather than a deliberate size-mismatch guard).
				// `errNWsSizeMismatch' (6056, unw_defs.ado) already
				// names this exact situation for several sibling
				// commands.
				di "{err}Networks of different size"
				error `errNWsSizeMismatch'
			}
			
			// word is Stata _n or _N
			if (`"`x'"' == "_n"){
				local exp = subinword(`"`exp'"', `"`x'"', "(1::`nodes')",.)
			}
			if (`"`x'"' == "_N" ){
				local exp = subinword(`"`exp'"', `"`x'"', "J(`nodes',1,`=_N')",.)
			}
			
			// word is a Stata variable
			capture confirm variable `x'
			if (_rc == 0){
				local obsStata = _N
				local maxAllowedNodes = min(`obsStata', `nodes')
				local nodes = `maxAllowedNodes'
				local found = 1
				local stataVars = `stataVars' + 1
				mata: stataVar_`stataVars' = st_data((1::`nodes'),"`x'")
				
				local st_data_cmd "st_data"
				capture confirm numeric variable `x'
				if _rc != 0 {
					local st_data_cmd "st_sdata"
				}
				local stataVarExp `"`st_data_cmd'((1::`nodes'),"`x'")"'
				local exp = subinword(`"`exp'"', "`x'", `"`stataVarExp'"',.)
				
			}
		}
	}

	local exp = `" J(`nnodes',`nnodes',1) :* `exp'"'
	c_local netexp `"`exp'"'
	c_local last_netobj `"`last_netobj'"'
	if "`print'" != "" {
		di `"`exp'"'
	}
	
end

/*
capture mata : mata drop getResultWithNodes()
mata: 
real matrix getResultWithNodes(real matrix res, scalar nodes) {
	
	if (nodes < rows(res)){
		res = res[(1::nodes), (1::nodes)]
	}
	if (nodes > rows(res)){
		result2 = J(nodes, nodes, 0)
		
		result2[(1::rows(res)), (1::cols(res))] = res
		res = result2
	}
	return(res)
}
end*/



*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
