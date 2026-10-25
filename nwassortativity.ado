
capture program drop nwassortativity
program nwassortativity, rclass
	syntax [anything(name=netname)] [, attribute(varname) weighted silent BINary]
	_nwsyntax `netname'

	tempname attr pairs corrmat
	if "`attribute'" == "" {
		mata: `attr' = J(`nodes',1,0)
		if "`valued'" == "true" & "`binary'" == "" {
			// valued network: the node attribute is the strength (sum of the tie values; the larger direction of a
			// directed pair), not the number of ties; binary uses the degree
			mata: `attr' = nw_assort_strength(`netobj')
			local attrname "strength"
		}
		else {
			mata: for (__i=1; __i<=`nodes'; __i++) `attr'[__i] = rows(`netobj'->connected_neighbors(__i))
			local attrname "degree"
		}
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
			di "{txt}    Weighted assortativity coefficient (Leung & Chau 2007): {res}`=strtrim(string(round((r(assortativity))*1000)/1000,"%9.0g"))'"
		}
		else {
			di "{txt}    Assortativity coefficient: {res}`=strtrim(string(round((r(assortativity))*1000)/1000,"%9.0g"))'"
		}
	}
end

capture mata: mata drop nw_assort_strength()
mata:
// strength of every node: the tie values to its neighbours (the larger direction of a directed pair)
real colvector nw_assort_strength(pointer(class nw_def scalar) scalar p)
{
	real scalar i, k, n
	real colvector s
	real matrix nb

	n = p->get_nodes()
	s = J(n, 1, 0)
	for (i = 1; i <= n; i++) {
		nb = p->connected_neighbors(i)
		for (k = 1; k <= rows(nb); k++) s[i] = s[i] + max((p->edge_weight(i, nb[k]), p->edge_weight(nb[k], i)))
	}
	return(s)
}
end
