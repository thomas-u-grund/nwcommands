capture program drop nwuse
program nwuse
	syntax anything [, nwclear nwappend force clear *]
	local __changed = c(changed)
	unw_defs
	// anything keeps the quotes of a quoted file name (paths with spaces)
	local basename `anything'
	if regexm(`"`basename'"', "\.nwdta$") local basename = substr(`"`basename'"', 1, strlen(`"`basename'"') - 6)
	else if regexm(`"`basename'"', "\.dta$") local basename = substr(`"`basename'"', 1, strlen(`"`basename'"') - 4)

	if "`nwclear'" == "" {
		qui nwset
		if "`nwappend'" == "" & (`r(networks)' > 0 | "`r(networks)'" == "") {
			di "{err}No; data in memory would be lost. Specify either option {bf:nwclear} or {bf:nwappend}."
			exit 999
		}
	}

	if `__changed' & (_N > 0 | c(k) > 0) & "`nwclear'`nwappend'`clear'" == "" {
		di "{err}{p 0 0 2}no; data in memory would be lost. Save them first, or specify option {bf:clear}, {bf:nwclear} or {bf:nwappend}.{p_end}"
		exit 4
	}

	// the networks that exist now, to put things back after a failure
	local __nwu_before ""
	local __nwu_current ""
	capture mata: st_local("__nwu_before", invtokens(`nws'.get_names()))
	capture mata: st_local("__nwu_current", `nws'.get_current_name())
	capture mata: mata drop __nwuse_hold

	// The file is read and the networks are built in a second frame, on a
	// copy of the data: the data in memory are replaced only when all of it
	// has worked.
	tempfile result
	local __nwu_home = c(frame)
	tempname __nwu_frame
	frame copy `__nwu_home' `__nwu_frame'
	frame change `__nwu_frame'
	local __nwu_plain ""
	local __nwu_held ""
	capture noisily _nwuse_work, basename(`"`basename'"') result(`"`result'"') `nwclear' `nwappend' `force' current(`__nwu_current')
	local __nwu_rc = _rc

	if `__nwu_rc' {
		// put the networks back as they were (on the copy of the data)
		if "`__nwu_held'" != "" {
			// option nwclear had set the old networks aside
			capture mata: mata drop `nw'
			mata: `nw' = _nwuse_ref(__nwuse_hold)
		}
		else {
			local __nwu_after ""
			capture mata: st_local("__nwu_after", invtokens(`nws'.get_names()))
			local __nwu_new : list __nwu_after - __nwu_before
			if "`__nwu_before'" == "" & "`__nwu_new'" != "" {
				capture mata: mata drop `nw'
			}
			else {
				foreach onenet of local __nwu_new {
					capture nwdrop `onenet'
				}
			}
		}
		if "`__nwu_current'" != "" capture mata: `nws'.make_current_from_name("`__nwu_current'")
	}
	capture mata: mata drop __nwuse_hold
	capture mata: mata drop __nwmd
	quietly frame change `__nwu_home'
	frame drop `__nwu_frame'
	if `__nwu_rc' exit `__nwu_rc'

	if "`__nwu_plain'" != "" {
		qui use `"`basename'.dta"', clear
		di "{txt}{p 0 0 2}(plain Stata dataset loaded - not a saved {help nwsave:network} file; build a network from it directly, e.g. with {help nwfromedge} or {help nwgenerate}){p_end}"
		exit
	}
	qui use `"`result'"', clear
	// The data have not been saved (c(changed) is 1), and they belong to no
	// file: S_FN holds c(filename), so that -save, replace- cannot write
	// plain data over the network file.
	// (a temporary variable would not count as a change; the file holds no
	// variable of this name, they all were restored under their own names)
	capture confirm new variable _nw_changed
	if _rc == 0 {
		qui gen byte _nw_changed = .
		drop _nw_changed
	}
	global S_FN ""
	global S_FNDATE ""
	capture confirm number 0
end

// Reads the file into the current frame, which holds a copy of the user's
// data, builds the networks and saves the data that nwuse is to leave in
// memory in result(). Sets the caller's local __nwu_plain for a file that is
// a plain Stata dataset and __nwu_held when the networks have been set aside
// for option nwclear.
capture program drop _nwuse_work
program _nwuse_work
	syntax , basename(string asis) result(string asis) [nwclear nwappend force current(string)]
	unw_defs
	local basename `basename'
	local result `result'

	local __nwu_k = c(k)
	tempfile existing
	if "`nwappend'" != "" & "`nwclear'" == "" & `__nwu_k' > 0 {
		qui save `"`existing'"', emptyok
	}

	// BUGFIX: this used to unconditionally force a ".nwdta" suffix onto
	// every target (local or web), so any of this package's own example
	// datasets that are plain .dta files rather than a genuine nwsave()
	// restoration file (gang2/hpotter/institutions/klas12b/stockholm/
	// usstates/example1 - see netexample.sthlp, which already advertises
	// `nwwebuse usstates`/`nwwebuse klas12b`/etc. as the intended way to
	// load them) could never be loaded via nwuse/nwwebuse at all - it
	// always tried to fetch a nonexistent "<name>.nwdta" and
	// crashed, well before ever reaching the confirm-variable check
	// below that would have been the natural place to detect a plain
	// dataset. Only florentine/gang/glasgow actually ship a .nwdta
	// counterpart (confirmed against the data host's own listing).
	// Fixed to try .nwdta first (the common, documented case: a network
	// saved with nwsave), falling back to plain .dta - and, if loaded
	// that way, skipping the network-restoration logic entirely rather
	// than crashing on the missing _nw_* metadata columns.
	capture use `"`basename'.nwdta"', clear
	if _rc != 0 {
		capture use `"`basename'.dta"', clear
		if _rc != 0 {
			di "{err}{p 0 0 2}could not load {bf:`basename'} as either a saved network ({bf:.nwdta}) or a plain dataset ({bf:.dta}){p_end}"
			exit 601
		}
		if "`nwappend'" != "" & "`nwclear'" == "" & `__nwu_k' > 0 {
			di "{err}{p 0 0 2}{bf:`basename'} is a plain Stata dataset, not a saved network file; nothing was appended (see {help merge} and {help append}){p_end}"
			exit 610
		}
		if "`nwclear'" != "" {
			capture mata: mata drop `nw'
			mata: st_rclear()
		}
		qui nwset
		c_local __nwu_plain "yes"
		exit
	}

	confirm variable _nw_format _nw_nets _nw_netname _nw_size _nw_directed _nw_twomode _nw_title, exact
	// nwsave writes the self-loop flag as _nw_selfloops (exact names: works with set varabbrev off)
	capture confirm variable _nw_selfloops, exact
	if _rc == 0 local __nwu_slv _nw_selfloops
	else {
		confirm variable _nw_selfloop, exact
		local __nwu_slv _nw_selfloop
	}
	// _nw_modes/_nw_mode1desc/_nw_mode2desc are a newer addition (mode
	// membership was never actually saved before, despite the bare
	// is-two-mode flag surviving correctly - see nwsave.ado's own
	// comment for the full explanation) - not required here, unlike
	// the columns above, so that a .nwdta file saved before this fix
	// existed still loads cleanly; it just has no mode data to
	// restore (exactly the same "do not silently reinterpret old
	// data" principle new2mode() below already follows for is2mode).
	capture confirm variable _nw_modes
	local has_modes = (_rc == 0)
	capture confirm variable _nw_mode1desc
	local has_mode1desc = (_rc == 0)
	capture confirm variable _nw_mode2desc
	local has_mode2desc = (_rc == 0)
	capture confirm variable _nw_provenance
	local has_provenance = (_rc == 0)
	// temporal networks (nwsave of version 3.25 and later): the type and the names of the time variables of each network,
	// and the temporal data as rows; files without these columns hold no temporal network
	capture confirm variable _nw_ttype _nw_tvars _nw_tnet _nw_tego _nw_talter _nw_tt1 _nw_tt2 _nw_tval, exact
	local has_temporal = (_rc == 0)
	// the file is checked before any network is touched
	local f = _nw_format[1]
	local nets = _nw_nets[1]
	capture confirm integer number `nets'
	if _rc local nets = 0
	if `nets' < 1 | `nets' > _N {
		di "{err}{bf:`basename'.nwdta} is not a valid network file"
		exit 610
	}
	local __nwu_cols ""
	qui forvalues i = 1/`nets' {
		local n = _nw_netname[`i']
		// the column that marks the nodes (see nwsave.ado): numbered for names of more than 15 characters
		local __nwu_key = cond(ustrlen("`n'") <= 15, "_nw_match_`n'", "_nw_m`i'")
		capture confirm variable `n' `__nwu_key'_nw_ego _nw_ego _nw_alter, exact
		if _rc | "`n'" == "" {
			noi di "{err}{bf:`basename'.nwdta} is not a complete network file: the ties of network {bf:`n'} are missing"
			exit 610
		}
		local __nwu_cols "`__nwu_cols' `n'"
	}
	// with nwclear the networks in memory are set aside; -nwclear- itself
	// would clear the data that were just read
	if "`nwclear'" != "" {
		capture mata: __nwuse_hold = _nwuse_ref(`nw')
		if _rc == 0 c_local __nwu_held "yes"
		capture mata: mata drop `nw'
		mata: st_rclear()
	}
	// check if network names already exist
	qui nwset
	qui forvalues i = 1/`nets' {
		nwvalidate `=_nw_netname[`i']'
		if "`r(exists)'" == "true" & "`force'" == "" {
			noi di "{err}network {it:`r(tryname)'} already exists; use option {bf:force}"
			// Error-code coherence pass: this is the same "already
			// exists" situation `errNWsExists' (483, unw_defs.ado)
			// already names, not the "data in memory would be lost"
			// situation the OTHER `error 999' calls in this file use -
			// consolidated onto `errNWsExists' instead of reusing that
			// unrelated code by coincidence.
			error `errNWsExists'
		}
	}
	
	qui forvalues i = 1/`nets' {
		preserve
		local n = _nw_netname[`i']
		local s = _nw_size[`i']
		local d = _nw_directed[`i']
		local t = _nw_twomode[`i']
		local sl = `__nwu_slv'[`i']
		local tl = _nw_title[`i']
		local v = _nw_valued[`i']
		local md ""
		local m1d ""
		local m2d ""
		local prov ""
		// the mode list goes through Mata, never through a macro
		capture mata: mata drop __nwmd
		if `has_modes' mata: __nwmd = st_sdata(`i', "_nw_modes")
		if `has_mode1desc' local m1d = _nw_mode1desc[`i']
		if `has_mode2desc' local m2d = _nw_mode2desc[`i']
		if `has_provenance' local prov = _nw_provenance[`i']
		local ttype ""
		local tvars ""
		if `has_temporal' {
			local ttype = _nw_ttype[`i']
			local tvars = _nw_tvars[`i']
			if "`ttype'" != "" _nwtemporal take, tnet(`i') type(`ttype') tvars(`tvars')
		}
		local __nwu_key = cond(ustrlen("`n'") <= 15, "_nw_match_`n'", "_nw_m`i'")
		keep if `__nwu_key'_nw_ego == 1
		// Networks of different sizes in one file: the tie list of a network holds its pairs with every node of the file (the other
		// networks' nodes with a missing value), so a smaller network came back with the nodes of the largest one as isolates.
		// The file keeps the node list of each network (_nw_modes): rows with a node outside it are dropped, and the list itself is
		// handed to nwfromedge (isolate list), which also restores the isolates of the network. A file without _nw_modes loads as before.
		if `has_modes' {
			capture confirm string variable _nw_ego _nw_alter
			if _rc == 0 {
				_nwuse_nodelist
			}
		}
		// BUGFIX: this used to pass `n' (the raw, saved network name)
		// straight through as an explicit name() to nwfromedge - fine
		// as long as `n' is guaranteed not to collide, which used to be
		// true whenever execution reaches here (a hard collision on any
		// network name aborts this whole command earlier, at the
		// "already exists; use option force" check above, unless
		// `force' was given). Once nwfromedge.ado's own name()
		// collision guard was tightened (harmonisation unit 116: an
		// explicit name() collision now errors unless replace is also
		// given, rather than silently auto-incrementing) that stopped
		// being true for the one case this command's own `force' option
		// exists to support: `nwappend ..., force' deliberately allows
		// loading a network whose name already exists in memory,
		// auto-renumbering it (see cscripts/test_nwappend.do's own
		// "mynet1_1" case) rather than either erroring or replacing the
		// existing one - nwfromedge's new guard doesn't know that's
		// wanted and errors (6099) instead. Resolved here instead of by
		// passing replace (which would destroy the existing network
		// under that name, not what `force' means for nwappend):
		// nwvalidate's own r(validname) already implements exactly the
		// "same name if free, else auto-incremented" logic wanted -
		// resolving it BEFORE calling nwfromedge means nwfromedge is
		// only ever asked to create under a name confirmed not to
		// collide, so its own guard is never triggered. `ncreate' (not
		// `n') is used for every reference to the newly created network
		// for the remainder of this loop iteration, below.
		nwvalidate `n'
		local ncreate = r(validname)
		// an undirected network is saved with each tie once; `undirected' adds the missing direction with the tie's own
		// value (the nwsym below alone would keep 0 instead of a negative value)
		local fedir ""
		if "`d'" == "false" local fedir "undirected"
		// a network comes back exactly as saved: a directed network stays directed even when its matrix is
		// symmetric (nwfromedge would otherwise declare a symmetric list undirected)
		if "`d'" == "true" local fedir "directed"
		// a network with self-loops keeps its diagonal
		nwfromedge _nw_ego _nw_alter `n', name("`ncreate'") `fedir' `=cond("`sl'" == "true", "selfloop", "")'
		// BUGFIX: `_nw_netname' is a LOCAL-macro reference to a local
		// literally named "_nw_netname", which is never defined
		// anywhere in this loop - `_nw_netname' is the STATA VARIABLE
		// holding each row's network name, and `n' (set above from
		// _nw_netname[`i']) is the already-correct local for it. The
		// undefined-local reference silently expands to "" (Stata does
		// not error on an undefined local), so nwname/nwsym below were
		// being called *bare* - operating on whatever network happened
		// to be "current" at that instant rather than explicitly this
		// iteration's network. Found via a direct probe (set trace on)
		// while tracking down why a projected network's new provenance
		// metadata wasn't surviving a save/reload round-trip - the same
		// bug silently affected every other newXXX() field passed here
		// (new2mode/newselfloop/newtitle/newvalued/newmodes/
		// newmode1desc/newmode2desc) too, though it happened to go
		// unnoticed for those because "current" usually already matched
		// the intended network by the time this specific line ran.
		// BUGFIX: was "newvalued("``v'")" - a stray extra backtick left
		// the literal text "`false"/"`true" (backtick included) being
		// passed to newvalued() instead of the plain string, which
		// nwname.ado's own option processing didn't recognize -
		// confirmed directly via `set trace on`, the actual root cause
		// of this command's own long-documented "error in loading"
		// crash on every dataset that reaches this line (i.e. every
		// genuine .nwdta restoration - previously undiagnosed beyond
		// "some macro-quoting mismatch").
		nwname `ncreate', new2mode("`t'") newselfloop("`sl'") newtitle("`tl'") newvalued("`v'") newmode1desc(`"`m1d'"') newmode2desc(`"`m2d'"') newprovenance(`"`prov'"') skipcheck
		if `has_modes' {
			_nwsyntax `ncreate', other(other)
			mata: `othernetobj'->set_modes_from_labeled_string(__nwmd)
			// the node order of the file (nwfromedge numbers the nodes in label order; nwset ..., twomode puts
			// the mode-1 nodes first)
			mata: nw_reorder_to_labels(`othernetobj', nw_labels_from_modestring(__nwmd))
			mata: mata drop __nwmd
		}
		if "`d'"  == "false" {
			nwsym `ncreate'
		}
		if "`ttype'" != "" {
			_nwtemporal put `ncreate'
			_nwtemporal drop
		}
		restore
	}
	
	// The file has one row per observation of the saved data (and per node),
	// and further rows that hold ties only. nwsave marks the former with
	// _nw_userrow; in a file without the mark, they are the rows of the nodes
	// and the rows with a value in a variable of the user.
	capture confirm variable _nw_userrow, exact
	if _rc == 0 {
		qui keep if _nwnode != "" | _nw_userrow == 1
	}
	else {
		mata: _nwuse_oldrows("`nw_nodename' `nw_included' `nw_mode'", tokens(st_local("__nwu_cols")))
	}
	// drop the file's own columns and give the user's variables that were
	// stored under another name their names back
	mata: _nwuse_columns(tokens(st_local("__nwu_cols")))

	if "`nwappend'" != "" {
		if "`nwclear'" == "" & `__nwu_k' > 0 {
			_nwuse_append, existing(`"`existing'"')
		}
		qui capture order _nwnode _nwinclude
		if "`current'" != "" & "`nwclear'" == "" qui nwcurrent `current'
	}
	qui save `"`result'"', replace emptyok
end

// Adds the data just loaded from a file (in memory) to the data that were in
// memory before (file existing()). No observation and no variable of either
// is lost: observations are matched by node name, those without a match are
// added, and where both have a value the one that was in memory stays.
capture program drop _nwuse_append
program _nwuse_append
	syntax , existing(string asis)
	unw_defs
	local existing `existing'
	tempfile incoming keyed extra

	// the variables of the data from the file
	capture drop `nw_included'
	unab __nwu_inc : _all
	local __nwu_instr ""
	foreach v of local __nwu_inc {
		capture confirm string variable `v', exact
		if _rc == 0 local __nwu_instr "`__nwu_instr' `v'"
	}
	qui save `"`incoming'"', replace

	qui use `"`existing'"', clear
	capture confirm variable `nw_nodename', exact
	if _rc qui gen str1 `nw_nodename' = ""
	capture confirm string variable `nw_nodename', exact
	if _rc {
		di "{err}variable {bf:`nw_nodename'} in memory is not a string variable; nothing was appended"
		exit 106
	}
	// variables in both: a copy of a network made by nwload gives way to the
	// variable from the file; a string and a numeric variable cannot be one
	// column, so the one from the file gets another name
	local __nwu_common ""
	local __nwu_renames ""
	foreach v of local __nwu_inc {
		if "`v'" == "`nw_nodename'" continue
		capture confirm variable `v', exact
		if _rc continue
		local __nwu_mark : char `v'[nwload]
		if "`__nwu_mark'" != "" {
			drop `v'
			continue
		}
		capture confirm string variable `v', exact
		local s1 = (_rc == 0)
		local s2 : list v in __nwu_instr
		if `s1' == `s2' local __nwu_common "`__nwu_common' `v'"
		else local __nwu_renames "`__nwu_renames' `v'"
	}
	unab __nwu_mem : _all
	tempvar order iorder first
	qui gen long `order' = _n
	qui save `"`existing'"', replace

	qui use `"`incoming'"', clear
	local __nwu_taken : list __nwu_mem | __nwu_inc
	foreach v of local __nwu_renames {
		local j = 2
		local nv = substr("`v'", 1, 29) + "_`j'"
		while `: list nv in __nwu_taken' {
			local ++j
			local nv = substr("`v'", 1, 29) + "_`j'"
		}
		rename `v' `nv'
		local __nwu_taken "`__nwu_taken' `nv'"
		di "{txt}{p 0 0 2}(note: variable {res:`v'} is a string variable in one of the two datasets and numeric in the other; the one from the file is called {res:`nv'}){p_end}"
	}
	qui gen long `iorder' = _n
	// one observation per node name is matched with the data in memory; any
	// other observation is added as it is
	qui bysort `nw_nodename' (`iorder'): gen byte `first' = (_n == 1 & `nw_nodename' != "")
	preserve
	qui keep if !`first'
	drop `first'
	sort `iorder'
	local __nwu_nextra = _N
	qui save `"`extra'"', replace emptyok
	restore
	qui keep if `first'
	drop `first'
	local __nwu_i = 0
	foreach v of local __nwu_common {
		local ++__nwu_i
		tempvar t`__nwu_i'
		rename `v' `t`__nwu_i''
	}
	qui save `"`keyed'"', replace emptyok

	qui use `"`existing'"', clear
	tempvar match
	qui merge m:1 `nw_nodename' using `"`keyed'"', generate(`match')
	local __nwu_i = 0
	local __nwu_conflict ""
	foreach v of local __nwu_common {
		local ++__nwu_i
		local t `t`__nwu_i''
		if "`v'" != "`nw_mode'" {
			capture confirm string variable `v', exact
			if _rc == 0 qui count if `match' == 3 & !missing(`v') & !missing(`t') & `v' != `t'
			else qui count if `match' == 3 & !missing(`v') & !missing(`t') & float(`v') != float(`t')
			if r(N) > 0 local __nwu_conflict "`__nwu_conflict' `v'"
		}
		qui replace `v' = `t' if missing(`v')
		drop `t'
	}
	drop `match'
	sort `order' `iorder'
	if `__nwu_nextra' > 0 qui append using `"`extra'"'
	drop `order' `iorder'
	if "`__nwu_conflict'" != "" {
		di "{txt}{p 0 0 2}(note: for some nodes the file has other values than the data in memory; the values in memory were kept, in:{res:`__nwu_conflict'}){p_end}"
	}
end

// Restricts the tie list in memory (_nw_ego, _nw_alter: the rows of one network) to the node list the file keeps for that network
// (Mata string __nwmd, "name=mode,name=mode,..."), and stores the list as the isolate list that nwfromedge adds.
capture program drop _nwuse_nodelist
program define _nwuse_nodelist
	tempvar ok
	quietly gen byte `ok' = .
	// the pairs are separated by the comma that follows "=mode"; a comma inside a name ("Smith, J.") is not a separator
	mata: nwu_s = ustrregexra(__nwmd[1], "(=[0-9.]*),", "$1" + char(1))
	mata: nwu_t = tokeninit(char(1), "", "", 0, 0)
	mata: tokenset(nwu_t, nwu_s)
	mata: nwu_p = tokengetall(nwu_t)
	// "name=mode": the name is everything before the last "="
	mata: nwu_nm = substr(nwu_p, 1, strlen(nwu_p) :- strpos(strreverse(nwu_p), "="))
	mata: nwu_A = asarray_create()
	mata: for (nwu_i = 1; nwu_i <= cols(nwu_nm); nwu_i++) asarray(nwu_A, nwu_nm[nwu_i], 1)
	mata: nwu_e = st_sdata(., "_nw_ego")
	mata: nwu_a = st_sdata(., "_nw_alter")
	mata: nwu_ok = J(rows(nwu_e), 1, 0)
	mata: for (nwu_i = 1; nwu_i <= rows(nwu_e); nwu_i++) nwu_ok[nwu_i] = asarray_contains(nwu_A, nwu_e[nwu_i]) & asarray_contains(nwu_A, nwu_a[nwu_i])
	mata: st_store(., st_varindex(st_local("ok")), nwu_ok)
	mata: st_global("_dta[nwtoedge_nodes]", invtokens(nwu_nm, ";"))
	quietly keep if `ok' == 1
	capture mata: mata drop nwu_s nwu_t nwu_p nwu_nm nwu_i nwu_A nwu_e nwu_a nwu_ok
end

// a second name for the object that holds all networks (Mata assigns a class
// object by reference); it stays when the first name is dropped
capture mata: mata drop _nwuse_ref()
mata:
class nws scalar _nwuse_ref(class nws scalar x) return(x)
end

capture mata: mata drop _nwuse_columns()
capture mata: mata drop _nwuse_oldrows()
mata:
// netcols: the columns with the tie values of the networks in the file
void _nwuse_columns(string rowvector netcols)
{
	real scalar i
	string scalar v, nm
	string rowvector d, back
	d = J(1, 0, "")
	back = J(1, 0, "")
	for (i = 1; i <= st_nvar(); i++) {
		v = st_varname(i)
		if (substr(v, 1, 8) == "_nw_uvar" & st_global(v + "[nwsave_name]") != "") back = (back, v)
		else if (substr(v, 1, 4) == "_nw_" | anyof(netcols, v)) d = (d, v)
	}
	if (cols(d)) st_dropvar(d)
	for (i = 1; i <= cols(back); i++) {
		nm = st_global(back[i] + "[nwsave_name]")
		if (_st_varindex(nm) != .) continue
		st_varrename(back[i], nm)
		st_global(nm + "[nwsave_name]", "")
	}
}
// A file without the column _nw_userrow: keep the rows of the nodes and the
// rows that hold a value in some other variable than the file's own.
void _nwuse_oldrows(string scalar own, string rowvector netcols)
{
	real scalar i
	string scalar v
	real colvector keep
	if (st_nobs() == 0) return
	keep = (st_sdata(., "_nwnode") :!= "")
	for (i = 1; i <= st_nvar(); i++) {
		v = st_varname(i)
		if (substr(v, 1, 4) == "_nw_" | anyof(netcols, v) | anyof(tokens(own), v)) continue
		if (st_isstrvar(v)) keep = keep :| (st_sdata(., v) :!= "")
		else keep = keep :| (st_data(., v) :< .)
	}
	if (any(!keep)) st_dropobsif(!keep)
}
end
