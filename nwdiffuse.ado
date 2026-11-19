*! nwdiffuse: diffusion and contagion on a network: exposure, thresholds, adoption curve, hazard data, simulation (3.28.0)
capture program drop nwdiffuse
program nwdiffuse, rclass
	version 15
	gettoken sub 0 : 0, parse(" ,")
	if !inlist("`sub'", "exposure", "threshold", "curve", "long", "simulate") {
		di "{err}Subcommand {bf:`sub'} not allowed; use {bf:exposure}, {bf:threshold}, {bf:curve}, {bf:long} or {bf:simulate}."
		exit 198
	}
	capture noisily nwdiffuse_`sub' `0'
	local rc = _rc
	return add
	foreach m in __nwdif_toa __nwdif_G __nwdif_C __nwdif_share __nwdif_count __nwdif_x {
		capture mata: mata drop `m'
	}
	if `rc' exit `rc'
end

// ---------------------------------------------------------------------------------------------
// shared set-up: reads the networks (one, or one per period) into __nwdif_G and the adoption
// times into __nwdif_toa; returns n, t0, t1, T in r()
// ---------------------------------------------------------------------------------------------
capture program drop _nwdiffuse_setup
program _nwdiffuse_setup, rclass
	syntax [anything(name=netlist)] , [TOA(varname numeric) ADOPT(varlist numeric) T0(string) T1(string) ///
		valued incoming self nonet]
	if "`toa'" == "" & "`adopt'" == "" {
		di "{err}Specify {bf:toa()} (time of adoption) or {bf:adopt()} (one 0/1 variable per period)."
		exit 198
	}
	if "`toa'" != "" & "`adopt'" != "" {
		di "{err}Specify {bf:toa()} or {bf:adopt()}, not both."
		exit 198
	}
	local vflag = ("`valued'" != "")
	local oflag = ("`incoming'" == "")
	local sflag = ("`self'" != "")
	local n = _N
	local k = 0
	if "`nonet'" == "" {
		if "`netlist'" == "" {
			_nwsyntax, max(100)
		}
		else _nwsyntax `netlist', max(100)
		local names "`netname'"
		local k : word count `names'
		local first : word 1 of `names'
		_nwsyntax `first', max(1)
		local n = `nodes'
		if _N < `n' {
			di "{err}The data set has `=_N' observations, the network has `n' nodes: observation {it:i} must hold node {it:i}."
			exit 198
		}
	}
	// adoption times
	local T0 = .
	if "`t0'" != "" {
		capture confirm integer number `t0'
		if _rc {
			di "{err}t0() must be an integer."
			exit 198
		}
		local T0 = `t0'
	}
	if "`toa'" != "" {
		tempname v
		mata: __nwdif_toa = st_data((1::`n'), "`toa'")
		mata: st_local("bad", strofreal(any(__nwdif_toa :< . :& __nwdif_toa :!= floor(__nwdif_toa))))
		if `bad' {
			di "{err}{bf:`toa'} must hold whole numbers (periods) or missing (never adopts)."
			exit 198
		}
		mata: st_local("tmin", strofreal(min(__nwdif_toa)))
		mata: st_local("tmax", strofreal(max(__nwdif_toa)))
		mata: st_local("nobs", strofreal(sum(__nwdif_toa :< .)))
		if `nobs' == 0 {
			di "{err}Nobody adopts: {bf:`toa'} is missing for all nodes."
			exit 198
		}
		if `T0' >= . local T0 = `tmin'
		local T1 = `tmax'
		if "`t1'" != "" {
			capture confirm integer number `t1'
			if _rc {
				di "{err}t1() must be an integer."
				exit 198
			}
			local T1 = `t1'
		}
		if `tmin' < `T0' | `tmax' > `T1' {
			di "{err}{bf:`toa'} runs from `tmin' to `tmax', outside t0()=`T0' to t1()=`T1'."
			exit 198
		}
	}
	else {
		local T : word count `adopt'
		if `T0' >= . local T0 = 1
		local T1 = `T0' + `T' - 1
		mata: __nwdif_x = st_data((1::`n'), "`adopt'")
		mata: st_local("bad", strofreal(any(__nwdif_x :>= . ) | any(__nwdif_x :!= 0 :& __nwdif_x :!= 1)))
		if `bad' {
			di "{err}The variables in {bf:adopt()} must be 0 or 1 without missing values."
			exit 198
		}
		mata: st_local("bad", strofreal(any(__nwdif_x[., 2::cols(__nwdif_x)] :< __nwdif_x[., 1::(cols(__nwdif_x)-1)])))
		if `bad' {
			di "{err}Adoption cannot be undone: a variable in {bf:adopt()} is 0 after an earlier 1."
			exit 198
		}
		mata: __nwdif_toa = nw_dif_toafromcum(__nwdif_x, `T0')
		mata: st_local("nobs", strofreal(sum(__nwdif_toa :< .)))
		if `nobs' == 0 {
			di "{err}Nobody adopts in the variables of {bf:adopt()}."
			exit 198
		}
	}
	local T = `T1' - `T0' + 1
	if `k' > 0 {
		if `k' != 1 & `k' != `T' {
			di "{err}Give one network, or one network for each of the `T' periods (`k' given)."
			exit 198
		}
		mata: __nwdif_G = J(`n', 0, .)
		local i = 0
		foreach nm of local names {
			local ++i
			_nwsyntax `nm', max(1)
			_nw2guard `nm', cmd(nwdiffuse)
			if `nodes' != `n' {
				di "{err}The networks have different numbers of nodes."
				exit 198
			}
			nwtomatafast `nm'
			mata: __nwdif_G = __nwdif_G, nw_dif_clean(`r(mata)', `n', `vflag', `oflag', `sflag')
			mata: st_local("neg", strofreal(min(__nwdif_G) < 0))
			if `neg' {
				di "{err}Negative tie values are not allowed."
				exit 198
			}
		}
	}
	return scalar n = `n'
	return scalar t0 = `T0'
	return scalar t1 = `T1'
	return scalar T = `T'
	return scalar k = `k'
	return scalar adopters = `nobs'
	mata: __nwdif_C = nw_dif_cum(__nwdif_toa, `T0', `T')
	mata: __nwdif_share = J(0, 0, .)
	mata: __nwdif_count = J(0, 0, .)
end

capture program drop _nwdiffuse_newvars
program _nwdiffuse_newvars
	args stub t0 t1 replace
	forvalues t = `t0'/`t1' {
		if `t' < 0 {
			di "{err}Variable names need non-negative period numbers; recode the periods (see t0())."
			exit 198
		}
		capture confirm variable `stub'`t', exact
		if _rc == 0 & "`replace'" == "" {
			di "{err}Variable {bf:`stub'`t'} already exists; specify {bf:replace}"
			exit 110
		}
		else {
			capture drop `stub'`t'
		}
	}
end

// ---------------------------------------------------------------------------------------------
capture program drop nwdiffuse_exposure
program nwdiffuse_exposure, rclass
	syntax [anything(name=netlist)] , [TOA(varname numeric) ADOPT(varlist numeric) T0(string) T1(string) ///
		GENerate(string) COUnt(string) LAG(integer 0) valued incoming self replace]
	if "`generate'" == "" & "`count'" == "" {
		di "{err}Specify {bf:generate(stub)} for the share of adopting neighbours, {bf:count(stub)} for their number, or both."
		exit 198
	}
	if `lag' < 0 {
		di "{err}lag() must be 0 or larger."
		exit 198
	}
	local so ""
	foreach o in toa adopt t0 t1 {
		if "``o''" != "" local so "`so' `o'(``o'')"
	}
	_nwdiffuse_setup `netlist', `so' `valued' `incoming' `self'
	local n = r(n)
	local t0 = r(t0)
	local t1 = r(t1)
	local T = r(T)
	if r(k) == 0 {
		di "{err}A network is needed."
		exit 198
	}
	foreach stub in `generate' `count' {
		_nwdiffuse_newvars `stub' `t0' `t1' "`replace'"
	}
	mata: nw_dif_expo(__nwdif_G, `n', __nwdif_C, `lag', __nwdif_share, __nwdif_count)
	forvalues j = 1/`T' {
		local t = `t0' + `j' - 1
		if "`generate'" != "" {
			quietly generate double `generate'`t' = .
			mata: st_store((1::`n'), "`generate'`t'", __nwdif_share[., `j'])
			label variable `generate'`t' "Exposure (share of adopting neighbours), period `t'"
		}
		if "`count'" != "" {
			quietly generate double `count'`t' = .
			mata: st_store((1::`n'), "`count'`t'", __nwdif_count[., `j'])
			label variable `count'`t' "Exposure (adopting neighbours), period `t'"
		}
	}
	di "{txt}Exposure computed for periods {res}`t0'{txt} to {res}`t1'{txt}, lag `lag'; variables {res}`generate'`t0'{txt}...{res}`generate'`t1'"
	return scalar n = `n'
	return scalar t0 = `t0'
	return scalar t1 = `t1'
	return scalar periods = `T'
	return scalar lag = `lag'
end

// ---------------------------------------------------------------------------------------------
capture program drop nwdiffuse_threshold
program nwdiffuse_threshold, rclass
	syntax [anything(name=netlist)] , [TOA(varname numeric) ADOPT(varlist numeric) T0(string) T1(string) ///
		GENerate(string) COUnt(string) LAG(integer 0) valued incoming self replace]
	if "`generate'" == "" & "`count'" == "" {
		di "{err}Specify {bf:generate(newvar)} for the threshold (share) or {bf:count(newvar)} for the number of adopting neighbours."
		exit 198
	}
	if `lag' < 0 {
		di "{err}lag() must be 0 or larger."
		exit 198
	}
	local so ""
	foreach o in toa adopt t0 t1 {
		if "``o''" != "" local so "`so' `o'(``o'')"
	}
	_nwdiffuse_setup `netlist', `so' `valued' `incoming' `self'
	local n = r(n)
	local t0 = r(t0)
	local T = r(T)
	if r(k) == 0 {
		di "{err}A network is needed."
		exit 198
	}
	foreach v in `generate' `count' {
		capture confirm variable `v', exact
		if _rc == 0 & "`replace'" == "" {
			di "{err}Variable {bf:`v'} already exists; specify {bf:replace}"
			exit 110
		}
		capture drop `v'
	}
	mata: nw_dif_expo(__nwdif_G, `n', __nwdif_C, `lag', __nwdif_share, __nwdif_count)
	if "`generate'" != "" {
		quietly generate double `generate' = .
		mata: st_store((1::`n'), "`generate'", nw_dif_atadoption(__nwdif_share, __nwdif_toa, `t0'))
		label variable `generate' "Threshold: share of adopting neighbours at adoption"
	}
	if "`count'" != "" {
		quietly generate double `count' = .
		mata: st_store((1::`n'), "`count'", nw_dif_atadoption(__nwdif_count, __nwdif_toa, `t0'))
		label variable `count' "Number of adopting neighbours at adoption"
	}
	if "`generate'" != "" {
		quietly summarize `generate'
		return scalar mean = r(mean)
		return scalar N = r(N)
		di "{txt}Threshold of `r(N)' adopters (lag `lag'): mean {res}" %6.4f r(mean)
	}
	return scalar lag = `lag'
end

// ---------------------------------------------------------------------------------------------
capture program drop nwdiffuse_curve
program nwdiffuse_curve, rclass
	syntax [anything(name=netlist)] , [TOA(varname numeric) ADOPT(varlist numeric) T0(string) T1(string) ///
		GRAPH MATrix(name) silent *]
	local nn "nonet"
	if "`netlist'" != "" local nn ""
	local so ""
	foreach o in toa adopt t0 t1 {
		if "``o''" != "" local so "`so' `o'(``o'')"
	}
	_nwdiffuse_setup `netlist', `so' `nn'
	local n = r(n)
	local t0 = r(t0)
	local t1 = r(t1)
	local T = r(T)
	local nadopt = r(adopters)
	tempname Cv
	mata: nw_dif_curve(__nwdif_C, `t0', "`Cv'")
	matrix colnames `Cv' = period adopters proportion rate new
	if "`silent'" == "" {
		di "{hline 52}"
		di "{txt}  Period  Adopters  Proportion      Rate  New"
		forvalues j = 1/`T' {
			di "{res}" %8.0f `Cv'[`j',1] %10.0f `Cv'[`j',2] %12.4f `Cv'[`j',3] %10.4f `Cv'[`j',4] %5.0f `Cv'[`j',5]
		}
		di "{hline 52}"
	}
	if "`graph'" != "" {
		preserve
		quietly {
			drop _all
			svmat double `Cv', names(col)
			twoway line proportion period, ytitle("Proportion of adopters") xtitle("Period") `options'
		}
		restore
	}
	if "`matrix'" != "" matrix `matrix' = `Cv'
	return matrix curve = `Cv'
	return scalar n = `n'
	return scalar t0 = `t0'
	return scalar t1 = `t1'
	return scalar adopters = `nadopt'
end

// ---------------------------------------------------------------------------------------------
capture program drop nwdiffuse_long
program nwdiffuse_long, rclass
	syntax [anything(name=netlist)] , [TOA(varname numeric) ADOPT(varlist numeric) T0(string) T1(string) ///
		LAG(integer 1) valued incoming self clear KEEP(varlist)]
	if "`clear'" == "" {
		di "{err}{bf:nwdiffuse long} replaces the data in memory by the person-period data; specify {bf:clear} (use {bf:preserve} to keep the data)."
		exit 4
	}
	if `lag' < 0 {
		di "{err}lag() must be 0 or larger."
		exit 198
	}
	local so ""
	foreach o in toa adopt t0 t1 {
		if "``o''" != "" local so "`so' `o'(``o'')"
	}
	_nwdiffuse_setup `netlist', `so' `valued' `incoming' `self'
	local n = r(n)
	local t0 = r(t0)
	local T = r(T)
	if r(k) == 0 {
		di "{err}A network is needed."
		exit 198
	}
	foreach v of local keep {
		capture confirm numeric variable `v'
		if _rc {
			di "{err}keep(): {bf:`v'} is not numeric."
			exit 108
		}
	}
	mata: nw_dif_expo(__nwdif_G, `n', __nwdif_C, `lag', __nwdif_share, __nwdif_count)
	tempname K
	mata: `K' = J(`n', 0, .)
	if "`keep'" != "" mata: `K' = st_data((1::`n'), "`keep'")
	// person-period rows: periods t0+lag ... min(toa, t1), the period of adoption last
	mata: st_local("nrows", strofreal(nw_dif_long(__nwdif_share, __nwdif_count, __nwdif_toa, `t0', `T', `lag', `K', "__nwdif_x")))
	if `nrows' == 0 {
		mata: mata drop `K'
		di "{err}No person-period rows: every adopter adopts before period `=`t0'+`lag''."
		exit 198
	}
	quietly clear
	quietly set obs `nrows'
	quietly generate double node = .
	quietly generate double period = .
	quietly generate byte adopt = .
	quietly generate double exposure = .
	quietly generate double nexposed = .
	local kv ""
	foreach v of local keep {
		quietly generate double `v' = .
		local kv "`kv' `v'"
	}
	mata: st_store(., tokens("node period adopt exposure nexposed `keep'"), __nwdif_x)
	mata: mata drop `K'
	label variable node "Node number"
	label variable period "Period"
	label variable adopt "Adopts in this period (1) or not yet (0)"
	label variable exposure "Share of adopting neighbours (lag `lag')"
	label variable nexposed "Number of adopting neighbours (lag `lag')"
	quietly count if adopt == 1
	di "{txt}Person-period data: {res}`nrows'{txt} rows, {res}`r(N)'{txt} adoptions, exposure lagged by {res}`lag'{txt} period(s)."
	return scalar rows = `nrows'
	return scalar events = r(N)
	return scalar lag = `lag'
end

// ---------------------------------------------------------------------------------------------
capture program drop nwdiffuse_simulate
program nwdiffuse_simulate, rclass
	syntax [anything(name=netlist)] , Model(string) GENerate(string) [PRob(real -1) THReshold(real -1) ///
		THRESHOLDVar(varname numeric) NSeeds(integer 0) SEEDVar(varname numeric) SPont(real 0) STEPs(integer 20) ///
		SEED(integer -1) valued incoming self replace]
	if !inlist("`model'", "cascade", "threshold", "fraction") {
		di "{err}model() must be {bf:cascade}, {bf:threshold} or {bf:fraction}."
		exit 198
	}
	if `spont' < 0 | `spont' > 1 {
		di "{err}spont() must be a probability between 0 and 1."
		exit 198
	}
	if `steps' < 1 {
		di "{err}steps() must be at least 1."
		exit 198
	}
	if "`model'" == "cascade" {
		if `prob' <= 0 | `prob' > 1 {
			di "{err}model(cascade) needs prob() between 0 (exclusive) and 1: the probability that an adopter passes on to one neighbour."
			exit 198
		}
		if `threshold' >= 0 | "`thresholdvar'" != "" {
			di "{err}threshold() does not apply to model(cascade)."
			exit 198
		}
	}
	else {
		if `prob' >= 0 {
			di "{err}prob() applies to model(cascade) only."
			exit 198
		}
		if "`thresholdvar'" == "" & `threshold' <= 0 {
			di "{err}model(`model') needs threshold(#) larger than 0 (or thresholdvar()): the number (threshold) or share (fraction) of adopting neighbours needed."
			exit 198
		}
		if "`model'" == "fraction" & `threshold' > 1 {
			di "{err}model(fraction): threshold() is a share between 0 and 1."
			exit 198
		}
	}
	if `nseeds' <= 0 & "`seedvar'" == "" & `spont' == 0 {
		di "{err}Specify {bf:nseeds()}, {bf:seedvar()} or {bf:spont()}: nobody would adopt."
		exit 198
	}
	if `nseeds' > 0 & "`seedvar'" != "" {
		di "{err}Specify {bf:nseeds()} or {bf:seedvar()}, not both."
		exit 198
	}
	capture confirm variable `generate', exact
	if _rc == 0 & "`replace'" == "" {
		di "{err}Variable {bf:`generate'} already exists; specify {bf:replace}"
		exit 110
	}
	local vflag = ("`valued'" != "")
	local oflag = ("`incoming'" == "")
	local sflag = ("`self'" != "")
	local thv "`thresholdvar'"
	local thr = `threshold'
	// networks: one network (the same in every step) or one per step
	_nwsyntax `netlist', max(1000)
	local names "`netname'"
	local k : word count `names'
	local first : word 1 of `names'
	_nwsyntax `first', max(1)
	local n = `nodes'
	if _N < `n' {
		di "{err}The data set has `=_N' observations, the network has `n' nodes: observation {it:i} must hold node {it:i}."
		exit 198
	}
	if `k' != 1 & `k' != `steps' {
		di "{err}Give one network, or one network for each of the steps() = `steps' (`k' given)."
		exit 198
	}
	if `nseeds' > `n' {
		di "{err}nseeds() is larger than the number of nodes."
		exit 198
	}
	if "`thresholdvar'" != "" {
		mata: __nwdif_x = st_data((1::`n'), "`thresholdvar'")
		mata: st_local("bad", strofreal(any(__nwdif_x :>= .) | any(__nwdif_x :<= 0)))
		if `bad' {
			di "{err}thresholdvar() must be larger than 0 and without missing values."
			exit 198
		}
		if "`model'" == "fraction" {
			mata: st_local("bad", strofreal(any(__nwdif_x :> 1)))
			if `bad' {
				di "{err}thresholdvar() for model(fraction) must be shares between 0 and 1."
				exit 198
			}
		}
	}
	else mata: __nwdif_x = J(`n', 1, `=cond(`threshold' > 0, `threshold', 1)')
	mata: __nwdif_G = J(`n', 0, .)
	foreach nm of local names {
		_nwsyntax `nm', max(1)
		_nw2guard `nm', cmd(nwdiffuse)
		if `nodes' != `n' {
			di "{err}The networks have different numbers of nodes."
			exit 198
		}
		nwtomatafast `nm'
		mata: __nwdif_G = __nwdif_G, nw_dif_clean(`r(mata)', `n', `vflag', `oflag', `sflag')
	}
	mata: st_local("neg", strofreal(min(__nwdif_G) < 0))
	if `neg' {
		di "{err}Negative tie values are not allowed."
		exit 198
	}
	tempname S
	mata: `S' = J(`n', 1, 0)
	if "`seedvar'" != "" {
		mata: `S' = st_data((1::`n'), "`seedvar'")
		mata: st_local("bad", strofreal(any(`S' :>= . ) | any(`S' :!= 0 :& `S' :!= 1)))
		if `bad' {
			mata: mata drop `S'
			di "{err}seedvar() must be 0/1 without missing values."
			exit 198
		}
	}
	if `seed' >= 0 set seed `seed'
	if `nseeds' > 0 mata: `S'[order((runiform(`n', 1), (1::`n')), (1, 2))[1::`nseeds']] = J(`nseeds', 1, 1)
	mata: __nwdif_toa = nw_dif_simulate(__nwdif_G, `n', "`model'", `=cond(`prob' > 0, `prob', 0)', __nwdif_x, `S', `spont', `steps')
	mata: mata drop `S'
	capture drop `generate'
	quietly generate double `generate' = .
	mata: st_store((1::`n'), "`generate'", __nwdif_toa)
	label variable `generate' "Simulated period of adoption (seeds: 1)"
	quietly summarize `generate'
	local nad = r(N)
	local last = r(max)
	local pct : display %5.1f 100*`nad'/`n'
	di "{txt}Simulated `model' diffusion on `n' nodes: {res}`nad'{txt} adopters (`pct'%), last adoption in period {res}`last'"
	return scalar n = `n'
	return scalar adopters = `nad'
	return scalar share = `nad' / `n'
	return scalar lastperiod = `last'
	return local model "`model'"
end

capture mata: mata drop nw_dif_clean() nw_dif_toafromcum() nw_dif_cum() nw_dif_expo() nw_dif_atadoption()
capture mata: mata drop nw_dif_curve() nw_dif_long() nw_dif_simulate() nw_dif_slice()
mata:
// influence matrix B: B[i,j] is the weight with which the behaviour of j reaches i (outgoing: the ties of i)
real matrix nw_dif_clean(real matrix A0, real scalar n, real scalar valued, real scalar outgoing, real scalar self)
{
	real matrix B
	B = editmissing(A0[1::n, 1::n], 0)
	if (!self) B = B - diag(diagonal(B))
	if (!valued) B = (B :!= 0)
	if (!outgoing) B = B'
	return(B)
}

real colvector nw_dif_toafromcum(real matrix X, real scalar t0)
{
	real colvector toa
	real scalar i, T
	T = cols(X)
	toa = J(rows(X), 1, .)
	for (i = 1; i <= rows(X); i++) {
		if (any(X[i, .] :== 1)) toa[i] = t0 + min(selectindex(X[i, .] :== 1)) - 1
	}
	return(toa)
}

// cumulative adoption: node adopted in or before the period (a missing toa is never smaller)
real matrix nw_dif_cum(real colvector toa, real scalar t0, real scalar T)
{
	real matrix C
	real scalar t
	C = J(rows(toa), T, 0)
	for (t = 1; t <= T; t++) C[., t] = (toa :<= (t0 + t - 1))
	return(C)
}

real matrix nw_dif_slice(real matrix G, real scalar n, real scalar t)
{
	if (cols(G) == n) return(G)
	return(G[., ((t - 1) * n + 1)::(t * n)])
}

// exposure in period t: ties (graph of period t-lag) to the adopters of period t-lag, as netdiffuseR's exposure(lags=);
// share of the ties, and count
void nw_dif_expo(real matrix G, real scalar n, real matrix C, real scalar lag, real matrix share, real matrix count)
{
	real scalar t, T
	real matrix B
	real colvector cnt, rs
	T = cols(C)
	share = J(n, T, .)
	count = J(n, T, .)
	for (t = 1; t <= T; t++) {
		if (t - lag < 1) continue
		B = nw_dif_slice(G, n, t - lag)
		cnt = B * C[., t - lag]
		rs = rowsum(B)
		count[., t] = cnt
		share[., t] = cnt :/ (rs + (rs :== 0))
	}
}

real colvector nw_dif_atadoption(real matrix E, real colvector toa, real scalar t0)
{
	real colvector r
	real scalar i, j
	r = J(rows(toa), 1, .)
	for (i = 1; i <= rows(toa); i++) {
		j = toa[i] - t0 + 1
		if (toa[i] < . & j >= 1 & j <= cols(E)) r[i] = E[i, j]
	}
	return(r)
}

void nw_dif_curve(real matrix C, real scalar t0, string scalar name)
{
	real scalar T, t
	real colvector q, rate, newa
	real matrix M
	T = cols(C)
	q = colsum(C)'
	newa = q - (0 \ q[1::(T-1)])
	rate = J(T, 1, 0)
	if (T > 1) rate[2::T] = (q[2::T] - q[1::(T-1)]) :/ (q[1::(T-1)] :+ 1e-15)
	M = ((t0::(t0 + T - 1)), q, q / rows(C), rate, newa)
	st_matrix(name, M)
}

// person-period rows; x: node, period, adopt, exposure, nexposed, then the kept variables
real scalar nw_dif_long(real matrix share, real matrix count, real colvector toa, real scalar t0, real scalar T,
	real scalar lag, real matrix K, string scalar xname)
{
	real scalar i, t, tend, r, nr
	real matrix X
	nr = 0
	for (i = 1; i <= rows(toa); i++) {
		tend = (toa[i] < . ? toa[i] - t0 + 1 : T)
		if (tend >= 1 + lag) nr = nr + (tend - lag)
	}
	if (nr == 0) return(0)
	X = J(nr, 5 + cols(K), .)
	r = 0
	for (i = 1; i <= rows(toa); i++) {
		tend = (toa[i] < . ? toa[i] - t0 + 1 : T)
		for (t = 1 + lag; t <= tend; t++) {
			r++
			X[r, 1] = i
			X[r, 2] = t0 + t - 1
			X[r, 3] = (toa[i] < . & t == tend)
			X[r, 4] = share[i, t]
			X[r, 5] = count[i, t]
			if (cols(K) > 0) X[r, 6::cols(X)] = K[i, .]
		}
	}
	external real matrix __nwdif_x
	__nwdif_x = X
	return(nr)
}

// synchronous simulation; returns the period of adoption (seeds: 1)
real colvector nw_dif_simulate(real matrix G, real scalar n, string scalar model, real scalar prob,
	real colvector thr, real colvector seeds, real scalar spont, real scalar steps)
{
	real colvector toa, act, newact, cnt, rs, add
	real matrix B
	real scalar t
	toa = J(n, 1, .)
	toa[selectindex(seeds :== 1)] = J(sum(seeds :== 1), 1, 1)
	act = (toa :< .)
	newact = act
	for (t = 2; t <= steps + 1; t++) {
		B = nw_dif_slice(G, n, t - 1)
		if (model == "cascade") {
			// every node that adopted in the previous period gets one chance per neighbour (weights are ignored)
			cnt = (B :!= 0) * newact
			add = (cnt :> 0) :& (runiform(n, 1) :< (1 :- (1 - prob) :^ cnt))
		}
		else {
			cnt = B * act
			if (model == "fraction") {
				rs = rowsum(B)
				cnt = cnt :/ (rs + (rs :== 0))
			}
			add = cnt :>= thr
		}
		if (spont > 0) add = add :| (runiform(n, 1) :< spont)
		add = add :& (act :== 0)
		newact = add
		toa[selectindex(add)] = J(sum(add), 1, t)
		act = act :| add
		if (sum(add) == 0 & spont == 0 & (model == "cascade" | cols(G) == n)) break
	}
	return(toa)
}
end
