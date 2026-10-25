capture program drop _nw2guard
program _nw2guard, rclass
	// The one place where a command that has no meaning for a two-mode network refuses it:
	//   _nw2guard <net>, cmd(<command>) [allowone] [onemode]
	// A network that is not two-mode passes (r(net) = the name given). A two-mode network is refused with one
	// message and error 6088. A command that offers the option onemode (read the two-mode graph as a one-mode
	// graph, no ties inside a mode; what igraph does with a bipartite graph) passes allowone and the user's
	// onemode: the helper then makes a one-mode copy named __nw1m and returns its name in r(net); the caller
	// drops the copy when it is done (capture nwdrop __nw1m).
	syntax anything(name=netname), CMD(string) [ALLOWone ONEmode]
	_nwsyntax `netname', max(1) other(_g)
	return local net "`netname'"
	return scalar copied = 0
	if "`_gis2mode'" != "true" exit
	if "`allowone'" != "" & "`onemode'" != "" {
		capture nwdrop __nw1m
		qui nwduplicate `netname', name(__nw1m)
		qui _nwsyntax __nw1m, max(1)
		mata: `netobj'->set_2mode(0)
		mata: `netobj'->set_edge(editmissing(*`netobj'->get_matrix(), 0))
		qui nwcurrent `netname'
		return local net "__nw1m"
		return scalar copied = 1
		exit
	}
	unw_defs
	local tail ""
	if "`allowone'" != "" local tail " The option {bf:onemode} reads the two-mode network as a one-mode graph."
	di "{err}{bf:`cmd'} does not support two-mode networks ({bf:`netname'}): it reads the blocks between nodes of the same mode, which hold no ties. Make a one-mode network of one mode first ({help nwproject}).`tail'"
	error `errTwoModeUnsupported'
end
