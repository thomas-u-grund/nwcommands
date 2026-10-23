*! nwsaom multiplex (split out of nwsaom.ado: the programs of one ado-file all count towards Stata's 1000 KB adosize while loaded)
/* ===================================================================
   nwsaom multiplex: Stage 1 of multiplex/multi-relation SAOM support
   (docs/SAOM_ROADMAP.md's own "v1-scope exclusions" entry) - two
   networks co-evolving, WITHIN-network effects only (outdegree +
   reciprocity on each), no cross-network effects yet. A separate,
   self-contained subcommand (matching nwergm's own `nwergm simulate'
   dispatch precedent above) rather than folding a second network into
   the main `nwsaom' syntax/dispatch above - keeps this Stage-1 addition
   at ZERO regression risk to every existing single-network/co-evolution
   model, which the main command's own already-large option surface
   (present()/missnet()/waves()/behavior()/ratecov()/etc.) would
   otherwise have to reason about jointly with a second network.

   Mata engine: SaomSimulateIntervalCoevNetNet()/SaomEstimateRMCoevNetNet()
   (unw_saom.do) - a parallel implementation of SaomEstimateRMCoev()'s
   own three-phase joint Robbins-Monro structure for two ErgmModel/
   ErgmGraph instances instead of one ErgmModel + one SaomBehaviorModel,
   verified against RSiena's own real EpochSimulation.cpp source
   (chooseVariable()/chooseActor(): a rate-proportional choice among ALL
   of a model's dependent variables is a fully generic mechanism -
   network+behavior and network+network co-evolution are the SAME
   underlying RSiena process, just different variable types).

   Stage 2 (docs/SAOM_ROADMAP.md): adds the first real cross-network
   effect, `crprod()` - RSiena's own real "netA: netB" term (verified
   from real RSiena 1.6.6 source - see stat_crprod()/change_crprod()'s
   own header comment in unw_saom.do for the full account). `crprod`
   adds it to net1's own effect list (net1's ties rewarded/penalized by
   the SAME dyad's current state in net2); `crprodb` is the mirror,
   adding it to net2's own list reading net1 - independent flags, either
   or both may be given. Still v1 Stage-1/2 scope, disclosed not
   silently narrowed: exactly two waves per network, outdegree+
   reciprocity(+crprod) only, no composition change/missing data. Fully
   native (C) across all three Robbins-Monro phases (phase 1's Jacobian,
   phase 2's own theta updates, phase 3's sandwich covariance) whenever
   eligible - stale note removed here since an earlier version of this
   comment predated that work and was never updated afterward.
   =================================================================== */
capture program drop nwsaom_multiplex
program define nwsaom_multiplex, eclass
	version 14
	syntax , NETAWAVE1(string) NETAWAVE2(string) NETBWAVE1(string) NETBWAVE2(string) ///
		[ THETA01(string) THETA02(string) K0(integer 30) K3(integer 200) FIRSTG(real 0.2) seed(integer -1) CRPROD CRPRODB ]

	if `seed' != -1 set seed `seed'

	mata: __nwsaom_engine = ""
	mata: __nwsaom_engine_why = ""
	_nwsyntax `netawave1', max(1) other(w1a)
	_nwsyntax `netawave2', max(1) other(w1b)
	_nwsyntax `netbwave1', max(1) other(w2a)
	_nwsyntax `netbwave2', max(1) other(w2b)
	_nwrowalign `netawave1' `netawave2' `netbwave1' `netbwave2'

	foreach __w in w1a w1b w2a w2b {
		if "``__w'directed'" != "true" {
			di "{err}nwsaom multiplex requires directed networks, matching plain nwsaom's own v1 scope."
			error 198
		}
		if "``__w'is2mode'" == "true" {
			di "{err}nwsaom multiplex does not support two-mode (bipartite) networks."
			error 198
		}
	}
	if `w1anodes' != `w1bnodes' | `w1anodes' != `w2anodes' | `w1anodes' != `w2bnodes' {
		di "{err}every network/wave passed to nwsaom multiplex must share the same, fixed number of nodes."
		error 198
	}
	local nodes = `w1anodes'

	local wantcrprod = ("`crprod'" != "")
	local wantcrprodb = ("`crprodb'" != "")

	// Mata row-vector literal syntax needs COMMA-separated elements
	// (`(0, 0)', not `(0 0)') - confirmed directly, not assumed (the
	// space-separated form is a genuine parse error, "invalid
	// expression"), so theta01()/theta02() must be given comma-separated
	// too if a user overrides the default. Default length now tracks
	// whether crprod()/crprodb() add a third parameter to that network's
	// own effect list.
	if "`theta01'" == "" local theta01 = cond(`wantcrprod', "0, 0, 0", "0, 0")
	if "`theta02'" == "" local theta02 = cond(`wantcrprodb', "0, 0, 0", "0, 0")

	tempname b V
	// Single one-line call into a real, file-scope Mata function
	// (__nwsaom_mp_fit_and_post(), defined near __nwsaom_bridge_from_netobj()
	// above) rather than an inline multi-line `mata:'/`end' block nested
	// inside this program body - see that function's own header comment
	// for the real, reproducible parser bug the earlier inline-block
	// version hit (Stata silently closed THIS `program define' at the
	// inline block's own `end', dropping everything meant to run after
	// it) and why this codebase's own file-scope-Mata-function
	// convention exists.
	mata: __nwsaom_mp_fit_and_post(`w1anetobj', `w1bnetobj', `w2anetobj', `w2bnetobj', `nodes', (`theta01'), (`theta02'), `k0', `k3', `firstg', `wantcrprod', `wantcrprodb', "`b'", "`V'", "__nwsaom_mp_rate1", "__nwsaom_mp_rate2", "__NWSAOM_MP_COEFNAMES__")

	// Coefficient names/count now vary with crprod()/crprodb() (Mata's
	// own M1.coefnames/M2.coefnames, the actual source of truth for what
	// each ErgmModel really contains) rather than the old fixed 4-column
	// literal - posted back as a Stata global (cleared immediately after
	// reading) since `matrix colnames' needs a plain token list, not a
	// Mata return value directly.
	local __mp_coefnames "$__NWSAOM_MP_COEFNAMES__"
	macro drop __NWSAOM_MP_COEFNAMES__
	matrix colnames `b' = `__mp_coefnames'
	matrix colnames `V' = `__mp_coefnames'
	matrix rownames `V' = `__mp_coefnames'

	ereturn post `b' `V', obs(`nodes')
	ereturn scalar rate1 = __nwsaom_mp_rate1
	ereturn scalar rate2 = __nwsaom_mp_rate2
	ereturn scalar rate1_se = __nwsaom_mp_rate1_se
	ereturn scalar rate2_se = __nwsaom_mp_rate2_se
	ereturn scalar tconv_max = __nwsaom_mp_rate1_tconvmax
	scalar drop __nwsaom_mp_rate1 __nwsaom_mp_rate2 __nwsaom_mp_rate1_se __nwsaom_mp_rate2_se __nwsaom_mp_rate1_tconvmax
	matrix colnames __nwsaom_mp_rate1_tconv = `__mp_coefnames' rate1 rate2
	matrix rownames __nwsaom_mp_rate1_tconv = tconv
	ereturn matrix tconv = __nwsaom_mp_rate1_tconv
	ereturn local cmd "nwsaom_multiplex"
	_nwsaom_postengine

	di as text "{hline}"
	if `wantcrprod' | `wantcrprodb' di as text "Multiplex SAOM (Stage 2: crprod cross-network effect), Method of Moments"
	else di as text "Multiplex SAOM (Stage 1: within-network effects only), Method of Moments"
	di as text "{hline}"
	ereturn display
	di as text "Rates (estimated): net1 " as result %6.3f e(rate1) as text " (" as result %5.3f e(rate1_se) as text "), net2 " as result %6.3f e(rate2) as text " (" as result %5.3f e(rate2_se) as text ")"
	_nwsaom_tconvtable
end
