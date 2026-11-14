
capture program drop nwexport
program nwexport, rclass
	version 9
	syntax [anything(name=netname)], type(string) [FName(string asis) replace AGGregate]	
	
	_nwsyntax `netname', max(1)
	_opts_oneof "pajek ucinet gml edgelist" "type" "`type'" 6556

	// a temporal network: only the edge list can hold the times; the other formats refuse unless the aggregation over
	// all times is asked for
	if "`istemporal'" == "true" & "`aggregate'" == "" {
		if "`type'" != "edgelist" | "`is2mode'" == "true" {
			if "`type'" == "edgelist" {
				di "{err}{p 0 0 2}Network {bf:`netname'} is temporal (`temporaltype'): the edge list of a two-mode network cannot hold times. Use {help nwsave} to keep the temporal network, or specify {bf:aggregate} to export the ties aggregated over all times.{p_end}"
			}
			else {
				di "{err}{p 0 0 2}Network {bf:`netname'} is temporal (`temporaltype'): the format {bf:`type'} cannot hold times. Use {bf:type(edgelist)} to write the times (one-mode networks), {help nwsave} to keep the temporal network, or specify {bf:aggregate} to export the ties aggregated over all times.{p_end}"
			}
			exit 198
		}
	}

	if `"`fname'"' == "" {
		local fname = "`netname'"
	}

	di `"{txt}Exporting network: {it:`netname'}"'
	// the data synchronisation of the writers may move a variable: keep the order
	local __nwx_order ""
	if c(k) > 0 unab __nwx_order : _all
	local ending ""
	local __nwx_rc 0
	if "`type'" == "pajek" {
		 capture noisily qui _nwexport_pajek `netname', fname(`fname') `replace'
		 local __nwx_rc = _rc
		 local ending ".net"
	}
	if "`type'" == "ucinet" {
		 capture noisily qui _nwexport_ucinet `netname', fname(`fname') `replace'
		 local __nwx_rc = _rc
		 local ending ".dl"
	}
	if "`type'" == "gml" {
		 capture noisily qui _nwexport_gml `netname', fname(`fname') `replace'
		 local __nwx_rc = _rc
		 local ending ".gml"
	}
	if "`type'" == "edgelist" {
		 capture noisily qui _nwexport_edgelist `netname', fname(`fname') `replace' `aggregate'
		 local __nwx_rc = _rc
		 local ending ".txt"
	}
	if "`__nwx_order'" != "" capture order `__nwx_order'
	if `__nwx_rc' exit `__nwx_rc'
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

	qui nwtoedge `netname', compress aggregate
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
	// a binary one-mode network is written without tie values, so that it is read back as binary
	if "`valued'" == "false" & "`is2mode'" != "true" {
		mata: nwx_exp_pairs(st_local("fname") + ".net", "`nw_ego'", "`nw_alter'", 0, "`__head'", char(10))
	}
	else {
		mata: nw_exp_ties(st_local("fname") + ".net", "`nw_ego'", "`nw_alter'", "`netname'", 0, "`__head'", char(10))
	}
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
			exit 602
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
	// labels with a blank are written in double quotes
	mata: nwx_exp_ucinet_head(st_local("fname") + ".dl", `netobj'->get_nodenames())

	qui nwtoedge `netname', compress aggregate
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
	if "`valued'" == "false" {
		mata: nwx_exp_pairs(st_local("fname") + ".dl", "`nw_ego'", "`nw_alter'", ("`directed'" == "false"), "", char(10))
	}
	else {
		mata: nw_exp_ties(st_local("fname") + ".dl", "`nw_ego'", "`nw_alter'", "`netname'", ("`directed'" == "false"), "", char(10))
	}
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

	qui nwtoedge `netname', compress aggregate
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
	if "`valued'" == "false" & "`is2mode'" != "true" {
		mata: nwx_exp_gml_pairs(st_local("fname") + ".gml", "`nw_ego'", "`nw_alter'")
	}
	else {
		mata: nw_exp_gml_edges(st_local("fname") + ".gml", "`nw_ego'", "`nw_alter'", "`netname'")
	}
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
	syntax [anything(name=netname)], fname(string) [replace AGGregate]

	unw_defs
	_nwsyntax `netname'
	// temporal network: one row per event (snapshot observation, interval) with the time column(s) last:
	// ego alter [value] time, or ego alter [value] start end; nwimport reads it back with the option eventtime, time or interval
	if "`istemporal'" == "true" & "`aggregate'" == "" {
		local __tx_type "`temporaltype'"
		preserve
		qui nwtoedge `netname', time ego(ego) alter(alter)
		if "`__tx_type'" == "interval" local __tx_cols "_start _end"
		else local __tx_cols "_time"
		capture confirm variable _value
		local __tx_v = cond(_rc == 0, "_value", "")
		keep ego alter `__tx_v' `__tx_cols'
		order ego alter `__tx_v' `__tx_cols'
		export delimited using "`fname'.txt", delimiter(tab) novarnames `replace'
		restore
		exit
	}
	_nwdatasync `netname'
	_nwexport_levels `netname'
	local __lv1 `"`r(d1)'"'
	local __lv2 `"`r(d2)'"'
	local __haslv = ("`r(has)'" == "1")

	preserve
	qui nwtoedge `netname', compress aggregate
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
	// a binary network: ego and alter only, read back as binary
	if "`valued'" == "false" drop value
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
capture mata: mata drop nwx_exp_pairs()
capture mata: mata drop nwx_exp_ucinet_head()
capture mata: mata drop nwx_exp_gml_pairs()
mata:
void nwx_exp_ucinet_head(string scalar fname, string rowvector names)
{
	real scalar fh
	string scalar nl
	string rowvector q
	real scalar i

	nl = char(10)
	q = names
	for (i = 1; i <= cols(q); i++) {
		if (strpos(q[i], " ") | strpos(q[i], ",")) q[i] = char(34) + q[i] + char(34)
	}
	(void) _unlink(fname)
	fh = fopen(fname, "w")
	fwrite(fh, "dl n=" + strofreal(cols(names), "%18.0g") + nl + "format = edgelist1" + nl + "labels:" + nl + invtokens(q, ",") + nl + "data:")
	fclose(fh)
}

// ties of a binary network: "ego alter" per line (both directions with both = 1)
void nwx_exp_pairs(string scalar fname, string scalar vk, string scalar vl, real scalar both, string scalar head, string scalar tail)
{
	real scalar fh, n, a, b, chunk
	string scalar nl
	string colvector ks, ls, s

	nl = char(10)
	fh = fopen(fname, "a")
	fwrite(fh, head)
	n = st_nobs()
	chunk = 200000
	for (a = 1; a <= n; a = a + chunk) {
		b = min((a + chunk - 1, n))
		ks = strofreal(st_data((a::b), vk), "%18.0g")
		ls = strofreal(st_data((a::b), vl), "%18.0g")
		s = nl :+ ks :+ " " :+ ls
		if (both) s = s :+ (nl :+ ls :+ " " :+ ks)
		fwrite(fh, invtokens(s', ""))
	}
	fwrite(fh, tail)
	fclose(fh)
}

// GML edges of a binary network: source and target, no value
void nwx_exp_gml_pairs(string scalar fname, string scalar vk, string scalar vl)
{
	real scalar fh, n, a, b, chunk
	string scalar nl
	string colvector s

	nl = char(10)
	fh = fopen(fname, "a")
	n = st_nobs()
	chunk = 200000
	for (a = 1; a <= n; a = a + chunk) {
		b = min((a + chunk - 1, n))
		s = ("  edge [" + nl + "    source ") :+ strofreal(st_data((a::b), vk), "%18.0g") :+ (nl + "    target ") :+ strofreal(st_data((a::b), vl), "%18.0g") :+ (nl + "  ]" + nl)
		fwrite(fh, invtokens(s', ""))
	}
	fwrite(fh, "]" + nl)
	fclose(fh)
}

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
