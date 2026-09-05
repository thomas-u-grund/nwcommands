
capture program drop nwlambda
program nwlambda, rclass
	version 12
	syntax [anything(name=netname)] [, name(string) xvars replace]

	nw_syntax `netname'

	if "`name'" == "" {
		local name "lambda"
	}
	// replace, when given, reuses the exact requested name (drop then
	// recreate) rather than silently auto-incrementing to a different one
	// - matches nwsimindex.ado's own identical convention exactly (this
	// command is the same shape: compute an n x n matrix, save it as a
	// new valued network).
	nwvalidate `name'
	if "`r(exists)'" == "true" {
		if "`replace'" == "" {
			di "{txt}Warning! Switched to netname {res}`r(validname)'{txt} because {res}`name'{txt} already in use."
			local name = r(validname)
		}
		else {
			capture nwdrop `name'
		}
	}

	tempname __nw_lam
	mata: `__nw_lam' = `netobj'->calculate_lambda()

	nwset, mat(`__nw_lam') name(`name') undirected labs(`labs')
	mata: mata drop `__nw_lam'

	nw_syntax `name'
	mata: `netobj'->set_valued(1)

	return scalar nodes = `nodes'
	return local netname "`name'"

	di "{hline 40}"
	di "{txt}  Edge (line) connectivity network: {res}`name'"
	di "{txt}  Nodes: {res}`nodes'"
	di "{hline 40}"

	if "`xvars'" != "" {
		nwload `name'
	}
end
