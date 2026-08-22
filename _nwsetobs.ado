capture program drop _nwsetobs
program _nwsetobs
	syntax [anything(name=netname)] 
	// _nwsyntax is a deprecated pure wrapper around nw_syntax (re-exports
	// only 4 of its locals) - this file's own syntax line has no option
	// named the same as any of nw_syntax's other exports, so calling it
	// directly is a safe, direct simplification.
	nw_syntax _all, max(9999)
	local othernetname `netname'
	
	local maxnodes = 0
	foreach onenet in `othernetname' {
		nwname `onenet'
		if r(nodes) > `maxnodes' {
			local maxnodes = `r(nodes)'
		}
	}
	if _N < `maxnodes' {
		set obs `maxnodes'
	}
	mata: st_rclear()
	mata: st_numscalar("r(maxnodes)", `maxnodes')
end
