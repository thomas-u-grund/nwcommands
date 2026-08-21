

capture program drop nwclustering
program nwclustering
	version 9
	syntax [anything(name=netname)][, measure(string) SYMmetrize GENerate(string)]
	set more off
	
	unw_defs
	
	nw_syntax `netname', max(1)
	nw_datasync `netname'
	local original "`netname'"

	tempname symnet
	local symnet_created = 0
	if "`symmetrize'" != ""  {
		nwsym `netname', generate(`symnet') mode(max)
		nw_syntax
		local symnet_created = 1
	}
	
	if "`measure'" == "" {
		local measure "binary"
	}
	
	_opts_oneof "binary arithmetic geometric maximum minimum" "measure" "`measure'" 6556
	
	if "`is2mode'" == "true" {
		di "{err}{pstd}Network is a two-mode network. Automatically, switched to command {bf:nw2clustering}."
		nw2clustering `netname', measure(`measure') generate(`generate')
		exit
	}
	
	if ("`directed'" == "true" & "`measure'" != "binary") {
		di "{err}{pstd}Clustering coefficient not defined for networks that are both weighted and directed."
		di "{err}Either choose {bf:measure(binary)} or symmetrize the network."
		exit
	}
	
	if "`generate'" == "" {
		local generate = "_clustering"
	}
	
	capture drop `generate'
	qui gen `generate' = .
	
	tempfile temp clustering edge_list adj_list
	nw_syntax `netname'
	nw_datasync `netname'

	preserve
	
	qui {
	nw_syntax `netname'
	unw_defs
	nwtoedge `netname', full
	rename `nw_ego' ego
	rename `nw_alter' alter
	if "`netname'" != "value" {
		rename `netname' value
	}
	drop if value == 0 | value == .
	drop if alter == ego
    save `edge_list', replace

	use `edge_list', clear
	order ego alter
	rename alter alter_
	rename value value_
	bys ego: gen n = _n
	reshape wide alter_ value_, i(ego) j(n)
	save `adj_list', replace

	use `edge_list', clear
	rename value value0
	rename ego ego0
	rename alter ego
	merge m:m ego using `adj_list', nogenerate
	rename ego alter0
	reshape long alter_ value_, i(ego0 alter0) j(id)
	drop id
	drop if alter_ == "" | alter_ == ego0
	rename alter_ ego1
	rename value_ value1
	order ego0 value0 alter0 value1 ego1 

	rename ego0 ego
	merge m:m ego using `adj_list', nogenerate
	rename ego ego0
	reshape long alter_ value_, i(ego0 alter0 ego1) j(id)
	drop id
	drop if alter_ == ""
	rename value_ value2
	rename ego1 ego2
	rename alter0 ego1
	gen closed = (alter_ == ego2)
	collapse (max) closed, by(ego0 ego1 ego2 value0 value1)
	
	gen binary = 1
	gen arithmetic = (value0 + value1)/2
	gen geometric = sqrt(value0 * value1)
	gen minimum = min(value0, value1)
	gen maximum = max(value0, value1)

	drop if ego2 == ""
	gen closed_value = closed * `measure'
	sum closed_value
	local closed_3paths = r(sum)
	sum `measure'
	local potential_3paths = r(sum)
	
	capture bys ego1: egen pot = total(`measure')
	capture bys ego1: egen clo = total(closed_value)
	capture bys ego1: keep if _n == 1
	
	gen `generate' = .
	capture replace `generate' = clo / pot
	
	keep ego1 `generate'
	rename ego1 `nw_nodename'
	
	drop if `nw_nodename' == ""
	save `clustering'

	sum `generate'
	local C_avg = r(mean)

	restore
	capture drop `generate'
	merge m:m `nw_nodename' using `clustering', nogenerate
	
	}
	mata: st_rclear()
	mata: st_numscalar("r(cluster_global)", `=`closed_3paths' / `potential_3paths'')
	mata: st_global("r(measure)", "`measure'")	
	mata: st_numscalar("r(cluster_avg)", `C_avg')
	
	if "`symmetrize'" != "" {
		local netname "`original'"
	}
	
	noi di "{hline 40}"
	noi di "{txt}  Network name: {res}`netname'"
	if "`symmetrize'" != "" {
		noi di "{txt}  Symmetrized: {res}true"
		mata: st_global("r(symmetrized)", "false")
	}
	noi di "{hline 40}"
	noi di "{txt}    Measure: {res}`measure'"
	noi di "{txt}    Average clustering coefficient: {res}`=round(`r(cluster_avg)',0.001)'"
	noi di "{txt}    Global clustering coefficient: {res}`=round(`r(cluster_global)',0.001)'"
	noi di " "
	_return hold rcluster
	// BUGFIX: `symnet' is only ever actually created (tempname just
	// reserves a name, it doesn't create anything) when `symmetrize' was
	// given - the overwhelming common case (a plain "nwclustering
	// netname, generate(x)" call, no symmetrize) never creates it at
	// all, so this "capture nwdrop `symnet'" legitimately failed
	// ("network not found") on every single ordinary call. `capture'
	// swallows the failure, but "_return restore" (a low-level command
	// for restoring held r()-class results, not an ordinary Stata
	// command) does not itself reset `_rc' the way a normal successful
	// command would - so the stale nonzero `_rc' from the failed nwdrop
	// silently leaked out as this command's own return code on every
	// plain call. Confirmed directly: "nwclustering mynet, generate(x)"
	// on an already-undirected network returned _rc==482 despite
	// completing correctly and printing its own results - the exact
	// same bug class (a `capture'd cleanup on a conditionally-created
	// temp object, nothing afterward resetting `_rc') already found and
	// fixed repeatedly elsewhere this session. Fixed by only attempting
	// the drop when `symnet' was actually created, guarded by the same
	// condition that created it - not just wrapping it more, since that
	// would still print the correct results while returning a
	// misleading nonzero code to any caller that checks `_rc'.
	if `symnet_created' {
		capture nwdrop `symnet'
	}
	_return restore rcluster
end


