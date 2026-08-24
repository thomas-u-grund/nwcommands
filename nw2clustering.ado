

capture program drop nw2clustering
program nw2clustering
	syntax [anything(name=netname)][, measure(string) level(int 1) GENerate(string)]
	
	unw_defs

	if "`generate'" == "" {
		local generate = "_clustering2_lev`level'"
	}

	tempfile temp clustering edge_list ego_list alter_list
	nw_syntax `netname'
	nw_datasync `netname'

	// Auto-detect from the network's own stored valued/unvalued state
	// rather than always defaulting to "binary" regardless - matching
	// the netmeasure auto-detection convention already established in
	// nwcommunity.ado/nwconcor.ado/nwcoreperiphery.ado/nwmodularity.ado/
	// nwspectral.ado (and nwclustering.ado's own identical fix). Moved
	// below nw_syntax so `valued' is actually populated before this
	// check runs - it wasn't, previously.
	if "`measure'" == "" {
		if "`valued'" == "true" {
			local measure "arithmetic"
		}
		else {
			local measure "binary"
		}
	}
	_opts_oneof "binary arithmetic geometric maximum minimum" "measure" "`measure'" 6556

	qui {
	
	preserve

	nwtoedge `netname'
	keep if `netname' != 0 & _nwmode_ego == "`level'"
	if "`measure'" == "binary" {
		replace `netname' = (`netname' != 0)
		local measure = "arithmetic"
	}
	rename `nw_ego' ego
	rename `nw_alter' alter
	rename `netname' value
    save `edge_list'

	order alter ego
	rename ego ego_
	rename value value_
	bys alter: gen n = _n
	reshape wide ego_ value_, i(alter) j(n)
	save `alter_list'

	use `edge_list', clear
	order ego alter
	rename alter alter_
	rename value value_
	bys ego: gen n = _n
	reshape wide alter_ value_, i(ego) j(n)
	save `ego_list'

	use `edge_list', clear
	rename value value0
	rename ego ego0
	merge m:m alter using `alter_list', nogenerate
	// PERFORMANCE/CORRECTNESS FIX: this command has always crashed on
	// any bipartite network with a reshape error ("variable ... does
	// not uniquely identify the observations", r(9)), confirmed
	// reproducible even on a tiny 4-node network - not an edge case.
	// Root cause: an m:m merge against a per-key-unique `using' table
	// (alter_list/ego_list are each keyed uniquely by construction, via
	// their own earlier `reshape wide ... i(alter)/i(ego)') broadcasts
	// the SAME using-side row to every master-side row sharing that
	// key - so if the master side already has more than one row for a
	// given key (a real possibility this far into a multi-hop path
	// enumeration), those rows come out of the merge bit-for-bit
	// identical, not just sharing the same key. Confirmed directly
	// (`duplicates report' vs `duplicates report' restricted to the
	// reshape's own i()-varlist gave identical counts) - these are
	// pure redundant broadcast copies, not rows differing in some
	// other column, so dropping the surplus is lossless. The identical
	// pattern recurs at every merge+reshape step below (this function
	// walks a growing ego0-alter0-ego1-alter1-ego2-alter2-ego3 4-path,
	// one hop merged in at a time) - fixed at all of them, not just the
	// one specific network structure that happened to crash first.
	duplicates drop
	rename alter alter0
	reshape long ego_ value_, i(ego0 alter0) j(id)
	drop id
	drop if ego_ == "" | ego_ == ego0
	rename ego_ ego1
	rename value_ value1
	order ego0 value0 alter0 value1 ego1 

	rename ego1 ego
	merge m:m ego using `ego_list', nogenerate
	// same redundant-broadcast-duplicate fix as the first merge above.
	duplicates drop
	reshape long alter_ value_, i(ego0 alter0 ego) j(id)
	drop id
	drop if alter_ == "" | alter_ == alter0

	rename ego ego1
	rename alter_ alter1
	rename value_ value2
	order ego0 value0 alter0 value1 ego1 value2 alter1

	rename alter1 alter
	merge m:m alter using `alter_list', nogenerate
	// same redundant-broadcast-duplicate fix as the first merge above.
	duplicates drop
	reshape long ego_ value_, i(ego0 alter0 ego1 alter) j(id)
	drop id 
	drop if ego_ == "" | ego_ == ego1 | ego_ == ego0
	rename ego_ ego2
	rename value_ value3
	rename alter alter1
	order ego0 value0 alter0 value1 ego1 value2 alter1 value3 ego2

	gen potential_4path = 1
	gen arithmetic = (value0 + value1 + value2 + value3) / 4
	gen geometric = (value0 * value1 * value2 * value3)^(1/4)
	gen maximum = max(value0, value1, value2, value3)
	gen minimum = min(value0, value1, value2, value3)
	sum `measure'
	local potential_4paths = r(sum)
	save `temp', replace

	//// Check which ones are closed
	rename ego2 ego
	merge m:m ego using `ego_list', nogenerate
	drop if potential_4path == .
	// same redundant-broadcast-duplicate fix as the first merge above.
	duplicates drop
	reshape long alter_ ,i(ego0 alter0 ego1 alter1 ego) j(alter)
	drop if alter_ == alter0 | alter_ == alter1
	rename ego ego2
	rename alter_ alter2
	drop alter

	order ego0 alter0 ego1 alter1 ego2 alter2
	rename alter2 alter
	merge m:m alter using `alter_list', nogenerate
	drop if potential_4path == .
	// same redundant-broadcast-duplicate fix as the first merge above.
	duplicates drop
	reshape long ego_, i(ego0 alter0 ego1 alter1 ego2 alter) j(ego)
	drop if ego_ == ""
	drop ego
	rename ego_ ego3
	rename alter alter2
	order ego0 alter0 ego1 alter1 ego2 alter2 ego3
	gen closed = (ego0 == ego3) 
	keep ego0 value0 alter0 value1 ego1 value2 alter1 value3 ego2 arithmetic geometric maximum minimum closed
	collapse (max) closed, by(ego0 value0 alter0 value1 ego1 value2 alter1 value3 ego2 arithmetic geometric maximum minimum)

	merge m:m  ego0 value0 alter0 value1 ego1 value2 alter1 value3 ego2 arithmetic geometric maximum minimum using `temp', nogenerate

	gen closed_value = closed * `measure'
	sum closed_value
	local closed_4paths = r(sum)

	bys ego1: egen pot = total(`measure')
	bys ego1: egen clo = total(closed_value)
	bys ego1: keep if _n == 1
	list _all
	gen `generate' = clo / pot
	keep ego1 `generate'
	rename ego1 _nwnode
	save `clustering'

	sum `generate'
	local C_avg = r(mean)
	
	restore
	merge m:m `nw_nodename' using `clustering', nogenerate
	}
	
	mata: st_rclear()
	mata: st_numscalar("r(C_global)", `=`closed_4paths' / `potential_4paths'')
	mata: st_global("r(measure)", "`measure'")	
	mata: st_numscalar("r(C_avg)", `C_avg')
end











