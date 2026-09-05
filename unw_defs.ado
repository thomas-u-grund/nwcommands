capture program drop unw_defs
program unw_defs
	
	//error codes
	//
	// This package's own documented error-code registry (see also
	// nwerrorcodes.sthlp for the user-facing version of this same
	// table). Every one of these is a RECURRING situation shared by
	// multiple commands - use the matching code (by name if this
	// program is already called in scope, otherwise the literal
	// number) rather than inventing a new one-off code for a situation
	// this table already covers. A command-specific validation that
	// genuinely doesn't fit any of these may still use its own code,
	// but should not silently reuse one of these numbers for a
	// different meaning.
	c_local 	errNWsCreate	480	// network creation failed
	c_local 	errNodeDupName	481	// duplicate node name
	c_local 	errNWsNotFound	482	// network not found
	c_local 	errNWsExists	483	// network already exists; specify replace (or an equivalent override option)
	c_local 	errDenseTooLarge	484	// network too large for dense-matrix materialization
	c_local 	errOptValue	6556	// an option's value is not one of its documented allowed set (the _opts_oneof.ado convention)
	c_local 	errNWsSizeMismatch	6056	// two networks required to be the same size are not
	c_local 	errNWsDataLoss	999	// loading would discard unsaved data in memory; specify nwclear or nwappend
	c_local 	errTwoModeUnsupported	6088	// this command/option does not support two-mode networks
	c_local 	errNetexpMalformed	6077	// a netexp expression is empty or has unmatched parentheses
	c_local 	errMatrixShape	6082	// a user-supplied Mata/Stata matrix has the wrong shape (not square, wrong dimensions, etc.)
	c_local 	errFormatUnsupported	6705	// an unsupported file/data format was requested or detected
	c_local 	errNodeNotFound	485	// a referenced node (by name or id) does not exist in the network, or an id is out of range
	// Stata's own reserved codes are used as-is (not reinvented) for
	// their standard meanings package-wide: 99 = a STATA VARIABLE
	// already exists, specify replace (distinct from errNWsExists
	// above, which is about a NETWORK); 198 = invalid syntax / a
	// required option or option combination was not satisfied.

	// maximum node count for on-demand dense-matrix materialization
	// (get_matrix() et al.) of a network built sparse-natively; see
	// NWdef::ensure_dense_built() in unw_core.do
	c_local nw_max_dense_nodes 20000	

	//static objects
	
	c_local nw_static = "nw"
	c_local nws_static = "nws"
	c_local nwsder_static = "nwsder"

	c_local nw = "nw"
	c_local nws = "nw.nws"
	c_local nwsder = "nw.nwsder"
	
	//class definitions
	c_local vxNWs		nws
	c_local vxNWsdef	nws_def
	c_local vxNWsder	nws_der		
	c_local vxNWdef		nw_def
	
	c_local nwvars_def_pref "n"
	c_local cDftNodepref "n"
	
	c_local nw_tempfile "___temp_nw"
	c_local nw_nodename "_nwnode"
	c_local nw_included "_nwinclude"
	c_local nw_mode "_nwmode"
	c_local nw_ego "_ego"
	c_local nw_alter "_alter"
	c_local missing2 "-999999"
	c_local nw_max 10000
	
	c_local nwgen_reach "_reach"
	c_local nwgen_geodesic "_geodesic"
end
