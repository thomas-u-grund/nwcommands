capture program drop _nwergm_bip
program _nwergm_bip
	// Registers the bipartite terms that need sub-arguments (the b1*/b2* family of R's ergm and
	// coincidence). Called by nwergm and nwergm simulate right after the model object exists.
	// Options consumed here are cleared in the caller (c_local); plain forms of the older
	// bipartite options (bdegree1(0 1 2), bnodematch1(var), ...) are handed back untouched.
	version 14
	syntax , NODES(integer) [ ///
		BCONCURRENT1(string) BCONCURRENT2(string) BMINDEGREE1(string) BMINDEGREE2(string) ///
		BDEGRANGE1(string) BDEGRANGE2(string) BDEGREE1(string) BDEGREE2(string) ///
		BSTAR1(string) BSTAR2(string) BCOVRANGE1(string) BCOVRANGE2(string) ///
		BFACTORDISTINCT1(string) BFACTORDISTINCT2(string) BSOCIALITY1(string) BSOCIALITY2(string) ///
		BSTARMIX1(string) BSTARMIX2(string) BTWOSTAR1(string) BTWOSTAR2(string) COINCIDENCE(string) ///
		BDSP1(string) BDSP2(string) BGWDSP1(string) BGWDSP2(string) ///
		BNODEMATCH1(string) BNODEMATCH2(string) BGWDEGREE1(string) BGWDEGREE2(string) ]
	local temps ""
	foreach o in bconcurrent bmindegree bdegrange bdegree bstar bcovrange bfactordistinct bsociality bstarmix btwostar bdsp bgwdsp bnodematch bgwdegree {
		forvalues m = 1/2 {
			local spec `"``o'`m''"'
			if `"`spec'"' == "" continue
			// plain legacy forms stay with the original registration code
			if inlist("`o'", "bdegree", "bstar", "bnodematch", "bgwdegree") {
				if strpos(`"`spec'"', ",") == 0 continue
			}
			_nwergm_bip_one `o' `m' `nodes' `"`spec'"'
			local temps "`temps' `r(temps)'"
			c_local `o'`m' ""
		}
	}
	if `"`coincidence'"' != "" {
		_nwergm_bip_one coincidence 2 `nodes' `"`coincidence'"'
		local temps "`temps' `r(temps)'"
		c_local coincidence ""
	}
	c_local __ergm_bipnewtemps "`temps'"
end

capture program drop _nwergm_bip_nl
program _nwergm_bip_nl, rclass
	// numlist-or-dot -> comma list for Mata ("." = open end)
	args s
	local out ""
	if `"`s'"' != "" {
		local s2 : subinstr local s "." "9999999" , all
		capture numlist "`s2'"
		if _rc {
			di "{err}invalid numlist {bf:`s'}"
			exit 121
		}
		local s2 `r(numlist)'
		foreach t of local s2 {
			if `t' == 9999999 local t 131071
			local out "`out',`t'"
		}
	}
	return local list `"`=substr("`out'", 2, .)'"'
end

capture program drop _nwergm_bip_one
program _nwergm_bip_one, rclass
	args term m nodes spec
	local spec = trim(`"`spec'"')
	local pos = strpos(`"`spec'"', ",")
	if `pos' > 0 {
		local main = trim(substr(`"`spec'"', 1, `pos' - 1))
		local 0 `"`=substr(`"`spec'"', `pos', .)'"'
	}
	else if regexm(`"`spec'"', "^[a-z0-9_]+\(") {
		local main ""
		local 0 `", `spec'"'
	}
	else {
		local main `"`spec'"'
		local 0 ""
	}
	syntax [, BY(string) ATTR(string) LEVELS(string) HOMOPHILY TO(string) NODIFF DIFF ATTR2(string) LEVELS1(string) LEVELS2(string) ///
		BYATTR(string) KEEP(string) ALPHA(real 1) BETA(real 1) BASE(string) ACTIVE(real 0) LEVELS3(string) ]
	local main = trim(`"`main'"')
	if `"`main'"' == "all" local main ""
	// attributes
	local a1 ""
	local an ""
	local a2 ""
	local an2 ""
	local bname ""
	local P "0"
	local F "0"
	local nm ""
	local X ""
	local TO ""
	local L1 ""
	local L2 ""
	local pre = cond(`m'==1, "b1", "b2")
	if "`term'" == "bconcurrent" {
		local nm conc
		local a1 "`by'"
		local L1 "`levels'"
		if `"`main'"' != "" & `"`main'"' != "all" {
			di "{err}{bf:bconcurrent`m'()}: unexpected argument {bf:`main'}; use {bf:bconcurrent`m'(all)} or {bf:bconcurrent`m'(by(var) levels(numlist))}"
			error 198
		}
	}
	else if "`term'" == "bmindegree" {
		local nm mindeg
		local X "`main'"
	}
	else if "`term'" == "bdegree" {
		local nm deg
		local X "`main'"
		local a1 "`by'"
		local L1 "`levels'"
		if "`homophily'" != "" local F 1
	}
	else if "`term'" == "bdegrange" {
		local nm degrange
		local X "`main'"
		local TO "`to'"
		local a1 "`by'"
		local L1 "`levels'"
		if "`homophily'" != "" local F 1
	}
	else if "`term'" == "bstar" {
		local nm star
		local X "`main'"
		local a1 "`attr'"
		local L1 "`levels'"
	}
	else if "`term'" == "bcovrange" {
		local nm covrange
		local a1 "`main'"
	}
	else if "`term'" == "bfactordistinct" {
		local nm factdist
		local a1 "`main'"
		local L1 "`levels'"
	}
	else if "`term'" == "bsociality" {
		local nm soc
		local X "`main'"
		if "`X'" == "" local X "-1"
	}
	else if "`term'" == "bstarmix" {
		local nm starmix
		local X "`main'"
		local a1 "`attr'"
		if "`nodiff'" != "" local F 0
		else local F 1
		if "`base'" != "" local TO : subinstr local base " " ",", all
		if "`base'" != "" {
			// base() drops statistics by position
			local TO ""
			foreach b of numlist `base' {
				local TO "`TO',-`b'"
			}
			local TO = substr("`TO'",2,.)
			local base ""
		}
	}
	else if "`term'" == "btwostar" {
		local nm twostar
		local a1 "`main'"
		local a2 "`attr2'"
		if "`a2'" == "" local a2 "`a1'"
		local L1 "`levels1'"
		local L2 "`levels2'"
		local TO "`levels3'"
		if "`base'" != "" {
			local TO ""
			foreach b of numlist `base' {
				local TO "`TO',-`b'"
			}
			local TO = substr("`TO'",2,.)
		}
	}
	else if "`term'" == "coincidence" {
		local nm coinc
		local F "`active'"
	}
	else if "`term'" == "bdsp" {
		local nm dsp
		local X "`main'"
	}
	else if "`term'" == "bgwdsp" {
		local nm gwdsp
		local P "`main'"
		confirm number `P'
	}
	else if "`term'" == "bnodematch" {
		local nm bnm
		local a1 "`main'"
		local a2 "`byattr'"
		local L1 "`levels'"
		if "`diff'" != "" local F 1
		else local F 0
		if "`keep'" != "" local TO "`keep'"
		if `alpha' < 0 | `alpha' > 1 {
			di "{err}alpha argument to b`m'nodematch must be between 0 and 1 inclusive."
			error 198
		}
		if `beta' < 0 | `beta' > 1 {
			di "{err}beta argument to b`m'nodematch must be between 0 and 1 inclusive."
			error 198
		}
		local P "`alpha',`beta'"
	}
	else if "`term'" == "bgwdegree" {
		local nm gwdega
		local P "`main'"
		confirm number `P'
		local a1 "`attr'"
		local L1 "`levels'"
		if "`a1'" == "" {
			// no attribute: the original fixed-decay term
			di "{err}{bf:bgwdegree`m'(`spec')}: give {bf:attr(var)} or use the plain form {bf:bgwdegree`m'(decay)}."
			error 198
		}
	}
	if `"`nm'"' == "star" & "`a1'" == "" {
		// b1star(k) without attr is the plain form
		di "{err}{bf:bstar`m'(`spec')}: expected {bf:attr(var)}."
		error 198
	}
	// numeric lists
	foreach v in X TO L1 L2 {
		_nwergm_bip_nl "``v''"
		local `v'l `"`r(list)'"'
	}
	// attribute variables -> Mata column vectors
	local A1m "J(0,1,.)"
	local A2m "J(0,1,.)"
	if "`a1'" != "" {
		_nwergm_bip_numvar `a1' `term'`m'
		local A1m `"st_data(1::`nodes', "`a1'")"'
		local an "`a1'"
	}
	if "`a2'" != "" {
		_nwergm_bip_numvar `a2' `term'`m'
		local A2m `"st_data(1::`nodes', "`a2'")"'
		local an2 "`a2'"
	}
	if "`nm'" == "twostar" & "`a2'" == "" {
		local A2m `"`A1m'"'
		local an2 "`an'"
	}
	local Xm = cond("`Xl'"=="", "J(1,0,.)", "(`Xl')")
	local Tm = cond("`TOl'"=="", "J(1,0,.)", "(`TOl')")
	local L1m = cond("`L1l'"=="", "J(1,0,.)", "(`L1l')")
	local L2m = cond("`L2l'"=="", "J(1,0,.)", "(`L2l')")
	local Fm = cond("`F'"=="", "0", "(`F')")
	local Pm = cond("`P'"=="", "0", "(`P')")
	if "`nm'" == "bnm" {
		local Fm "(`F')"
	}
	// not a tempname: the Mata object must outlive this program and a recycled tempname would be overwritten by the caller
	capture mata: __nwbx_cnt = __nwbx_cnt + 1
	if _rc mata: __nwbx_cnt = 1
	mata: st_local("td", "__nwbx" + strofreal(__nwbx_cnt))
	mata: `td' = ErgmTermData()
	mata: __bxn = _bx_build(`td', __nwergm_last_G, "`nm'", `m', `Xm', `Tm', `A1m', `A2m', `L1m', `L2m', `Fm', `Pm', "`an'", "`an2'")
	mata: st_local("__bxk", strofreal(cols(__bxn)))
	if `__bxk' > 0 {
		mata: __nwergm_last_M.addterm("bipx", `__bxk', &stat_bipx(), &change_bipx(), `td', __bxn)
	}
	capture mata: mata drop __bxn
	return local temps "`td'"
end

capture program drop _nwergm_bip_numvar
program _nwergm_bip_numvar
	args v term
	confirm variable `v'
	capture confirm numeric variable `v'
	if _rc {
		di "{err}{bf:`term'(`v')}: {bf:`v'} is a string variable; nwergm needs a numeric attribute."
		di "{err}Encode it first, e.g. {bf:encode `v', generate(`v'_n)}, and specify {bf:`term'(`v'_n)}."
		error 109
	}
end
