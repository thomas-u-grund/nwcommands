
capture program drop nwcontext
program nwcontext 
	version 9
	syntax [anything(name=netname)],  ATTRibute(string) [ stat(string) mode(string) GENerate(string) mat(string) noweight REPlace force ]
	_nwsyntax `netname', max(1)
	_nwdenseguard, command(nwcontext) nodes(`nodes') copies(3) alternative(Use nwaltergen, which computes mean, sum, min, max, sd and more of the neighbors' attribute from the stored ties and scales to millions of ties.) `force'
	
	if "`stat'" == "" {
		local stat = "mean"
	}
	
	_opts_oneof "mean max min sum sd meanego maxego minego sumego sdego" "stat" "`stat'" 6556
	if "`mode'" == "" {
		local mode = "outgoing"
	}
	// "either" is the package-wide canonical term for this concept (see
	// NWCOMMANDS_COMMAND_STYLE.md and nwneighbor's own mode(), which
	// already used it) - accepted here as a synonym for the pre-existing
	// "both" and normalized to it immediately below, so the rest of this
	// command's logic (which checks the literal string "both") needs no
	// further changes and "both" keeps working exactly as before.
	_opts_oneof "incoming outgoing both either" "mode" "`mode'" 6556
	if "`mode'" == "either" {
		local mode "both"
	}
	
	// the result goes to a variable (generate()), to a Mata matrix (mat()), or to both
	if "`generate'" == "" & "`mat'" == "" {
		di "{err}option {bf:generate()} or {bf:mat()} required."
		error 198
	}
	if "`generate'" != "" {
		capture confirm variable `generate', exact
		if _rc == 0 & "`replace'" == "" {
			di "{err}Variable {bf:`generate'} already exists; use {bf:replace}"
			err 99
		}
		capture confirm new variable `generate'
		if _rc capture drop `generate'
	}
	
	_nwdatasync `netname'
	_nwsyntax `netname', max(1)

	if ("`stat'" == "") {
		local stat = "mean"
	}
	
	if ("`weight'" == "noweight"){
		local net_matrix (*`netobj'->get_matrix_unvalued())
	}
	else {
		local net_matrix (*`netobj'->get_matrix())
	}
	
	mata: __nwcontext_attr = J(`nodes', 1, 0)
	if `nodes' >= _N {
		local validCase = _N
		mata: __nwcontext_attr[(1::`validCase')] = st_data((1,`validCase'), "`attribute'")
	}
	else {
		mata: __nwcontext_attr[(1::`nodes')] = st_data((1,`nodes'), "`attribute'")
	}
	
	if ("`mode'" == "incoming") {
		local net_matrix (`net_matrix')'
	}
	if ("`mode'" == "both") {
		// a neighbour in either direction counts once, with the larger of the two tie values
		local net_matrix (((`net_matrix')' + `net_matrix' + abs((`net_matrix')' - `net_matrix')) / 2)
	}
	local net_matrix ((`net_matrix') :* (__nwcontext_attr :!= .)')
	mata: __nwcontext_contextNet = (`net_matrix')
	mata: _editmissing(__nwcontext_attr,0)
	mata: _editmissing(__nwcontext_contextNet, 0)

	if ("`stat'" == "mean"){
		mata: __nwcontext_context = (__nwcontext_contextNet * __nwcontext_attr) :/ (rowsum(__nwcontext_contextNet))
	}
	
	if ("`stat'" == "meanego"){
		mata: _diag(__nwcontext_contextNet, 1)
		// BUGFIX: referenced the undeclared Mata variables `contextNet'/
		// `attr' instead of `__nwcontext_contextNet'/`__nwcontext_attr' (the names actually
		// populated earlier in this program, used by every other stat
		// branch) - always failed with "variable not found", r(3499).
		mata: __nwcontext_context = (__nwcontext_contextNet * __nwcontext_attr) :/ (rowsum(__nwcontext_contextNet))
	}
	
	if ("`stat'" == "sd"){
		mata: __nwcontext_netVal = rowsum(__nwcontext_contextNet)
		mata: __nwcontext_avgContext = (__nwcontext_contextNet * __nwcontext_attr) :/ __nwcontext_netVal
		mata: _editvalue(__nwcontext_contextNet,0,.)
		mata: __nwcontext_diffContext = (__nwcontext_contextNet :* __nwcontext_attr') :- __nwcontext_avgContext
		mata: __nwcontext_context = sqrt(rowsum(__nwcontext_diffContext :* __nwcontext_diffContext):/rowsum(__nwcontext_contextNet))
		mata: mata drop __nwcontext_netVal __nwcontext_diffContext __nwcontext_avgContext 
	}
	
	if ("`stat'" == "sdego"){
		mata: _diag(__nwcontext_contextNet, 1)
		mata: __nwcontext_netVal = rowsum(__nwcontext_contextNet)
		mata: __nwcontext_avgContext = (__nwcontext_contextNet * __nwcontext_attr) :/ __nwcontext_netVal
		mata: _editvalue(__nwcontext_contextNet,0,.)
		mata: __nwcontext_diffContext = (__nwcontext_contextNet :* __nwcontext_attr') :- __nwcontext_avgContext
		mata: __nwcontext_context = sqrt(rowsum(__nwcontext_diffContext :* __nwcontext_diffContext):/rowsum(__nwcontext_contextNet))
		mata: mata drop __nwcontext_netVal __nwcontext_diffContext __nwcontext_avgContext 
	}
	
	if ("`stat'" == "max"){
		mata: _editvalue(__nwcontext_contextNet,0,.)
		mata: __nwcontext_context = rowmax(__nwcontext_contextNet :* __nwcontext_attr')
	}
	
	if ("`stat'" == "maxego"){
		// BUGFIX: a stray trailing "4" after the closing paren made this
		// a Mata syntax error ("invalid syntax", r(3000)) on every call,
		// unlike the four other identical `_diag(__nwcontext_contextNet, 1)' calls
		// elsewhere in this file.
		mata: _diag(__nwcontext_contextNet, 1)
		mata: _editvalue(__nwcontext_contextNet,0,.)
		mata: __nwcontext_context = rowmax(__nwcontext_contextNet :* __nwcontext_attr')
	}
	
	if ("`stat'" == "min"){	
		mata: _editvalue(__nwcontext_contextNet,0,.)
		mata: __nwcontext_context = rowmin(__nwcontext_contextNet :* __nwcontext_attr')
	}
	
	if ("`stat'" == "minego"){	
		mata: _diag(__nwcontext_contextNet, 1)
		mata: _editvalue(__nwcontext_contextNet,0,.)
		mata: __nwcontext_context = rowmin(__nwcontext_contextNet :* __nwcontext_attr')
	}
	
	if ("`stat'" == "sum"){
		mata: __nwcontext_context = (__nwcontext_contextNet * __nwcontext_attr) 
	}
	
	if ("`stat'" == "sumego"){
		mata: _diag(__nwcontext_contextNet, 1)
		mata: __nwcontext_context = (__nwcontext_contextNet * __nwcontext_attr) 
	}
	
	//mata: _editvalue(__nwcontext_context,0,.)
	if "`mat'" != "" {
		mata: `mat' = __nwcontext_context
	}
	if "`generate'" != "" {
		qui generate double `generate' = .
		mata: st_store((1, `nodes'), "`generate'",__nwcontext_context)
	}
	capture mata: mata drop __nwcontext_*
end

