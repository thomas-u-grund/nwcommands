
capture program drop nwassortativity
program nwassortativity, rclass
	syntax [anything(name=netname)] [, attribute(varname) silent]
	nw_syntax `netname'

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

	mata: `corrmat' = correlation(`pairs')
	mata: st_numscalar("r(assortativity)", `corrmat'[2,1])
	mata: mata drop `attr' `pairs' `corrmat'
	capture mata: mata drop __i

	return scalar assortativity = r(assortativity)
	return scalar ties = r(ties)
	return local attribute "`attrname'"
	return local name "`netname'"

	if "`silent'" == "" {
		di
		di "{txt}  Network name: {res}`netname'"
		di "{txt}  Attribute: {res}`attrname'"
		di "{hline 40}"
		di "{txt}    Ties: {res}`=r(ties)'"
		di "{txt}    Assortativity coefficient: {res}`=round(r(assortativity),0.001)'"
	}
end
