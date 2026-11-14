*! Date        : 4nov2026
*! Version     : 1.0
*! Author      : Thomas Grund, RWTH Aachen University
*! Email       : thomas.u.grund@gmail.com

capture program drop nwstack
program nwstack, rclass
	version 17
	_nwlibcheck
	syntax anything(name=netlist), Name(string) [GRoup(name) replace]

	// the networks to stack
	nwunab netlist : `netlist', min(2)
	local k : word count `netlist'

	if "`replace'" == "" {
		capture _nwsyntax `name', max(1)
		if _rc == 0 {
			di as err "network {bf:`name'} already exists; use {bf:replace}"
			exit 483
		}
	}

	// all networks must be one-mode and agree in direction
	local first : word 1 of `netlist'
	_nwsyntax `first', max(1)
	local dir0 "`directed'"
	local total = 0
	tempname M S
	mata: __nwstack_S = J(0, 0, .)
	forvalues i = 1/`k' {
		local net : word `i' of `netlist'
		_nwsyntax `net', max(1)
		if "`directed'" != "`dir0'" {
			di as err "{p 0 0 2}{bf:`net'} and {bf:`first'} differ in direction; stack directed or undirected networks, not a mix{p_end}"
			capture mata: mata drop __nwstack_S
			error 198
		}
		capture noisily _nw2guard `net', cmd(nwstack)
		if _rc {
			local __st_rc = _rc
			capture mata: mata drop __nwstack_S
			exit `__st_rc'
		}
		quietly nwtomata `net', mat(__nwstack_M)
		mata: __nwstack_S = blockdiag(__nwstack_S, __nwstack_M); st_local("n_`i'", strofreal(rows(__nwstack_M)))
		local total = `total' + `n_`i''
		capture mata: mata drop __nwstack_M
	}
	mata: st_matrix("`S'", __nwstack_S)
	capture mata: mata drop __nwstack_S

	// the group variable, one value per stacked network
	if "`group'" != "" {
		if _N == 0 {
			quietly set obs `total'
		}
		else if _N != `total' {
			di as err "{p 0 0 2}the data in memory have " _N " observations, the stacked network has `total' nodes; use {bf:group()} with an empty data set or one that already lists the nodes of all networks in the order of {it:netlist}{p_end}"
			exit 198
		}
		quietly generate long `group' = .
		local first_obs = 1
		forvalues i = 1/`k' {
			quietly replace `group' = `i' in `first_obs'/`=`first_obs'+`n_`i''-1'
			local first_obs = `first_obs' + `n_`i''
		}
	}

	local opts ""
	if "`dir0'" == "true" local opts "directed"
	else local opts "undirected"
	if "`replace'" != "" local opts "`opts' replace"
	// more rows than nodes are fine (set obs cannot shrink the data)
	if _N < `total' {
		quietly set obs `total'
	}
	nwset, mat(`S') name(`name') `opts' nooutput
	return scalar k = `k'
	return scalar N = `total'
	di as txt "(`k' networks stacked into {bf:`name'}: `total' nodes)"
end
