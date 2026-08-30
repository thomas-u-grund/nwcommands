

capture program drop nw_datasync
program nw_datasync
	syntax [anything(name=netname)] [, force overwrite generate(string) on off]
	unw_defs
	if "`on'" != "" {
		di "{txt}Switching datasync on."
		mata: `nws'.set_datasync(1)
	}
	if "`off'" != "" {
		di "{txt}Switching datasync off."
		mata: `nws'.set_datasync(0)
	}
	nw_syntax `netname'
		
	capture confirm variable `nw_nodename'
	
	// Maybe datasync is not needed
	if (_rc == 0 & _N >= `nodes' & "`force'" == ""){
		qui putmata `nw_nodename' if _n <= `nodes' , replace
		mata: check_signatures(`nodes', `netobj'->get_nodenames(), "`nw_nodename'", `netobj'->is_2mode())
		mata: mata drop `nw_nodename'
	}
	
	if `datasync' == 0 {
		di "{txt}Warning! Datasync switched off. Variables might be corrupted."
		// `nwname' is itself r-class - calling it bare would clobber
		// whatever r()-results the CALLER already had posted (e.g. a
		// preceding nwset() call's own r(networks)/r(nets)), which is
		// exactly the kind of caller-visible side effect this call is
		// NOT meant to have (it exists purely to leave `_rc' clean - see
		// this file's own header note on this final stretch below) -
		// `_return hold'/`_return restore' (the same pattern already
		// used in nwgeodesic.ado for an identical "run something r-class
		// purely for a side effect, then put the caller's own r() back"
		// need) discards nwname's own r() output while keeping its
		// `_rc'-resetting effect.
		capture _return drop _nwds
		_return hold _nwds
		qui nwname `netname'
		_return restore _nwds
		exit
	}
	
	set more off
	tempfile f
	tempname nodename
	tempname nodeindex

	mata: `nodename' = (`netobj'->get_nodenames())'
	mata: st_numscalar("r(nodes)", `netobj'->get_nodes())
	local __nwds_nodes = r(nodes)

	if "`overwrite'" != "" {
		capture drop `nw_nodename'
		qui getmata `nw_nodename' = `nodename', force replace
		// the two capture mata drops right above are pure best-effort
		// cleanup (`nodeindex' in particular is only ever populated much
		// further down, past every `exit' in this program, so dropping
		// it here always "fails" - harmlessly, since it was never
		// created). Without a genuine, uncaptured command run AFTER
		// them, this branch's own final reported outcome to the caller
		// would be whichever of these two capture's own (harmless,
		// expected) failure happened to run last, not this call's real,
		// successful completion - `_rc' is NOT reset merely by reaching
		// `exit'/`exit 0' (confirmed directly: neither actually clears
		// a stale nonzero `_rc' left by an earlier capture - only a
		// genuine subsequent command execution does that), so a real,
		// always-succeeding command (`nwname', already used throughout
		// this package to report a network's own current state) is run
		// immediately before returning, purely to leave `_rc' clean.
		capture mata: mata drop `nodename'
		capture mata: mata drop `nodeindex'
		// see the `datasync == 0' branch above for why `nwname' is
		// wrapped in `_return hold'/`_return restore' here, not called
		// bare.
		capture _return drop _nwds
		_return hold _nwds
		qui nwname `netname'
		_return restore _nwds
		exit
	}
	
	preserve
	drop _all

	unw_defs
	tempname mode

	//if `r(nodes)' > `=_N' {
		//set obs `r(nodes)'
	//}

	qui getmata `nw_nodename' = `nodename', force replace
	
	nw_syntax `netname'
	
	if ("`is2mode'" == "true") {
		mata: `mode' = (`netobj'->get_modes())'
		qui getmata `nw_mode' =  `mode'
	}
	qui gen `nodeindex' = _n
	qui save `f', replace
	restore
	
	capture confirm variable `nw_nodename'
	local __nwds_var_exists = (_rc == 0)
	local __nwds_all_blank = 1
	if `__nwds_var_exists' {
		qui count if `nw_nodename' != ""
		if r(N) > 0 {
			local __nwds_all_blank = 0
		}
	}
	// BUGFIX: this used to unconditionally create `_nwnode' as blank
	// strings whenever the variable didn't already exist, then merge it
	// (below) against the network's own real node names ("n1", "n2", ...
	// for a freshly built network with no explicit labs()) - a blank
	// string can never match a real name, so the merge was a guaranteed,
	// deterministic 0% match: every one of the network's own nodes came
	// back "using only" and got APPENDED as new rows, while every one of
	// the caller's original rows came back "master only" and was KEPT
	// rather than dropped (by original design, so a genuinely different,
	// already-synced network's own data isn't silently discarded when
	// switching between two named networks that coexist in one session)
	// - together silently DOUBLING the active dataset's row count on the
	// very first sync of any newly built network, with every one of the
	// caller's own plain variables (any attribute they had loaded)
	// missing on the network's own real rows.
	//
	// Checking "does the variable exist" alone is not enough to detect
	// this case: `create_by_name()' (unw_core.do) itself already adds
	// `_nwnode' via a bare st_addvar() - present, but entirely blank -
	// the moment ANY new network is created, before this program ever
	// runs, so `capture confirm variable' alone always finds it already
	// there. Checking whether it actually holds any real (non-blank)
	// value catches both that case and the original "doesn't exist at
	// all" one.
	//
	// Confirmed directly: nwset's own bare mat() path, nwrandom, nwpref,
	// and nwlattice (any command that creates a new, default-named
	// network) all reproduced this on the very first call in a session
	// that already had unrelated attribute data loaded. This exact
	// "no real `_nwnode' yet" case is precisely the one where there is
	// no PRIOR network's data to preserve at all - the dataset has never
	// been synced to any network before - so when the row count already
	// matches this network's own node count, attach the real node names
	// directly, by position, instead of leaving a placeholder guaranteed
	// to force a spurious append. Row counts that DON'T match are
	// genuinely ambiguous (which existing rows correspond to which
	// nodes?) and keep the original placeholder-then-merge behavior
	// unchanged.
	if (`__nwds_all_blank') {
		if (`=_N' == `__nwds_nodes' & `=_N' > 0) {
			qui getmata `nw_nodename' = `nodename', force replace
		}
		else if (!`__nwds_var_exists') {
			qui gen str40 `nw_nodename' = ""
		}
	}

	tempvar current
	qui capture drop `generate'
	qui merge n:1 (`nw_nodename') using `f', generate(`current')

	qui replace `current' = (`current' != 1)
	gsort -`current' +`nodeindex'
	qui if "`generate'" != "" {
		capture drop `generate'
		gen `generate' = (`current'==1)
	}
	else {
		capture drop `nw_included'
		gen `nw_included' = (`current'==1)
	}
	
	
	// `mode' in particular is only ever populated for a two-mode network
	// (see the `is2mode' check above) - dropping it here always "fails"
	// harmlessly otherwise, since it was never created. Without a
	// genuine, uncaptured command run AFTER these three, this program's
	// own final reported outcome to the caller would be whichever of
	// them happened to run last, not this call's real, successful
	// completion - the exact bug that used to silently leak a stray
	// nonzero _rc into nwload's own `xvars'-suppress branch
	// (nw_datasync `netname'; exit), which unlike this full var-
	// generation path has no further command of its own to mask the
	// leak. `exit'/`exit 0' do NOT themselves reset `_rc' (confirmed
	// directly - neither clears a stale nonzero `_rc' left by an
	// earlier capture), so `nwname' (a genuine, always-succeeding ado
	// call, already used throughout this package to report a network's
	// own current state) is run immediately before returning, purely to
	// leave `_rc' clean.
	capture mata: mata drop `mode'
	capture mata: mata drop `nodename'
	capture mata: mata drop `nodeindex'
	// see the `datasync == 0' branch above for why `nwname' is wrapped
	// in `_return hold'/`_return restore' here, not called bare - this
	// path in particular must preserve this program's OWN r(nodes)
	// (set near its own top), which nwload.ado's own caller reads
	// right after this call returns.
	capture _return drop _nwds
	_return hold _nwds
	qui nwname `netname'
	_return restore _nwds

end

capture mata: mata drop check_signatures()
mata:
void check_signatures(real scalar nodes, string matrix nodenames, string scalar nwnode, string scalar is2mode) {
	if ((nodenames') == st_sdata((1,nodes), nwnode)) {
		if (is2mode != "") {
		   // ----- TODO ----- implement 
		}
		else {
			stata("exit")
		}
	}
}
end


