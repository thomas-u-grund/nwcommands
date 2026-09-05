
capture program drop nwassortativity
program nwassortativity, rclass
	syntax [anything(name=netname)] [, attribute(varname) weighted silent]
	_nwsyntax `netname'

	tempname attr pairs corrmat
	if "`attribute'" == "" {
		mata: `attr' = J(`nodes',1,0)
		mata: for (__i=1; __i<=`nodes'; __i++) `attr'[__i] = rows(`netobj'->connected_neighbors(__i))
		local attrname "degree"
	}
	else {
		confirm numeric variable `attribute'
		mata: `attr' = st_data((1::`nodes'), "`attribute'")
		local attrname "`attribute'"
	}

	mata: `pairs' = `netobj'->calculate_assortativity_pairs(`attr')
	mata: st_numscalar("r(ties)", rows(`pairs')/2)

	if "`weighted'" == "" {
		mata: `corrmat' = correlation(`pairs'[.,(1,2)])
		mata: st_numscalar("r(assortativity)", `corrmat'[2,1])
		mata: mata drop `corrmat'
	}
	else {
		// Leung & Chau (2007): weighted assortativity is the weighted
		// Pearson correlation of the same (attr_i,attr_j) pairs, using
		// each pair's own tie weight - not a different pair
		// construction, only a different (weighted) correlation of the
		// identical pair list the unweighted case already builds.
		mata: st_numscalar("r(assortativity)", WeightedPearsonCorr(`pairs'))
	}
	mata: mata drop `attr' `pairs'
	capture mata: mata drop __i

	return scalar assortativity = r(assortativity)
	return scalar ties = r(ties)
	return local attribute "`attrname'"
	return local name "`netname'"
	local weightedflag = cond("`weighted'" != "", "true", "false")
	return local weighted "`weightedflag'"

	if "`silent'" == "" {
		di
		di "{txt}  Network name: {res}`netname'"
		di "{txt}  Attribute: {res}`attrname'"
		di "{hline 40}"
		di "{txt}    Ties: {res}`=r(ties)'"
		if "`weighted'" != "" {
			di "{txt}    Weighted assortativity coefficient (Leung & Chau 2007): {res}`=round(r(assortativity),0.001)'"
		}
		else {
			di "{txt}    Assortativity coefficient: {res}`=round(r(assortativity),0.001)'"
		}
	}
end
