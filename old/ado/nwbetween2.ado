

capture program drop nwbetween2
program nwbetween2
	syntax [anything(name=netname)]
	
	drop _all
	nw_syntax `netname'
	unw_defs
	nwtoedge `netname', full
	
	rename `nw_ego' ego
	rename `nw_alter' alter
	rename `netname' value
	drop if value == 0 | value == .
	drop if alter == ego
    save edge_list, replace

	use edge_list, clear
	order ego alter
	rename alter alter_
	rename value value_
	bys ego: gen n = _n
	reshape wide alter_ value_, i(ego) j(n)
	gen cycle = 0
	save adj_list, replace

	use edge_list, clear
	rename ego ego0
	rename alter ego1
	rename value value0
	local egos "ego0 ego1"
	gen cycle = 0
	
	tempfile paths
	save `paths'
	tempfile temp
	
	local z = 12
	local k = 0
	local pathsleft = 1
	
	while (`pathsleft' == 1){
		local k = `k' + 1
		rename ego`k' ego
		merge m:m ego cycle using adj_list, nogenerate
		rename ego ego`k'
		reshape long alter_ value_, i(`egos' ) j(id)
		drop id
		forvalues i = 0/`k' {
			replace cycle = 1 if alter_ == "" | alter_ == ego`i'
		}
		rename alter_ ego`=`k'+1'
		rename value_ value`k'
		local egos "`egos' ego`=`k'+1'"
		drop if cycle == 1
		drop if ego0 == "" | value`k' == .
		save `temp', replace
		append using `paths'
		save `paths', replace
		if ego`k'[1] == "" {
			local pathsleft 0
		}
		use `temp', clear
	}
	
	use `paths', clear
	drop if ego2 == ""
	
	unab egos : ego*
	di "`egos'"
	gen start = ego0
	gen end = ego2
	foreach l of local `egos' {
		if "`l'" != "ego0" & "`l'" != "ego1" & "`l'" != "ego2" {
			replace end = `l' if `l' != ""
		}
	}
	
end


