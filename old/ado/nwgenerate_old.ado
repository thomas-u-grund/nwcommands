capture program drop nwgenerate
program nwgenerate
	local arg `0'
	gettoken arg options: arg, parse(",") bind
	if "`options'" != "" {
		local options: subinstr local options "," " " 
	}
	
	gettoken newnetname netexp: arg, parse("=")
	local netexp: subinstr local netexp "_if" "$$ff"
	local netexp: subinstr local netexp "if" "#"
	
	gettoken dump opts: arg, parse(",") bind
	if "`opts'" != "" {
		local 0 `opts'
		syntax [, xvars vars(string) replace *]
	}
	local fcn_opt = "`options'"
	local newnetname = trim("`newnetname'")
	
	di "h0"
	unw_defs
		
	capture nw_syntax `newnetname'

	if _rc == 0 & (strpos("`options'", "replace")==0){
		di "{err}Network {bf:`newnetname'} already exists. Change {it:netname} or specify option {bf:replace}.{txt}"
		error 6099
	}
	else {
		capture nwdrop `newnetname'
	}
	
	// if condition
	local netexp: subinstr local netexp "_if" "$"	
	gettoken netexp ifcond: netexp, parse("#")
	local ifcond: subinstr local ifcond "#" "if"
	local ifcond: subinstr local ifcond "$$ff" "_if"
	local netexp: subinstr local netexp "$$ff" "_if"

	
	// check if network or variable should be created
	local netexp : subinstr local netexp "("  "( "	
	local selectjob : word 2 of `netexp'
	local nwgenopt "large( addnodes( collapse( duplicate( dyadprob( geodesic( subset( homophily( lattice( path( permute( pref( random( reach( ring( small( sym( transpose( evcent( context( degree( outdegree( indegree( isolates( components( lgc( clustering( closeness( farness( nearness( between("
	local whichjob : list  nwgenopt & selectjob
	local netfcn : word count `whichjob'
	
	di "h1"
	// no varfcn or netfcn
	if `netfcn' == 0 {
	
		local netexp : subinstr local netexp "=" " "
		capture nw_name `newnetname'
		if _rc == 0 & (strpos("`options'", "replace")==0){
			di "{err}network {it:`netname'} already defined"
			error 6004
		}
	
		// replace the network if it exists already
		if (strpos("`options'", "replace")!=0){
			capture nwdrop `netname'
			local options ""
		}

		// evaluate network expression
		nw_expnetexp `netexp'
		nwset, mat(`netexp') name(`newnetname') `undirected' `options' xvars nodenames(`last_netobj'->get_nodenames())
		qui nwsym `netname', check
		
		if "`r(is_symmetric)'" == "true" {
			nw_name `netname', newdirected(false)
		}
		
		if "`ifcond'" != "" {
			nwkeep `netname' `ifcond'
		}
	}
	
	// generate variable or network based on function
	else  {
		
		// get whatever is inside parenthesis
		local start = strpos("`netexp'", "(")
		local length2 = length("`netexp'")
		local length = `length2' - `start' - 1
		//local length = (strpos("`netexp'",")")) - `start' 
		local subopt = substr("`netexp'", `=`start' + 1', `length')
		
		local optionsold `options'
		
		local 0 `subopt'
		syntax [anything(name=sub1)] [, *]
		local sub2 `options'
		
		di "newnetname: `newnetname'"
		di "netexp: `netexp'"
		di "subopt: `subopt'"
		di "sub1: `sub1'"
		di "sub2: `sub2'"
		di "options: `options'"
		
		qui if "`whichjob'" == "large(" {	
			tempvar _lgc
			nwcomponents `sub1', lgc generate(`_lgc')
			nwduplicate `sub1',  name(`newnetname')
			nwkeep `netname' if `_lgc' == 1
		}	
		
		// nwduplicate shortcut
		qui if "`whichjob'" == "duplicate(" {
			noi nw_syntax `sub1', max(1) 
			nwduplicate `sub1', `sub2' name(`newnetname') `fcn_opt'
		}	

		// nwdyadprob shortcut
		qui if "`whichjob'" == "dyadprob(" {
			
			/*noi _nwsyntax_other `sub1', max(9999) 
			nwdyadprob `sub1', `sub2' name(`netname') `fcn_opt'*/
		}	
		
		// nwgeodesic shortcut
		qui if "`whichjob'" == "geodesic(" {
			noi nw_syntax `sub1', max(1) 
			nwgeodesic `sub1', `sub2' name(`newnetname') `fcn_opt'
		}
		// nwgeodesic shortcut
		qui if "`whichjob'" == "homophily(" {
			//noi _nwsyntax_other `sub1', max(9999) 
			//nwhomophily `sub1', `sub2' name(`netname') `fcn_opt'
		}
		// nwlattice shortcut
		qui if "`whichjob'" == "lattice(" {
			//nwlattice `sub1', `sub2'name(`netname') `fcn_opt'
		}	
		// nwlattice shortcut
		qui if "`whichjob'" == "path(" {
			//noi _nwsyntax_other `sub1', max(9999) 
			//nwpath `subopt', name(`netname') `fcn_opt'
		}
		// nwpermute shortcut
		qui if "`whichjob'" == "permute(" {
			noi nw_syntax `sub1', max(1) 
			nwpermute `sub1', `sub2' name(`newnetname') `fcn_opt'
		}	
		// nwpref shortcut
		qui if "`whichjob'" == "pref(" {
			//nwpref `sub1', `sub2' name(`netname') `fcn_opt'
		}	
		// nwrandom shortcut
		qui if "`whichjob'" == "random(" {
			nwrandom `sub1', `sub2' name(`newnetname') `fcn_opt'
		}	
		// nwreach shortcut
		qui if "`whichjob'" == "reach(" {
			noi nw_syntax `sub1', max(1) 
			nwreach `sub1', `sub2' name(`newnetname') `fcn_opt'
		}	
		// nwring shortcut
		if "`whichjob'" == "ring(" {
			//nwring `sub1', `sub2' name(`netname') `fcn_opt'
		}	
		// nwsmall shortcut
		qui if "`whichjob'" == "small(" {
			//nwsmall `sub1', `sub2' name(`netname') `fcn_opt'
		}
		// nwtranspose shortcut
		qui if "`whichjob'" == "transpose(" {
			//noi _nwsyntax_other `sub1', max(9999)
			//nwtranspose `sub1', `sub2' name(`netname') `fcn_opt'
		}	
	
	// TODO - Move variable producing functions into -egen-
	
		/// VARIABLE PRODUCING FUNCTIONS
		/////////
		
		// nwclustering shortcuts
		qui if "`whichjob'" == "clustering(" {
			noi nw_syntax `sub1'
			nwclustering `subopt', gen(`netname') `fcn_opt'
		}
		
		// nwcloseness shortcuts
		qui if "`whichjob'" == "closeness(" {
			tempvar _t1 _t2
			noi nw_syntax `sub1'
			nwcloseness `sub1', `sub2' gen(`newnetname' `_t1' `_t2') `fcn_opt'
		}
		qui if "`whichjob'" == "farness(" {
			tempvar _t1 _t2
			noi nwsyntax `sub1'
			nwcloseness `sub1', `sub2' gen(`_t1' `newnetname' `_t2') `fcn_opt'
		}
		qui if "`whichjob'" == "nearness(" {
			tempvar _t1 _t2
			noi nw_syntax `sub1'
			nwcloseness `sub1', `sub2' gen(`_t1' `_t2' `newnetname') `fcn_opt'
		}
		
		// nwcomponents shortcuts
		if "`whichjob'" == "components(" {
			noi nw_syntax `sub1'	
			qui nwcomponents `sub1', `sub2' gen(`newnetname') `fcn_opt'
		}
		
		if "`whichjob'" == "lgc(" {
			noi nw_syntax `sub1'
			qui nwcomponents `sub1', `sub2' gen(`newnetname') lgc `fcn_opt'
		}
		
		// nwdegree shortcuts
		// Tested!
		qui if "`whichjob'" == "isolates(" {
			tempvar _t1 
			nw_syntax `sub1'
			di "nwdegree `sub1', `sub2' isolates gen(`_t1') `fcn_opt'"
			nwdegree `sub1', `sub2' isolates gen(`_t1') `fcn_opt'
			rename _isolate `newnetname' 
			capture drop *`_t1'
		}
		
		qui if "`whichjob'" == "indegree(" {
			tempvar _t1 
			noi nw_syntax `sub1'
			nwdegree `sub1', `sub2' gen(`newnetname' `_t1') `fcn_opt'
			capture confirm variable _in`newnetname'
			if _rc == 0 {
				rename _in`newnetname' `newnetname'
				drop _out`newnetname'
			}
		}
		qui if "`whichjob'" == "outdegree(" {
			tempvar _t1
			noi nw_syntax `sub1'		
			nwdegree `sub1', `sub2' gen(`newnetname' `_t1') `fcn_opt'
			capture confirm variable _out`newnetname'
			if _rc == 0 {
				rename _out`newnetname' `newnetname'
				drop _in`newnetname'
			}
		}
		qui if "`whichjob'" == "degree(" {
			tempvar _t1
			noi nw_syntax `sub1'
			nwdegree `sub1', `sub2' gen(`newnetname' `_t1') `fcn_opt'
			capture confirm variable `newnetname'
			if _rc == 0 {
				rename _out`newnetname' `newnetname'
			}
		}
		
		// nwbetween shortcuts
		if "`whichjob'" == "between(" {
			noi _nwsyntax_other `sub1'
			nwbetween `sub1', `sub2'  generate(`netname') `fcn_opt'
		}
		
		// nwcontext shortcuts
		if "`whichjob'" == "context(" {
			noi _nwsyntax_other `sub1'
			nwcontext `sub1',   generate(`netname') `fcn_opt'
		}
		
		// nwevcent shortcuts
		if "`whichjob'" == "evcent(" {
			noi _nwsyntax_other `sub1'
			nwevcent `sub1', `sub2'  generate(`netname') `options'
		}
		
		
	}

end
