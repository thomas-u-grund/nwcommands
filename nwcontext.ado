
capture program drop nwcontext
program nwcontext 
	version 9
	syntax [anything(name=netname)],  ATTRibute(string) [ stat(string) mode(string) GENerate(string) mat(string) noweight REPlace ]
	nw_syntax `netname', max(1)
	
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
	
	capture confirm variable `generate'
	if _rc == 0 & "`replace'" == "" {
		di "{err}Variable {bf:`generate'} already exists; use {bf:replace}"
		err 99
	}
	if "`generate'" == "" {
		local generate _context_`attribute'
	}
	capture drop `generate'
	
	_nwdatasync `netname'
	nw_syntax `netname', max(1)

	if ("`stat'" == "") {
		local stat = "mean"
	}
	
	if ("`weight'" == "noweight"){
		local net_matrix (*`netobj'->get_matrix_unvalued())
	}
	else {
		local net_matrix (*`netobj'->get_matrix())
	}
	
	mata: __attr = J(`nodes', 1, 0)
	if `nodes' >= _N {
		local validCase = _N
		mata: __attr[(1::`validCase')] = st_data((1,`validCase'), "`attribute'")
	}
	else {
		mata: __attr[(1::`nodes')] = st_data((1,`nodes'), "`attribute'")
	}
	
	if ("`mode'" == "incoming") {
		local net_matrix (`net_matrix')'
	}
	if ("`mode'" == "both") {
		local net_matrix ((`net_matrix')' + `net_matrix')
	}
	local net_matrix ((`net_matrix') :* (__attr :!= .)')
	mata: __contextNet = (`net_matrix')
	mata: _editmissing(__attr,0)
	mata: _editmissing(__contextNet, 0)

	if ("`stat'" == "mean"){
		mata: __context = (__contextNet * __attr) :/ (rowsum(__contextNet))
	}
	
	if ("`stat'" == "meanego"){
		mata: _diag(__contextNet, 1)
		// BUGFIX: referenced the undeclared Mata variables `contextNet'/
		// `attr' instead of `__contextNet'/`__attr' (the names actually
		// populated earlier in this program, used by every other stat
		// branch) - always failed with "variable not found", r(3499).
		mata: __context = (__contextNet * __attr) :/ (rowsum(__contextNet))
	}
	
	if ("`stat'" == "sd"){
		mata: __netVal = rowsum(__contextNet)
		mata: __avgContext = (__contextNet * __attr) :/ __netVal
		mata: _editvalue(__contextNet,0,.)
		mata: __diffContext = (__contextNet :* __attr') :- __avgContext
		mata: __context = sqrt(rowsum(__diffContext :* __diffContext):/rowsum(__contextNet))
		mata: mata drop __netVal __diffContext __avgContext 
	}
	
	if ("`stat'" == "sdego"){
		mata: _diag(__contextNet, 1)
		mata: __netVal = rowsum(__contextNet)
		mata: __avgContext = (__contextNet * __attr) :/ __netVal
		mata: _editvalue(__contextNet,0,.)
		mata: __diffContext = (__contextNet :* __attr') :- __avgContext
		mata: __context = sqrt(rowsum(__diffContext :* __diffContext):/rowsum(__contextNet))
		mata: mata drop __netVal __diffContext __avgContext 
	}
	
	if ("`stat'" == "max"){
		mata: _editvalue(__contextNet,0,.)
		mata: __context = rowmax(__contextNet :* __attr')
	}
	
	if ("`stat'" == "maxego"){
		// BUGFIX: a stray trailing "4" after the closing paren made this
		// a Mata syntax error ("invalid syntax", r(3000)) on every call,
		// unlike the four other identical `_diag(__contextNet, 1)' calls
		// elsewhere in this file.
		mata: _diag(__contextNet, 1)
		mata: _editvalue(__contextNet,0,.)
		mata: __context = rowmax(__contextNet :* __attr')
	}
	
	if ("`stat'" == "min"){	
		mata: _editvalue(__contextNet,0,.)
		mata: __context = rowmin(__contextNet :* __attr')
	}
	
	if ("`stat'" == "minego"){	
		mata: _diag(__contextNet, 1)
		mata: _editvalue(__contextNet,0,.)
		mata: __context = rowmin(__contextNet :* __attr')
	}
	
	if ("`stat'" == "sum"){
		mata: __contextNet
		mata: __attr
		mata: __context = (__contextNet * __attr) 
	}
	
	if ("`stat'" == "sumego"){
		mata: _diag(__contextNet, 1)
		mata: __context = (__contextNet * __attr) 
	}
	
	//mata: _editvalue(__context,0,.)
	if "`mat'" != "" {
		mata: `mat' = __context
	}
	else {
		capture generate `generate' = .
		mata: st_store((1, `nodes'), "`generate'",__context)
	}
	mata: mata drop __context __attr __contextNet   
end

