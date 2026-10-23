*! _nwsaom_nx - the native-only network options of nwsaom (netx ownx dyadx tvdyadcov tvdyadcovrecip tvdyadx), split out of nwsaom.ado because Stata caps one ado program at about 141 KB of code
capture program drop _nwsaom_nx
program define _nwsaom_nx, rclass
	version 14
	syntax , NODES(integer) NWAVES(integer) CENTER(integer) XPARAM(real) TM(integer) [ TMNA(integer 0) TMNE(integer 0) NETX(string) OWNX(string) DYADX(string) TVDYADCOV(string) TVDYADCOVRECIP(string) TVDYADX(string) TVNAMES(string) ]
	local __nwsaom_nwaves = `nwaves'
	local __nwsaom_center = `center'
	local __nwsaom_tm = `tm'
	local __nwsaom_tm_na = `tmna'
	local __nwsaom_tm_ne = `tmne'
	local __nwsaom_tvnames "`tvnames'"
	local __nwsaom_efflist ""
	// protocol 46: netx(effect:var ...) - further covariate network effects, native only (the observed statistic comes from the plugin's NETSTAT):
	// crossxoutact homxoutact2 outxmore indties transtripx jumpxtranstrip altdist2 totdist2 simdist2 simegodist2 sameegodist2 altindist2 totindist2
	// simegoindist2 sameegoindist2; var is a numeric variable or a tvcov stem. xparam(#) is outxmore's c.
	local __nx_names "crossxoutact homxoutact2 outxmore indties transtripx jumpxtranstrip altdist2 totdist2 simdist2 simegodist2 sameegodist2 altindist2 totindist2 simegoindist2 sameegoindist2 homxtransrectrip samextransrectrip diffxtransrectrip egoxaltxrecip samexcycle4 sameinxcycle4 avgroupegox totgroupegox"
	local __nx_codes "220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242"
	foreach __t of local netx {
		// protocol 59: sameXV / sameXVInPop / sameXVInPop2 take two category covariates, netx(samexv:var1:var2[:#]); registered in Mata (SaomRegDcAll)
		mata: st_local("__vl", SaomRegDcAll(__nwsaom_last_M, `"`__t'"', `nodes'))
		local __nwsaom_efflist "`__nwsaom_efflist' `__vl'"
		if "`__vl'" != "" continue
		gettoken __f __vv : __t, parse(":")
		local __vv = subinstr("`__vv'", ":", "", 1)
		local __fi : list posof "`__f'" in __nx_names
		if `__fi' == 0 | "`__vv'" == "" {
			di "{err}netx(): `__t' is not effect:variable; effects: `__nx_names'."
			error 198
		}
		local __code : word `__fi' of `__nx_codes'
		local __kind "c"
		if "`__f'" == "homxoutact2" local __kind "r"
		if inlist("`__f'", "simdist2", "simegodist2", "simegoindist2") local __kind "s"
		local __vl "`__vv'"
		if inlist("`__f'", "avgroupegox", "totgroupegox") & !`: list __vv in __nwsaom_tvnames' {
			di "{err}netx(`__f'): RSiena defines it for a changing covariate (tvcov()) or the dependent behavior only."
			error 198
		}
		if `: list __vv in __nwsaom_tvnames' local __vl "${NWSAOM_TVV_`__vv'}"
		else {
			capture confirm numeric variable `__vv'
			if _rc {
				di "{err}netx(): `__vv' is not a numeric variable or a tvcov() covariate."
				error 198
			}
		}
		if `__nwsaom_tm' {
			local __tmnx "altindist2 totindist2 simegoindist2 sameegoindist2 crossxoutact samexcycle4 homxoutact2 sameinxcycle4 avgroupegox totgroupegox"
			if !`: list __f in __tmnx' {
				di "{err}netx(`__f') is not available for a two-mode network."
				error 198
			}
			local __tmidx = cond(inlist("`__f'", "sameinxcycle4", "homxoutact2"), "__nwsaom_tm_evidx", "__nwsaom_tm_actidx")
			if inlist("`__f'", "crossxoutact", "avgroupegox", "totgroupegox") {
				// RSiena reads the actor covariate at the EVENT's index within its mode for the alter (copied): needs at least as many actors as events
				if `__nwsaom_tm_ne' > `__nwsaom_tm_na' {
					di "{err}netx(`__f') in a two-mode network needs at least as many actors as events (RSiena reads the actor covariate at the event's index)."
					error 198
				}
				mata: SaomRegNat(__nwsaom_last_M, "`__f'", `__code', "`__kind'", "`__vv'", "`__vl'", `nodes', `=`__nwsaom_nwaves'-1', `__nwsaom_center', `xparam', `__tmidx', __nwsaom_tm_evidx)
			}
			else mata: SaomRegNat(__nwsaom_last_M, "`__f'", `__code', "`__kind'", "`__vv'", "`__vl'", `nodes', `=`__nwsaom_nwaves'-1', `__nwsaom_center', `xparam', `__tmidx')
		}
		else mata: SaomRegNat(__nwsaom_last_M, "`__f'", `__code', "`__kind'", "`__vv'", "`__vl'", `nodes', `=`__nwsaom_nwaves'-1', `__nwsaom_center', `xparam')
		local __nwsaom_efflist "`__nwsaom_efflist' `__f'(`__vv')"
	}
	// protocol 54: ownx(effect[:#] ...) - own-network effects without a covariate, native only: jin jout transtrip1 transtrip2 transrectrip2 (= transtripfr) transtripfe transtripee
	// outpopmore:# outpopsqrtmore:# outpopthreshold:# and the ego degree effects outactego[:2] outactmoreego:# outactsqrtmoreego:# outmoreego:# divoutego[:2] inactego[:2] divinego[:2] reciactego[:2]
	local __n0_names "jin jout transtrip1 transtrip2 transrectrip2 transtripfe transtripee outpopmore outpopsqrtmore outpopthreshold outactego outactmoreego outactsqrtmoreego outmoreego divoutego inactego divinego reciactego outinass inpopdya inisdegree instructeq densetriads outoutass ininass inoutass primary primcompress nonpcompress primdegact primdegactlog primdegactsqrt primdegactinv primdegactdiff primdegactdiffsqrt"
	local __n0_codes "0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 36 37 38 39 40 41 42 43 44"
	if "`ownx'" != "" {
		// the primary-setting effects read the start network of each period: the wave graphs travel in __saom_sg
		local __sgl "&__nwsaom_last_G1"
		forvalues __w = 2/`__nwsaom_nwaves' {
			local __sgl "`__sgl', &__nwsaom_last_G`__w'"
		}
		capture mata: mata drop __saom_sg
		mata: __saom_sg = (`__sgl')
		mata: __nwsaom_dg_ties = 0
		mata: __nwsaom_dg_rec = 0
		forvalues __w = 1/`__nwsaom_nwaves' {
			mata: __nwsaom_dg_acc(__nwsaom_last_G`__w')
		}
		mata: __nwsaom_dg_sma = 0
		mata: __nwsaom_dg_smb = 0
		forvalues __w = 1/`=`__nwsaom_nwaves'-1' {
			mata: __nwsaom_sm_acc(__nwsaom_last_G`__w')
		}
	}
	foreach __t of local ownx {
		gettoken __f __pp : __t, parse(":")
		local __pp = subinstr("`__pp'", ":", "", 1)
		if "`__f'" == "transtripfr" local __f "transrectrip2"
		local __fi : list posof "`__f'" in __n0_names
		if `__fi' == 0 {
			di "{err}ownx(): `__t' is not an effect; effects: `__n0_names' (transtripfr = transrectrip2)."
			error 198
		}
		local __code : word `__fi' of `__n0_codes'
		if "`__pp'" == "" {
			if inlist("`__f'", "outpopmore", "outpopsqrtmore", "outpopthreshold", "outmoreego") local __pp 1
			else if inlist("`__f'", "outactmoreego", "outactsqrtmoreego") local __pp 1
			else if inlist("`__f'", "outinass", "outoutass", "ininass", "inoutass") local __pp 2
			else if "`__f'" == "densetriads" local __pp 5
			else if inlist("`__f'", "primary", "primcompress") local __pp 10
			else if "`__f'" == "nonpcompress" local __pp 1
			else local __pp 0
		}
		local __dgn `nodes'
		if `__nwsaom_tm' local __dgn `__nwsaom_tm_na'
		mata: SaomRegDg(__nwsaom_last_M, "`__f'", `__code', `__pp', `nodes', __nwsaom_dg_ties / (`__dgn' * `__nwsaom_nwaves'), __nwsaom_dg_rec / (`__dgn' * `__nwsaom_nwaves'), __nwsaom_dg_sma / __nwsaom_dg_smb)
		local __nwsaom_efflist "`__nwsaom_efflist' `__f'"
	}
	// protocol 49: dyadx(effect:matrix ...) - network effects of a constant dyadic covariate W (RSiena WWX cyWWX InWWX OutWWX WXX XWX XWX1 XWX2 XXW),
	// native only; the matrix is used raw (never centred), as RSiena does for these effects
	local __dx_names "wwx cywwx inwwx outwwx wxx xwx xwx1 xwx2 xxw"
	foreach __t of local dyadx {
		gettoken __f __vv : __t, parse(":")
		local __vv = subinstr("`__vv'", ":", "", 1)
		local __fi : list posof "`__f'" in __dx_names
		if `__fi' == 0 | "`__vv'" == "" {
			di "{err}dyadx(): `__t' is not effect:matrix; effects: `__dx_names'."
			error 198
		}
		capture confirm matrix `__vv'
		if _rc {
			di "{err}dyadx(): matrix {bf:`__vv'} not found."
			error 111
		}
		if rowsof(`__vv') != `nodes' | colsof(`__vv') != `nodes' {
			di "{err}dyadx(): matrix {bf:`__vv'} must be `nodes' x `nodes'."
			error 198
		}
		mata: SaomRegNatDy(__nwsaom_last_M, "`__f'", `=249+`__fi'', "`__vv'", `nodes')
		local __nwsaom_efflist "`__nwsaom_efflist' `__f'(`__vv')"
	}
	// tvdyadcov(stem ...) / tvdyadcovrecip(stem ...): the matrices stem1 .. stem`P' (P = waves - 1, the period's START wave), centred by their overall
	// mean; tvdyadx(effect:stem ...): RSiena's WWX ... XXW with changing W, raw. Native plugin only (the matrices travel as time-varying attribute columns).
	foreach __dk in tvdyadcov tvdyadcovrecip {
		foreach __st of local `__dk' {
			forvalues __p = 1/`=`__nwsaom_nwaves'-1' {
				capture confirm matrix `__st'`__p'
				if _rc {
					di "{err}{bf:`__dk'()}: matrix {bf:`__st'`__p'} not found (a matrix for each of the `=`__nwsaom_nwaves'-1' periods: `__st'1 ...)."
					error 111
				}
			}
			mata: SaomRegDycTV(__nwsaom_last_M, "`=cond("`__dk'" == "tvdyadcov", "dyadcov", "dyadcovrecip")'", 0, "`__st'", `nodes', `=`__nwsaom_nwaves'-1', `__nwsaom_center')
			local __nwsaom_efflist "`__nwsaom_efflist' `__dk'(`__st')"
		}
	}
	local __dx_names "wwx cywwx inwwx outwwx wxx xwx xwx1 xwx2 xxw"
	foreach __t of local tvdyadx {
		gettoken __f __vv : __t, parse(":")
		local __vv = subinstr("`__vv'", ":", "", 1)
		local __fi : list posof "`__f'" in __dx_names
		if `__fi' == 0 | "`__vv'" == "" {
			di "{err}tvdyadx(): `__t' is not effect:stem; effects: `__dx_names'."
			error 198
		}
		forvalues __p = 1/`=`__nwsaom_nwaves'-1' {
			capture confirm matrix `__vv'`__p'
			if _rc {
				di "{err}tvdyadx(): matrix {bf:`__vv'`__p'} not found."
				error 111
			}
		}
		mata: SaomRegDycTV(__nwsaom_last_M, "`__f'", `=249+`__fi'', "`__vv'", `nodes', `=`__nwsaom_nwaves'-1', 0)
		local __nwsaom_efflist "`__nwsaom_efflist' `__f'(`__vv')"
	}

	return local efflist "`__nwsaom_efflist'"
end
