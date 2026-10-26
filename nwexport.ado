
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
	// a two-mode network is written in Pajek's bipartite form: "*Vertices n n1", the n1 nodes of the first mode come
	// first, and every tie is listed from its first-mode node to its second-mode node
	local __n1 0
	if "`is2mode'" == "true" {
		tempvar __md __ord
		_nwexport_modevar `nw_mode', generate(`__md')
		qui count if `__md' == 1
		local __n1 = r(N)
		gen long `__ord' = _n
		sort `__md' `__ord'
	}
	gen `_running' = _n
	keep `nw_nodename' `_running'
	save `f', replace
	tempname expfile

	// the file is created (and refused if it exists without replace) here;
	// the vertex block and the tie rows are then written in blocks by Mata
	file open `expfile' using "`fname'.net", write `replace'
	file close `expfile'
	if "`is2mode'" == "true" {
		mata: nw_exp_pajek_vertices(st_local("fname") + ".net", "`nw_nodename'", `nodes', `__n1')
	}
	else {
		mata: nw_exp_pajek_vertices(st_local("fname") + ".net", "`nw_nodename'", `nodes')
	}

	qui nwtoedge `netname', compress
	qui keep if `netname' != 0
	// merge m:1 orders the rows of one alter arbitrarily; fix the order
	// (by alter label, then ego label) so a file is reproducible
	tempvar _rk
	sort `nw_alter' `nw_ego'
	gen long `_rk' = _n
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
	if "`is2mode'" == "true" {
		tempvar __a
		qui gen double `__a' = `nw_ego'
		qui replace `nw_ego' = `nw_alter' if `__a' > `__n1'
		qui replace `nw_alter' = `__a' if `__a' > `__n1'
	}
	sort `_rk'
	local __head "*Edges"
	if "`directed'" == "true" local __head "*Arcs"
	mata: nw_exp_ties(st_local("fname") + ".net", "`nw_ego'", "`nw_alter'", "`netname'", 0, "`__head'", char(10))
	restore
	// the level labels of a two-mode network: Pajek's format has no place for mode names, but a comment line
	// (starting with %) is ignored by Pajek and by the other readers; nwimport reads the labels back from it
	if "`is2mode'" == "true" {
		_nwexport_levels `netname'
		if "`r(has)'" == "1" {
			tempfile __tmp
			mata: nwx_insert_lines(st_local("fname") + ".net", st_local("__tmp"), "pajek", st_global("r(d1)"), st_global("r(d2)"))
			qui copy "`__tmp'" "`fname'.net", replace
		}
	}
end


capture program drop _nwexport_ucinet
program _nwexport_ucinet
	syntax [anything(name=netname)], fname(string) [replace]
	
	unw_defs
	_nwsyntax `netname'
	_nwdatasync `netname'
	// a two-mode network is written as a rectangular matrix (nr rows = first mode, nc columns = second mode) with
	// row and column labels; nwimport reads it back as a two-mode network
	if "`is2mode'" == "true" {
		capture confirm file "`fname'.dl"
		if _rc == 0 & "`replace'" == "" {
			di "{err}file `fname'.dl already exists"
			error 602
		}
		mata: nw_exp_ucinet_rect(st_local("fname") + ".dl", `netobj')
		exit
	}
	
	tempvar _running
	tempfile f
	
	preserve
	keep if _n <= `nodes'
	gen `_running' = _n
	keep `nw_nodename' `_running'
	save `f', replace
	tempname expfile
	
	file open `expfile' using "`fname'.dl", write `replace'
	file close `expfile'
	mata: nw_exp_ucinet_head(st_local("fname") + ".dl", `netobj'->get_nodenames())

	qui nwtoedge `netname', compress
	qui keep if `netname' != 0
	// merge m:1 orders the rows of one alter arbitrarily; fix the order
	// (by alter label, then ego label) so a file is reproducible
	tempvar _rk
	sort `nw_alter' `nw_ego'
	gen long `_rk' = _n
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
	sort `_rk'
	mata: nw_exp_ties(st_local("fname") + ".dl", "`nw_ego'", "`nw_alter'", "`netname'", ("`directed'" == "false"), "", char(10))
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
	file close `expfile'
	if "`is2mode'" == "true" {
		// the attribute nwmode (1 or 2) of every node keeps the two modes
		tempvar __md
		_nwexport_modevar `nw_mode', generate(`__md')
		mata: nw_exp_gml_nodes(st_local("fname") + ".gml", ("`directed'" == "true"), "`nw_nodename'", `nodes', "`__md'")
	}
	else {
		mata: nw_exp_gml_nodes(st_local("fname") + ".gml", ("`directed'" == "true"), "`nw_nodename'", `nodes')
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

	qui nwtoedge `netname', compress
	// `!= 0' alone lets nwtoedge's own diagonal self-rows through
	// whenever they hold a MISSING tie value rather than a real 0 (`.'
	// is not `== 0') - confirmed directly (a real, self-loop-free test
	// network still exported a spurious "Alice Alice ." edge) - matches
	// _nwexport_pajek's own already-correct `drop if `netname' == .'
	// step (further down that program), not reimplemented differently.
	qui keep if `netname' != 0 & `netname' != .
	tempvar _rk
	sort `nw_alter' `nw_ego'
	gen long `_rk' = _n
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

	sort `_rk'
	mata: nw_exp_gml_edges(st_local("fname") + ".gml", "`nw_ego'", "`nw_alter'", "`netname'")
	restore
	// the level labels of a two-mode network are graph attributes (nwmodelabel1, nwmodelabel2), written after the
	// line "directed"
	if "`is2mode'" == "true" {
		_nwexport_levels `netname'
		if "`r(has)'" == "1" {
			tempfile __tmp
			mata: nwx_insert_lines(st_local("fname") + ".gml", st_local("__tmp"), "gml", st_global("r(d1)"), st_global("r(d2)"))
			qui copy "`__tmp'" "`fname'.gml", replace
		}
	}
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
	_nwexport_levels `netname'
	local __lv1 `"`r(d1)'"'
	local __lv2 `"`r(d2)'"'
	local __haslv = ("`r(has)'" == "1")

	preserve
	qui nwtoedge `netname', compress
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
	if "`is2mode'" == "true" {
		// a two-mode network: every row runs from the first-mode node to the second-mode node and carries the two mode
		// numbers (1 and 2) in two more columns; nwimport recognises the five columns
		tempvar __swap __t
		qui gen str244 `__t' = `nw_ego'
		qui gen byte `__swap' = (`nw_mode'`nw_ego' == "2")
		qui replace `nw_ego' = `nw_alter' if `__swap'
		qui replace `nw_alter' = `__t' if `__swap'
		keep `nw_ego' `nw_alter' value
		// the two columns hold the numbers 1 and 2, or the level labels of the network when it has any (then
		// nwimport restores the labels)
		if `__haslv' {
			qui gen str244 mode_ego = `"`__lv1'"'
			qui gen str244 mode_alter = `"`__lv2'"'
		}
		else {
			qui gen byte mode_ego = 1
			qui gen byte mode_alter = 2
		}
		rename `nw_ego' ego
		rename `nw_alter' alter
		order ego alter value mode_ego mode_alter
		export delimited using "`fname'.txt", delimiter(tab) novarnames `replace'
		restore
		exit
	}
	keep `nw_ego' `nw_alter' value
	rename `nw_ego' ego
	rename `nw_alter' alter
	export delimited using "`fname'.txt", delimiter(tab) novarnames `replace'
	restore
end

// numeric mode (1 or 2) of the nodes of the data set into a new variable (the mode variable may be string or numeric)
capture program drop _nwexport_modevar
program _nwexport_modevar
	syntax varname, GENerate(name)
	capture confirm string variable `varlist'
	if _rc == 0 {
		qui gen byte `generate' = real(`varlist')
	}
	else {
		qui gen byte `generate' = `varlist'
	}
end


// the level labels of a two-mode network: r(has) = 1 when both are set, differ and are not the defaults "mode 1" / "mode 2"
capture program drop _nwexport_levels
program _nwexport_levels, rclass
	syntax [anything(name=netname)]
	unw_defs
	_nwsyntax `netname'
	mata: st_local("__d1", `netobj'->get_description_mode1())
	mata: st_local("__d2", `netobj'->get_description_mode2())
	// no double quote inside a label (it would end the quoted label in the files)
	local __d1 = subinstr(`"`__d1'"', `"""', "'", .)
	local __d2 = subinstr(`"`__d2'"', `"""', "'", .)
	local __has = (`"`__d1'"' != "" & `"`__d2'"' != "" & `"`__d1'"' != `"`__d2'"' & !(`"`__d1'"' == "mode 1" & `"`__d2'"' == "mode 2"))
	return local has "`__has'"
	return local d1 `"`__d1'"'
	return local d2 `"`__d2'"'
end

capture mata: mata drop nwx_insert_lines()
mata:
// copies file fname to tmp with the level label lines of a two-mode network (kind pajek: one comment line at the
// top; gml: two graph attributes after the first two lines)
void nwx_insert_lines(string scalar fname, string scalar tmp, string scalar kind, string scalar d1, string scalar d2)
{
	real scalar fh, fo, k, after
	string scalar line, buf, q
	string colvector add

	q = char(34)
	if (kind == "pajek") {
		after = 0
		add = "% nwcommands level labels " + q + d1 + q + " " + q + d2 + q
	}
	else {
		after = 2
		add = ("  nwmodelabel1 " + q + d1 + q \ "  nwmodelabel2 " + q + d2 + q)
	}
	(void) _unlink(tmp)
	fh = fopen(fname, "r")
	fo = fopen(tmp, "w")
	for (k = 1; k <= after; k++) {
		line = fget(fh)
		fput(fo, line)
	}
	for (k = 1; k <= rows(add); k++) fput(fo, add[k])
	while (1) {
		buf = fread(fh, 1000000)
		if (buf == J(0, 0, "")) break
		fwrite(fo, buf)
	}
	fclose(fh)
	fclose(fo)
}
end
