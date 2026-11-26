
capture program drop nwcoreperiphery
program nwcoreperiphery, rclass
	version 12
	syntax [anything(name=netname)][, GENerate(string) replace measure(string) maxiter(int 100) RESTarts(integer 1) SEED(string) silent SYMmetrize]
	set more off

	if `maxiter' < 1 {
		di "{err}maxiter() must be a positive integer."
		exit 198
	}

	if `restarts' < 1 {
		di "{err}restarts() must be a positive integer."
		exit 198
	}
	if "`seed'" != "" {
		capture confirm integer number `seed'
		if _rc | real("`seed'") < 0 {
			di "{err}seed() must be a non-negative integer."
			exit 198
		}
		if `restarts' == 1 {
			di "{err}seed() needs restarts() of 2 or more; with one start the search uses no random numbers."
			exit 198
		}
	}

	_nwsyntax `netname', max(9999)

	if `networks' > 1 {
		local k = 1
	}

	qui foreach netname_temp in `netname' {
		_nwsyntax `netname_temp'
		noi _nw2guard `netname_temp', cmd(nwcoreperiphery)
		_nwsymguard `netname_temp', cmd(nwcoreperiphery) `symmetrize'
		local __symmsg `"`r(msg)'"'

		local netmeasure "`measure'"
		if "`netmeasure'" == "" {
			if "`valued'" == "true" {
				local netmeasure "valued"
			}
			else {
				local netmeasure "binary"
			}
		}
		_opts_oneof "binary valued" "measure" "`netmeasure'" 6556
		_nwsyntax `netname_temp'
		mata: st_local("__neg", strofreal(sum(`netobj'->edgelist()[., 3] :< 0) > 0))
		if `__neg' noi di "{txt}{p 0 0 2}(warning: the network has negative tie values, for which a core-periphery fit is not meaningful){p_end}"

		if "`generate'" == "" {
			noi di "{err}option {bf:generate()} required."
			exit 198
		}
		local netgenerate "`generate'"

		capture confirm variable `netgenerate'`k', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`netgenerate'`k'} already exists; specify {bf:replace}"
			exit 110
		}

		local val = ("`netmeasure'" == "valued")

		capture confirm new variable `netgenerate'`k'
		if _rc capture drop `netgenerate'`k'
		gen `netgenerate'`k' = .
		mata: st_rclear()
		qui if _N < `nodes' {
			set obs `nodes'
		}
		// align row i of the data set with node i of this network before the
		// positional st_store() below (a data set that was sorted or reordered, or
		// synced to another network such as a two-mode projection, would otherwise
		// receive the values on the wrong rows)
		_nwsyncrows `netname_temp'
		mata: st_rclear()
		_nwsyntax `netname_temp'

		tempname __nw_cp
		capture noisily mata: `__nw_cp' = `netobj'->calculate_coreperiphery(`val', `maxiter')
		if _rc != 0 {
			exit _rc
		}
		local nbest = 1
		local beststart = 1
		if `restarts' > 1 {
			// random starts: the degree-based start above is start 1; the best fitness over all starts is kept (an earlier
			// start wins a tie), so the result never has a lower fitness than with one start
			if `nodes' > 2000 {
				noi di "{err}{p 0 0 2}restarts() is available for networks of up to 2,000 nodes.{p_end}"
				exit 198
			}
			if "`seed'" != "" set seed `seed'
			capture noisily mata: nw_cp_restarts(`netobj', `val', `maxiter', `restarts', `__nw_cp')
			if _rc != 0 {
				exit _rc
			}
			local nbest = nwcp_nbest
			local beststart = nwcp_beststart
			scalar drop nwcp_nbest nwcp_beststart
		}
		mata: st_store((1::`nodes'),"`netgenerate'`k'", `__nw_cp'[1::`nodes',1])
		mata: st_numscalar("cp_fitness", `__nw_cp'[`nodes'+1,1])
		mata: st_numscalar("cp_coresize", sum(`__nw_cp'[1::`nodes',1]))
		mata: mata drop `__nw_cp'

		return scalar fitness = cp_fitness
		return scalar core = cp_coresize
		return scalar restarts = `restarts'
		return scalar beststart = `beststart'
		return scalar nbest = `nbest'
		local lfit = cp_fitness
		local lcore = cp_coresize

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			if `"`__symmsg'"' != "" {
				noi di `"`__symmsg'"'
			}
			noi di "{txt}  Core size: {res}`lcore'{txt}   Fitness: {res}`=strtrim(string(round((`lfit')*1000)/1000,"%9.0g"))'"
			if `restarts' > 1 noi di "{txt}  Starts: {res}`restarts'{txt}   best fitness reached by {res}`nbest'{txt} of them (first at start {res}`beststart'{txt})"
			noi tab `netgenerate'`k'
			noi di " "
		}
		local k = `=`k' + 1'
	}
end

capture mata: mata drop nw_cp_restarts()
capture mata: mata drop nw_cp_localsearch()

mata:
// Single-node flip local search from the 0/1 column vector `core' (the search of CorePeriphery() of the library, with a given start);
// returns the final core. net: symmetric, zero diagonal, n x n.
real colvector nw_cp_localsearch(real matrix net, real colvector core0, real scalar maxiter, real scalar sumA, real scalar varA)
{
	real colvector core, periph
	real matrix pattern0
	real scalar n, m, sumP, sumAP, sweep, moved, i, c_old, dirn, nP, wsum, sumP1, sumAP1, fit0, fit1, varP0, varP1

	n = rows(net)
	m = n * (n - 1)
	core = core0
	pattern0 = ((core * J(1, n, 1)) :+ (J(n, 1, 1) * core')) :> 0
	_diag(pattern0, 0)
	sumP = sum(pattern0)
	sumAP = sum(net :* pattern0)
	sweep = 0
	moved = 1
	while (moved & sweep < maxiter) {
		moved = 0
		sweep++
		for (i = 1; i <= n; i++) {
			varP0 = sumP * (m - sumP)
			fit0 = (varP0 <= 0 | varA <= 0) ? . : (m * sumAP - sumA * sumP) / sqrt(varA * varP0)
			c_old = core[i]
			periph = (core :== 0)
			periph[i] = 0
			nP = sum(periph)
			wsum = sum(periph :* (net[i, .]' :+ net[., i]))
			dirn = (c_old == 1 ? -1 : 1)
			sumP1 = sumP + dirn * 2 * nP
			sumAP1 = sumAP + dirn * wsum
			varP1 = sumP1 * (m - sumP1)
			fit1 = (varP1 <= 0 | varA <= 0) ? . : (m * sumAP1 - sumA * sumP1) / sqrt(varA * varP1)
			if (fit1 > fit0 + 1e-12) {
				core[i] = 1 - c_old
				sumP = sumP1
				sumAP = sumAP1
				moved = 1
			}
		}
	}
	return(core)
}

// restarts-1 further searches from random starts (each node in the core with probability 1/2); res is the (n+1) x 1 result of the
// degree-based start (core, fitness) and is replaced by the best one; scalars nwcp_beststart (the first start that reached the best
// fitness) and nwcp_nbest (the number of starts that reached it)
void nw_cp_restarts(pointer (class nw_def scalar) scalar p, real scalar val, real scalar maxiter, real scalar restarts, real matrix res)
{
	real matrix net, mask
	real colvector idx, core, fits
	real scalar n, r, sumA, varA, m, best, bi

	net = *(p->get_matrix_mod(val, 0))
	n = rows(net)
	_diag(net, 0)
	m = n * (n - 1)
	sumA = sum(net)
	varA = m * sum(net :^ 2) - sumA^2
	mask = J(n, n, 1)
	_diag(mask, 0)
	idx = selectindex(vec(mask))
	fits = J(restarts, 1, .)
	fits[1] = res[n + 1, 1]
	best = fits[1]
	bi = 1
	for (r = 2; r <= restarts; r++) {
		core = (runiform(n, 1) :< 0.5)
		if (sum(core) == 0 | sum(core) == n) core[ceil(runiform(1, 1) * n)] = !core[1]
		core = nw_cp_localsearch(net, core, maxiter, sumA, varA)
		fits[r] = nw_cp_fitness(net, core, idx)
		if (fits[r] < . & (best >= . | fits[r] > best + 1e-12)) {
			best = fits[r]
			bi = r
			res = core \ fits[r]
		}
	}
	st_numscalar("nwcp_beststart", bi)
	st_numscalar("nwcp_nbest", sum(fits :< . :& abs(fits :- best) :< 1e-9))
}
end
