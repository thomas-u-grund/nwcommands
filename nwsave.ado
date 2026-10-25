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
	_nwsyntax _all, max(99999)
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
	_nwsyntax _all, max(99999)
	qui foreach onenet in `netname' {
		nwload `onenet', labelonly
		gen _nw_match_`onenet' = 1 if _nwinclude == 1
	}
	
	// A two-mode network must not list the dyads inside each mode (a
	// 5,092 x 455 network came to 2.6 GB that way): when the file holds
	// a two-mode network, every network's tie list is made on its own
	// (nwtoedge lists only the between-mode ties of a two-mode network)
	// and the lists are stacked. A row then carries the tie value of its
	// own network only, the others are missing, which nwuse ignores
	// (the value variable is the weight of nwfromedge). Files with
	// one-mode networks only are written as before.
	local __nws_any2 = 0
	qui foreach onenet in `netname' {
		nwname `onenet'
		if "`r(mode2)'" == "true" local __nws_any2 = 1
	}
	if `__nws_any2' {
		tempfile __nws_all __nws_prep
		qui save `__nws_prep'
		local __nws_first = 1
		qui foreach onenet in `netname' {
			use `__nws_prep', clear
			nwtoedge `onenet', egovars(_nw_match_`onenet') ego(_nw_ego) alter(_nw_alter) ignore2mode compress
			// the isolate list nwtoedge attaches belongs to one network
			// only; with several networks in the file it would add
			// another network's nodes to each one on nwuse (the
			// single-network list stays, as before)
			if `: word count `netname'' > 1 {
				char _dta[nwtoedge_nodes]
			}
			if `__nws_first' {
				save `__nws_all', replace
				local __nws_first = 0
			}
			else {
				append using `__nws_all'
				save `__nws_all', replace
			}
		}
		use `__nws_all', clear
	}
	else {
		qui nwtoedge _all, egovars(_nw_match_*) ego(_nw_ego) alter(_nw_alter) ignore2mode compress
	}
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
		 // strL, and filled from Mata below: a big network's mode list is far
	 // longer than a Stata macro or a str# value can be
	 gen strL _nw_modes = ""
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
		replace _nw_mode1desc = `"`r(mode1desc)'"' in `i'
		replace _nw_mode2desc = `"`r(mode2desc)'"' in `i'
		replace _nw_provenance = `"`r(provenance)'"' in `i'
		// last, because _nwsyntax resets r()
		_nwsyntax `onenet', other(other)
		mata: st_sstore(`i', "_nw_modes", `othernetobj'->get_modes_labeled_string())
		local i = `i' + 1
	}
	qui replace _nw_nets = `=`i'-1' in 1
	qui gen _nw_running = _n
	tempfile metadata
	qui save`old' `metadata', replace
	
	qui merge 1:1 _nw_running using `attributes', nogenerate
	qui merge 1:1 _nw_running using `edgelist', nogenerate
	
	// BUGFIX: this used to hardcode the literal "replace" here regardless
	// of whether the caller actually passed the `replace' option (that
	// local was declared in `syntax' and documented in nwsave.sthlp as
	// "overwrite existing dataset", but never once referenced in the
	// command body) - so nwsave always silently overwrote an existing
	// target file, exactly the data-loss `replace' exists to guard
	// against. Found via a failure-path test that expected a plain
	// second `nwsave <same file>' (no `replace') to error and it didn't.
	// Fixed to pass the caller's own `replace' local through instead of
	// a hardcoded one, so an existing target file without `replace'
	// now correctly raises Stata's own "file already exists" error.
	//
	// BUGFIX (found immediately by the fix above): once this save can
	// actually fail, failing here used to abort the command before the
	// `use `existing', clear' line below ever ran - leaving the CALLER'S
	// OWN in-memory dataset stuck in this command's internal merged/
	// mutated working state (stray _nw_running/_nw_match_* columns etc.)
	// instead of restored, and the next command run in that same session
	// (including a corrected `nwsave ..., replace' retry) hit an
	// unrelated, confusing "variable _nw_running already defined" error
	// instead of ever surfacing the real problem. `capture` the save,
	// always restore the caller's original data either way, then
	// re-raise the real error/rc so failures are still reported.
	capture qui save`old' `webname'.nwdta, `replace' `options'
	local savercc = _rc
	use `existing', clear
	if `savercc' != 0 {
		error `savercc'
	}
end

