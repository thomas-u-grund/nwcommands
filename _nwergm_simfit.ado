*! _nwergm_simfit.ado -- nwergm simulate from the last fit (R: simulate.ergm)
capture program drop _nwergm_simfit
program _nwergm_simfit, rclass
	version 14
	syntax [, NSIM(integer 1) SEED(integer -1) OUTput(string) BASIS(string) NOSEQuential ///
		BURNin(integer -1) INTERval(integer -1) GENerate(string) COEF(string) CLEAR]
	if `"`e(cmd)'"' != "nwergm" {
		di as err "last nwergm estimates not found"
		exit 301
	}
	capture mata: __nwergm_last_G.n
	if _rc {
		di as err "no fitted nwergm model available for simulation - re-run nwergm first."
		exit 498
	}
	if `nsim' < 1 {
		di as err "option nsim() must be at least 1."
		exit 198
	}
	if "`output'" == "" local output "network"
	local output = lower("`output'")
	_opts_oneof "network stats edgelist" "output" "`output'" 198
	if "`output'" == "edgelist" & "`clear'" == "" {
		di as err "output(edgelist) replaces the data in memory; specify {bf:clear}."
		exit 198
	}
	if "`generate'" == "" local generate "sim"
	if `seed' != -1 set seed `seed'
	if `burnin' < 0 {
		local burnin = 16384
		if "`e(mcmc_burnin)'" != "" local burnin = e(mcmc_burnin)
	}
	if `interval' < 0 {
		local interval = 1024
		if "`e(mcmc_interval_final)'" != "" local interval = e(mcmc_interval_final)
		else if "`e(mcmc_interval)'" != "" local interval = e(mcmc_interval)
	}
	local dir = ("`e(directed)'" == "true")
	local nodes = e(nodes)

	tempname bmat
	if "`coef'" != "" {
		capture confirm matrix `coef'
		if _rc {
			di as err "coef(): matrix `coef' not found."
			exit 111
		}
		matrix `bmat' = `coef'
		if colsof(`bmat') != colsof(e(b)) {
			di as err "coef() needs " colsof(e(b)) " values, one per coefficient."
			exit 198
		}
	}
	else matrix `bmat' = e(b)

	// starting network: the fit's last network (R: newnetwork) unless basis() is given
	tempname A0
	if "`basis'" != "" {
		capture _nwsyntax `basis', max(1)
		if _rc {
			di as err "network `basis' not found."
			exit 498
		}
		if `nodes' != e(nodes) | ("`directed'"=="true") != `dir' {
			di as err "basis(): network `basis' must have the nodes and directedness of the fitted network."
			exit 498
		}
		tempname bG
		mata: `bG' = ErgmGraph()
		mata: `bG'.init(`nodes', `dir')
		mata: ergm_bridge_obs(`netobj', `bG', `dir')
		mata: `A0' = `bG'.to_dense()
		mata: mata drop `bG'
	}
	else mata: `A0' = __nwergm_last_G.to_dense()

	mata: st_local("__hasmask", strofreal(__nwergm_last_G.has_dyadmask))
	if `__hasmask' {
		if "`e(proposal)'" == "tnt" local propfn "&ergm_propose_tnt_masked()"
		else local propfn "&ergm_propose_uniform_masked()"
	}
	else if "`e(proposal)'" == "uniform" local propfn "&ergm_propose_uniform()"
	else local propfn "&ergm_propose_tnt()"
	local want = cond("`output'" == "network", 1, cond("`output'" == "edgelist", 2, 0))
	local seq = ("`nosequential'" == "")
	if !`seq' & "`basis'" == "" {
		// R: without sequential, each draw starts again from the basis
	}
	tempname nets
	mata: `nets' = ergm_sim_run(__nwergm_last_M, __nwergm_last_G, `A0', st_matrix("`bmat'"), `nsim', `burnin', `interval', `propfn', `seq', `want', "__simE7")
	tempname S
	matrix `S' = __simE7_stats
	matrix drop __simE7_stats
	mata: st_local("cn", invtokens(__nwergm_last_M.coefnames))
	matrix colnames `S' = `cn'
	return matrix stats = `S'
	if "`output'" == "network" {
		forvalues s = 1/`nsim' {
			tempname M1
			mata: st_matrix("`M1'", asarray(`nets', `s'))
			local nm = cond(`nsim' == 1, "`generate'", "`generate'_`s'")
			capture nwdrop `nm'
			preserve
			qui drop _all
			qui set obs `nodes'
			nwset, mat(`M1') `=cond(`dir',"directed","undirected")' name(`nm') nooutput
			restore
		}
		di as txt "(`nsim' simulated network(s) created: `generate'" cond(`nsim' > 1, "_1 ... `generate'_`nsim'", "") ")"
	}
	else if "`output'" == "edgelist" {
		tempname EL
		matrix `EL' = __simE7_el
		matrix drop __simE7_el
		qui drop _all
		qui svmat double `EL', names(col)
		capture rename c1 _sim
		capture rename c2 _tail
		capture rename c3 _head
		if _N == 0 {
			qui set obs 0
		}
	}
	capture mata: mata drop `nets' `A0'
	return scalar nsim = `nsim'
	return scalar burnin = `burnin'
	return scalar interval = `interval'
end
