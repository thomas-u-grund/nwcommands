capture program drop nw2toedge
program nw2toedge
	version 9
	syntax [anything(name=netname)][, isolates0 compress upper egovars(varlist) altervars(varlist)  ///
	ego(name) alter(name) full ignore2mode]

	unw_defs
	nw_syntax `netname', max(9999)
	local nets `netname'


	if "`ego'" == "" {
		local ego = "`nw_ego'"
	}
	if "`alter'" == "" {
		local alter = "`nw_alter'"
	}

	foreach net in `nets' {
		nw_datasync `net'
	}

	// Deal with two-mode networks
	if "`is2mode'" == "true"  & "`ignore2mode'" == ""{
		local egovars "`nw_mode' `egovars'"
		local altervars "`nw_mode' `altervars'"
	}

	// Handle attributes of nodes
	qui if "`egovars'" != "" {
		preserve
		tempfile fromfile
		keep `nw_nodename' `egovars'
		foreach var of varlist `egovars' {
			rename `var' `var'`ego'
		}
		save `fromfile'
		restore
	}

	qui if "`altervars'" != "" {
		preserve
		tempfile tofile
		keep `nw_nodename' `altervars'
		foreach var of varlist `altervars' {
			rename `var' `var'`alter'
		}
		save `tofile'
		restore
	}


	// Check if there is at least one directed network in the list
	qui foreach net in `nets' {
		nw_syntax `net'
		if "`directed'" == "true" {
			local full = "full"
		}
	}

	local i = 0
	qui foreach net in `nets' {
		nw_syntax `net'
		tempfile __nwedgelist`i'

		if "`upper'" != "" & "`directed'" == "true" {
			noi di "{txt}Warning! Network {res}`net'{txt} is directed. Option {res}upper{txt} surpressed."
		}
		mata: __nwedgelist`i' = (`netobj'->get_edgelist((("`upper'" != "" | "`directed'" == "false") & "`full'" == "")))[,(1::5)]
		preserve
		drop _all
		tempvar include
		tempvar transp
		getmata (`ego' `alter' `net' `include' `transp') = __nwedgelist`i', force
		destring `include', replace force
		capture drop if `include' != 1
		capture drop `include'
		destring `net', replace force
		mata: mata drop __nwedgelist`i'
		save `__nwedgelist`i''
		restore
		local i = `i' + 1
	}

	qui drop _all
	qui use `__nwedgelist0'

	qui forvalues j = 1/`=`i'-1' {
		merge m:n (`ego' `alter') using `__nwedgelist`j'', nogenerate
	}

	qui if trim("`egovars'") != "" {
		capture drop `nw_nodename'
		gen `nw_nodename' = `ego'
		merge m:n (`nw_nodename') using `fromfile', nogenerate
	}
	qui if trim("`altervars'") != "" {
		capture drop `nw_nodename'
		gen `nw_nodename' = `alter'
		merge m:n (`nw_nodename') using `tofile', nogenerate
	}
	capture drop `nw_nodename'
	sort `ego' `alter'
	qui if "`compress'" != "" {
		tempvar t
		gen `t' = 0
		foreach net in `nets' {
			replace `t' = `t' + abs(`net')
		}
		drop if `t' == 0
	}

	foreach net in `nets' {
		capture drop if `net' == `missing2'
	}
	// BUGFIX: this used to run unconditionally, but the `nw_mode'`ego'/
	// `nw_mode'`alter' variables it references only exist when the
	// two-mode block above (line ~94) actually ran - which it
	// deliberately skips when `ignore2mode' is given, since the whole
	// point of that option is to bypass 2-mode-specific handling. Any
	// two-mode network combined with `ignore2mode' crashed ("variable
	// not found") as a result - a completely ordinary, easily-triggered
	// combination. Guarded with the same condition as the block that
	// actually creates those variables.
	if "`is2mode'" == "true" & "`ignore2mode'" == "" {
		qui keep if `nw_mode'`ego' != `nw_mode'`alter'
	}

end
