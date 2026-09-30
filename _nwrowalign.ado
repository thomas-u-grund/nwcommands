*! _nwrowalign: make sure node attributes are read in a network's node order
capture program drop _nwrowalign
program _nwrowalign
	// _nwrowalign net1 [net2 ...]
	//
	// Commands such as nwsaom and nwergm read node attributes by row
	// position (st_data(1::nodes, var)), so rows 1..nodes of the data
	// must be in the node order of the network(s) being analysed.
	// Declaring a network whose node order differs (e.g. a different
	// node set) re-sorts the rows (datasync), which leaves the rows out
	// of the node order of the networks declared before it.  This
	// helper
	//   (1) refuses networks that list their nodes in different orders
	//       (their matrices would be combined position by position), and
	//   (2) re-sorts the rows into the first network's node order when
	//       they are not in it already (attributes move with their node
	//       labels, so nothing is misaligned), with a note.
	syntax anything(name=netnames)
	unw_defs
	gettoken first rest : netnames
	_nwsyntax `first', max(1) other(ra0)
	local i 0
	foreach net of local rest {
		local ++i
		_nwsyntax `net', max(1) other(ra`i')
		mata: st_local("__same", strofreal(nw_same_nodeorder(`ra0netobj', `ra`i'netobj')))
		if `__same' != 1 {
			di "{err}networks {bf:`first'} and {bf:`net'} do not list the same nodes in the same order; declare them with the same node labels in the same order."
			error 198
		}
	}
	mata: st_local("__al", strofreal(nw_rows_aligned(`ra0netobj', "`nw_nodename'")))
	if `__al' != 1 {
		qui _nwdatasync `first'
		mata: st_local("__al", strofreal(nw_rows_aligned(`ra0netobj', "`nw_nodename'")))
		if `__al' != 1 {
			di "{err}the rows of the data are not in the node order of network {bf:`first'} (variable {bf:`nw_nodename'}), so node attributes cannot be matched to its nodes; see {help _nwdatasync}."
			error 459
		}
		di "{txt}(data sorted into the node order of network {res}`first'{txt})"
	}
end
