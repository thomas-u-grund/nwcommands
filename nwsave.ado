capture program drop nwsave
program nwsave
	// A former format(string) option was accepted by syntax but immediately
	// discarded - `format' below is `.nwdta''s own single, fixed internal
	// storage layout, not something a caller could ever meaningfully vary
	// (any value, including nonsense, was silently accepted and ignored).
	// Removed rather than wired up, since there is no second storage format
	// implemented anywhere in this file to select between.
	syntax anything [, old replace *]
	unw_defs
	// stops here when there is no network
	_nwsyntax _all, max(99999)
	// All work is done on a copy of the data in a second frame: the data in
	// memory, their order, c(filename) and c(changed) stay as they are, also
	// when the save fails. The current network is put back at the end.
	mata: st_local("__nws_current", `nws'.get_current_name())
	local __nws_home = c(frame)
	tempname __nws_frame
	frame copy `__nws_home' `__nws_frame'
	frame change `__nws_frame'
	capture noisily _nwsave_work `0'
	local __nws_rc = _rc
	quietly frame change `__nws_home'
	frame drop `__nws_frame'
	if "`__nws_current'" != "" capture mata: `nws'.make_current_from_name("`__nws_current'")
	if `__nws_rc' exit `__nws_rc'
	capture confirm number 0
end

capture program drop _nwsave_work
program _nwsave_work
	syntax anything [, old replace *]
	// anything keeps the quotes of a quoted file name (paths with spaces)
	local webname `anything'
	if regexm(`"`webname'"', "\.nwdta$") local webname = substr(`"`webname'"', 1, strlen(`"`webname'"') - 6)
	else if regexm(`"`webname'"', "\.dta$") local webname = substr(`"`webname'"', 1, strlen(`"`webname'"') - 4)
	unw_defs
	_nwsyntax _all, max(99999)
	local nets r(networks)

	// variables that nwload made from a network are copies of it, not data
	mata: _nwsave_dropcopies(tokens(`nws'.get_names()), `nws'.pdefs)
	// The file's own columns are named _nw_... and, for the tie values, like
	// the networks. A variable of the user with such a name is stored as
	// _nw_uvar# with its name in a characteristic; nwuse gives it back.
	mata: _nwsave_aside(tokens(st_local("netname")))
	// marks the observations that are in memory now: nwuse keeps them, also
	// those that belong to no node (the other rows of the file hold ties only)
	qui gen byte _nw_userrow = 1
	local __nws_dlabel : data label

	local format = "edgelist"

	
	// save attributes first
	qui foreach onenet in `netname' {
		_nwdatasync `onenet'
	}
	capture drop _nwinclude
	tempfile attributes
	qui gen _nw_running = _n
	qui save`old' `attributes', replace
	
	// obtain edgelists for each network together with entries to which network entry belongs
	_nwsyntax _all, max(99999)
	// The column that marks the nodes of a network is _nw_match_<name>; the file has it with the suffix _nw_ego, which
	// leaves 15 characters for the name. A network with a longer name gets _nw_m<number> instead (nwuse knows both).
	local __nws_i 0
	local __nws_keys ""
	qui foreach onenet in `netname' {
		local ++__nws_i
		if ustrlen("`onenet'") <= 15 local __nws_key`__nws_i' "_nw_match_`onenet'"
		else local __nws_key`__nws_i' "_nw_m`__nws_i'"
		local __nws_keys "`__nws_keys' `__nws_key`__nws_i''"
		_nwdatasync `onenet'
		gen `__nws_key`__nws_i'' = 1 if _nwinclude == 1
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
		local __nws_i 0
		qui foreach onenet in `netname' {
			local ++__nws_i
			use `__nws_prep', clear
			nwtoedge `onenet', egovars(`__nws_key`__nws_i'') ego(_nw_ego) alter(_nw_alter) ignore2mode compress aggregate
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
		qui nwtoedge _all, egovars(`__nws_keys') ego(_nw_ego) alter(_nw_alter) ignore2mode compress aggregate
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
		replace _nw_selfloops = "`r(selfloop)'" in `i'
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
	// Temporal networks (event times, times of the ties of snapshot networks, intervals): the file gets the columns _nw_ttype
	// and _nw_tvars (one row per network) and the rows of the temporal data in _nw_tnet, _nw_tego, _nw_talter, _nw_tt1, _nw_tt2
	// and _nw_tval. A file without a temporal network has none of these columns, and a version that does not know them
	// loads the (aggregated) ties of the network, so that a file stays readable by older versions.
	local __nws_anyt = 0
	qui foreach onenet in `netname' {
		nwname `onenet'
		if "`r(temporal)'" == "true" local __nws_anyt = 1
	}
	if `__nws_anyt' {
		qui gen str20 _nw_ttype = ""
		qui gen str244 _nw_tvars = ""
		local i = 1
		qui foreach onenet in `netname' {
			_nwsyntax `onenet', other(other)
			if "`otheristemporal'" == "true" {
				replace _nw_ttype = "`othertemporaltype'" in `i'
				mata: st_sstore(`i', "_nw_tvars", `othernetobj'->get_timevar() + "|" + `othernetobj'->get_startvar() + "|" + `othernetobj'->get_endvar() + "|" + `othernetobj'->get_eventtimevar())
			}
			local i = `i' + 1
		}
	}
	qui gen _nw_running = _n
	tempfile metadata
	qui save`old' `metadata', replace
	if `__nws_anyt' {
		tempfile __nws_tall __nws_tone
		local i = 1
		local __nws_tfirst = 1
		qui foreach onenet in `netname' {
			nwname `onenet'
			if "`r(temporal)'" == "true" {
				_nwtemporal pack `onenet', ego(_nw_tego) alter(_nw_talter) t1(_nw_tt1) t2(_nw_tt2) value(_nw_tval) tnet(`i')
				_nwtemporal drop
				if `__nws_tfirst' {
					save `__nws_tall', replace
					local __nws_tfirst = 0
				}
				else {
					append using `__nws_tall'
					save `__nws_tall', replace
				}
			}
			local i = `i' + 1
		}
		use `__nws_tall', clear
		qui gen _nw_running = _n
		qui save`old' `__nws_tone', replace
		use `metadata', clear
	}
	
	qui merge 1:1 _nw_running using `attributes', nogenerate
	qui merge 1:1 _nw_running using `edgelist', nogenerate
	if `__nws_anyt' {
		qui merge 1:1 _nw_running using `__nws_tone', nogenerate
	}
	
	if `"`__nws_dlabel'"' != "" label data `"`__nws_dlabel'"'

	// without -replace- an existing file stops here with Stata's own error
	qui save`old' `"`webname'.nwdta"', `replace' `options'
end

capture mata: mata drop _nwsave_nodesvar()
mata:
string rowvector _nwsave_nodesvar(pointer(class nw_def scalar) scalar p)
{
	return(p->get_nodesvar())
}
end
capture mata: mata drop _nwsave_dropcopies()
capture mata: mata drop _nwsave_aside()
mata:
// drop the variables that carry the mark of nwload and are still node
// variables of the network named in it
void _nwsave_dropcopies(string rowvector nets, pointer rowvector pdefs)
{
	real scalar i, j
	string scalar v, net
	string rowvector d
	d = J(1, 0, "")
	for (i = 1; i <= st_nvar(); i++) {
		v = st_varname(i)
		net = st_global(v + "[nwload]")
		if (net == "") continue
		for (j = 1; j <= cols(nets); j++) {
			if (nets[j] == net) {
				if (anyof(_nwsave_nodesvar(pdefs[j]), v)) d = (d, v)
				break
			}
		}
	}
	if (cols(d)) st_dropvar(d)
}
end
mata:
// rename the variables named _nw_... or like a network to _nw_uvar#
void _nwsave_aside(string rowvector nets)
{
	real scalar i, k
	string scalar v, nv
	string rowvector todo
	todo = J(1, 0, "")
	for (i = 1; i <= st_nvar(); i++) {
		v = st_varname(i)
		if (substr(v, 1, 4) == "_nw_" | anyof(nets, v)) todo = (todo, v)
	}
	k = 0
	for (i = 1; i <= cols(todo); i++) {
		do {
			nv = "_nw_uvar" + strofreal(++k)
		} while (_st_varindex(nv) != . | anyof(nets, nv))
		st_varrename(todo[i], nv)
		st_global(nv + "[nwsave_name]", todo[i])
	}
}
end
