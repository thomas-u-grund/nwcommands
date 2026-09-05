
capture program drop nwset	
program nwset
syntax [varlist (default=none)][, valued unvalued nodenames(string) overwrite REPLACE bipartite TWOmode biprownames(varname) selfloop labs(string) vars(string) keeporiginal xvars clear nwclear nooutput edgelist name(string) labsfromvar(string) edgelabs(string asis) detail mat(string) undirected directed time(varname) interval(varlist min=2 max=2) eventtime(varname)]
// `overwrite' was declared here but never actually connected to any
// check anywhere in this file (confirmed directly: it was the ONLY
// occurrence of the word in the whole file) - a network name
// collision has always silently auto-picked a different valid name
// via nwvalidate below and warned, regardless of whether `overwrite'
// was given. `replace' is the real, now-wired option (matching this
// package's own naming convention elsewhere, e.g. nwgenerate's
// `replace'); `overwrite' is kept as a backward-compatible alias for
// any existing caller already passing it (it did nothing before, so
// no prior behavior is lost by finally giving it one).
if "`overwrite'" != "" local replace "replace"

	// twomode is a genuinely different declaration shape from
	// bipartite, not a synonym for it - bipartite (long-established,
	// left completely unchanged) takes a Mata matrix or a *wide*
	// affiliation-matrix varlist (each named variable is one mode-1
	// node, each observation is one mode-2 node); twomode instead
	// takes exactly the same "two (or three, for a valued network) ID
	// variables, one row per tie" edgelist shape nwset's own one-mode
	// edgelist option already uses (see edgelist below) - the two-mode
	// analogue of it, and the literal syntax requested when this
	// option was added: nwset person organisation, twomode. That exact
	// shape already existed as the separate nw2fromedge command
	// (unchanged, still directly callable, and still what this
	// delegates to internally - not reimplemented a second time here)
	// - twomode's only job is making it reachable through nwset itself
	// too, matching how nwfromedge is reachable both directly and via
	// nwset's own edgelist option. Kept as a clearly distinct option
	// name (not folded into bipartite) specifically to avoid any
	// ambiguity between "these variables are wide-format mode-1 nodes"
	// and "these variables are a two-column edgelist" - the two shapes
	// cannot be told apart from the variable list alone.
	if "`twomode'" != "" & "`bipartite'" != "" {
		di "{err}options {bf:twomode} and {bf:bipartite} cannot be combined - they declare two different input shapes (an edgelist of ties vs. a wide affiliation matrix); use whichever one matches your data."
		error 198
	}
	if "`twomode'" != "" {
		if "`varlist'" == "" {
			di "{err}option {bf:twomode} requires exactly two (or three, for a valued network) variables: the mode-1 id, the mode-2 id, and optionally a tie value."
			error 198
		}
		local twomode_nvars : word count `varlist'
		if `twomode_nvars' < 2 | `twomode_nvars' > 3 {
			di "{err}option {bf:twomode} requires exactly two (or three, for a valued network) variables; got `twomode_nvars'."
			error 198
		}
		if "`name'" == "" {
			local name "network"
		}

		local ntemporal_opts = ("`time'" != "") + ("`interval'" != "") + ("`eventtime'" != "")
		if `ntemporal_opts' > 1 {
			di "{err}options {bf:time}, {bf:interval}, and {bf:eventtime} are mutually exclusive - a network has exactly one temporal semantics (snapshot, interval, or event)."
			error 198
		}

		if `ntemporal_opts' == 0 {
			// nwset's own syntax line takes no [if] qualifier at all (see
			// above) - a bare "if ..." after the comma would already have
			// been rejected by the "syntax" command itself, before this
			// code ever runs, so none is threaded through here.
			nw2fromedge `varlist', name(`name') `xvars' `keeporiginal'
			exit
		}

		// Two-mode + temporal composability (two-mode/temporal
		// architecture initiative, closing the item this file's own
		// "Composability with twomode/bipartite is intentionally NOT
		// attempted" comment below originally left open). nw2fromedge
		// itself does two things beyond a plain nwfromedge call that
		// matter here, both confirmed directly by reading its own source
		// (not assumed): (1) if both mode-1/mode-2 id variables are
		// numeric with OVERLAPPING ranges, it permanently offsets the
		// mode-2 variable so "id 3" in each mode maps to a genuinely
		// distinct node; (2) if both are string with an overlapping
		// VALUE actually used by both modes, it permanently prefixes
		// them "m1_"/"m2_". A REAL bug found while building this (not
		// just theorized): nw2fromedge's own internal nwfromedge call
		// REPLACES the current dataset with the network's own internal
		// representation, so the mode-1/mode-2/time variables no longer
		// exist in the calling dataset once nw2fromedge returns -
		// confirmed directly ("person not found" on the very first end-
		// to-end trial run, not caught by inspection). Fixed by
		// capturing every row-level value needed here into Mata BEFORE
		// calling nw2fromedge at all, replicating its own two collision-
		// handling rules on this captured copy (mirrored, not shared
		// code - matches this file's own general style elsewhere) so the
		// labels built here still exactly match what nw2fromedge's own
		// (now-vanished) internal nwfromedge call actually used.
		local mode1id : word 1 of `varlist'
		local mode2id : word 2 of `varlist'
		local ivstart ""
		local ivend ""
		if "`time'" != "" {
			confirm numeric variable `time'
		}
		if "`eventtime'" != "" {
			confirm numeric variable `eventtime'
		}
		if "`interval'" != "" {
			local ivstart : word 1 of `interval'
			local ivend : word 2 of `interval'
			confirm numeric variable `ivstart' `ivend'
		}

		capture confirm numeric variable `mode1id'
		local mode1numeric = (_rc == 0)
		capture confirm numeric variable `mode2id'
		local mode2numeric = (_rc == 0)
		tempvar tm_lab1 tm_lab2
		if `mode1numeric' & `mode2numeric' {
			// mirrors nw2fromedge.ado's own numeric-overlap offset
			// exactly: if mode-2's own minimum falls within mode-1's own
			// range, shift mode-2 up by mode-1's own max so the two id
			// spaces cannot collide.
			tempvar mode2adj
			qui gen `mode2adj' = `mode2id'
			qui sum `mode1id'
			local __g1max = r(max)
			qui sum `mode2id'
			local __g2min = r(min)
			if (`__g1max' >= `__g2min') {
				qui replace `mode2adj' = `mode2adj' + `__g1max'
			}
			qui gen `tm_lab1' = "n" + strofreal(`mode1id')
			qui gen `tm_lab2' = "n" + strofreal(`mode2adj')
		}
		else if `mode1numeric' & !`mode2numeric' {
			qui gen `tm_lab1' = strofreal(`mode1id')
			qui gen `tm_lab2' = trim(`mode2id')
		}
		else if !`mode1numeric' & `mode2numeric' {
			qui gen `tm_lab1' = trim(`mode1id')
			qui gen `tm_lab2' = strofreal(`mode2id')
		}
		else {
			// mirrors nw2fromedge.ado's own string-overlap check exactly:
			// if the SAME string value is actually used by both modes,
			// prefix both with "m1_"/"m2_" to disambiguate.
			tempvar __tm_id
			tempfile __tm_g1 __tm_g2
			preserve
			keep `mode1id'
			rename `mode1id' `__tm_id'
			save `__tm_g1'
			restore
			preserve
			keep `mode2id'
			rename `mode2id' `__tm_id'
			qui merge m:n `__tm_id' using `__tm_g1'
			qui sum _merge
			local __tm_needprefix = (r(max) == 3)
			restore
			if `__tm_needprefix' {
				qui gen `tm_lab1' = "m1_" + trim(`mode1id')
				qui gen `tm_lab2' = "m2_" + trim(`mode2id')
			}
			else {
				qui gen `tm_lab1' = trim(`mode1id')
				qui gen `tm_lab2' = trim(`mode2id')
			}
		}

		tempname tm_lab1m tm_lab2m tm_tval tm_tval2
		mata: `tm_lab1m' = st_sdata(., "`tm_lab1'")
		mata: `tm_lab2m' = st_sdata(., "`tm_lab2'")
		mata: `tm_tval2' = J(0,1,.)
		if "`time'" != "" {
			mata: `tm_tval' = st_data(., "`time'")
		}
		if "`eventtime'" != "" {
			mata: `tm_tval' = st_data(., "`eventtime'")
		}
		if "`interval'" != "" {
			mata: `tm_tval' = st_data(., "`ivstart'")
			mata: `tm_tval2' = st_data(., "`ivend'")
		}

		// Every row-level value needed below is now safely captured in
		// Mata, independent of whatever nw2fromedge does to the current
		// dataset - safe to call it (and let it replace the dataset)
		// now.
		qui nw2fromedge `varlist', name(`name') `xvars' `keeporiginal'
		nw_syntax `name'
		mata: st_local("symmetric", strofreal(!(`netobj'->is_directed_boolean())))

		if "`time'" != "" {
			mata: `netobj'->set_edge_time(build_edge_value_matrix(`netobj'->get_nodenames(), `tm_lab1m', `tm_lab2m', `tm_tval', `symmetric'))
			mata: `netobj'->set_temporal_type("snapshot")
			mata: `netobj'->set_timevar("`time'")
		}
		else if "`eventtime'" != "" {
			mata: `netobj'->set_eventlist(build_eventlist(`netobj'->get_nodenames(), `tm_lab1m', `tm_lab2m', `tm_tval'))
			mata: `netobj'->set_temporal_type("event")
			mata: `netobj'->set_eventtimevar("`eventtime'")
		}
		else {
			mata: `netobj'->set_edge_interval(build_edge_value_matrix(`netobj'->get_nodenames(), `tm_lab1m', `tm_lab2m', `tm_tval', `symmetric'), build_edge_value_matrix(`netobj'->get_nodenames(), `tm_lab1m', `tm_lab2m', `tm_tval2', `symmetric'))
			mata: `netobj'->set_temporal_type("interval")
			mata: `netobj'->set_startvar("`ivstart'")
			mata: `netobj'->set_endvar("`ivend'")
		}
		mata: `netobj'->set_temporal(1)
		mata: mata drop `tm_lab1m' `tm_lab2m' `tm_tval' `tm_tval2'
		exit
	}
	// Temporal metadata declaration (two-mode/temporal architecture
	// initiative, Part II) - groundwork only: distinguishes snapshot
	// (time()), interval (interval()), and event (eventtime())
	// semantics per the user's own specification, storing per-edge
	// time value(s) alongside the ordinary edgelist topology rather
	// than pretending a network has no temporal dimension at all.
	// Composability with `twomode' is now supported (see that option's
	// own branch above, which handles the temporal case itself and
	// always `exit's - this point in the file is only ever reached when
	// `twomode' is empty). `bipartite' composability is NOT attempted
	// (tracked in docs/ROADMAP.md) - its own wide-affiliation-matrix
	// input shape (one variable per mode-1 node, one row per mode-2
	// node) has no natural per-row time value to attach the way an
	// edgelist-shaped input (twomode's own shape, and this one-mode
	// branch's own) does - errors clearly below rather than silently
	// doing something wrong.
	if "`time'" != "" | "`interval'" != "" | "`eventtime'" != "" {
		local ntemporal_opts = ("`time'" != "") + ("`interval'" != "") + ("`eventtime'" != "")
		if `ntemporal_opts' > 1 {
			di "{err}options {bf:time}, {bf:interval}, and {bf:eventtime} are mutually exclusive - a network has exactly one temporal semantics (snapshot, interval, or event)."
			error 198
		}
		if "`bipartite'" != "" {
			di "{err}combining temporal declaration ({bf:time}/{bf:interval}/{bf:eventtime}) with {bf:bipartite} is not supported - {bf:bipartite}'s own wide-affiliation-matrix shape has no per-row time value to attach. Use {bf:twomode} instead (an edgelist shape: mode-1 id, mode-2 id, optional value) - two-mode + temporal composability is supported there."
			error 198
		}
		if "`varlist'" == "" {
			di "{err}declaring temporal metadata requires an edgelist varlist: {it:ego alter} [{it:value}]."
			error 198
		}
		local temporal_nvars : word count `varlist'
		if `temporal_nvars' < 2 | `temporal_nvars' > 3 {
			di "{err}temporal edgelist declaration requires exactly two (or three, for a valued network) variables; got `temporal_nvars'."
			error 198
		}
		if "`name'" == "" {
			local name "network"
		}

		local ego : word 1 of `varlist'
		local alter : word 2 of `varlist'
		local ivstart ""
		local ivend ""
		if "`time'" != "" {
			confirm numeric variable `time'
		}
		if "`eventtime'" != "" {
			confirm numeric variable `eventtime'
		}
		if "`interval'" != "" {
			local ivstart : word 1 of `interval'
			local ivend : word 2 of `interval'
			confirm numeric variable `ivstart' `ivend'
		}

		// Resolve ego/alter to the exact string LABELS nwfromedge
		// (called below) will end up using as node names, mirroring
		// its own top-of-file numeric/string harmonization exactly
		// (see nw2fromedge.ado's near-identical comment for the fuller
		// explanation of why this must match: numeric-only pairs get
		// an "n"-prefix, mixed numeric/string pairs do not) - captured
		// as Mata state (survives past nwfromedge's own internal
		// dataset manipulation, unlike Stata variables) before calling
		// it, then used afterward to resolve each row's node-label
		// pair to indices by LABEL, not position.
		capture confirm numeric variable `ego'
		local egonumeric = (_rc == 0)
		capture confirm numeric variable `alter'
		local alternumeric = (_rc == 0)
		tempvar egolab alterlab
		if `egonumeric' & `alternumeric' {
			qui gen `egolab' = "n" + strofreal(`ego')
			qui gen `alterlab' = "n" + strofreal(`alter')
		}
		else if `egonumeric' & !`alternumeric' {
			qui gen `egolab' = strofreal(`ego')
			qui gen `alterlab' = trim(`alter')
		}
		else if !`egonumeric' & `alternumeric' {
			qui gen `egolab' = trim(`ego')
			qui gen `alterlab' = strofreal(`alter')
		}
		else {
			qui gen `egolab' = trim(`ego')
			qui gen `alterlab' = trim(`alter')
		}

		tempname __lab1 __lab2 __tval __tval2
		mata: `__lab1' = st_sdata(., "`egolab'")
		mata: `__lab2' = st_sdata(., "`alterlab'")
		// `__tval2' is only actually populated on the interval() branch
		// below - given a harmless placeholder value here unconditionally
		// so the unconditional (non-capture) cleanup drop near the end of
		// this block always has something real to drop. An earlier
		// version used `capture mata: mata drop `__tval2'' instead,
		// which is the wrong fix: capture swallows the "not found" error
		// on the time()/eventtime() branches (where `__tval2' was never
		// created) but leaves Stata's own `_rc' polluted with that
		// failure's return code, since nothing runs afterward to reset
		// it - so the CALLER of nwset would see a stray nonzero _rc even
		// though nwset itself succeeded. Found via a direct probe: the
		// exact same nwset call reported _rc==0 under `set trace on'
		// (trace happens to touch _rc as a side effect) but _rc==111
		// without it - a real, confusing bug, not a flaky test.
		mata: `__tval2' = J(0,1,.)
		if "`time'" != "" {
			mata: `__tval' = st_data(., "`time'")
		}
		if "`eventtime'" != "" {
			mata: `__tval' = st_data(., "`eventtime'")
		}
		if "`interval'" != "" {
			mata: `__tval' = st_data(., "`ivstart'")
			mata: `__tval2' = st_data(., "`ivend'")
		}

		qui nwfromedge `varlist', name(`name') `xvars' `keeporiginal' `undirected' `replace'
		nw_syntax `name'
		mata: st_local("symmetric", strofreal(!(`netobj'->is_directed_boolean())))

		if "`time'" != "" {
			mata: `netobj'->set_edge_time(build_edge_value_matrix(`netobj'->get_nodenames(), `__lab1', `__lab2', `__tval', `symmetric'))
			mata: `netobj'->set_temporal_type("snapshot")
			mata: `netobj'->set_timevar("`time'")
		}
		else if "`eventtime'" != "" {
			// event ties are NOT folded into the ordinary edge matrix
			// at all - raw sender/receiver/eventtime triplets only,
			// resolved to node indices here so eventlist() consumers
			// don't have to repeat the label lookup - see unw_core.do's
			// own comment on `eventlist' for the full rationale (this
			// package must not silently pretend a raw event stream is
			// an ordinary persistent-tie graph). build_eventlist() is a
			// standalone Mata function (unw_core.do), not an inline
			// for-loop here, after confirming (during the unit-41
			// mode-assignment fix) that Stata's one-line interactive
			// `mata:' command form does not reliably parse a for-loop
			// with a braced multi-statement body.
			mata: `netobj'->set_eventlist(build_eventlist(`netobj'->get_nodenames(), `__lab1', `__lab2', `__tval'))
			mata: `netobj'->set_temporal_type("event")
			mata: `netobj'->set_eventtimevar("`eventtime'")
		}
		else {
			mata: `netobj'->set_edge_interval(build_edge_value_matrix(`netobj'->get_nodenames(), `__lab1', `__lab2', `__tval', `symmetric'), build_edge_value_matrix(`netobj'->get_nodenames(), `__lab1', `__lab2', `__tval2', `symmetric'))
			mata: `netobj'->set_temporal_type("interval")
			mata: `netobj'->set_startvar("`ivstart'")
			mata: `netobj'->set_endvar("`ivend'")
		}
		mata: `netobj'->set_temporal(1)
		mata: mata drop `__lab1' `__lab2' `__tval' `__tval2'
		exit
	}
	set more off
	unw_defs

	// `clear'/`nwclear' used to `exit' unconditionally, even when the
	// same call also carried a creation request (a non-empty varlist -
	// edgelist/twomode/bipartite/temporal forms - or mat()). That made
	// e.g. "nwset ego alter, edgelist name(mini) nwclear" silently wipe
	// the registry and return without ever creating "mini" - nwset
	// itself reported no error, since from its own point of view it
	// successfully executed the "clear" form; the failure only
	// surfaced later, when something else referenced "mini" and hit
	// the emptied registry (a confusing "type mismatch:
	// exp.exp: transmorphic found where struct expected" instead of a
	// clean "network not found"). The .sthlp only documents clear/
	// nwclear as standalone forms, but nothing in the syntax line
	// stopped a caller from combining one onto a creation call as a
	// natural "clear anything old, then set this" shorthand. Now only
	// exits early when clearing is the ONLY thing being requested;
	// otherwise the clear happens as a side effect BEFORE the
	// `nws_create()' step below (not after - `nwclear' itself drops
	// the whole `nw' Mata registry object, so running it after
	// `nws_create()' had already built a fresh one would immediately
	// destroy it again) and execution falls through into the normal
	// creation path. Combining `nwclear' with a varlist-based creation
	// form (edgelist/twomode/temporal) is not made to work by this fix
	// - `nwclear' wipes the Stata dataset those forms read their own
	// source columns from, so the two are inherently in tension; that
	// combination surfaces as an ordinary "variable not found"-style
	// error now instead of a silent no-op, which is the actual bug
	// this fixes. `mat()' is unaffected (its input is a Mata
	// expression, not dataset columns) and works correctly combined
	// with either `clear' or `nwclear'.
	if "`clear'" != "" & "`varlist'`mat'" == "" {
		// `nwdrop' has never accepted a `netonly' option (confirmed
		// directly: `nwdrop.ado's own syntax line only declares
		// `clean') - this call has always errored ("option netonly not
		// allowed", r(198)), meaning `nwset, clear' was completely
		// broken before this fix, not merely a corner case. Plain
		// `nwdrop _all' already does exactly what `clear' is
		// documented to do (drop all networks, leave the Stata dataset
		// untouched) - confirmed directly - so `netonly' was pure
		// vestigial cruft, not a missing feature to add.
		nwdrop _all
		exit
	}
	if "`nwclear'" != "" & "`varlist'`mat'" == "" {
		nwclear
		exit
	}
	if "`clear'" != "" {
		// same fix as the standalone-form branch above (`netonly' was
		// never a real nwdrop option).
		nwdrop _all
	}
	if "`nwclear'" != "" {
		nwclear
	}

	capture mata: `nw'
	if (_rc != 0) {
		if ("`varlist'" != "" | "`mat'" != ""){
			mata: `nw' = nws_create()
		}
	}

	if "`edgelist'" != "" {
		local labsfromvar ""
	}

	local numnets = 0
	mata: st_rclear()
	local max_nodes = 0
	local allnames ""
	
	qui if "`edgelist'" != "" {
		qui nwfromedge `varlist', name(`name') `xvars' `keeporiginal' `undirected' `replace'
		exit
	}
	
	// display information about network
	if ("`varlist'" == "" & "`mat'" == "") {
		capture mata: `nw'
		if _rc == 0 {
			mata: st_numscalar("r(networks)", `nws'.get_number())
			mata: st_global("r(nets)", `nws'.get_names())
			if  ("`output'" == "") {
				di "{txt}(`r(networks)' networks)"
				di "{hline 20}"
				forvalues  i = 1/`r(networks)' {
					local onename : word `i' of `r(nets)'
					di "      {res}`onename'"
				}
			}
		}
		else {
			di "{txt}(0 networks)"
			mata: st_numscalar("r(networks)", 0)
			mata: st_global("r(nets)", "")	
		}
		exit
	}
	
	// set a new network
	else {
		tempname __nwnew
		tempname __nwnodenames
		tempname __modes

		// Captured BEFORE the "network" default below, so the
		// collision check right after can tell an explicit name(foo)
		// apart from an unspecified one - only an explicit, caller-
		// chosen name is held to the create/replace convention used
		// elsewhere in the package (nwgenerate's own `replace' guard);
		// letting the anonymous "network"/"network_1"/... default keep
		// auto-numbering on collision matches nwfromedge's own
		// documented behavior for the same unspecified-name case and
		// is not something the caller expressed any intent about.
		local name_given = ("`name'" != "")

		if "`name'" == "" {
			local name "network"
		}

		nwvalidate `name'
		if "`r(exists)'"=="true" {
			if "`replace'" != "" {
				// keep the caller's own requested name and drop the
				// existing network under it first, rather than
				// switching to an auto-generated alternative name -
				// this is the only place that name collision is
				// actually decided, so this is the one place `replace'
				// needs to hook in. nwdrop itself drops the whole `nw'
				// Mata registry object once the last network is gone
				// (confirmed directly in nwdrop.ado) - if the network
				// being replaced was the only one registered, the
				// creation path below would otherwise find no `nw' to
				// register the replacement into, so it is rebuilt here
				// exactly the same way the top of this program already
				// does when `nw' does not yet exist at all.
				nwdrop `name'
				capture mata: `nw'
				if (_rc != 0) mata: `nw' = nws_create()
			}
			else if `name_given' {
				// An explicit name(foo) collision must not silently
				// diverge to foo_1 - that left "foo" itself untouched
				// while the caller's later references to "foo" kept
				// hitting stale data, exactly the silent-destructive-
				// operation trap the create/replace convention exists
				// to prevent. Errors instead, matching nwgenerate's own
				// message shape for the same situation.
				// Error-code coherence pass: consolidated onto
				// `errNWsExists' (483, unw_defs.ado) - see
				// nwsimmelian.ado's own fix for the history of this
				// convention's drift onto an undocumented `6099'.
				di "{err}Network `name' already exists. Specify option {bf:replace} to overwrite it."
				error `errNWsExists'
			}
			else {
				di "{txt}Warning! Switched to netname {res}`r(validname)'{txt} because {res}`name'{txt} already in use."
				local name = r(validname)
			}
		}

		// set network from varlist
		if ("`varlist'" != "") {
			mata: `__nwnew' = check_bipartite(st_data(.,"`varlist'"), "`bipartite'")
			mata: `__modes' = J(rows(`__nwnew'), 1, 2)
			
			if "`bipartite'"  != "" {
				local mode1 : word count `varlist'
				mata: `__modes'[(1::`mode1'),1] = J(`mode1', 1, 1)
			}
			mata: `__modes'=strofreal(`__modes')'
		}
		
		// set network from mata matrix
		if ("`mat'" != "") {
			// mat() has always evaluated its own argument as a bare
			// Mata expression - a literal expression like `(0,1\1,0)'
			// parses directly as an anonymous Mata matrix constant
			// regardless, but a bare NAME referring to an existing
			// STATA matrix does not auto-import into Mata (Mata has no
			// such convenience) - confirmed directly: `matrix define X
			// = (0,1\1,0)' then `nwset, mat(X)' failed with "X not
			// found" (r(3499)) before this fix. Every existing internal
			// caller of `nwset, mat(...)' in this package happens to
			// always pass either a literal expression or an existing
			// MATA variable name (both already work, since Mata
			// variables ARE directly usable as bare expressions) -
			// only a genuine Stata matrix name was ever unsupported.
			// Detected via `confirm matrix', then copied into Mata
			// explicitly via `st_matrix()' first; a literal expression
			// or Mata variable name fails `confirm matrix' harmlessly
			// (it is not a valid/existing Stata matrix name) and falls
			// through to the original, unchanged behavior.
			capture confirm matrix `mat'
			if _rc == 0 {
				tempname __nwmatcopy
				mata: `__nwmatcopy' = st_matrix("`mat'")
				local mat "`__nwmatcopy'"
			}

			// BUGFIX: a non-square matrix passed to mat() for a plain
			// (non-bipartite) one-mode network used to crash uncleanly
			// two different ways depending on shape - check_bipartite()'s
			// own non-bipartite branch first SILENTLY TRUNCATES to the
			// smaller-dimension square submatrix (m=min(rows,cols),
			// edge[1::m,1::m]) with no warning, discarding real data the
			// caller likely did not intend to lose; then the modes-vector
			// sizing just below (`__modes' sized off the TRUNCATED
			// matrix's own column count, but indexed via `mode1' from the
			// ORIGINAL untruncated one) indexes out of bounds and crashes
			// with a raw, low-level "subscript invalid" (r3301) with no
			// nwcommands-style message at all. An empty (0x0) matrix hit
			// the identical crash one function earlier, inside
			// check_bipartite() itself (min(0,0)=0, `edge[1::0,1::0]' is
			// itself the actual trigger there). Both confirmed via a
			// direct adversarial-input probe, not merely inspection.
			// Fixed by validating BEFORE any of this runs: a non-bipartite
			// mat() needs a genuinely square, non-empty matrix; a
			// bipartite one only needs at least one row and column
			// (rectangular is the whole point there).
			mata: st_numscalar("__nwset_mat_rows", rows(`mat'))
			mata: st_numscalar("__nwset_mat_cols", cols(`mat'))
			if "`bipartite'" == "" {
				if `=__nwset_mat_rows' != `=__nwset_mat_cols' | `=__nwset_mat_rows' == 0 {
					di "{err}mat() must be a square, non-empty matrix for a one-mode network (got `=__nwset_mat_rows' x `=__nwset_mat_cols'); use the {bf:bipartite} option for a rectangular affiliation matrix."
					error 198
				}
			}
			else {
				if `=__nwset_mat_rows' == 0 | `=__nwset_mat_cols' == 0 {
					di "{err}mat() must have at least one row and one column."
					error 198
				}
			}

			mata: mode1 = cols(`mat')
			mata: st_local("mode1", strofreal(mode1))
			mata: `__nwnew' = check_bipartite(`mat',"`bipartite'")
			mata: `__modes' = J(cols(`__nwnew'), 1, 2)
			mata: `__modes'[(1::mode1),1] = J(mode1, 1, 1)
			mata: `__modes'=strofreal(`__modes')'
		}
				
		// generate nodenames if not specified
		if "`varlist'" != "" {
			local labs = ""
			foreach var of varlist `varlist' {
				local labs = "`labs'`var',"
			}
		}

		local notvalid 0
		
		if "`labs'" != "" & "`labsfromvar'" == "" {
			mata: `__nwnodenames' = (get_nodenames_from_string(`"`labs'"', rows(`__nwnew'),"`cDftNodepref'"))'
		}
		if "`labsfromvar'" != "" {
			capture tostring `labsfromvar', replace
			if "`bipartite'" == "" {
				mata: `__nwnodenames' = (st_sdata((1::rows(`__nwnew')),"`labsfromvar'"))'
			}
			else {
				mata: `__nwnodenames' = (st_sdata(.,"`labsfromvar'"))'
			}
			
			if("`varlist'" != "" & "`bipartite'" != ""){
				mata: `__nwnodenames' = (tokens("`varlist'"),`__nwnodenames')
			}
			if("`varlist'" != "" & "`bipartite'" == ""){
				mata: `__nwnodenames' = `__nwnodenames'[(1::rows(`__nwnew'))] 
			}
			if("`mat'" != "") {
				mata: `__nwnodenames' = (J(rows(`__nwnew'),1,"`cDftNodepref'") + get_node_suffix(rows(`__nwnew')))'
			}
			
			mata: st_local("notvalid", strofreal(cols(`__nwnodenames') != cols(`__nwnew')))
		}

		if (("`labs'" == "" & "`labsfromvar'" == "") | `notvalid' != 0) {
			mata: `__nwnodenames' = (J(rows(`__nwnew'),1,"`cDftNodepref'") + get_node_suffix(rows(`__nwnew')))'
		}
		
		mata: st_rclear()
		mata: st_numscalar("r(networks)", `nws'.get_number())
		mata: st_global("r(names)", `nws'.get_names())
		mata: `nws'.add("`name'")
		
		nw_syntax `name'
		mata: `netobj'->create_by_name(`__nwnodenames')
		mata: `netobj'->set_name("`name'")
		mata: `netobj'->set_edge(`__nwnew')
		mata: `netobj'->set_directed("`undirected'" == "")
		mata: `netobj'->set_selfloop("`selfloop'" == "selfloop")
	
		if "`nodenames'" != "" {
			mata: `netobj'->set_nodenames(`nodenames')
		}

		// vars() lets a caller explicitly name the Stata variables
		// nwload will later materialize this network into, overriding
		// update_nodesvar()'s own auto-derived-from-node-names default
		// (called internally by create_by_name() above). Documented
		// since at least this file's own doc header ("can be set wit
		// option vars()"), but the option itself had been silently
		// dropped from this syntax line at some point - confirmed via
		// direct probe that nwlattice.ado's own `` nwset, vars(...) ``
		// call crashed with "option vars() not allowed" before this
		// fix, the actual root cause behind nwlattice's own long-open
		// Pending item (previously misdiagnosed as a missing
		// nwvalidvars.ado, which turned out to be a red herring - see
		// docs/CERTIFICATION.md).
		if "`vars'" != "" {
			mata: st_local("nwsetvarsnodes", strofreal(rows(`__nwnew')))
			local varscount : word count `vars'
			if `varscount' != `nwsetvarsnodes' {
				di "{err}option {bf:vars()} needs to have as many entries as there are nodes in the network ({bf:`nwsetvarsnodes'})."
				error 6070
			}
			mata: `netobj'->set_nodesvar(tokens("`vars'"))
		}

		if "`undirected'" != "" | "`bipartite'" != "" {
			nwsym `name'
		}

		if "`bipartite'" != "" {
			mata: `netobj'->set_2mode(1)
			mata: `netobj'->set_modes(`__modes')
			mata: `netobj'->set_nodes_mode1(`mode1')
		}
		
		// check if network is valued or not
		mata: `netobj'->set_valued(`netobj'->check_valued())
		
		_nwdatasync
	}
	
	 capture mata: mata drop mode1
	 capture mata: mata drop `__modes'
	 capture mata: mata drop `__nwnew' 
	 capture mata: mata drop `__nwnodenames'
end

capture mata: mata drop check_bipartite()
capture mata: mata drop get_2mode_edge()

// get_node_suffix()/get_nodenames_from_string()/get_nodenames_from_var()
// moved to unw_core.do (sparse-backend migration, nwfromedge.ado's own
// rewiring) - shared with nwfromedge.ado's sparse-native construction,
// which cannot safely depend on this file's own Mata block having
// already been loaded first. This file's own callers below are
// unaffected - the functions are still callable by the same names,
// just defined in the always-loaded core file now instead of here.

mata:
real matrix get_2mode_edge(real matrix edge){
	real scalar r, c, n
	real matrix edge2
	
	r = rows(edge)
	c = cols(edge)
	n = r + c
	
	edge2 = J(n,n, .)
	edge2[((c + 1)::n), (1::c)]= edge
	edge2[(1::c),((c+1)::n)] = edge'
	return(edge2)
}


real matrix check_bipartite(real matrix edge, string scalar bip){
	real scalar m

	if (bip == "bipartite"){
		edge = get_2mode_edge(edge)
	}
	else {
		m = min((rows(edge), cols(edge)))
		edge = edge[(1::m),(1::m)]
	}
	return(edge)
}
end
