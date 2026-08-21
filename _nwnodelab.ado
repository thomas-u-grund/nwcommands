*! Date        : 15sept2014
*! Version     : 1.0
*! Author      : Thomas Grund, Linkoping University
*! Email	   : contact@nwcommands.org

capture program drop _nwnodelab
program _nwnodelab
	syntax [anything(name=netname)], nodeid(integer) [detail]
	_nwsyntax `netname'
	nwname `netname'

	if `nodeid' > `r(nodes)' {
		mata: st_rclear()
		di "{err}{it:nodeid} {bf:`nodeid'} out of bounds"
		error 600022
	}
	else {
		// r(labs) is comma-separated (see nw_name.ado's own
		// invtokens with a comma delimiter), but "word N of ..."
		// needs a space-separated list - without this conversion,
		// the whole comma-joined string is one "word" and any
		// nodeid past 1 silently returns empty.
		local labs "`r(labs)'"
		local labs : subinstr local labs "," " ", all
		local onelab : word `nodeid' of `labs'
	}
	mata: st_rclear()
	mata: st_numscalar("r(nodeid)", `nodeid')
	mata: st_global("r(nodelab)", "`onelab'")
	mata: st_global("r(netname)", "`netname'")
	di
	if "`detail'" == "detail" {
	    di "{hline 40}"
		di "{txt}  Network: {res}`netname'"
		di "{hline 40}"
		di "{txt}    Nodeid: {res}`nodeid'"
		di "{txt}    Nodelab: {res}`onelab'"
	}
end
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
