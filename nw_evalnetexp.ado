capture program drop nw_evalnetexp
program nw_evalnetexp
	syntax [anything] [, nodes(string)]
	local mynodes = "`nodes'"
	local arg = "`anything'"
	gettoken netexp result: arg, parse("%")
	
	// prepare result
	local result = trim(subinstr("`result'", "%", "",.))
	
	// prepare netexp and perform basic syntax check
	local netexp = trim("`netexp'")
	local lnet = length("`netexp'") 
	local netexp = substr("`netexp'", 1, `lnet')
	local netexp_raw = "`netexp'"
	
	local parenthesisBalance = 0
	forvalues i = 1/`lnet'{
		local charAt = substr("`netexp'",`i',1)
		if ("`charAt'" == "(") local parenthesisBalance = `parenthesisBalance' + 1
		if ("`charAt'" == ")") local parenthesisBalance = `parenthesisBalance' - 1
	}
	if ("`netexp'" == "" | `parenthesisBalance' != 0){a
		di "{err}{it:netexp} empty or contains unmatched parentheses"
		error 6077
	}
	
	local subpos1 = strpos("`netexp'","[")
	
	// check for simple non-network expressions
	capture mata: `netexp'
	if (_rc == 0) {
		mata: `result' = `netexp'
		mata: st_numscalar("r(nodes)", rows(`result'))
		local nodes = r(nodes)
	}
	
	// left-align parenthesis
	forvalues k = 1/10 {
		local nonet = subinstr("`netexp'","( ", "(",.)
	}
	
	
	/////////////////////////////
	//
	//
	/////////////////////////////
	
	// Deal with operators in netexp expression 
	local exp "`netexp'"
	local stataVars = 0
	local netexp_mata ""
	
	// replace all operators
	local exp = subinstr("`exp'","**"," matmult ",.)
	local exp = subinstr("`exp'","=="," :== ",.)
	local exp = subinstr("`exp'",">="," :grequ ",.)
	local exp = subinstr("`exp'","<="," :smequ ",.)	
	local exp = subinstr("`exp'",">"," :> ",.)
	local exp = subinstr("`exp'","<"," :< ",.)	
	local exp = subinstr("`exp'",":grequ"," :>= ",.)
	local exp = subinstr("`exp'",":smequ"," :<= ",.)	
	local exp = subinstr("`exp'","*"," :* ",.)
	local exp = subinstr("`exp'","/"," :/ ",.)
	local exp = subinstr("`exp'","(-"," (J(matanodes , matanodes , mataminus1) * ",.)
	local exp = subinstr("`exp'","-"," :- ",.)
	local exp = subinstr("`exp'","mataminus1","-1",.)
	local exp = subinstr("`exp'","+"," :+ ",.)
	local exp = subinstr("`exp'","&"," :& ",.)
	local exp = subinstr("`exp'","|"," :| ",.)
	local exp = subinstr("`exp'","("," ( ",.)
	local exp = subinstr("`exp'",")"," ) ",.)
	local exp = subinstr("`exp'","["," [ ",.)
	local exp = subinstr("`exp'","]"," ] ",.)
	local exp = subinstr("`exp'","::"," :: ",.)
	local exp = subinstr("`exp'",","," , ",.)
	local exp = subinstr("`exp'","!="," :!= ",.)
	local exp = subinstr("`exp'"," matmult "," * ",.)
	local exp = subinstr("`exp'","^"," :^ ",.)

	// cycle through expression words first to get number of maxAllowedNodes
	local exp_words = wordcount("`exp'")
	local exp_net = "`exp'"
	tokenize "`exp_net'"
	local maxAllowedNodes = .
	forvalues i = 1/`exp_words' {
		local x "``i''"
		mata: st_rclear()
		capture nw_syntax `x'
		if (_rc == 0){
			local maxAllowedNodes = min(`maxAllowedNodes', `nodes')
		}
	}
	
	// set number of nodes
	local nodes = `maxAllowedNodes'
	
	// cycle through words in netexp
	local exp = subinstr("`exp'", "matanodes", "`nodes'",.)
	local exp_words = wordcount("`exp'")
	local exp_net = "`exp'"
	
	tokenize "`exp_net'"

	forvalues i = 1/`exp_words' {
		local x "``i''"
		local operators = "op round( exp( abs( sqrt( log( ln( J , * :^ :!= :: [ ] :& :| :> :< :>= :<= :* :/ :== & | :- :+ ( )"
		local isoperator_match : list operators & x
		local isoperator = wordcount("`isoperator_match'")		
		
		//(strpos("`operators'", "`x'") > 0)
		local subnet = "[(1::`nodes'),(1::`nodes')]"
		
		// word is not a number or operator
		if (real("`x'")== . & `isoperator' != 1 ){		
			local found = 0
			
			// word is a network
			capture nw_syntax `x'
			if (_rc == 0){	
				local found = 1
				local exp = subinword("`exp'", "`x'", "(*`netobj'->get_matrix())`subnet' ",1)
			}
			
			// word is Stata _n or _N
			if ("`x'" == "_n" | "`x'" == "_N" ){
				local found = 1
				tempvar _ntemp
				gen `_ntemp' = `x'
				local exp = subinword("`exp'", "`x'", "`_ntemp'",.)
				local x = "`_ntemp'"
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
				local exp = subinword("`exp'", "`x'", "stataVar_`stataVars'",.)
			}
			
			/*
			// word is neither number, operator, nor network or variable
			if (`found' == 0) {
				if (strpos("`x'","_nw") == 1){
					di "{err}{it:nwgenerator} {bf:`x'} failed"
				}
				else {
					di "{err}{it:network} or {it:variable} {bf:`x'} not found"
				}
				local errorOccued = "errorNetwork"
				continue, break
			}*/
		}
	}


	local netexp_mata = "`exp'"

	/*
	// to handle single numbers
	local sub_exp = "`exp'"
	local subpos1 = strpos("`sub_exp'","[")
	local subnodes = `nodes'
	
	
	while (`subpos1' != 0) {
		di "S:`subpos1'"
		local subpos1 = strpos("`sub_exp'","[")
		local subpos2 = strpos("`sub_exp'","]")
		local subdiff = `subpos2' - `subpos1' + 1
		local sub = trim(substr("`sub_exp'", `subpos1',`subdiff'))
		local subcomma = strpos("`sub'", ",")
		local subend1 = `subcomma' - 2
		local substart2 = `subcomma' + 1
		local sublen2 = length("`sub'") - `substart2'
		local sub1 = substr("`sub'",2,`subend1')
		local sub2 = substr("`sub'", `substart2', `sublen2')
		if (`subpos1' != 0) {
			local sub1 = "(`sub1')"
			local sub2 = "(`sub2')"
			mata: st_numscalar("r(sub1)", rows(`sub1'))
			mata: st_numscalar("r(sub2)", rows(`sub2'))
			local subwords1 = wordcount("`sub1'")
			local subnodes = min(`subnodes', `r(sub1)')
			local subnodes = min(`subnodes', `r(sub2)')
			// invalid subnet
			if r(sub1) != r(sub2) {
				local subprint = subinstr("`sub'"," ","",.)
				di "{err}{it:subnet} {bf:`subprint'} not square"
				local errorOccured = "errorSubnet"
				continue, break
			}
		}
		
		local nextsubstart = `subpos2' + 1
		local sub_exp = substr("`sub_exp'",`nextsubstart',.)		
	}
	
	local netexp_mata = " J(`subnodes',`subnodes',1) :* `netexp_mata'"
	*/
	di "hallo"
	di `"`netexp_mata'"'
	local matacmd "`netexp_mata'"


	// execute network expression in mata
	if ("`result'" != ""){
		capture mata: mata drop `result'
		mata: `result' = `matacmd'
	
		if "`mynodes'" != "" {
			mata: `result' = getResultWithNodes(`result', `mynodes')
		}
	}

	
	/////////////////////////////
	//
	// clean up 
	//
	/////////////////////////////
	forvalues j= 1/`stataVars' {
		mata: mata drop stataVar_`j'
	}

	mata: st_rclear()
	mata: st_numscalar("r(nodes)", `nodes')
	mata: st_global("r(mat)", "`result'")
	mata: st_global("r(netexp)","`netexp_raw'")
	
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
