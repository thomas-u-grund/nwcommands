capture program drop _nwsymguard
program _nwsymguard, rclass
	// For a command that is defined on undirected networks only (cliques, k-plexes, k-components, ...):
	//   _nwsymguard <net>, cmd(nwxxx) [sym quiet]
	// undirected network: nothing happens. Directed network whose ties are all reciprocated (with the same value):
	// the symmetrized network is the network itself, so the command runs and says so. Any other directed network:
	// error 198 unless option sym asks for the symmetrized network (a tie counts in both directions, the larger of
	// its two values); the command then says so. The note is returned in r(msg) (printed by the caller: a noisily inside a quietly block does not show from here); quiet leaves r(msg) empty (never the error).
	syntax anything(name=netname), cmd(string) [SYMmetrize quiet]
	return scalar symdo = 0
	_nwsyntax `netname', max(1)
	if "`directed'" != "true" exit
	tempname ok
	mata: st_numscalar("`ok'", `netobj'->check_symmetry())
	if scalar(`ok') == 1 {
		return scalar symdo = 0
		if "`quiet'" == "" return local msg "{txt}{p 4 4 2}(directed network with every tie reciprocated: analysed as an undirected network){p_end}"
		exit
	}
	if "`symmetrize'" == "" {
		di "{err}{p 0 0 2}{bf:`cmd'} is defined for undirected networks and {bf:`netname'} is directed with ties that are not reciprocated. Add option {bf:sym} to analyse the symmetrized network (a tie counts in both directions, with the larger of its two values).{p_end}"
		exit 198
	}
	return scalar symdo = 1
	if "`quiet'" == "" return local msg "{txt}{p 4 4 2}(directed network symmetrized: the larger of the two directions of a tie){p_end}"
end
