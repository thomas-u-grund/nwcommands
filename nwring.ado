
capture program drop nwring
program nwring
	// `prob(real 0)' removed - it was accepted by syntax but never
	// referenced anywhere in this file's body (confirmed: density on a
	// prob()-specified call was identical to the same call with no
	// prob() at all), so it had zero effect regardless of value. Unlike
	// nwsmall's own prob() (a substantially different rewiring
	// algorithm, `smallworldprob()' in unw_core.do), wiring up a real
	// rewiring feature here would be new functionality, not a bug fix -
	// out of scope for this pass; see nwsmall for the small-world
	// variant if that behavior is wanted.
	syntax anything(name=nodes), k(integer) [ weights(string) ntimes(integer 1) labs(string) name(string) undirected noreplace xvars]

	// BUGFIX: an unspecified name() has always been documented/expected
	// to auto-rename on collision ("ring", "ring_1", ...) rather than
	// require replace() - see nwrandom.ado's/nwpref.ado's own identical
	// fix (harmonisation unit 126/129) for the full root cause. Resolved
	// the same way: only when the caller did NOT supply name(),
	// pre-resolve the actual (possibly auto-incremented) target name via
	// nwvalidate before nwset ever sees it.
	local name_was_given = ("`name'" != "")
	if "`name'" == "" {
		local name "ring"
	}
	if !`name_was_given' {
		nwvalidate `name'
		local name = r(validname)
	}

	if `ntimes' != 1 {
		di in smcl as txt "{p}"
		qui nwset
		local oldnetlist `r(nets)'
		forvalues i = 1/`ntimes'{
			if mod(`i', 25) == 0 {
				di in smcl as txt "...`i'"
			}
			// BUGFIX: was `stub(`stub')' - nwring's own syntax line
			// never declares a `stub' option at all (unlike sibling
			// nwlattice/nwpref, which do), so this stray token made
			// EVERY ntimes()>1 call crash with r(198) "option stub()
			// not allowed" - the documented multi-network-generation
			// feature was completely broken. Also forwards `weights'
			// now, which this recursive call never did (a separate,
			// silent bug: ntimes()>1 always came back unweighted
			// regardless of weights() - see nwrandom.ado's/nwpref.ado's
			// own identical fix).
			nwring `nodes', k(`k') name(`name'_`i') weights(`weights') `xvars' `undirected'
		}
		// Feature parity (moderate-severity pass, generators_structural
		// group): only nwrandom exposed r(netlist) for its own ntimes()>1
		// case; nwpref/nwlattice/nwring/nwsmall all share the identical
		// convention but never returned it.
		qui nwset
		local newnetlist `r(nets)'
		local netlist : list newnetlist - oldnetlist
		mata: st_rclear()
		mata: st_global("r(netlist)", "`netlist'")
		exit
	}
	
	tempname __nwnew
	mata: `__nwnew' = ringlattice(`nodes', `k')
	if "`weights'" != "" {
		tempname w
		capture mata: `w' = rdiscrete(`nodes', `nodes',(`weights')) 
		if _rc != 0 {
			di "{err}Could not sample tie weights, check option {bf:weights()}.{txt}"
		}
		capture mata: `w' = `w' :/ sum((`weights'))
		if "`undirected'" != "" {
			mata: `w' = lowertriangle(`w',0)
			mata: `w' = `w' + `w''
		}
		capture mata: `__nwnew' = `__nwnew' :* `w'
	}
	mata: st_rclear()
	nwset, mat(`__nwnew') labs(`labs') name(`name') `undirected'
	if "`xvars'" == "" {
		nwload, xvars
	}
	else {
		nwload
	}
	mata: st_global("r(netlist)", "`name'")

end

capture mata: mata drop ringlattice()

mata: 
real matrix ringlattice(nodes, k){
	real matrix net, y, rows
	real scalar i, j
	// generate ring lattice
	net = J(nodes, nodes, 0)
	rows = (1::nodes)
	for (i = 1; i<=k; i++) {
		y = (editvalue(mod((rows' :+ i), (nodes)),0,nodes))'
		for (j = 1; j<= rows(y); j++){
			net[j, y[j,1]] = 1
		}
		y = (editvalue(mod((rows' :- i), (nodes)),0,nodes))'
		for (j = 1; j<= rows(y); j++){
			net[j, y[j,1]] = 1
		}
	}
	return(net)
}
end
