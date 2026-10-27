capture program drop nwreplacemat
program nwreplacemat
	version 9.0
	syntax anything(name=netname), [newmat(string) TRIplets(string) vars(string) labs(string) LABSMata(string) nosync netonly xvars]

	// _nwsyntax itself exports a local called `labs' (the *current*
	// network's own labels, via its own c_local labs "..." with no
	// other() prefix given) - calling it immediately below would
	// silently clobber the caller's own labs() option value before
	// this file ever uses it, which is exactly what was happening
	// here: labs() has never actually done anything in this command,
	// confirmed directly by tracing `labs' immediately after the
	// _nwsyntax call below and finding it held the *original*
	// network's labels, not whatever the caller passed. Captured into
	// a differently-named local first so it survives.
	local newmatlabs "`labs'"
	unw_defs
	_nwsyntax `netname', max(1)
	// the valued flag of the network is kept; it turns on if the new values need it
	local __wasv "`valued'"

	// triplets(): the new network (fewer nodes, named by labsmata()) as a list of ties (ego, alter, value) of new
	// node numbers instead of a matrix, for a network that is held as stored ties: the same steps as the matrix
	// route below, without any n x n matrix
	if "`triplets'" != "" {
		if "`labsmata'" == "" | "`netonly'" != "" | "`newmat'" != "" {
			di "{err}triplets() needs labsmata() and cannot be combined with newmat() or netonly."
			error 198
		}
		mata: st_local("matrows", strofreal(cols(`labsmata')))
		nwdrop `netname'
		_nwsetsparse, triplets(`triplets') nodes(`matrows') name(`netname') nodenames(`labsmata')
		if "`xvars'" == "" {
			nwload, xvars
		}
		else {
			nwload
		}
		_nwsyntax `netname', max(1)
		mata: st_local("__sym", strofreal(nw_triplets_symmetric(`triplets', `matrows')))
		mata: `netobj'->set_valued(("`__wasv'" == "true") | `netobj'->check_valued())
		if "`sync'" == "" {
			nwsync `netname'
		}
		if "`xvars'" != "" {
			nwload `netname'
		}
		mata: `netobj'->set_directed(!`__sym')
		exit
	}
	if "`newmat'" == "" {
		di "{err}option newmat() or triplets() required."
		error 198
	}

	tempname __rmm
	local __matname "`newmat'"
	capture mat list `newmat'
	if _rc == 0 {
		// a Stata matrix is copied to a Mata matrix with a private name (the user's own Mata variables are not touched)
		mata: `__rmm' = st_matrix("`newmat'")
		local __matname "`__rmm'"
	}

	mata: st_numscalar("r(matrows)", rows(`__matname'))
	mata: st_numscalar("r(matcols)", cols(`__matname'))
	local matrows = r(matrows)
	local matcols = r(matcols)

	// newmat is invalid (not N x X matrix)
	if (`matrows' != `matcols'){
		// `errMatrixShape' (6082, unw_defs.ado) - this is the original
		// source of this convention; nwdyadprob.ado's own identical
		// check now also uses it, having previously drifted onto an
		// unrelated code.
		di "{err}input matrix has invalid dimensions"
		error `errMatrixShape'
	}
	
	// newmat is of different size than the network
	if (`matrows' != `nodes'){
		//di "{txt}input matrix has different dimensions than existing {it:network} {bf:`netname'}. size of {bf:`netname'} has been adjusted."
		local nodes = `matrows'
		
		if ("`netonly'" != "" | "`sync'" != "") {
			// BUGFIX: was writing only to legacy pre-2016 nw_mata`id'/
			// nwsize_`id'/nw_`id'/nwlabs_`id' globals - the modern
			// netobj/NWdef Mata class architecture never reads any of
			// these, so a resize+netonly call raised no error but
			// silently left the network object at its old dimensions
			// and values (same class of bug already fixed for the
			// same-size path below via set_edge(), and for
			// set_directed() further down). set_edge() itself is
			// size-agnostic (confirmed directly in unw_core.do - it just
			// replaces the internal edge matrix wholesale, with no
			// dimension check tied to a separately-stored node count),
			// but get_nodes() derives the reported node count from
			// cols(nodes) - the node-NAMES vector - not from the edge
			// matrix's own dimensions, so set_nodenames() must be
			// updated too or the object would report the OLD node count
			// forever despite holding a differently-sized edge matrix.
			mata: `netobj'->set_edge(`__matname')
			if "`labsmata'" != "" {
				mata: `netobj'->set_nodenames(`labsmata')
			}
			else if "`newmatlabs'" != "" {
				mata: `netobj'->set_nodenames(tokens(subinstr("`newmatlabs'", ",", " ", .)))
			}
			else {
				mata: `netobj'->set_nodenames(strofreal((1::`matrows'))')
			}
		}
		else {
			nwdrop `netname', `netonly'
			// BUGFIX: `nwrandom' has never had a `vars()' option (it
			// generates its own default variable names) - this call
			// only ever "worked" because `nwrandom''s own trailing `*'
			// wildcard used to silently absorb and discard unrecognized
			// options; once that dead wildcard was correctly removed
			// (moderate-severity pass, generators_structural group unit)
			// to make nwrandom reject genuinely misspelled options, this
			// pre-existing call broke outright ("option vars() not
			// allowed", r198) - a real, latent bug this uncovered, not a
			// new one. Harmless to simply drop here: `nwrandom''s own
			// ties (from `prob(1)') are immediately overwritten by the
			// very next line's recursive `nwreplacemat' call regardless
			// of what `nwrandom' names its variables.
			// a network of the new size, overwritten with the new matrix just below: created without ties
			// (the earlier nwrandom, prob(1) built a complete graph and several n x n matrices to be overwritten)
			mata: __nwrm_noties = J(0, 3, 0)
			if "`labsmata'" != "" {
				_nwsetsparse, triplets(__nwrm_noties) nodes(`nodes') name(`netname') nodenames(`labsmata')
			}
			else {
				_nwsetsparse, triplets(__nwrm_noties) nodes(`nodes') name(`netname') labs(`newmatlabs')
			}
			mata: mata drop __nwrm_noties
			if "`xvars'" == "" {
				nwload, xvars
			}
			else {
				nwload
			}
			// `nosync' itself is never populated (Stata's own "no"-
			// prefix syntax convention stores the literal string
			// "nosync" in `sync' instead - see the check just above
			// this block, which already gets this right) - so this
			// recursive call previously never actually forwarded the
			// caller's own nosync option. Fixed to forward `sync'.
			nwreplacemat `netname', newmat(`newmat') `sync' `xvars'
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
		// a two-mode network keeps no tie inside a mode: refuse a matrix that has one (before anything is changed)
		if "`is2mode'" == "true" {
			tempname __md2 __bm2
			mata: `__md2' = strtoreal(`netobj'->get_modes())'; `__bm2' = editmissing(`__matname', 0); _diag(`__bm2', 0)
			mata: st_local("__bad2", strofreal(sum((`__bm2' :!= 0) :& ((`__md2' * J(1, rows(`__md2'), 1)) :== (J(rows(`__md2'), 1, 1) * `__md2''))) / 2))
			mata: mata drop `__md2' `__bm2'
			if `__bad2' > 0 {
				di "{err}The matrix has `__bad2' ties between nodes of the same mode; network {bf:`netname'} is two-mode (no tie can join two nodes of one mode)."
				error 459
			}
		}
		mata: `netobj'->set_edge(`__matname')
		if "`netonly'" == "" {
			if "`sync'" == "" {
				nwsync `netname'
			}
		}
		// BUGFIX: `xvars' was accepted by syntax but never referenced
		// anywhere in this same-size branch - requesting it never
		// actually loaded the updated network as Stata variables,
		// unlike the resize branch, which already forwards it (via
		// nwrandom's own xvars handling). Calling bare `nwload', not
		// `nwload, xvars' - nwload's OWN `xvars' flag confusingly means
		// something else entirely (a lightweight `_nwdatasync' sync,
		// exiting immediately) - its DEFAULT (no-flag) path is what
		// actually generates the Stata variables, confirmed directly
		// against nwload.ado's own body.
		if "`xvars'" != "" {
			nwload `netname'
		}
	}

	// check for directed/undirected of new network and adjust if necessary
	mata: st_numscalar("r(directed)", (issymmetric(`__matname') == 1))

	// was "global nwdirected_`id' = ..." - same legacy-global issue as
	// above; set_directed() is the modern equivalent (matches
	// _nwname.ado's own newdirected() implementation).
	if (`r(directed)' == 1) {
		mata: `netobj'->set_directed(0)
	}
	else {
		mata: `netobj'->set_directed(1)
	}

	// the valued flag follows the new values (a network created empty is unvalued until now)
	mata: `netobj'->set_valued(("`__wasv'" == "true") | `netobj'->check_valued())
	capture mata: mata drop `__rmm'
	capture confirm number 0
end
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
