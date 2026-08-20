capture program drop unw_defs
program unw_defs
	
	//error codes
	c_local 	errNWsCreate	480
	c_local 	errNodeDupName	481
	c_local 	errNWsNotFound	482
	c_local 	errNWsExists	483
	c_local 	errDenseTooLarge	484

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
