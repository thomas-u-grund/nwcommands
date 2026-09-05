capture program drop _nwnodeid
program _nwnodeid
	syntax [anything(name=netname)], nodelab(string) [detail]
	// _nwsyntax is a deprecated pure wrapper around _nwsyntax (re-exports
	// only 4 of its locals) - this file's own syntax line has no option
	// named the same as any of _nwsyntax's other exports, so calling it
	// directly is a safe, direct simplification.
	_nwsyntax `netname'
	nwname `netname'
	local netnodes `r(nodes)'

	mata: st_rclear()
	mata: st_global("r(netname)", "`netname'")
	mata: st_global("r(nodelab)", "`nodelab'")

	capture confirm integer number `nodelab'
	if _rc == 0 {
		if `nodelab' > `netnodes' {
			
			mata: st_numscalar("r(nodeid)", -1)
			di "{err}{it:nodelab} {bf:`nodelab'} out of bounds"
			error 600021
		}
		mata: st_numscalar("r(nodeid)", `nodelab')
		exit
	}
	else {
		nwname `netname'
		local labs "`r(labs)'"
		// r(labs) is comma-separated (see _nwname.ado's own
		// invtokens with a comma delimiter), but the foreach loop
		// below needs a space-separated list to iterate over
		// individual labels - without this, the whole comma-joined
		// string is treated as a single list item and never matches
		// any individual label, silently failing every lookup.
		local labs : subinstr local labs "," " ", all
		mata: st_rclear()
		mata: st_global("r(netname)", "`netname'")
		mata: st_global("r(nodelab)", "`nodelab'")
		local i = 1
		local found = 0
		 capture foreach onelab in `labs' {
			noi if "`onelab'" == "`nodelab'"{
				mata: st_numscalar("r(nodeid)", `i')
				local found = 1
				di
				if "`detail'" == "detail" {
					di "{hline 40}"
					di "{txt}  Network: {res}`netname'"
					di "{hline 40}"
					di "{txt}    Nodeid  : {res}`r(nodeid)'"
					di "{txt}    Nodelab : {res}`r(nodelab)'"
				}
				exit 1
			}
			local i = `i' + 1
		}
		if `found' == 0 {
			mata: st_numscalar("r(nodeid)", -1)
			di "{err}{it:nodelab} `nodelab' not found"
			error 6012
		}
	}
end
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
