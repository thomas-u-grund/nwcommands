capture program drop _nwmissnote
program _nwmissnote, rclass
	// Prints "(N missing ties treated as 0)" when the network has missing tie values; nothing otherwise.
	//   _nwmissnote <net> [, quiet noprint]
	// r(nmissing) is the number of missing ties (undirected: pairs; the diagonal of a network without self-loops and
	// the structurally empty blocks of a two-mode network are not counted).
	syntax anything(name=netname) [, quiet noPRint]
	return scalar nmissing = 0
	_nwsyntax `netname', max(1)
	tempname mm
	mata: st_numscalar("`mm'", nw_missing_ties(`netobj'))
	local nm = scalar(`mm')
	return scalar nmissing = `nm'
	if `nm' > 0 & "`quiet'" == "" & "`noprint'" == "" {
		di "{txt}{p 4 4 2}(`nm' missing ties treated as 0){p_end}"
	}
end

capture mata: mata drop nw_missing_ties()
mata:
// number of missing ties of a network (undirected: pairs); 0 when there are none
real scalar nw_missing_ties(pointer(class nw_def scalar) scalar p)
{
	real scalar m, n, k
	real matrix E
	pointer(real matrix) scalar e

	m = p->get_missing_edges()
	if (m == 0) return(0)
	n = p->get_nodes()
	if (p->is_2mode() == "true") {
		// only the cells between the two modes count (the within-mode blocks are structurally empty); small networks
		e = p->get_matrix()
		E = (*e :>= .)
		k = p->get_nodes_mode1()
		E = E[|1,k+1 \ k,n|]
		return(sum(E))
	}
	// the count of the network holds the diagonal of a network without self-loops; an undirected tie fills two cells
	if (p->is_selfloop() == "false") m = m - n
	if (p->is_directed() == "false") m = m / 2
	return(floor(m))
}
end
