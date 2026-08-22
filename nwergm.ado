/***
{smcl}
{* *! version 2.0.0  22aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwergm {hline 2} Exponential-family random graph model (ERGM) estimation{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwergm}
[{it:{help netname}}]
{cmd:,}
{opt edges} [{opt mutual}]
[{opth nodematch(varlist)}]
[{opth nodecov(varlist)}]
[{opth nodeicov(varlist)}]
[{opth nodeocov(varlist)}]
[{opth edgecov(netname)}]
[{opt gwesp(real)}]
[{opt gwdegree(real)}]
[{opt gwodegree(real)}]
[{opt gwidegree(real)}]
[{opt method(mple|mcmle)}
{opt mcmcburnin(int)}
{opt mcmcinterval(int)}
{opt mcmcsamplesize(int)}
{opt mcmleiterations(int)}
{opt proposal(uniform|tnt)}
{opt seed(int)}
{opt verbose}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt edges}}Include the {cmd:edges} term (density/intercept); required{p_end}
{synopt:{opt mutual}}Reciprocated-tie count; directed networks only{p_end}
{synopt:{opth nodematch(varlist)}}Homophily on each listed categorical node attribute (exact match){p_end}
{synopt:{opth nodecov(varlist)}}Continuous node covariate main effect (sum over tie endpoints){p_end}
{synopt:{opth nodeicov(varlist)}}Directed receiver-covariate effect; directed networks only{p_end}
{synopt:{opth nodeocov(varlist)}}Directed sender-covariate effect; directed networks only{p_end}
{synopt:{opth edgecov(netname)}}Dyadic covariate effect, taken from an already-loaded network's own tie values{p_end}
{synopt:{opt gwesp(real)}}Geometrically weighted edgewise shared partners, fixed decay; undirected only{p_end}
{synopt:{opt gwdegree(real)}}Geometrically weighted degree, fixed decay{p_end}
{synopt:{opt gwodegree(real)}}Geometrically weighted out-degree, fixed decay; directed networks only{p_end}
{synopt:{opt gwidegree(real)}}Geometrically weighted in-degree, fixed decay; directed networks only{p_end}
{synopt:{opt method(mple|mcmle)}}Estimation method; default {it:mcmle} unless the model is dyad-independent, in which case MPLE already is the MLE{p_end}
{synopt:{opt mcmcburnin(int)}}MCMC burn-in steps per simulation; default 3,000{p_end}
{synopt:{opt mcmcinterval(int)}}MCMC steps between recorded draws; default 50{p_end}
{synopt:{opt mcmcsamplesize(int)}}Number of recorded MCMC draws per simulation; default 3,000{p_end}
{synopt:{opt mcmleiterations(int)}}Maximum MCMLE outer iterations; default 20{p_end}
{synopt:{opt proposal(uniform|tnt)}}Metropolis-Hastings proposal; default {it:tnt}{p_end}
{synopt:{opt seed(int)}}Set the random-number seed before simulating (for reproducibility){p_end}
{synopt:{opt verbose}}Show MPLE/MCMLE iteration detail{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwergm} fits an exponential-family random graph model (ERGM) to the network(s) in
{help netname} (default: the currently set network) using a fully native Stata/Mata
implementation - no R or other external statistical software is called at any point, at
estimation time or otherwise. Statnet's mature {cmd:ergm} R package was studied in detail as a
behavioural and architectural reference during development (see {browse "https://cran.r-project.org/package=ergm":statnet.org})
and used, during development only, to certify {cmd:nwergm}'s own independently-written
implementation against real reference output; see {help nwergm##provenance:Provenance} below.

{pstd}
This is a deliberately small first release: a working extensible core (term registry,
Metropolis-Hastings simulation with a genuine tie/no-tie proposal, maximum pseudolikelihood
estimation, and Monte Carlo maximum likelihood estimation) with a small, carefully certified
effect library, rather than an attempt at parity with Statnet's own much larger term/control
surface. See {help nwergm##limitations:Limitations} below for exactly what is and is not
supported, and the package's own {browse "docs/ERGM_ROADMAP.md"} for the prioritised extension
plan.

{pstd}
{opt method()} selects the estimation method. If every requested term is dyad-independent
(currently: {opt edges}, {opt nodematch()}, {opt nodecov()}, {opt nodeicov()},
{opt nodeocov()}, {opt edgecov()}) and neither {opt mutual} nor any geometrically weighted term
is present, maximum pseudolikelihood {it:is} the maximum likelihood estimate - {cmd:nwergm}
detects this automatically and reports {opt method(mple)} results directly (labeled as such,
not as full ERGM MLE) without ever running MCMC. Otherwise the default is
{opt method(mcmle)}: pseudolikelihood is used only as the starting value for Monte Carlo maximum
likelihood.

{marker limitations}{...}
{title:Limitations (v1 scope)}

{pstd}
{cmd:nwergm} estimates {bf:binary, static, one-mode} ERGMs only:

{p2colset 9 13 15 2}{...}
{p2col: o}Two-mode (bipartite) networks are rejected with an explicit error - never silently
projected to one mode.{p_end}
{p2col: o}Temporal networks (snapshot/interval/event metadata) are rejected with an explicit
error - never silently collapsed to a single static slice.{p_end}
{p2col: o}Valued/weighted or signed networks are rejected with an explicit error - never
silently dichotomized or stripped of sign. Valued ERGMs are a materially different statistical
framework (Krivitsky 2012) and are tracked as a separate future initiative, not a small
extension.{p_end}
{p2colreset}{...}

{pstd}
The effect library covers {opt edges}, {opt mutual}, {opt nodematch()}, {opt nodecov()},
{opt nodeicov()}/{opt nodeocov()}, {opt edgecov()}, and the geometrically weighted
{opt gwesp()}/{opt gwdegree()}/{opt gwodegree()}/{opt gwidegree()} family with FIXED decay only
(curved/free-decay estimation is a roadmap item). Constraints beyond the free binary dyad space,
offsets, and goodness-of-fit/MCMC-diagnostics postestimation commands are not yet implemented -
see the roadmap.

{title:Stored results}

	Scalars
	  {bf:e(N)}			number of dyads
	  {bf:e(nodes)}			number of nodes
	  {bf:e(ties)}			number of observed ties
	  {bf:e(converged)}		1 if MCMLE's own convergence test was satisfied (method(mcmle) only)
	  {bf:e(mcmle_iterations)}	number of MCMLE outer iterations run (method(mcmle) only)

	Macros
	  {bf:e(cmd)}			{bf:nwergm}
	  {bf:e(title)}			title of estimation
	  {bf:e(depvar)}		name of the estimated network
	  {bf:e(method)}		{bf:mple} or {bf:mcmle}
	  {bf:e(directed)}		{bf:true}/{bf:false}
	  {bf:e(proposal)}		Metropolis-Hastings proposal used (method(mcmle) only)

	Matrices
	  {bf:e(b)}			coefficient vector
	  {bf:e(V)}			variance-covariance matrix

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwergm flomarriage, edges}
	{cmd:. nwergm flomarriage, edges nodecov(wealth)}
	{cmd:. nwergm flomarriage, edges gwesp(.5)}

{marker provenance}{...}
{title:References}

{pstd}
Hunter, D.R., Handcock, M.S., Butts, C.T., Goodreau, S.M., Morris, M. (2008). ergm: A Package to
Fit, Simulate and Diagnose Exponential-Family Models for Networks. {it:Journal of Statistical
Software}, 24(3), 1-29.

{pstd}
Hunter, D.R., Handcock, M.S. (2006). Inference in curved exponential family models for networks.
{it:Journal of Computational and Graphical Statistics}, 15(3), 565-583. (MPLE)

{pstd}
Hunter, D.R. (2007). Curved exponential family models for social networks. {it:Social Networks},
29(2), 216-230. (GWESP/GWDEGREE)

{pstd}
Morris, M., Handcock, M.S., Hunter, D.R. (2008). Specification of Exponential-Family Random
Graph Models: Terms and Computational Aspects. {it:Journal of Statistical Software}, 24(4),
1-24. (TNT proposal)

{pstd}
Hummel, R.M., Hunter, D.R., Handcock, M.S. (2012). Improving Simulation-Based Algorithms for
Fitting ERGMs. {it:Journal of Computational and Graphical Statistics}, 21(4), 920-939. (MCMLE
step length)

{pstd}
Geyer, C.J., Thompson, E.A. (1992). Constrained Monte Carlo Maximum Likelihood for Dependent
Data. {it:Journal of the Royal Statistical Society, Series B}, 54(3), 657-699. (MCMLE)

{pstd}
{cmd:nwergm} is an independent, native reimplementation and is not affiliated with or endorsed
by the Statnet project. See {browse "docs/ERGM_PROVENANCE.md"} for the full licensing and
provenance account, and {browse "docs/ERGM_STATNET_STUDY.md"} for the architecture study this
implementation is based on.

{title:See also}

	{help nwqap}, {help nwrandom}, {help nwcug}

***/

capture program drop nwergm
program nwergm, eclass
	version 14
	syntax [anything(name=netname)] [, edges mutual ///
		NODEMATCH(string) NODECOV(string) NODEICOV(string) NODEOCOV(string) ///
		EDGECOV(string) GWESP(string) GWDEGREE(string) GWODEGREE(string) GWIDEGREE(string) ///
		METHOD(string) MCMCBURNIN(integer 3000) MCMCINTERVAL(integer 50) ///
		MCMCSAMPLESIZE(integer 3000) MCMLEITERATIONS(integer 20) ///
		PROPOSAL(string) SEED(integer -1) VERBOSE ]
	set more off

	if "`edges'" == "" {
		di "{err}option {bf:edges} is required - every v1 nwergm model includes an edges term."
		error 198
	}
	if "`proposal'" == "" local proposal "tnt"
	_opts_oneof "uniform tnt" "proposal" "`proposal'" 198
	if "`method'" != "" {
		_opts_oneof "mple mcmle" "method" "`method'" 198
	}

	nw_syntax `netname', max(1)

	// --- network-type validation (Part IV/XXII/XXIII/XXIV): reject,
	// never silently reinterpret.
	if "`is2mode'" == "true" {
		di "{err}nwergm does not yet support two-mode (bipartite) networks; {bf:`netname'} is two-mode."
		di "{err}Native bipartite ERGM terms are a roadmap item - nwergm never silently projects a two-mode network to one mode."
		error 198
	}
	if "`istemporal'" == "true" {
		di "{err}nwergm estimates static ERGMs only; {bf:`netname'} carries temporal metadata."
		di "{err}nwergm never silently collapses a temporal network to a single slice - build an explicit static network first (e.g. via nwattime) and estimate on that."
		error 198
	}
	if "`valued'" == "true" {
		di "{err}nwergm estimates binary ERGMs only; {bf:`netname'} is valued/weighted."
		di "{err}nwergm never silently dichotomizes tie values or drops signs. Valued ERGMs are a separate, larger future initiative (see docs/ERGM_ROADMAP.md)."
		error 198
	}
	if "`mutual'" != "" & "`directed'" != "true" {
		di "{err}option {bf:mutual} requires a directed network; {bf:`netname'} is undirected."
		error 198
	}
	if ("`nodeicov'" != "" | "`nodeocov'" != "") & "`directed'" != "true" {
		di "{err}options {bf:nodeicov()}/{bf:nodeocov()} require a directed network; {bf:`netname'} is undirected."
		error 198
	}
	if "`gwesp'" != "" & "`directed'" == "true" {
		di "{err}option {bf:gwesp()} (v1 scope) is undirected only; {bf:`netname'} is directed. See docs/ERGM_ROADMAP.md for the directed OTP/ITP/OSP/ISP variants."
		error 198
	}
	if ("`gwodegree'" != "" | "`gwidegree'" != "") & "`directed'" != "true" {
		di "{err}options {bf:gwodegree()}/{bf:gwidegree()} require a directed network; {bf:`netname'} is undirected. Use {bf:gwdegree()} for an undirected network."
		error 198
	}

	if `seed' != -1 {
		set seed `seed'
	}

	// --- build the ErgmGraph from the current NWdef network (one-time
	// read via the already-established sparse accessors; ErgmGraph
	// itself never touches NWdef again after this point - it is, by
	// design, fully decoupled from NWdef; see unw_ergm.do's own header
	// comment). The bridge itself (ergm_bridge_from_netobj(), defined
	// once at file scope below) lives here, in the .ado integration
	// layer, not in either decoupled Mata subsystem.
	// every Mata-side tempname created below is appended to this list
	// (in expanded, literal-name form) so it can be dropped in one shot
	// at the end of the program - a one-line interactive `mata: X = ...'
	// call creates a permanent, top-level Mata variable that is NEVER
	// garbage-collected on its own (unlike a proper Mata function's own
	// locals), so without this bookkeeping every nwergm call leaks one
	// object per term instance into the ambient Mata workspace. Left
	// unfixed, this eventually collides with Mata objects Stata's own
	// machinery creates internally (e.g. `estimates table'/`esttab'),
	// surfacing as a baffling "Mata object __NNNNNN already exists".
	local __ergm_matatemps ""

	tempname __nw_G
	mata: `__nw_G' = ErgmGraph()
	mata: `__nw_G'.init(`nodes', ("`directed'"=="true"))
	mata: ergm_bridge_from_netobj(`netobj', `__nw_G', ("`directed'"=="true"))
	local __ergm_matatemps "`__ergm_matatemps' `__nw_G'"

	// --- build the model: one addterm() call per requested term.
	tempname __nw_M
	mata: `__nw_M' = ErgmModel()
	mata: `__nw_M'.init()
	local __ergm_matatemps "`__ergm_matatemps' `__nw_M'"

	tempname __td_edges
	mata: `__td_edges' = ErgmTermData()
	mata: `__nw_M'.addterm("edges", 1, &stat_edges(), &change_edges(), `__td_edges', ("edges"))
	local __ergm_matatemps "`__ergm_matatemps' `__td_edges'"

	if "`mutual'" != "" {
		tempname __td_mutual
		mata: `__td_mutual' = ErgmTermData()
		mata: `__nw_M'.addterm("mutual", 1, &stat_mutual(), &change_mutual(), `__td_mutual', ("mutual"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_mutual'"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local nodematch {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nm`__ergm_termidx'
		mata: `__td_nm`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nm`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: `__nw_M'.addterm("nodematch", 1, &stat_nodematch(), &change_nodematch(), `__td_nm`__ergm_termidx'', ("nodematch_`__ergm_v'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_nm`__ergm_termidx''"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local nodecov {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nc`__ergm_termidx'
		mata: `__td_nc`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nc`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: `__nw_M'.addterm("nodecov", 1, &stat_nodecov(), &change_nodecov(), `__td_nc`__ergm_termidx'', ("nodecov_`__ergm_v'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_nc`__ergm_termidx''"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local nodeicov {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_ni`__ergm_termidx'
		mata: `__td_ni`__ergm_termidx'' = ErgmTermData()
		mata: `__td_ni`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: `__nw_M'.addterm("nodeicov", 1, &stat_nodeicov(), &change_nodeicov(), `__td_ni`__ergm_termidx'', ("nodeicov_`__ergm_v'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_ni`__ergm_termidx''"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local nodeocov {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_no`__ergm_termidx'
		mata: `__td_no`__ergm_termidx'' = ErgmTermData()
		mata: `__td_no`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: `__nw_M'.addterm("nodeocov", 1, &stat_nodeocov(), &change_nodeocov(), `__td_no`__ergm_termidx'', ("nodeocov_`__ergm_v'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_no`__ergm_termidx''"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local edgecov {
		local ++__ergm_termidx
		tempname __td_ec`__ergm_termidx'
		mata: `__td_ec`__ergm_termidx'' = ErgmTermData()
		nw_syntax `__ergm_v', max(1) other(ec`__ergm_termidx')
		if `ec`__ergm_termidx'nodes' != `nodes' {
			di "{err}edgecov() network {bf:`__ergm_v'} has a different number of nodes than {bf:`netname'}."
			error 198
		}
		mata: `__td_ec`__ergm_termidx''.edgecovmat = *(`ec`__ergm_termidx'netobj'->get_matrix_mod(1,("`directed'"=="true")))
		mata: `__nw_M'.addterm("edgecov", 1, &stat_edgecov(), &change_edgecov(), `__td_ec`__ergm_termidx'', ("edgecov_`__ergm_v'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_ec`__ergm_termidx''"
	}

	if "`gwesp'" != "" {
		confirm number `gwesp'
		tempname __td_gwesp
		mata: `__td_gwesp' = ErgmTermData()
		mata: `__td_gwesp'.decay = `gwesp'
		mata: `__nw_M'.addterm("gwesp", 1, &stat_gwesp(), &change_gwesp(), `__td_gwesp', ("gwesp_`gwesp'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwesp'"
	}
	if "`gwdegree'" != "" {
		confirm number `gwdegree'
		tempname __td_gwdeg
		mata: `__td_gwdeg' = ErgmTermData()
		mata: `__td_gwdeg'.decay = `gwdegree'
		mata: `__nw_M'.addterm("gwdegree", 1, &stat_gwdegree(), &change_gwdegree(), `__td_gwdeg', ("gwdegree_`gwdegree'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwdeg'"
	}
	if "`gwodegree'" != "" {
		confirm number `gwodegree'
		tempname __td_gwod
		mata: `__td_gwod' = ErgmTermData()
		mata: `__td_gwod'.decay = `gwodegree'
		mata: `__nw_M'.addterm("gwodegree", 1, &stat_gwodegree(), &change_gwodegree(), `__td_gwod', ("gwodegree_`gwodegree'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwod'"
	}
	if "`gwidegree'" != "" {
		confirm number `gwidegree'
		tempname __td_gwid
		mata: `__td_gwid' = ErgmTermData()
		mata: `__td_gwid'.decay = `gwidegree'
		mata: `__nw_M'.addterm("gwidegree", 1, &stat_gwidegree(), &change_gwidegree(), `__td_gwid', ("gwidegree_`gwidegree'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwid'"
	}

	// dyad-independent iff only edges/nodematch/nodecov/nodeicov/nodeocov/edgecov
	// are present (mutual and every gw term are dyad-dependent).
	local __ergm_dind = (`"`mutual'"'=="" & `"`gwesp'"'=="" & `"`gwdegree'"'=="" & `"`gwodegree'"'=="" & `"`gwidegree'"'=="")
	if "`method'" == "" {
		local method = cond(`__ergm_dind', "mple", "mcmle")
	}
	if "`method'" == "mple" & !`__ergm_dind' {
		di "{txt}Note: {bf:method(mple)} requested for a dyad-dependent model - reporting pseudolikelihood, NOT full ERGM maximum likelihood."
	}

	tempname __nw_D
	mata: `__nw_D' = `__nw_M'.build_mple_data(`__nw_G')
	mata: st_matrix("nw_ergm_D", `__nw_D')
	local __ergm_matatemps "`__ergm_matatemps' `__nw_D'"
	local __ergm_p = colsof(nw_ergm_D) - 1

	tempname __ergm_coefnames
	mata: st_local("__ergm_coefnames", invtokens(`__nw_M'.coefnames))

	local __ergm_xlist ""
	forvalues __k = 1/`__ergm_p' {
		local __ergm_xlist "`__ergm_xlist' __ergm_x`__k'"
	}

	preserve
	qui drop _all
	qui set obs `=rowsof(nw_ergm_D)'
	foreach __v of local __ergm_xlist {
		qui gen double `__v' = .
	}
	qui gen double __ergm_y = .
	mata: st_store(., tokens("`__ergm_xlist' __ergm_y"), st_matrix("nw_ergm_D"))

	qui logit __ergm_y `__ergm_xlist', noconstant
	tempname __b_mple __V_mple
	matrix `__b_mple' = e(b)
	matrix `__V_mple' = e(V)
	restore

	if "`method'" == "mple" {
		// logit's own e(b)/e(V) carry an equation-name stripe (the
		// depvar's own name, e.g. "__ergm_y:__ergm_x1") - blanked
		// explicitly before assigning fresh colnames/rownames, or a
		// stale/mismatched stripe between b and V makes `ereturn post`
		// fail with a "name conflict" (r(507)) - the exact same bug
		// class already found and fixed once in nwqap.ado (see its own
		// header comment).
		matrix coleq `__b_mple' = _
		matrix coleq `__V_mple' = _
		matrix roweq `__V_mple' = _
		matrix colnames `__b_mple' = `__ergm_coefnames'
		matrix rownames `__V_mple' = `__ergm_coefnames'
		matrix colnames `__V_mple' = `__ergm_coefnames'

		ereturn post `__b_mple' `__V_mple', depname(`netname') obs(`=rowsof(nw_ergm_D)')
		ereturn local cmd "nwergm"
		ereturn local title "Exponential-family random graph model (MPLE)"
		ereturn local depvar "`netname'"
		ereturn local method "mple"
		ereturn local directed "`directed'"
		ereturn scalar N = rowsof(nw_ergm_D)
		ereturn scalar nodes = `nodes'
		mata: st_numscalar("e(ties)", `__nw_G'.nties)

		nwergm_display "`netname'" "`nodes'" "`directed'" "MPLE" "" ""
	}
	else {
		tempname __theta0
		mata: `__theta0' = st_matrix("`__b_mple'")
		local __ergm_matatemps "`__ergm_matatemps' `__theta0'"

		if "`proposal'" == "tnt" local __ergm_propfn "&ergm_propose_tnt()"
		else local __ergm_propfn "&ergm_propose_uniform()"

		tempname __fit
		mata: `__fit' = ErgmMCMLE(`__nw_M', `__nw_G', `__theta0', `mcmleiterations', `mcmcburnin', `mcmcinterval', `mcmcsamplesize', `__ergm_propfn', ("`verbose'"!=""))
		local __ergm_matatemps "`__ergm_matatemps' `__fit'"

		tempname __b_mcmle __V_mcmle
		mata: st_matrix("`__b_mcmle'", `__fit'.coef)
		mata: st_matrix("`__V_mcmle'", `__fit'.vcov)
		// captured into plain locals, NOT e(name)-style scalars: `ereturn
		// post' below clears whatever the e() results namespace
		// currently holds, so referencing `e(converged)' AFTER that
		// call (as this code originally, incorrectly, did) reads back
		// missing - the exact same "r(x) is only published once the
		// program exits" confusion already found and fixed once in this
		// package's own nw2project.ado, here for e() instead of r().
		mata: st_local("__ergm_converged", strofreal(`__fit'.converged))
		mata: st_local("__ergm_niter", strofreal(`__fit'.niter))

		matrix coleq `__b_mcmle' = _
		matrix coleq `__V_mcmle' = _
		matrix roweq `__V_mcmle' = _
		matrix colnames `__b_mcmle' = `__ergm_coefnames'
		matrix rownames `__V_mcmle' = `__ergm_coefnames'
		matrix colnames `__V_mcmle' = `__ergm_coefnames'

		ereturn post `__b_mcmle' `__V_mcmle', depname(`netname') obs(`=rowsof(nw_ergm_D)')
		ereturn local cmd "nwergm"
		ereturn local title "Exponential-family random graph model (MCMLE)"
		ereturn local depvar "`netname'"
		ereturn local method "mcmle"
		ereturn local directed "`directed'"
		ereturn local proposal "`proposal'"
		ereturn scalar N = rowsof(nw_ergm_D)
		ereturn scalar nodes = `nodes'
		ereturn scalar converged = `__ergm_converged'
		ereturn scalar mcmle_iterations = `__ergm_niter'
		mata: st_numscalar("e(ties)", `__nw_G'.nties)

		if `__ergm_converged' == 0 {
			di "{err}Warning: MCMLE did NOT satisfy its own convergence test after `__ergm_niter' iterations."
			di "{err}Results are reported but should not be treated as a converged fit - consider increasing mcmleiterations()/mcmcsamplesize()."
		}

		nwergm_display "`netname'" "`nodes'" "`directed'" "MCMLE" "`__ergm_converged'" "`__ergm_niter'" "`mcmcsamplesize'"
	}

	mata: mata drop `__ergm_matatemps'
end

capture program drop nwergm_display
program nwergm_display
	args netname nodes directed method converged niter mcmcsamplesize

	di
	di "{txt}Exponential-family random graph model"
	di
	di "{txt}Network:{col 24}={res}  `netname'"
	di "{txt}Nodes:{col 24}={res}  `nodes'"
	di "{txt}Ties:{col 24}={res}  `=e(ties)'"
	di "{txt}Directed:{col 24}={res}  " cond("`directed'"=="true","Yes","No")
	di "{txt}Estimation:{col 24}={res}  `method'"
	if "`method'" == "MCMLE" {
		di "{txt}MCMC sample size:{col 24}={res}  `mcmcsamplesize'"
	}
	di
	ereturn display
	di
	if "`method'" == "MCMLE" {
		if "`converged'" == "1" {
			di "{txt}MCMLE converged after `niter' iteration(s)."
		}
		else {
			di "{err}MCMLE did not converge after `niter' iteration(s)."
		}
	}
	else {
		di "{txt}Maximum pseudolikelihood estimate (not full ERGM maximum likelihood unless the model is dyad-independent)."
	}
end

/*
	Bridge from an NWdef network to a fresh ErgmGraph: one-time read via
	NWdef's own neighbors() sparse accessor, undirected ties added once
	each (nb[k] <= i skipped, since ErgmGraph.toggle() already mirrors
	an undirected tie in both directions internally). Defined once at
	file scope (guarded, matching nwqap.ado's own established pattern
	for file-scope Mata helpers) rather than inside the program body -
	redefining a Mata function on every single nwergm call would error
	on the second call within the same session ("already exists").
*/
capture mata: mata drop ergm_bridge_from_netobj()
mata:
void ergm_bridge_from_netobj(pointer(class nw_def scalar) scalar netobj,
	class ErgmGraph scalar G, real scalar directed){
	real scalar i, k
	real matrix nb

	for (i=1; i<=G.n; i++) {
		nb = netobj->neighbors(i)
		for (k=1; k<=rows(nb); k++) {
			if (!directed & nb[k] <= i) continue
			G.toggle(i, nb[k])
		}
	}
}
end
