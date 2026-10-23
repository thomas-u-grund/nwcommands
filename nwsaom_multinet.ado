*! nwsaom multinet (split out of nwsaom.ado, see nwsaom_multiplex.ado)
capture mata: mata drop __nwsaom_mn_addwave()
capture mata: mata drop __nwsaom_mn_post()
capture mata: mata drop __nwsaom_mnb_post()
capture mata: mata drop __nwsaom_mn_avg()
capture mata: mata drop __nwsaom_mn_avgsq()
mata:
/* nwsaom multinet (protocol 52): collects the wave graphs of one network (slot 1 or 2) and posts the fit */
void __nwsaom_mn_addwave(pointer(class nw_def scalar) scalar netobj, real scalar n, real scalar slot) {
	external pointer(class ErgmGraph scalar) rowvector __nwsaom_mn_Gs1, __nwsaom_mn_Gs2
	class ErgmGraph scalar G
	G = ErgmGraph()
	G.init(n, 1)
	__nwsaom_bridge_from_netobj(netobj, G)
	if (slot == 1) __nwsaom_mn_Gs1 = (__nwsaom_mn_Gs1, &(G))
	else __nwsaom_mn_Gs2 = (__nwsaom_mn_Gs2, &(G))
}
/* average degree over all waves of network `slot' (RSiena NetworkLongitudinalData::averageInDegree()) */
real scalar __nwsaom_mn_avg(real scalar slot) {
	external pointer(class ErgmGraph scalar) rowvector __nwsaom_mn_Gs1, __nwsaom_mn_Gs2
	pointer(class ErgmGraph scalar) rowvector Gs
	real scalar w, tot, n
	Gs = (slot == 1 ? __nwsaom_mn_Gs1 : __nwsaom_mn_Gs2)
	tot = 0
	n = (*Gs[1]).n
	for (w=1; w<=cols(Gs); w++) tot = tot + rows((*Gs[w]).all_ties())
	return(tot / (n * cols(Gs)))
}
/* average squared in-degree over all waves of network `slot' */
real scalar __nwsaom_mn_avgsq(real scalar slot) {
	external pointer(class ErgmGraph scalar) rowvector __nwsaom_mn_Gs1, __nwsaom_mn_Gs2
	pointer(class ErgmGraph scalar) rowvector Gs
	real scalar w, tot, n, k
	real colvector d
	real matrix e
	Gs = (slot == 1 ? __nwsaom_mn_Gs1 : __nwsaom_mn_Gs2)
	tot = 0
	n = (*Gs[1]).n
	for (w=1; w<=cols(Gs); w++) {
		d = J(n, 1, 0)
		e = (*Gs[w]).all_ties()
		if (rows(e) > 0) for (k=1; k<=rows(e); k++) d[e[k,2]] = d[e[k,2]] + 1
		tot = tot + sum(d :^ 2)
	}
	return(tot / (n * cols(Gs)))
}
void __nwsaom_mn_post(real rowvector theta01, real rowvector theta02, real scalar K0, real scalar K3, real scalar firstg, real scalar sym1, real scalar sym2,
	string scalar bname, string scalar Vname, string scalar ratename, string scalar tcname, string scalar ncoefname, string scalar targetname) {
	external pointer(class ErgmGraph scalar) rowvector __nwsaom_mn_Gs1, __nwsaom_mn_Gs2
	external class ErgmModel scalar __nwsaom_mn_M1, __nwsaom_mn_M2
	struct SaomMNFit scalar fit
	real scalar p, P
	real rowvector t1, t2
	t1 = (cols(theta01) == __nwsaom_mn_M1.nparam() & !any(theta01 :>= .) ? theta01 : J(1, __nwsaom_mn_M1.nparam(), 0))
	t2 = (cols(theta02) == __nwsaom_mn_M2.nparam() & !any(theta02 :>= .) ? theta02 : J(1, __nwsaom_mn_M2.nparam(), 0))
	if (findexternal("__nwsaom_mn_theta0") != NULL) {
		t1 = (*findexternal("__nwsaom_mn_theta0"))[1..__nwsaom_mn_M1.nparam()]
		t2 = (*findexternal("__nwsaom_mn_theta0"))[(__nwsaom_mn_M1.nparam()+1)..(__nwsaom_mn_M1.nparam()+__nwsaom_mn_M2.nparam())]
	}
	fit = SaomEstimateMN(__nwsaom_mn_Gs1, __nwsaom_mn_M1, __nwsaom_mn_Gs2, __nwsaom_mn_M2, t1, t2, K0, K3, firstg, sym1, sym2)
	p = fit.p1 + fit.p2
	P = fit.P
	st_matrix(bname, fit.par[1..p])
	st_matrix(Vname, fit.Vfull[1..p, 1..p])
	st_matrix(ratename, (fit.par[(p+1)..(p+P)] \ fit.par[(p+P+1)..(p+2*P)] \ sqrt(diagonal(fit.Vfull)[(p+1)..(p+P)])' \ sqrt(diagonal(fit.Vfull)[(p+P+1)..(p+2*P)])'))
	st_matrix(tcname, fit.tconv)
	st_matrix(targetname, fit.target)
	st_numscalar(tcname + "_max", fit.tconvMax)
	st_global(ncoefname, invtokens(("net1_" :+ __nwsaom_mn_M1.coefnames, "net2_" :+ __nwsaom_mn_M2.coefnames)))
}
/* nwsaom multinet with a behavior (protocol 64) */
void __nwsaom_mnb_post(real rowvector theta01, real rowvector theta02, real rowvector thetab0, real scalar K0, real scalar K3, real scalar firstg, real scalar sym1, real scalar sym2,
	string scalar bname, string scalar Vname, string scalar ratename, string scalar tcname, string scalar ncoefname, string scalar targetname) {
	external pointer(class ErgmGraph scalar) rowvector __nwsaom_mn_Gs1, __nwsaom_mn_Gs2
	external class ErgmModel scalar __nwsaom_mn_M1, __nwsaom_mn_M2
	external class SaomBehaviorModel scalar __nwsaom_mn_Mbeh
	external pointer(real colvector) rowvector __nwsaom_mn_Bw
	external real rowvector __nwsaom_mn_net2flag
	external real scalar __nwsaom_mn_behmin, __nwsaom_mn_behmax
	struct SaomMNBFit scalar fit
	real scalar p, P
	real rowvector t1, t2, tb
	t1 = (cols(theta01) == __nwsaom_mn_M1.nparam() & !any(theta01 :>= .) ? theta01 : J(1, __nwsaom_mn_M1.nparam(), 0))
	t2 = (cols(theta02) == __nwsaom_mn_M2.nparam() & !any(theta02 :>= .) ? theta02 : J(1, __nwsaom_mn_M2.nparam(), 0))
	tb = (cols(thetab0) == __nwsaom_mn_Mbeh.nparam() & !any(thetab0 :>= .) ? thetab0 : J(1, __nwsaom_mn_Mbeh.nparam(), 0))
	if (findexternal("__nwsaom_mn_theta0") != NULL) {
		t1 = (*findexternal("__nwsaom_mn_theta0"))[1..__nwsaom_mn_M1.nparam()]
		t2 = (*findexternal("__nwsaom_mn_theta0"))[(__nwsaom_mn_M1.nparam()+1)..(__nwsaom_mn_M1.nparam()+__nwsaom_mn_M2.nparam())]
		tb = (*findexternal("__nwsaom_mn_theta0"))[(__nwsaom_mn_M1.nparam()+__nwsaom_mn_M2.nparam()+1)..(__nwsaom_mn_M1.nparam()+__nwsaom_mn_M2.nparam()+__nwsaom_mn_Mbeh.nparam())]
	}
	fit = SaomEstimateMNB(__nwsaom_mn_Gs1, __nwsaom_mn_M1, __nwsaom_mn_Gs2, __nwsaom_mn_M2, __nwsaom_mn_Bw, __nwsaom_mn_behmin, __nwsaom_mn_behmax, __nwsaom_mn_Mbeh,
		__nwsaom_mn_net2flag, t1, t2, tb, K0, K3, firstg, sym1, sym2)
	p = fit.p1 + fit.p2 + fit.pb
	P = fit.P
	st_matrix(bname, fit.par[1..p])
	st_matrix(Vname, fit.Vfull[1..p, 1..p])
	st_matrix(ratename, (fit.par[(p+1)..(p+P)] \ fit.par[(p+P+1)..(p+2*P)] \ fit.par[(p+2*P+1)..(p+3*P)] \ sqrt(diagonal(fit.Vfull)[(p+1)..(p+P)])' \ sqrt(diagonal(fit.Vfull)[(p+P+1)..(p+2*P)])' \ sqrt(diagonal(fit.Vfull)[(p+2*P+1)..(p+3*P)])'))
	st_matrix(tcname, fit.tconv)
	st_matrix(targetname, fit.target)
	st_numscalar(tcname + "_max", fit.tconvMax)
	st_global(ncoefname, invtokens(("net1_" :+ __nwsaom_mn_M1.coefnames, "net2_" :+ __nwsaom_mn_M2.coefnames, __nwsaom_mn_Mbeh.coefnames)))
}
end

capture program drop nwsaom_multinet
program define nwsaom_multinet, eclass
	version 14
	syntax , NET1(string) NET2(string) [ EFF1(string) EFF2(string) CROSS1(string) CROSS2(string) SYM1 SYM2 BEHavior(string) BEHEFF1(string) BEHEFF2(string) THETA0(numlist) FIX(string) TVCOV(string) ///
		K0(integer 30) K3(integer 200) FIRSTG(real 0.2) seed(integer -1) ACTORmode(integer 2) ]

	if `seed' != -1 set seed `seed'
	capture mata: mata drop __nwsaom_fixmask
	capture mata: mata drop __nwsaom_score_D
	capture mata: mata drop __nwsaom_score_S
	capture mata: mata drop __nwsaom_score_m
	capture mata: mata drop __nwsaom_score_fix
	capture mata: mata drop __nwsaom_score_par
	capture mata: mata drop __nwsaom_score_Zp
	capture mata: mata drop __nwsaom_score_Sp
	capture mata: mata drop __nwsaom_score_qf
	capture mata: mata drop __nwsaom_mn_theta0
	local nw1 : word count `net1'
	local nw2 : word count `net2'
	if `nw1' != `nw2' | `nw1' < 2 {
		di "{err}net1() and net2() need the same number (at least two) of waves."
		error 198
	}
	mata: __nwsaom_engine = ""
	mata: __nwsaom_engine_why = ""
	capture mata: mata drop __nwsaom_mn_Gs1 __nwsaom_mn_Gs2 __nwsaom_mn_M1 __nwsaom_mn_M2
	mata: __nwsaom_mn_Gs1 = J(1, 0, NULL)
	mata: __nwsaom_mn_Gs2 = J(1, 0, NULL)
	// changing covariates: tvcov(a1 a2 a3 | s1 s2 s3), referred to by the stem of the first variable (the name without trailing digits)
	local __tvrest `"`tvcov'"'
	while `"`__tvrest'"' != "" {
		gettoken __g __tvrest : __tvrest, parse("|")
		if `"`__g'"' == "|" continue
		local __st : word 1 of `__g'
		local __st = regexr("`__st'", "[0-9]+$", "")
		local __tvl_`__st' `__g'
	}
	local nodes = .
	// a two-mode (bipartite) member: the actors (mode actormode(), default 2 = the rows of the affiliation matrix of nwset, bipartite) choose among the events;
	// every member is embedded in the graph on all nodes of the two-mode network (actors first), see SaomMNAddWave()
	local __tmany = 0
	forvalues __s = 1/2 {
		local __tm`__s' = 0
		forvalues __w = 1/`nw`__s'' {
			local __wname : word `__w' of `net`__s''
			_nwsyntax `__wname', max(1) other(mn`__s'_`__w')
			local __wtm = ("`mn`__s'_`__w'is2mode'" == "true")
			if `__w' == 1 local __tm`__s' = `__wtm'
			else if `__wtm' != `__tm`__s'' {
				di "{err}the waves of net`__s'() mix two-mode and one-mode networks."
				error 198
			}
			if !`__wtm' & "`mn`__s'_`__w'directed'" != "true" & "`sym`__s''" == "" {
				di "{err}nwsaom multinet needs directed one-mode networks (or undirected ones with sym1 / sym2)."
				error 198
			}
			if `__wtm' & "`sym`__s''" != "" {
				di "{err}sym`__s' does not apply to a two-mode network."
				error 198
			}
		}
		if `__tm`__s'' local __tmany = 1
	}
	if `__tmany' {
		if !inlist(`actormode', 1, 2) {
			di "{err}actormode() must be 1 or 2 (the mode whose nodes are the actors)."
			error 198
		}
		if "`behavior'" != "" {
			di "{err}a two-mode network is not available together with behavior() in nwsaom multinet."
			error 198
		}
		forvalues __s = 1/2 {
			forvalues __w = 1/`nw`__s'' {
				if `__tm`__s'' {
					mata: st_local("__na", strofreal(sum(`mn`__s'_`__w'netobj'->get_modes() :== "`actormode'")))
					mata: st_local("__sameact", strofreal(all((`mn`__s'_`__w'netobj'->get_modes() :== "`actormode'") :== (`mn`__s'_1netobj'->get_modes() :== "`actormode'"))))
					if !`__sameact' {
						di "{err}the waves of net`__s'() have different two-mode node sets (modes)."
						error 198
					}
					if `__w' == 1 local __nA`__s' = `__na'
				}
				else if `__w' == 1 local __nA`__s' = `mn`__s'_`__w'nodes'
				if `mn`__s'_`__w'nodes' != `mn`__s'_1nodes' {
					di "{err}every wave of net`__s'() must have the same number of nodes."
					error 198
				}
			}
		}
		if `__nA1' != `__nA2' {
			di "{err}the actors of the two networks differ in number (`__nA1' and `__nA2'); a two-mode network and a one-mode one need the same actors."
			error 198
		}
		if `__tm1' & `__tm2' {
			di "{err}only one of the two networks can be two-mode (the other one is a one-mode network on the actors)."
			error 198
		}
		local nodes = cond(`__tm1', `mn1_1nodes', `mn2_1nodes')
		if `nodes' < 12 {
			di "{err}a two-mode member needs at least 12 nodes (actors plus events)."
			error 198
		}
		mata: __nwsaom_mn_nA = `__nA1'
		mata: __nwsaom_mn_actmode = `actormode'
		mata: __nwsaom_mn_tm1 = `__tm1'
		mata: __nwsaom_mn_tm2 = `__tm2'
		mata: SaomMNSetNSR(`nodes', `__nA1', `__tm1', `__tm2')
	}
	else {
		capture mata: mata drop __nwsaom_mn_nA __nwsaom_mn_tm1 __nwsaom_mn_tm2
		capture mata: mata drop __nwsaom_mn_nsr
		mata: __nwsaom_mn_nsr = J(1, 0, 0)
	}
	forvalues __s = 1/2 {
		forvalues __w = 1/`nw`__s'' {
			if `nodes' == . local nodes = `mn`__s'_`__w'nodes'
			if `mn`__s'_`__w'nodes' != `nodes' & !`__tmany' {
				di "{err}every network/wave passed to nwsaom multinet must share the same number of nodes."
				error 198
			}
			if !`__tmany' local __nA`__s' = `mn`__s'_`__w'nodes'
			mata: SaomMNAddWave(`mn`__s'_`__w'netobj', `nodes', `__s', `__tm`__s'', `actormode', `__nA`__s'')
		}
	}
	if "`behavior'" != "" {
		local nb : word count `behavior'
		if `nb' != `nw1' {
			di "{err}behavior() needs one variable per wave (`nw1')."
			error 198
		}
		mata: __nwsaom_mn_Bw = J(1, 0, NULL)
		foreach __v of local behavior {
			mata: SaomMNAddBeh("`__v'", `nodes')
		}
		mata: __nwsaom_mn_behmin = SaomMNBehMin(__nwsaom_mn_Bw)
		mata: __nwsaom_mn_behmax = SaomMNBehMax(__nwsaom_mn_Bw)
	}
	else capture mata: mata drop __nwsaom_mn_Bw
	if "`eff1'" == "" local eff1 = cond("`sym1'" != "" | `__tm1', "outdegree", "outdegree reciprocity")
	if "`eff2'" == "" local eff2 = cond("`sym2'" != "" | `__tm2', "outdegree", "outdegree reciprocity")
	// the models: within-network effects, then the cross-network effects of the other network (effect[:#])
	forvalues __s = 1/2 {
		mata: __nwsaom_mn_M`__s' = ErgmModel()
		mata: __nwsaom_mn_M`__s'.init()
		foreach __t of local eff`__s' {
			gettoken __e __v : __t, parse(":")
			if `__tm`__s'' & !inlist("`__e'", "outdegree", "indegpop", "outact", "cycle4") {
				di "{err}`__e' is not available for a two-mode network in nwsaom multinet (available: outdegree indegpop outact cycle4)."
				error 198
			}
			local __v = subinstr("`__v'", ":", "", 1)
			mata: SaomMNAddEff(__nwsaom_mn_M`__s', "`__e'", "`__v'", `nodes', 0)
		}
		foreach __t of local cross`__s' {
			gettoken __e __pp : __t, parse(":")
			local __pp = subinstr("`__pp'", ":", "", 1)
			mata: st_local("__isdy", strofreal(anyof(SaomMNDyNames(), "`__e'")))
			if `__isdy' {
				// a dyadic covariate (Stata matrix): effect:matrix[:#]
				gettoken __cv __pp : __pp, parse(":")
				local __pp = subinstr("`__pp'", ":", "", 1)
				if "`__pp'" == "" mata: st_local("__pp", strofreal(SaomMNDyDefaultParam("`__e'")))
				mata: __nwsaom_dgo = SaomMNDeg(3 - `__s')
				local __co = 0
				local __os = 3 - `__s'
				if `__tmany' {
					if `__tm`__os'' local __co = `__nA1'
				}
				mata: SaomMNAddCrossDy(__nwsaom_mn_M`__s', "`__e'", "`__cv'", `nodes', `__pp', `__co')
				continue
			}
			mata: st_local("__iscov", strofreal(anyof(SaomMNCovNames(), "`__e'")))
			if `__iscov' {
				gettoken __cv __pp : __pp, parse(":")
				local __pp = subinstr("`__pp'", ":", "", 1)
				if "`__pp'" == "" local __pp 1
				if "`__tvl_`__cv''" != "" {
					mata: SaomMNAddCrossCovTV(__nwsaom_mn_M`__s', "`__e'", "`__tvl_`__cv''", `nodes', `__pp', `=`nw1'-1')
					continue
				}
				mata: SaomMNAddCrossCov(__nwsaom_mn_M`__s', "`__e'", "`__cv'", `nodes', `__pp')
				continue
			}
			if "`__pp'" == "" mata: st_local("__pp", strofreal(SaomMNDefaultParam("`__e'")))
			local __os = 3 - `__s'
			if `__tmany' {
				local __nE = `nodes' - `__nA1'
				// RSiena reads the other network's (or the own network's) node with the index of an event for these effects: defined only when the events are not more than the actors
				if (`__tm`__s'' & inlist("`__e'", "divinaltintn", "joutmix", "gwespfbmix") & `__nE' > `__nA1') | (`__tm`__os'' & inlist("`__e'", "outoutactintn", "outoutavintn") & `__nE' > `__nA1') {
					di "{err}`__e' needs at most as many events as actors when a two-mode network is combined with a one-mode one (the effect indexes both networks by the same node number)."
					error 198
				}
				if `__tm`__os'' & "`__e'" == "toany" {
					di "{err}toany needs a one-mode other network."
					error 198
				}
			}
			mata: __nwsaom_dgo = SaomMNDeg(`__os'); __nwsaom_dgs = SaomMNDeg(`__s')
			mata: SaomMNAddCross(__nwsaom_mn_M`__s', "`__e'", `nodes', `__pp', __nwsaom_dgo[1], __nwsaom_dgs[2], __nwsaom_dgo[3], __nwsaom_dgo[2], __nwsaom_dgo[5])
		}
	}
	local hasbeh = ("`behavior'" != "")
	if `hasbeh' {
		if "`beheff1'`beheff2'" == "" local beheff1 "linear quadratic avalt"
		mata: __nwsaom_mn_Mbeh = SaomBehaviorModel()
		mata: __nwsaom_mn_Mbeh.init()
		mata: st_local("__b1", SaomMBAddTerms(__nwsaom_mn_Mbeh, "`beheff1'", "beh_"))
		mata: st_local("__b2", SaomMBAddTerms(__nwsaom_mn_Mbeh, "`beheff2'", "beh2_"))
		local __n1 : word count `beheff1'
		local __n2 : word count `beheff2'
		mata: __nwsaom_mn_net2flag = (J(1, `__n1', 0), J(1, `__n2', 1))
		mata: __nwsaom_mn_Mbeh.setsimmean(saom_similarity_mean(__nwsaom_mn_Bw, __nwsaom_mn_behmax - __nwsaom_mn_behmin))
	}
	// theta0() / fix(): starting values and fixed effects, in the order of the coefficients (net1_*, net2_*, beh_*)
	if "`theta0'`fix'" != "" {
		mata: st_local("__cnall", invtokens(("net1_" :+ __nwsaom_mn_M1.coefnames, "net2_" :+ __nwsaom_mn_M2.coefnames)))
		if `hasbeh' {
			mata: st_local("__cnb", invtokens(__nwsaom_mn_Mbeh.coefnames))
			local __cnall `__cnall' `__cnb'
		}
		local __pall : word count `__cnall'
		if "`theta0'" != "" {
			local __nt : word count `theta0'
			if `__nt' != `__pall' {
				di "{err}theta0() must supply exactly `__pall' starting value(s), in the order: `__cnall'."
				error 198
			}
			mata: __nwsaom_mn_theta0 = strtoreal(tokens("`theta0'"))
		}
		if "`fix'" != "" {
			if "`fix'" == "_all" local fix "`__cnall'"
			foreach __w of local fix {
				if !`: list __w in __cnall' {
					di "{err}fix(): `__w' is not one of the effects: `__cnall'."
					error 198
				}
			}
			local __fm ""
			foreach __w of local __cnall {
				local __fm `__fm' `: list __w in fix'
			}
			mata: __nwsaom_fixmask = strtoreal(tokens("`__fm'"))
		}
	}
	tempname b V R tc tg
	if `hasbeh' {
		mata: __nwsaom_mnb_post((.), (.), (.), `k0', `k3', `firstg', ("`sym1'" != ""), ("`sym2'" != ""), "`b'", "`V'", "`R'", "`tc'", "__NWSAOM_MN_COEFNAMES__", "`tg'")
	}
	else mata: __nwsaom_mn_post((.), (.), `k0', `k3', `firstg', ("`sym1'" != ""), ("`sym2'" != ""), "`b'", "`V'", "`R'", "`tc'", "__NWSAOM_MN_COEFNAMES__", "`tg'")
	local __cn "$__NWSAOM_MN_COEFNAMES__"
	macro drop __NWSAOM_MN_COEFNAMES__
	matrix colnames `b' = `__cn'
	matrix colnames `V' = `__cn'
	matrix rownames `V' = `__cn'
	matrix colnames `tg' = `__cn'
	ereturn post `b' `V', obs(`nodes')
	ereturn matrix target = `tg'
	ereturn scalar nwaves = `nw1'
	ereturn scalar twomode1 = `__tm1'
	ereturn scalar twomode2 = `__tm2'
	if `__tmany' {
		ereturn scalar n_actors = `__nA1'
		ereturn scalar n_events = `nodes' - `__nA1'
	}
	ereturn local estat_cmd "nwsaom_estat"
	capture mata: mata drop __nwsaom_mn_theta0
	local P = `nw1' - 1
	forvalues __k = 1/`P' {
		local __rn "`__rn' period`__k'"
	}
	matrix colnames `R' = `__rn'
	if `hasbeh' matrix rownames `R' = rate_net1 rate_net2 rate_beh se_net1 se_net2 se_beh
	else matrix rownames `R' = rate_net1 rate_net2 se_net1 se_net2
	ereturn matrix rates = `R'
	matrix `tc' = `tc'
	ereturn matrix tconv = `tc'
	ereturn scalar tconv_max = scalar(`tc'_max)
	ereturn local cmd "nwsaom_multinet"
	_nwsaom_postengine
	di as text "{hline}"
	if `__tmany' di as text "Several co-evolving networks (Method of Moments), `nw1' waves, `__nA1' actors and `=`nodes'-`__nA1'' events (network " cond(`__tm1', "1", "2") " is two-mode)"
	else di as text "Several co-evolving networks (Method of Moments), `nw1' waves, `nodes' actors"
	di as text "{hline}"
	ereturn display
	di as text "Rates (estimated):"
	matrix list e(rates), noheader format(%8.3f)
	di as text "Overall maximum convergence ratio: " as result %5.3f e(tconv_max)
end
