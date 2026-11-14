capture program drop nwuse
program nwuse
	syntax anything [, nwclear nwappend force *]
	unw_defs
	// anything keeps the quotes of a quoted file name (paths with spaces)
	local basename `anything'
	if regexm(`"`basename'"', "\.nwdta$") local basename = substr(`"`basename'"', 1, strlen(`"`basename'"') - 6)
	else if regexm(`"`basename'"', "\.dta$") local basename = substr(`"`basename'"', 1, strlen(`"`basename'"') - 4)

	tempfile existing
	capture save `existing'
	local have_existing = (_rc == 0)

	`nwclear'
	qui nwset
	if "`nwappend'" == "" & (`r(networks)' > 0 | "`r(networks)'" == "") {
		di "{err}No; data in memory would be lost. Specify either option {bf:nwclear} or {bf:nwappend}."
		error 999
	}

	qui if "`nwappend'" != "" {
		capture qui nwcurrent
		local current "`r(current)'"
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
	capture use `"`basename'.nwdta"'
	if _rc != 0 {
		capture use `"`basename'.dta"'
		if _rc != 0 {
			if `have_existing' {
				use `existing'
			}
			di "{err}{p 0 0 2}could not load {bf:`basename'} as either a saved network ({bf:.nwdta}) or a plain dataset ({bf:.dta}){p_end}"
			error 601
		}
		di "{txt}{p 0 0 2}(plain Stata dataset loaded - not a saved {help nwsave:network} file; build a network from it directly, e.g. with {help nwfromedge} or {help nwgenerate}){p_end}"
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
	local f = _nw_format[1]
	local nets = _nw_nets[1]
	// check if network names already exist
	qui forvalues i = 1/`nets' {
		nwvalidate `=_nw_netname[`i']'
		if "`r(exists)'" == "true" & "`force'" == "" {
			noi di "{err}network {it:`r(tryname)'} already exists; use option {bf:force}"
			if `have_existing' {
				use `existing'
			}
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
		keep if _nw_match_`n'_nw_ego == 1
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
	
	if _rc != 0 {
		di "{err}error in loading"
		error 999
	}
	
	qui keep if _nwnode != ""
	qui capture drop _nw_*
	
	_nwsyntax _all, max(99999)
	qui foreach onenet in `netname' {
		capture drop `onenet'
	}
	
	qui if "`nwappend'" != "" {
		capture merge 1:1 _nwnode using `existing', nogenerate
		capture order _nwnode _nwinclude
		nwcurrent `current'
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
