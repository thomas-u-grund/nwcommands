capture program drop nwreplacemat
program nwreplacemat
	version 9.0
	syntax anything(name=netname), newmat(string) [vars(string) labs(string) nosync netonly xvars]
	nw_syntax `netname', max(1)

	capture mat list `newmat'
	if _rc == 0 {
		mata: `newmat' = st_matrix("`newmat'")
	}

	mata: st_numscalar("r(matrows)", rows(`newmat'))
	mata: st_numscalar("r(matcols)", cols(`newmat'))
	local matrows = r(matrows)
	local matcols = r(matcols)

	// newmat is invalid (not N x X matrix)
	if (`matrows' != `matcols'){
		di "{err}input matrix has invalid dimensions"
		error 6082
	}
	
	// newmat is of different size than the network
	if (`matrows' != `nodes'){
		//di "{txt}input matrix has different dimensions than existing {it:network} {bf:`netname'}. size of {bf:`netname'} has been adjusted."
		local nodes = `matrows'
		
		if ("`netonly'" != "" | "`sync'" != "") {
			mata: `newmat'
			mata: nw_mata`id' = `newmat'
			global nwsize_`id' = `matrows'
			if "`vars'" != "" {
				global nw_`id' "`vars'"
			}
			if "`labs'" != "" {
				global nwlabs_`id' "`labs'"
			}
		}
		else {
			nwdrop `netname', `netonly'
			nwrandom `nodes', prob(1) name(`netname') vars(`vars') labs(`labs') `xvars'
			nwreplacemat `netname', newmat(`newmat') `nosync' `xvars'
			// delete empty observations in Stata
			nwcompressobs
		}
	}
	else {
		// was "mata: nw_mata`id' = `newmat'" - nw_mata<id> is a
		// legacy pre-2016 global the modern netobj/NWdef Mata class
		// architecture never reads from, so this silently did nothing
		// to the network as far as any other command could see.
		// set_edge() is the modern equivalent (already used
		// elsewhere in this package, e.g. nwkatz's own in-place
		// matrix update).
		mata: `netobj'->set_edge(`newmat')
		if "`netonly'" == "" {
			if "`sync'" == "" {
				nwsync `netname'
			}
		}
	}

	// check for directed/undirected of new network and adjust if necessary
	mata: st_numscalar("r(directed)", (issymmetric(`newmat') == 1))

	// was "global nwdirected_`id' = ..." - same legacy-global issue as
	// above; set_directed() is the modern equivalent (matches
	// nw_name.ado's own newdirected() implementation).
	if (`r(directed)' == 1) {
		mata: `netobj'->set_directed(0)
	}
	else {
		mata: `netobj'->set_directed(1)
	}
end
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
