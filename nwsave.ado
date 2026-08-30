capture program drop nwsave
program nwsave
	// A former format(string) option was accepted by syntax but immediately
	// discarded - `format' below is `.nwdta''s own single, fixed internal
	// storage layout, not something a caller could ever meaningfully vary
	// (any value, including nonsense, was silently accepted and ignored).
	// Removed rather than wired up, since there is no second storage format
	// implemented anywhere in this file to select between.
	syntax anything [, old replace *]
	local webname = subinstr(`"`anything'"', ".dta","",.)
	local webname = subinstr(`"`webname'"', ".nwdta","",.)
	unw_defs
	nwload, labelonly

	tempfile existing
	qui save `existing'
	nw_syntax _all, max(99999)
	local nets r(networks)

	local format = "edgelist"

	
	// save attributes first
	qui foreach onenet in `netname' {
		nwload `onenet', labelonly
	}
	capture drop _nwinclude
	tempfile attributes
	qui gen _nw_running = _n
	qui save`old' `attributes', replace
	
	// obtain edgelists for each network together with entries to which network entry belongs
	nw_syntax _all, max(99999)
	qui foreach onenet in `netname' {
		nwload `onenet', labelonly
		gen _nw_match_`onenet' = 1 if _nwinclude == 1
	}
	
	qui nwtoedge _all, egovars(_nw_match_*) ego(_nw_ego) alter(_nw_alter) ignore2mode compress
	qui gen _nw_running = _n
	tempfile edgelist
	qui save`old' `edgelist', replace

	clear
	qui nwset
    qui set obs `r(networks)'
	qui {
	 gen _nw_format = "" 
	 gen _nw_nets = . 
	 gen _nw_netname = ""
	 gen _nw_size = .
	 gen _nw_directed = ""
	 gen _nw_twomode = ""
	 gen _nw_selfloops = ""
	 gen _nw_title = ""
	 gen _nw_valued = ""
	 // was missing entirely: r(mode2) above only ever saved the bare
	 // is-two-mode yes/no flag, never the actual per-node mode
	 // partition - nwtoedge's own edgelist export (below, ignore2mode)
	 // discards mode information by design, so nothing captured it at
	 // all, and every saved-and-reloaded two-mode network silently
	 // lost its real mode membership (confirmed via a direct
	 // round-trip probe before this fix - see get_modes_labeled_string()'s
	 // own header comment in unw_core.do for the full explanation).
	 gen _nw_modes = ""
	 gen _nw_mode1desc = ""
	 gen _nw_mode2desc = ""
	 gen _nw_provenance = ""
    }
	local i = 1
	
	qui foreach onenet in `netname' {
		nwname `onenet'
		replace _nw_netname = "`onenet'" in `i'
		local nodes = `r(nodes)'
		replace _nw_format = "edgelist" in `i'
		replace _nw_size = `nodes' in `i'
		replace _nw_directed = "`r(directed)'" in `i'
		replace _nw_selfloop = "`r(selfloop)'" in `i' 
		replace _nw_twomode = "`r(mode2)'" in `i'
		replace _nw_valued = "`r(valued)'" in `i'
		replace _nw_title = "`r(title)'" in `i'
		replace _nw_modes = `"`r(modes)'"' in `i'
		replace _nw_mode1desc = `"`r(mode1desc)'"' in `i'
		replace _nw_mode2desc = `"`r(mode2desc)'"' in `i'
		replace _nw_provenance = `"`r(provenance)'"' in `i'
		local i = `i' + 1
	}
	qui replace _nw_nets = `=`i'-1' in 1
	qui gen _nw_running = _n
	tempfile metadata
	qui save`old' `metadata', replace
	
	qui merge 1:1 _nw_running using `attributes', nogenerate
	qui merge 1:1 _nw_running using `edgelist', nogenerate
	
	qui save`old' `webname'.nwdta, replace `options'
	use `existing', clear
end

