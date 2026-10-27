capture program drop nwqap_p
program nwqap_p
	// Postestimation  predict newnetname  after nwqap: stores the dyad-level
	// fitted values of the last nwqap model (type()'s own default
	// prediction, e.g. Pr(y=1) after logit) as a new valued network.
	// Variables cannot hold dyad-level values (the data set has one row
	// per node), so a variable name is not accepted.
	if "`e(cmd)'" != "nwqap" {
		error 301
	}
	syntax anything(name=newnet id="new network name") [if] [in] [, *]
	if `"`options'"' != "" | `"`if'`in'"' != "" {
		di "{err}predict after {bf:nwqap} takes only a new network name: {bf:predict} {it:newnetname}"
		error 198
	}
	capture mata: st_numscalar("__nwqap_ok", rows(__nwqapfit))
	if _rc != 0 | scalar(__nwqap_ok) == . {
		di "{err}the fitted values of the last {bf:nwqap} are no longer in memory; rerun {bf:nwqap}"
		error 498
	}
	capture scalar drop __nwqap_ok
	nwvalidate `newnet'
	local newnet = r(validname)
	if "`e(fit_directed)'" == "true" {
		qui nwset, mat(__nwqapfit) name(`newnet') directed labs(`e(fit_labs)')
	}
	else {
		qui nwset, mat(__nwqapfit) name(`newnet') undirected labs(`e(fit_labs)')
	}
	di "{txt}(fitted values stored as network {res}`newnet'{txt})"
end
