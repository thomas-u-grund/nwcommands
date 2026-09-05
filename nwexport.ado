
capture program drop nwexport
program nwexport
	version 9
	syntax [anything(name=netname)], type(string) [FName(string asis) replace]	
	
	_nwsyntax `netname', max(1)
	_opts_oneof "pajek ucinet gml edgelist" "type" "`type'" 6556

	if `"`fname'"' == "" {
		local fname = "`netname'"
	}

	di `"{txt}Exporting network: {it:`netname'}"'
	local ending ""
	if "`type'" == "pajek" {
		 qui _nwexport_pajek `netname', fname(`fname') `replace'
		 local ending ".net"
	}
	if "`type'" == "ucinet" {
		 qui _nwexport_ucinet `netname', fname(`fname') `replace'
		 local ending ".dl"
	}
	if "`type'" == "gml" {
		 qui _nwexport_gml `netname', fname(`fname') `replace'
		 local ending ".gml"
	}
	if "`type'" == "edgelist" {
		 qui _nwexport_edgelist `netname', fname(`fname') `replace'
		 local ending ".txt"
	}
	di `"{txt}Saved as file: {it:`fname'`ending'}"'
end


capture program drop _nwexport_pajek
program _nwexport_pajek
	syntax [anything(name=netname)], fname(string) [replace]
	
	unw_defs
	_nwsyntax `netname'
	_nwdatasync `netname'
	
	tempvar _running
	tempfile f
	
	preserve
	keep if _n <= `nodes'
	gen `_running' = _n
	keep `nw_nodename' `_running'
	save `f', replace
	tempname expfile

	file open `expfile' using "`fname'.net", write `replace'
	file write `expfile' "*Vertices `nodes'" _newline
	forvalues i = 1/`nodes' {
		file write `expfile' (`i')
		file write `expfile' ("   ")
		file write `expfile' (char(34))
		file write `expfile' (`nw_nodename'[`i'])
		file write `expfile' (char(34)) _newline	
	}
	
	if ("`directed'" == "true"){
		file write `expfile' "*Arcs"
	}
	else {
		file write `expfile' "*Edges"
	}
	
	qui nwtoedge `netname'
	qui keep if `netname' != 0
	gen `nw_nodename' = `nw_ego'
	merge m:1 `nw_nodename' using `f'
	drop if _merge != 3
	drop _merge 
	drop `nw_ego'
	rename `_running' `nw_ego'
	drop `nw_nodename'
	
	gen `nw_nodename' = `nw_alter'
	merge m:1 `nw_nodename' using `f'
	drop if _merge != 3
	drop _merge `nw_alter'
	rename `_running' `nw_alter'
	drop `nw_nodename'
	local ties = _N
	drop if `netname' == .
	forvalues i = 1/`=_N' {
		if `netname'[`i'] != 0 {
			local value = `netname'[`i']
			local k = `nw_ego'[`i']
			local l = `nw_alter'[`i']
			file write `expfile' _newline
			file write `expfile' (`k')
			file write `expfile' " "
			file write `expfile' (`l')
			file write `expfile' " `value'" 	
		}
	
	}
	file write `expfile' "" _newline
	file close `expfile'	
	restore
end


capture program drop _nwexport_ucinet
program _nwexport_ucinet
	syntax [anything(name=netname)], fname(string) [replace]
	
	unw_defs
	_nwsyntax `netname'
	_nwdatasync `netname'
	
	tempvar _running
	tempfile f
	
	preserve
	keep if _n <= `nodes'
	gen `_running' = _n
	keep `nw_nodename' `_running'
	save `f', replace
	tempname expfile
	
	nwname `netname'
	file open `expfile' using "`fname'.dl", write `replace'
	file write `expfile' "dl n=`nodes'" _newline
	file write `expfile' "format = edgelist1" _newline
	file write `expfile' "labels:" _newline
	file write `expfile' "`r(labs)'" _newline
	file write `expfile' "data:"

	qui nwtoedge `netname'
	qui keep if `netname' != 0
	gen `nw_nodename' = `nw_ego'
	merge m:1 `nw_nodename' using `f'
	drop if _merge != 3
	drop _merge 
	drop `nw_ego'
	rename `_running' `nw_ego'
	drop `nw_nodename'
	
	gen `nw_nodename' = `nw_alter'
	merge m:1 `nw_nodename' using `f'
	drop if _merge != 3
	drop _merge `nw_alter'
	rename `_running' `nw_alter'
	drop `nw_nodename'
	local ties = _N
	drop if `netname' == .
	forvalues i = 1/`=_N' {
		if `netname'[`i'] != 0 {
			local value = `netname'[`i']
			local k = `nw_ego'[`i']
			local l = `nw_alter'[`i']
			file write `expfile' _newline
			file write `expfile' (`k')
			file write `expfile' " "
			file write `expfile' (`l')
			file write `expfile' " `value'" 	
			if "`directed'" == "false" {
				file write `expfile' _newline
				file write `expfile' (`l')
				file write `expfile' " "
				file write `expfile' (`k')
				file write `expfile' " `value'"
			}
		}
	}
	file write `expfile' "" _newline
	file close `expfile'
	restore
end


// GML export - matches the token-based dialect nwimport's own
// _nwimport_gml() parses (a `graph [ node [ id N label "..." ] edge [
// source N target N ] ]' subset, not the full GML spec): a plain,
// minimal writer, following the exact same nwtoedge-based row-building
// pattern _nwexport_pajek/_nwexport_ucinet already use above. Edge
// weight is written as a `value' attribute (real GML practice) but
// nwimport's own GML reader never reads it back - disclosed in this
// file's own .sthlp, not silently lost.
capture program drop _nwexport_gml
program _nwexport_gml
	syntax [anything(name=netname)], fname(string) [replace]

	unw_defs
	_nwsyntax `netname'
	_nwdatasync `netname'

	tempname expfile
	file open `expfile' using "`fname'.gml", write `replace'
	file write `expfile' "graph [" _newline
	file write `expfile' ("  directed " + cond("`directed'"=="true", "1", "0")) _newline
	forvalues i = 1/`nodes' {
		file write `expfile' "  node [" _newline
		file write `expfile' ("    id " + strofreal(`i')) _newline
		file write `expfile' ("    label " + char(34) + `nw_nodename'[`i'] + char(34)) _newline
		file write `expfile' "  ]" _newline
	}

	// `nw_ego'/`nw_alter' (nwtoedge's own output) are node LABELS, not
	// numeric positions (confirmed directly the same way
	// _nwexport_pajek's own header comment already documents) - GML's
	// `source'/`target' need the numeric `id' declared in each node
	// block above, so labels are remapped back to 1..`nodes' the same
	// merge-against-a-name/position-lookup-table way _nwexport_pajek
	// already does, not reimplemented differently.
	tempvar _running
	tempfile f
	preserve
	keep if _n <= `nodes'
	gen `_running' = _n
	keep `nw_nodename' `_running'
	save `f', replace

	qui nwtoedge `netname'
	// `!= 0' alone lets nwtoedge's own diagonal self-rows through
	// whenever they hold a MISSING tie value rather than a real 0 (`.'
	// is not `== 0') - confirmed directly (a real, self-loop-free test
	// network still exported a spurious "Alice Alice ." edge) - matches
	// _nwexport_pajek's own already-correct `drop if `netname' == .'
	// step (further down that program), not reimplemented differently.
	qui keep if `netname' != 0 & `netname' != .
	gen `nw_nodename' = `nw_ego'
	merge m:1 `nw_nodename' using `f'
	drop if _merge != 3
	drop _merge `nw_ego' `nw_nodename'
	rename `_running' `nw_ego'

	gen `nw_nodename' = `nw_alter'
	merge m:1 `nw_nodename' using `f'
	drop if _merge != 3
	drop _merge `nw_alter' `nw_nodename'
	rename `_running' `nw_alter'

	local nties = _N
	forvalues i = 1/`nties' {
		local k = `nw_ego'[`i']
		local l = `nw_alter'[`i']
		local value = `netname'[`i']
		file write `expfile' "  edge [" _newline
		file write `expfile' ("    source " + strofreal(`k')) _newline
		file write `expfile' ("    target " + strofreal(`l')) _newline
		file write `expfile' ("    value " + strofreal(`value')) _newline
		file write `expfile' "  ]" _newline
	}
	restore

	file write `expfile' "]" _newline
	file close `expfile'
end


// Plain tab-delimited (ego, alter, value) edgelist export - node
// LABELS, not positions (unlike pajek/gml above, which both need a
// numeric vertex id) - matches nwimport's own type(edgelist) default
// tab-delimited auto-detection (_nwimport_edgelist.ado) directly, no
// numeric id/lookup step needed on either side of the round-trip.
capture program drop _nwexport_edgelist
program _nwexport_edgelist
	syntax [anything(name=netname)], fname(string) [replace]

	unw_defs
	_nwsyntax `netname'
	_nwdatasync `netname'

	preserve
	qui nwtoedge `netname'
	// `!= 0' alone lets nwtoedge's own diagonal self-rows through
	// whenever they hold a MISSING tie value rather than a real 0 - see
	// _nwexport_gml's own identical comment above.
	qui keep if `netname' != 0 & `netname' != .
	// `nw_ego'/`nw_alter' (nwtoedge's own output) are ALREADY the node
	// LABELS themselves (confirmed directly - a string-labeled test
	// network's own `_ego'/`_alter' held "Alice"/"Bob", not a numeric
	// position), unlike pajek/gml's own numeric vertex-id requirement -
	// no lookup/remapping needed here at all, matching nwimport's own
	// type(edgelist) importer, which reads ego/alter as plain labels.
	rename `netname' value
	keep `nw_ego' `nw_alter' value
	rename `nw_ego' ego
	rename `nw_alter' alter
	export delimited using "`fname'.txt", delimiter(tab) novarnames `replace'
	restore
end

