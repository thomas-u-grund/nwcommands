*! Date        : 24aug2014
*! Version     : 1.0.4
*! Author      : Thomas Grund, Linkoping University
*! Email	   : contact@nwcommands.org

* Calculates actor closeness centrality according to Sabidussi (1966)
* See Wassermann & Faust (1994, p. 184)

capture program drop nwcloseness
program nwcloseness
	version 9
	syntax [anything(name=netname)] [, GENerate(string) *]	
	// _nwsyntax is a deprecated pure wrapper around nw_syntax (re-exports
	// only 4 of its locals) - this file's own syntax line has no option
	// named the same as any of nw_syntax's other exports, so calling it
	// directly is a safe, direct simplification.
	nw_syntax `netname', max(9999)
	
	if `networks' > 1 {
		local k = 1
	}
	_nwsetobs `netname'
	
	local gencount : word count `generate'
	if (`gencount' != 3) {
		local generate = "_closeness _farness _nearness"
	}
	local generate_all ""
	
	set more off
	qui foreach netname_temp in `netname' {
		preserve
		qui nwgeodesic `netname_temp', name(_tempgeodesic) `options' xvars
		nwname _tempgeodesic
		nwtomata _tempgeodesic, mat(geodesic)
		mata: st_numscalar("r(mindistance)", min(geodesic))
		mata: far = rowsum(geodesic)
		
		if `r(mindistance)' < 0 {
			mata: far = J(rows(geodesic), 1, .)
			noi di "{txt}Warning: network {bf:`netname_temp'} not connected; specify {bf:unconnected()} to obtain results.
			nwdrop _tempgeodesic
			exit
		}
		
		nw_syntax `netname_temp'

		mata: nearness = J(`nodes', 1,1) :/ far
		mata: closeness = nearness :* (`nodes' - 1)
		local _closeness : word 1 of `generate'
		local _farness : word 2 of `generate'
		local _nearness : word 3 of `generate'
		nwdrop _tempgeodesic
		restore

		_nwsetobs `netname_temp'
		// _nwsetobs only ensures enough observations exist - it does
		// not align row i with node i of `netname_temp' specifically
		// (a real, separate bug found while adding netlist test
		// coverage: without this sync, st_store below wrote into
		// whatever rows happened to be there, silently misplacing
		// and even losing data for every network after the first).
		// nw_datasync is this package's own established mechanism for
		// that alignment (see e.g. nwdegree's netlist support).
		tempvar included
		nw_datasync `netname_temp', generate(`included')

		qui capture drop `_closeness'`k'
		qui gen `_closeness'`k' = .
		qui capture drop `_farness'`k'
		qui gen `_farness'`k' = .
		qui capture drop `_nearness'`k'
		qui gen `_nearness'`k' =.
		
		mata: st_store((1::`nodes'),"`_closeness'`k'",closeness)
		mata: st_store((1::`nodes'),"`_farness'`k'",far)
		mata: st_store((1::`nodes'),"`_nearness'`k'",nearness)
	
		local generate_all "`generate_all' `_closeness'`k' `_farness'`k' `_nearness'`k'"
		capture drop `included'
		mata: mata drop closeness far nearness geodesic
		
		local k = `k' + 1	
	}
	mata: st_rclear()
	di "{hline 40}"
	di "{txt}  Network name: {res}`netname'"
	di "{hline 40}"
	di "{txt}    Closeness centrality"
	sum `generate_all'
end
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
