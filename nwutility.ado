capture program drop nwutility
program nwutility
	syntax [anything(name=netname)], [Benefit(real 1) Cost(real 1) INTRValue(string) INTRCost(string) *]
	nw_syntax `netname', max(1)
	// _nwsyntax (now nw_syntax directly, since _nwsyntax never
	// re-exports the node count) gives the main network's node
	// count, but the intrvalue()/intrcost() branches below call
	// nw_syntax again for a different network - which would silently
	// overwrite the main network's own name and node-count locals
	// too, since nw_syntax exports both under the same plain names
	// every time it's called. Captured once here, before any second
	// call, and the network name is restored from the backup
	// afterward (the backup already existed in this file, unused,
	// before this fix - the collision it guards against was real,
	// just never completed).
	local netname_backup "`netname'"
	local netnodes `nodes'

	if `benefit' > 1 | `benefit' < 0 {
		di "{err}{bf:benefit} needs to be in the range between 0 and 1."
		error 60044
	}

	if "`intrvalue'" != "" {
		nw_syntax `intrvalue', max(1)
		if `nodes' != `netnodes' {
			di "{err}network {bf:`intrvalue'} of wrong size"
			error 60033
		}
		nwtomata `intrvalue', mat(checkedvalue)
	}
	else {
		mata: checkedvalue = (I(`netnodes') :- 1) :*(-1)
	}

	if "`intrcost'" != "" {
		nw_syntax `intrcost', max(1)
		if `nodes' != `netnodes' {
			di "{err}network {bf:`intrcost'} of wrong size"
			error 60033
		}
		// this line used to pull the matrix from intrvalue instead
		// of intrcost - a real, separate copy-paste bug: intrcost's
		// own network was resolved just above but never actually
		// used, so checkedcost always held intrvalue's matrix (or
		// was undefined if intrvalue() wasn't also passed).
		nwtomata `intrcost', mat(checkedcost)
	}
	else {
		mata: checkedcost = (I(`netnodes') :- 1) :*(-1)
	}

	local netname `netname_backup'

	// was "nwgenerate _temp_util = (_nwgeodesic `netname', `options')"
	// - two stacked bugs: "_nwgeodesic" (underscore-prefixed) does
	// not exist (the real command is nwgeodesic), and routing a
	// whole sub-command call with its own comma-separated options
	// through nwgenerate's arithmetic-expression translator isn't
	// valid usage of that translator in the first place (Mata
	// "illegal arglist" - the same class of misuse already found and
	// fixed in nwkatz earlier this session). Fixed by calling
	// nwgeodesic directly to create the named network, the same
	// working pattern nwcloseness already uses for this exact
	// purpose.
	qui nwgeodesic `netname', name(_temp_util) `options'
	nwtomata _temp_util, mat(geonet)
	// the diagonal (self-distance) is stored as missing, per this
	// package's convention - distance_distribution()'s own dist>0
	// check already excludes it correctly once it's a real number,
	// but Mata's max() propagates a missing value as the maximum,
	// so max(geonet) would otherwise be missing instead of the
	// network's true longest shortest path, breaking the matrix
	// size (J(nodes, missing, 0)) used to tabulate it.
	mata: _diag(geonet, 0)
	nwdrop _temp_util
	if ("`intrvalue'" == "" & "`intrcost'" == ""){
		mata: util = util_simple(distance_distribution(geonet), `benefit', `cost')
	}
	else {
		// "nw" is this package's own reserved global Mata identifier
		// (the NWs class instance holding all network state, set up
		// in unw_core.do) - using it as a plain local matrix name
		// here clobbered that global, corrupting package state and
		// crashing the very next Mata statement with a class/real
		// type mismatch. Renamed to avoid the collision.
		nwtomata `netname', mat(netmat)
		mata: util = util_weighted(netmat, geonet, checkedvalue, checkedcost, 1)
		mata: mata drop netmat
		mata: mata drop checkedcost
	}
	capture drop _cost
	capture drop _benefit
	capture drop _util
	nwtostata, mat(util) gen(_benefit _cost _util)
	mata: mata drop util
	mata: mata drop geonet
    
end

capture mata mata drop distance_distribution()
capture mata mata drop util_simple()
capture mata mata drop util_weighted()

mata:
real matrix distance_distribution(real matrix dist) {	
	
	nodes = rows(dist)
	maxdist = max(dist)
	
	dd = J(nodes, maxdist, 0)
	
	for(i = 1; i<= nodes; i++){
		for(j = 1; j <= nodes; j++){
		    if (dist[i,j] > 0) {
				dd[i,dist[i,j]] = dd[i,dist[i,j]] + 1
			}
		}
	}
	return(dd)
}


real matrix util_simple(real matrix dd, real scalar b, real scalar c) {
	benefit_cost = J(rows(dd), 3,0)
	// was "i < cols(dd)" - an off-by-one that silently dropped the
	// longest-distance bucket from every node's benefit sum (e.g. on
	// a 4-node network with a diameter of 2, only distance-1 ties
	// were ever counted, never distance-2).
	for (i = 1;i<= cols(dd); i ++){
		benefit_cost[,1] = benefit_cost[,1] :+ (dd[,i] * b^i)
	}
	benefit_cost[,2] = dd[,1] :* c
	benefit_cost[,3] = benefit_cost[,1] - benefit_cost[,2]
	return(benefit_cost)
}

real matrix util_weighted(real matrix net, real matrix geonet, real matrix w, real matrix c, real scalar b) {
	benefit_cost = J(rows(geonet), 3,0)
	// same off-by-one as util_simple: "i < cols(...)"/"j < cols(...)"
	// silently excluded the last node from being either an ego or an
	// alter in this sum.
	for (i = 1;i<= cols(geonet); i ++){
		for (j = 1;j<= cols(geonet); j ++){

			// was "geonet[i,j] >= 0" - the diagonal (self-distance)
			// is 0 after _diag(geonet,0) in the caller, so ">= 0"
			// included it here even though it is already added back
			// separately below via diagonal(w); the self term (w's
			// own possibly-missing diagonal, via b^0=1) was silently
			// corrupting every row's sum with a missing value.
			if (geonet[i,j] > 0) {
				benefit_cost[i,1] = benefit_cost[i,1] + (w[i,j] * b^(geonet[i,j]))
			}
		}
	}

	benefit_cost[,1] = benefit_cost[,1] + diagonal(w)
	cost = net :* c
	benefit_cost[,2] = rowsum(cost)
	benefit_cost[,3] = benefit_cost[,1] - benefit_cost[,2]
	return(benefit_cost)
}
end
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
