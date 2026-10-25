capture program drop nw2nested
program nw2nested, rclass
	version 12
	// Nestedness of a two-mode network: NODF (Almeida-Neto et al. 2008) and the C-score (Stone and Roberts 1990).
	//   nw2nested [netname] [, level(1|2) silent]
	// Ties are read as present or absent (binary). Equals vegan::nestednodf(web, order = TRUE) (the NODF2 of
	// bipartite::nested) and bipartite::C.score.
	syntax [anything(name=netname)] [, LEVel(integer 2) silent]

	_nwsyntax `netname', max(1)
	if "`is2mode'" != "true" {
		di "{err}nw2nested requires a two-mode network; {bf:`netname'} is one-mode (see {help nw2set})."
		error 198
	}
	if !inlist(`level', 1, 2) {
		di "{err}level() must be 1 or 2"
		error 198
	}

	tempname __nw_B
	mata: `__nw_B' = editmissing((*`netobj'->get_matrix())[selectindex(strtoreal(`netobj'->get_modes()) :== 1), selectindex(strtoreal(`netobj'->get_modes()) :== 2)], 0) :!= 0
	mata: st_matrix("__nw2n_nodf", nw_nodf(`__nw_B'))
	// the C-score compares pairs of columns: the nodes of the level asked for
	mata: st_matrix("__nw2n_cs", nw_cscore(`level' == 2 ? `__nw_B' : `__nw_B''))
	mata: mata drop `__nw_B'

	local nodf = __nw2n_nodf[1,1]
	local nodf1 = __nw2n_nodf[1,2]
	local nodf2 = __nw2n_nodf[1,3]
	local cs = __nw2n_cs[1,1]
	local csn = __nw2n_cs[1,2]
	local csp = __nw2n_cs[1,3]
	matrix drop __nw2n_nodf __nw2n_cs

	return scalar nodf = `nodf'
	return scalar nodf_mode1 = `nodf1'
	return scalar nodf_mode2 = `nodf2'
	return scalar cscore = `cs'
	return scalar cscore_norm = `csn'
	return scalar cscore_pairs = `csp'
	return scalar level = `level'
	return local netname "`netname'"

	if "`silent'" == "" {
		di "{hline 60}"
		di "{txt}  Network name: {res}`netname'"
		di "{txt}  NODF (Almeida-Neto et al. 2008): {res}" %9.4f `nodf'
		di "{txt}      among the nodes of mode 1: {res}" %9.4f `nodf1' "{txt}    of mode 2: {res}" %9.4f `nodf2'
		di "{txt}  C-score, pairs of mode-`level' nodes: {res}" %9.4f `cs' "{txt}   normalised (0-1): {res}" %9.4f `csn'
		di "{hline 60}"
	}
end
