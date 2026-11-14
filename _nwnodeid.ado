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
		if `nodelab' > `netnodes' | `nodelab' < 1 {
			
			mata: st_numscalar("r(nodeid)", -1)
			di "{err}{it:nodelab} {bf:`nodelab'} out of bounds"
			exit 485
		}
		mata: st_numscalar("r(nodeid)", `nodelab')
		exit
	}
	else {
		// the label is looked up in Mata: labels may contain blanks, and
		// the list of labels of a big network does not fit into a macro
		mata: st_local("__nwid", strofreal(first_index_match(`netobj'->get_nodenames(), st_local("nodelab"))))
		mata: st_rclear()
		mata: st_global("r(netname)", "`netname'")
		mata: st_global("r(nodelab)", st_local("nodelab"))
		if `__nwid' > 0 {
			mata: st_numscalar("r(nodeid)", `__nwid')
			if "`detail'" == "detail" {
				di
				di "{hline 40}"
				di "{txt}  Network: {res}`netname'"
				di "{hline 40}"
				di "{txt}    Nodeid  : {res}`__nwid'"
				di `"{txt}    Nodelab : {res}`nodelab'"'
			}
			exit
		}
		mata: st_numscalar("r(nodeid)", -1)
		di `"{err}{it:nodelab} `nodelab' not found"'
		exit 485
	}
end
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
