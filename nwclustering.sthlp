

capture program drop nwclustering
program nwclustering
	version 9
	syntax [anything(name=netname)][, measure(string) SYMmetrize GENerate(string)]
	set more off
	
	unw_defs
	
	nw_syntax , max(1)
	nw_datasync 
	local original ""

	tempname symnet
	local symnet_created = 0
	if "" != ""  {
		nwsym , generate() mode(max)
		nw_syntax
		local symnet_created = 1
	}
	
	if "" == "" {
		local measure "binary"
	}
	
	_opts_oneof "binary arithmetic geometric maximum minimum" "measure" "" 6556
	
	if "" == "true" {
		di "{err}{pstd}Network is a two-mode network. Automatically, switched to command {bf:nw2clustering}."
		nw2clustering , measure() generate()
		exit
	}
	
	if ("" == "true" & "" != "binary") {
		di "{err}{pstd}Clustering coefficient not defined for networks that are both weighted and directed."
		di "{err}Either choose {bf:measure(binary)} or symmetrize the network."
		exit
	}
	
	if "" == "" {
		local generate = "_clustering"
	}
	
	capture drop 
	qui gen  = .
	
	tempfile temp clustering edge_list adj_list
	nw_syntax 
	nw_datasync 

	preserve
	
	qui {
	nw_syntax 
	unw_defs
	nwtoedge , full
	rename  ego
	rename  alter
	if "" != "value" {
		rename  value
	}
	drop if value == 0 | value == .
	drop if alter == ego
    save , replace

	use , clear
	order ego alter
	rename alter alter_
	rename value value_
	bys ego: gen n = _n
	reshape wide alter_ value_, i(ego) j(n)
	save , replace

	use , clear
	rename value value0
	rename ego ego0
	rename alter ego
	merge m:m ego using , nogenerate
	rename ego alter0
	reshape long alter_ value_, i(ego0 alter0) j(id)
	drop id
	drop if alter_ == "" | alter_ == ego0
	rename alter_ ego1
	rename value_ value1
	order ego0 value0 alter0 value1 ego1 

	rename ego0 ego
	merge m:m ego using , nogenerate
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
	gen closed_value = closed * 
	sum closed_value
	local closed_3paths = r(sum)
	sum 
	local potential_3paths = r(sum)
	
	capture bys ego1: egen pot = total()
	capture bys ego1: egen clo = total(closed_value)
	capture bys ego1: keep if _n == 1
	
	gen  = .
	capture replace  = clo / pot
	
	keep ego1 
	rename ego1 
	
	drop if  == ""
	save 

	sum 
	local C_avg = r(mean)

	restore
	capture drop 
	merge m:m  using , nogenerate
	
	}
	mata: st_rclear()
	mata: st_numscalar("r(cluster_global)", )
	mata: st_global("r(measure)", "")	
	mata: st_numscalar("r(cluster_avg)", )
	
	if "" != "" {
		local netname ""
	}
	
	noi di "{hline 40}"
	noi di "{txt}  Network name: {res}"
	if "" != "" {
		noi di "{txt}  Symmetrized: {res}true"
		mata: st_global("r(symmetrized)", "false")
	}
	noi di "{hline 40}"
	noi di "{txt}    Measure: {res}"
	noi di "{txt}    Average clustering coefficient: {res}0"
	noi di "{txt}    Global clustering coefficient: {res}0"
	noi di " "
	_return hold rcluster
	// BUGFIX:  is only ever actually created (tempname just
	// reserves a name, it doesn't create anything) when  was
	// given - the overwhelming common case (a plain "nwclustering
	// netname, generate(x)" call, no symmetrize) never creates it at
	// all, so this "capture nwdrop " legitimately failed
	// ("network not found") on every single ordinary call. 
	// swallows the failure, but "_return restore" (a low-level command
	// for restoring held r()-class results, not an ordinary Stata
	// command) does not itself reset  the way a normal successful
	// command would - so the stale nonzero  from the failed nwdrop
	// silently leaked out as this command's own return code on every
	// plain call. Confirmed directly: "nwclustering mynet, generate(x)"
	// on an already-undirected network returned _rc==482 despite
	// completing correctly and printing its own results - the exact
	// same bug class (a d cleanup on a conditionally-created
	// temp object, nothing afterward resetting ) already found and
	// fixed repeatedly elsewhere this session. Fixed by only attempting
	// the drop when  was actually created, guarded by the same
	// condition that created it - not just wrapping it more, since that
	// would still print the correct results while returning a
	// misleading nonzero code to any caller that checks .
	if  {
		capture nwdrop 
	}
	_return restore rcluster
end


last certified : 21 Aug 2026
