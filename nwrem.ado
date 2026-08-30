
capture program drop nwrem
program nwrem, eclass
	version 14
	syntax [anything(name=netname)] [, NODSND NIDREC NIDSND NODREC NTDEGSND NTDEGREC FRPSNDSND FRRECSND COVSND(varname numeric) COVREC(varname numeric) COVINT(varname numeric) COVEVENT(string) RSNDSND RRECSND SEED(integer -1)]
	set more off

	nw_syntax `netname', max(1)

	if "`istemporal'" != "true" | "`temporaltype'" != "event" {
		di as error "nwrem requires a network declared via nwset's eventtime() option (an event-type temporal network) - see {help nwset##temporal:nwset}."
		error 198
	}
	// Defensive, matching nwergm.ado's/nwsaom.ado's own explicit
	// two-mode rejection (harmonisation unit 158 survey): currently
	// unreachable in practice (nwset's own time()/interval()/
	// eventtime() cannot yet be combined with twomode/bipartite in the
	// same call, docs/ROADMAP.md's own tracked composability item), so
	// no live network can reach this point with `is2mode'=="true" today
	// - but nwrem's own 14-effect engine (unw_rem.do) was derived and
	// certified entirely on one-mode data and has never been checked
	// against a two-mode dyad space, so this stays a real, explicit
	// guard rather than relying solely on that unrelated upstream
	// restriction never being lifted.
	if "`is2mode'" == "true" {
		di as error "nwrem does not support two-mode (bipartite) networks; {bf:`netname'} is two-mode."
		error 198
	}

	// Fixed effect order matching unw_rem.do's own rem_loglik_grad_multi()
	// exactly - see that function's own header comment. At least one
	// effect must be selected; no default is silently assumed.
	local __nwrem_effnames "nodsnd nidrec nidsnd nodrec ntdegsnd ntdegrec frpsndsnd frrecsnd covsnd covrec covint covevent rsndsnd rrecsnd"
	local __nwrem_active ""
	local __nwrem_sep ""
	local __nwrem_collabs ""
	local __nwrem_nactive = 0
	foreach __nwrem_e of local __nwrem_effnames {
		if "``__nwrem_e''" != "" {
			local __nwrem_active "`__nwrem_active'`__nwrem_sep'1"
			// covsnd()/covrec()/covint() are valued options (a variable
			// name), the other 8 are booleans - label with the variable
			// for the covariate trio (matching nwsaom's own
			// nodecov_`varname' convention) so e(b) shows which
			// variable was used, not just the generic effect name.
			if inlist("`__nwrem_e'", "covsnd", "covrec", "covint", "covevent") {
				local __nwrem_collabs "`__nwrem_collabs' `__nwrem_e'_``__nwrem_e''"
			}
			else {
				local __nwrem_collabs "`__nwrem_collabs' `__nwrem_e'"
			}
			local __nwrem_nactive = `__nwrem_nactive' + 1
		}
		else {
			local __nwrem_active "`__nwrem_active'`__nwrem_sep'0"
		}
		local __nwrem_sep ","
	}
	if `__nwrem_nactive' == 0 {
		di as error "nwrem requires at least one effect: {bf:nodsnd} {bf:nidrec} {bf:nidsnd} {bf:nodrec} {bf:ntdegsnd} {bf:ntdegrec} {bf:frpsndsnd} {bf:frrecsnd} {bf:covsnd()} {bf:covrec()} {bf:covint()} {bf:covevent()} {bf:rsndsnd} {bf:rrecsnd} (see {help nwrem} for what each computes; docs/REM_ROADMAP.md for what is not yet implemented)."
		error 198
	}

	// Covariates are read from the CURRENT Stata dataset by row
	// position 1..nodes, matching nwsaom's own established nodecov()
	// convention exactly (nwsaom.ado: confirm variable + st_data(1::nodes,
	// ...)) - NOT from the event-list dataset nwrem's own event data
	// comes from (that is read separately, via Mata, from the network
	// object itself). The caller is responsible for having the event
	// network's own per-node attribute dataset loaded first (e.g. via
	// {bf:nwload `netname', xvars}) before calling nwrem with covsnd()/
	// covrec()/covint() - the same responsibility nwsaom/nwergm already
	// place on their own nodecov()-style callers.
	tempname __nwrem_covsnd __nwrem_covrec __nwrem_covint
	foreach __nwrem_cv in covsnd covrec covint {
		if "``__nwrem_cv''" != "" {
			capture confirm numeric variable ``__nwrem_cv''
			if _rc {
				di as error "``__nwrem_cv'' is not a numeric variable in the current dataset - `__nwrem_cv'() must be a per-actor covariate, one row per node in the same order as `netname''s own actors (see {help nwload}'s {bf:xvars} option to load that dataset first)."
				error 198
			}
			capture assert _N == `nodes'
			if _rc {
				di as error "the current dataset has `=_N' observations but `netname' has `nodes' actors - `__nwrem_cv'() requires exactly one row per actor, in actor order (see {help nwload}'s {bf:xvars} option)."
				error 198
			}
			mata: `__nwrem_`__nwrem_cv'' = st_data(1::`nodes', "``__nwrem_cv''")'
		}
		else {
			mata: `__nwrem_`__nwrem_cv'' = J(1, `nodes', 0)
		}
	}

	// covevent() references ANOTHER already-loaded network (a pairwise,
	// not per-actor, covariate) - resolved via nw_syntax exactly as
	// nwergm's own edgecov()/hamming() do (nwergm.ado's dyadic-covariate
	// block), using other() so its locals (covevnetobj/covevnodes) don't
	// clobber `netobj'/`nodes' from the primary network above.
	tempname __nwrem_covevmat
	if "`covevent'" != "" {
		nw_syntax `covevent', max(1) other(covev)
		if `covevnodes' != `nodes' {
			di as error "covevent() network `covevent' has `covevnodes' actors but `netname' has `nodes' - covevent() requires the same actors as `netname'."
			error 198
		}
		mata: `__nwrem_covevmat' = *(`covevnetobj'->get_matrix_mod(1,1))
	}
	else {
		mata: `__nwrem_covevmat' = J(`nodes', `nodes', 0)
	}

	if `seed' != -1 {
		set seed `seed'
	}

	tempname __nwrem_events
	mata: `__nwrem_events' = *(`netobj'->get_eventlist())
	mata: st_numscalar("__nwrem_nevents", rows(`__nwrem_events'))
	local nevents = __nwrem_nevents
	scalar drop __nwrem_nevents

	if `nevents' < 2 {
		di as error "nwrem needs at least 2 events to fit a model; `netname' has `nevents'."
		error 2001
	}

	mata: RemFitMulti(`__nwrem_events', `nodes', (`__nwrem_active'), `__nwrem_covsnd', `__nwrem_covrec', `__nwrem_covint', `__nwrem_covevmat', "__nwrem_b", "__nwrem_V", "__nwrem_ll")
	mata: mata drop `__nwrem_events' `__nwrem_covsnd' `__nwrem_covrec' `__nwrem_covint' `__nwrem_covevmat'

	tempname b V
	matrix `b' = __nwrem_b
	matrix `V' = __nwrem_V
	matrix colnames `b' = `__nwrem_collabs'
	matrix colnames `V' = `__nwrem_collabs'
	matrix rownames `V' = `__nwrem_collabs'
	local __nwrem_ll = __nwrem_ll
	matrix drop __nwrem_b __nwrem_V
	scalar drop __nwrem_ll

	ereturn post `b' `V', obs(`nevents')
	ereturn local cmd "nwrem"
	ereturn local title "Relational event model (ordinal partial likelihood, MLE)"
	ereturn local depvar "`netname'"
	ereturn scalar N = `nevents'
	ereturn scalar nodes = `nodes'
	ereturn scalar ll = `__nwrem_ll'

	di as text "{hline 60}"
	di as text "Relational event model (ordinal partial likelihood, MLE)"
	di as text "Network: " as result "`netname'" _col(40) as text "Actors: " as result `nodes'
	di as text "Events: " as result `nevents' _col(40) as text "Log likelihood: " as result %9.4f `__nwrem_ll'
	di as text "{hline 60}"
	ereturn display
end
