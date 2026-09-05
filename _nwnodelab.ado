*! Date        : 15sept2014
*! Version     : 1.0
*! Author      : Thomas Grund, Linkoping University
*! Email	   : thomas.u.grund@gmail.com

capture program drop _nwnodelab
program _nwnodelab
	syntax [anything(name=netname)], nodeid(integer) [detail]
	// _nwsyntax is a deprecated pure wrapper around nw_syntax (re-exports
	// only 4 of its locals) - this file's own syntax line has no option
	// named the same as any of nw_syntax's other exports, so calling it
	// directly is a safe, direct simplification.
	nw_syntax `netname'
	nwname `netname'

	if `nodeid' > `r(nodes)' {
		mata: st_rclear()
		di "{err}{it:nodeid} {bf:`nodeid'} out of bounds"
		error 600022
	}
	else {
		// r(labs) is comma-separated (see _nwname.ado's own
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
