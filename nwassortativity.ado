
capture program drop nwassortativity
program nwassortativity, rclass
	syntax [anything(name=netname)] [, attribute(varname) weighted silent BINary SYMmetrize]
	_nwsyntax `netname'
	// a directed network is analysed as it is (one pair per tie: sender against receiver); sym asks for the symmetrized network
	local __symdo = ("`symmetrize'" != "" & "`directed'" == "true")
	local __dirdo = ("`directed'" == "true" & !`__symdo')

	tempname attr pairs corrmat attr2
	if `__dirdo' & "`attribute'" == "" {
		// directed degree assortativity (Newman 2003; igraph::assortativity_degree(directed = TRUE)): out-degree of
		// the sender against in-degree of the receiver; a valued network uses out- and in-strength
		if "`valued'" == "true" & "`binary'" == "" {
			mata: `attr' = nw_assort_dstrength(`netobj', 1)
			mata: `attr2' = nw_assort_dstrength(`netobj', 0)
			local attrname "strength"
		}
		else {
			mata: `attr' = nw_assort_dstrength(`netobj', 1, 1)
			mata: `attr2' = nw_assort_dstrength(`netobj', 0, 1)
			local attrname "degree"
		}
	}
	else if "`attribute'" == "" {
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

	if `__dirdo' {
		if "`attribute'" != "" mata: `attr2' = `attr'
		mata: `pairs' = nw_assort_dpairs(`netobj', `attr', `attr2')
		mata: st_numscalar("r(ties)", rows(`pairs'))
	}
	else {
		mata: `pairs' = `netobj'->calculate_assortativity_pairs(`attr')
		mata: st_numscalar("r(ties)", rows(`pairs')/2)
	}

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
	capture mata: mata drop `attr2'
	mata: mata drop `attr' `pairs'
	capture mata: mata drop __i

	local __r = r(assortativity)
	local __t = r(ties)
	return scalar assortativity = `__r'
	return scalar ties = `__t'
	return local attribute "`attrname'"
	return local name "`netname'"
	return local directed = cond(`__dirdo', "true", cond(`__symdo', "symmetrized", "false"))
	local weightedflag = cond("`weighted'" != "", "true", "false")
	return local weighted "`weightedflag'"
	_nwmissnote `netname', quiet
	local __nmiss = r(nmissing)

	if "`silent'" == "" {
		di
		di "{txt}  Network name: {res}`netname'"
		di "{txt}  Attribute: {res}`attrname'"
		di "{hline 40}"
		if `__dirdo' & "`attribute'" == "" di "{txt}{p 4 4 2}(directed network: out-degree of the sender against in-degree of the receiver, one pair per tie){p_end}"
		else if `__dirdo' di "{txt}{p 4 4 2}(directed network: the attribute of the sender against that of the receiver, one pair per tie){p_end}"
		else _nwdirnote, directed(`directed') symdo(`__symdo') text(x)
		di "{txt}    Ties: {res}`__t'"
		if "`weighted'" != "" {
			di "{txt}    Weighted assortativity coefficient (Leung & Chau 2007): {res}`=strtrim(string(round((`__r')*1000)/1000,"%9.0g"))'"
		}
		else {
			di "{txt}    Assortativity coefficient: {res}`=strtrim(string(round((`__r')*1000)/1000,"%9.0g"))'"
		}
		if `__nmiss' > 0 di "{txt}{p 4 4 2}(`__nmiss' missing ties treated as 0){p_end}"
	}
end

capture mata: mata drop nw_assort_dstrength()
capture mata: mata drop nw_assort_dpairs()
capture mata: mata drop nw_assort_strength()
mata:
// out (out = 1) or in (out = 0) strength of every node of a directed network; bin = 1 counts ties
real colvector nw_assort_dstrength(pointer(class nw_def scalar) scalar p, real scalar out, | real scalar bin)
{
	real scalar i, k, n
	real colvector s
	real matrix nb

	if (args() < 3) bin = 0
	n = p->get_nodes()
	s = J(n, 1, 0)
	for (i = 1; i <= n; i++) {
		nb = (out ? p->neighbors(i) : p->neighbors_in(i))
		if (bin) s[i] = rows(nb)
		else for (k = 1; k <= rows(nb); k++) s[i] = s[i] + (out ? p->edge_weight(i, nb[k]) : p->edge_weight(nb[k], i))
	}
	return(s)
}

// one row per tie i -> j: value of the sender, value of the receiver, tie value
real matrix nw_assort_dpairs(pointer(class nw_def scalar) scalar p, real colvector xs, real colvector yt)
{
	real scalar i, k, n, cnt, m
	real matrix nb, pairs

	n = p->get_nodes()
	m = 0
	for (i = 1; i <= n; i++) m = m + rows(p->neighbors(i))
	pairs = J(m, 3, .)
	cnt = 0
	for (i = 1; i <= n; i++) {
		nb = p->neighbors(i)
		for (k = 1; k <= rows(nb); k++) {
			cnt++
			pairs[cnt, 1] = xs[i]
			pairs[cnt, 2] = yt[nb[k]]
			pairs[cnt, 3] = p->edge_weight(i, nb[k])
		}
	}
	return(pairs)
}

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
