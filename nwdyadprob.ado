capture program drop nwdyadprob
program nwdyadprob
	syntax [anything(name=weightnet)],  [ weights(string) density(string) mat(string) name(string) labs(passthru) xvars undirected]
	
	unw_defs
	
	// BUGFIX: an unspecified name() has always been documented/expected
	// to auto-rename on collision ("dyadprob", "dyadprob_1", ...) rather
	// than require replace() - see nwrandom.ado's/nwpref.ado's own
	// identical fix (harmonisation unit 126/129/130) for the full root
	// cause. Resolved the same way: only when the caller did NOT supply
	// name(), pre-resolve the actual (possibly auto-incremented) target
	// name via nwvalidate before nwset ever sees it.
	local name_was_given = ("`name'" != "")
	if "`name'" == "" {
		local name "dyadprob"
	}
	if !`name_was_given' {
		nwvalidate `name'
		local name = r(validname)
	}
	
	tempname m
	if "`mat'" == "" {
		local mat = "`m'"
	}
	else {
		// BUGFIX: a caller-supplied mat() used to be referenced directly
		// by its raw text everywhere below, including two in-place
		// mutation attempts (`mat' = lowertriangle(`mat')' further down,
		// and `mat' = transformIntoProbs(...)' above when combined with
		// weightnet). That only works when mat() is an actual, existing
		// Mata variable NAME - it crashes ("invalid lval", r3000) the
		// moment mat() is instead a literal expression (e.g.
		// mat(J(5,5,.5)), exactly as shown working in this command's own
		// .sthlp examples) combined with `undirected'. Copying into a
		// private tempname up front - the same pattern already used just
		// above for the "mat() unspecified" case - makes every later
		// reference (read or write) operate on a real, assignable
		// variable regardless of what kind of Mata argument the caller
		// passed.
		tempname __matcopy
		mata: `__matcopy' = (`mat')
		local mat = "`__matcopy'"
	}


	// Install gsample if needed
	capture which gsample
	if _rc != 0 {
		ssc install gsample
	}
	capture mata: mata which mm_sample()
	if _rc != 0 {
		ssc install moremata
	}

	if "`weightnet'" != "" {
		_nwsyntax `weightnet', other(_wn)
		mata: `mat' = transformIntoProbs((*`_wnnetobj'->get_matrix()))
	}
	
	tempname __nwnew
	mata: `__nwnew' = getNetFromProbs(`mat')
	mata: st_numscalar("r(nodes)", rows(`__nwnew' ))
	local nodes = `r(nodes)'
	
	if  "`density'" == ""{
		capture mata: `mat'
		if _rc != 0 {
			di "{err}Mata matrix `mat' not found.{txt}"
			error _rc
		}
		else {
			mata: st_numscalar("r(matrows)", rows(`mat'))
			mata: st_numscalar("r(matcols)", cols(`mat'))
			if (`r(matrows)' != `r(matcols)') {
				// Error-code coherence pass: a malformed input matrix
				// shape, not a "network already exists" collision (the
				// `6099' this line had drifted onto by coincidence) -
				// `errMatrixShape' (6082, unw_defs.ado) already names
				// this exact situation for nwreplacemat.ado's own
				// identical check.
				di "{err}Mata matrix `mat' not square.{txt}"
				error `errMatrixShape'
			}
			if "`undirected'" != "" {
				mata: `mat' = lowertriangle(`mat')
			}
			// BUGFIX: `weights()' is documented ("the command generates
			// a weighted network") but was accepted by `syntax' and
			// then never referenced anywhere else in this program - a
			// complete no-op; the network always came back plain
			// binary 0/1 regardless of what weights() requested.
			// Implemented using the exact same sampling pattern this
			// package's own generator siblings (nwrandom.ado/
			// nwpref.ado) already use and have had cross-validated:
			// rdiscrete() over the (standardized) requested weight
			// probabilities, one draw per potential dyad, applied as
			// an elementwise multiplier onto the realized 0/1 tie
			// matrix (so a non-tie, 0, stays 0 regardless of the
			// sampled weight).
			if "`weights'" != "" {
				tempname w
				capture mata: `w' = rdiscrete(`nodes', `nodes',(`weights'))
				if _rc != 0 {
					// BUGFIX: see nwrandom.ado's own header comment on
					// this identical block (nwrandom/nwring/nwsmall/
					// nwpref all share it too) for the full explanation -
					// this used to print the message and fall through,
					// silently producing an unweighted network while
					// claiming success.
					di "{err}Could not sample tie weights, check option {bf:weights()}.{txt}"
					error 198
				}
				capture mata: `w' = `w' :/ sum((`weights'))
				if "`undirected'" != "" {
					mata: `w' = lowertriangle(`w',0)
					mata: `w' = `w' + `w''
				}
				capture mata: `__nwnew' = `__nwnew' :* `w'
				capture mata: mata drop `w'
			}
			nwset, mat(`__nwnew') name(`name') `labs' `xvars'

			if "`undirected'" != "" {
				nwsym `dyadname'
			}
		}

	}
	if "`density'" != "" & "`weights'" != "" {
		// BUGFIX: `weights()' was silently ignored here too when
		// density() is also given (a separate code path - see the
		// `density'=="" branch above for the case that's now properly
		// implemented) - implementing weighted sampling for the
		// gsample()-based path is a larger, separate undertaking (it
		// depends on an external SSC package installed at runtime, and
		// needs its own dedicated validation) not attempted in this
		// pass. An honest, clear error is a real improvement over
		// silently producing an unweighted network while claiming
		// weights() was honored.
		di "{err}Option {bf:weights()} combined with {bf:density()} is not yet supported; specify {bf:mat()} instead of {bf:density()} to use weights().{txt}"
		error 198
	}
	if "`density'" != "" {
		// Generate network from weight network
		preserve
		nwset, mat(`mat') name(_tempdyad)
		nwreplace _tempdyad = _tempdyad * 10
		nwtoedge _tempdyad, full

		if "`undirected'" != "" {
			replace _tempdyad = 0 if `nw_alter' <= `nw_ego'
		}

		local ties = `nodes' * (`nodes' -1) * `density'
		if "`undirected'" != "" {
			local ties = `ties' / 2
		}
		qui gen _nonzero = (_tempdyad > 0)
		qui sum _nonzero
		if `r(sum)' < `ties' {
			// BUGFIX: was a bare `exit' (no return code) after dropping
			// the never-completed target network - the message printed
			// but the command returned rc==0 as if nothing were wrong,
			// with no network actually created (same disguised-silent-
			// failure class already fixed elsewhere in this package,
			// see nwrandom.ado's own header comment on its sibling
			// "Could not sample tie weights" bug).
			noi di "{err}Not enough non-zero weights to generate `ties' ties"
			nwdrop _tempdyad
			error 198
		}
		qui drop if `nw_ego' == `nw_alter'
		gsample `ties' [aweight=_tempdyad], generate(link) wor
		// REAL BUG FOUND AND FIXED (docs/ROADMAP.md's own tracked
		// nwhomophily investigation - "homophily(2) and homophily(-2)
		// produce identical output"): this used to hand the selected
		// dyads (`link'==1) to `nwfromedge `nw_ego' `nw_alter' link,
		// name(...)' to build the final network - but `nw_ego'/`nw_alter'
		// here are plain NUMERIC node identifiers (this branch's own
		// `_tempdyad' network was built with no explicit labs(), so
		// nwtoedge's own output carries bare numeric labels), and
		// nwfromedge's own node-ordering assigns each DISTINCT label a
		// position by STRING sort, not numeric sort - confirmed directly
		// (a 20-node network came back node-ordered "n1 n10 n11 ... n19
		// n2 n20 n3 ..."). The weighted sampling above (gsample) was
		// ALSO independently confirmed correct on its own terms (the
		// selected dyads' own mean weight is several times the
		// unselected dyads' mean, exactly as intended) - the bug was
		// entirely in this final reconstruction step silently scrambling
		// which node ends up at which position, decoupling the result
		// from the caller's own original attribute data (nwhomophily's
		// `grp' variable, in observation order) even though the
		// underlying tie-selection mechanism worked correctly the whole
		// time. Fixed by reconstructing the result as a plain matrix
		// directly (Mata `M[ego,alter]=1' per selected row, undirected
		// mirrored) and `nwset, mat()' - matching this SAME program's
		// own already-correct sibling branch just above (the
		// `"`density'"==""' / `mat()'-only path), which already builds
		// its own result this way rather than through nwfromedge, for
		// exactly this reason.
		tempname __densemat
		mata: `__densemat' = J(`nodes', `nodes', 0)
		// `_tempdyad' (just above, `nwset, mat(`mat') name(_tempdyad)'
		// with no explicit labs()) gets nwset's own default node labels
		// - confirmed directly this is "n" + position (e.g. "n1".."n20"
		// for a 20-node network), never bare numeric strings - so the
		// leading "n" is stripped before strtoreal() converts the
		// remainder back to the position it always encodes.
		mata: __nwdp_ego = strtoreal(substr(st_sdata(., "`nw_ego'"), 2, .))
		mata: __nwdp_alt = strtoreal(substr(st_sdata(., "`nw_alter'"), 2, .))
		mata: __nwdp_link = st_data(., "link")
		mata: __nwdp_sel = selectindex(__nwdp_link :== 1)
		mata: for (__nwdp_i=1; __nwdp_i<=rows(__nwdp_sel); __nwdp_i++) `__densemat'[__nwdp_ego[__nwdp_sel[__nwdp_i]], __nwdp_alt[__nwdp_sel[__nwdp_i]]] = 1
		if "`undirected'" != "" {
			mata: `__densemat' = `__densemat' :+ `__densemat''
			mata: `__densemat' = (`__densemat' :> 0)
		}
		mata: mata drop __nwdp_ego __nwdp_alt __nwdp_link __nwdp_sel __nwdp_i
		nwset, mat(`__densemat') name(`name') `labs' `xvars'
		mata: mata drop `__densemat'
		nwdrop _tempdyad
		restore
	}
	
	if "`undirected'" != "" {
		nwsym 
	}
	if "`xvars'" == "" {
		nwload, xvars
	}
	else {
		nwload
	}

end

capture mata: mata drop getNetFromProbs()
capture mata: mata drop transformIntoProbs()

mata:
real matrix getNetFromProbs(real matrix probs) {
	real matrix net
	real scalar nodes
	
	net = J(rows(probs), rows(probs), 0)
	if (rows(probs) == cols(probs)) {
		nodes = rows(probs)
		net = (runiform(rows(probs), cols(probs)):<= probs)	
		_diag(net, 0)
	}
	return(net)
}

real matrix transformIntoProbs(real matrix net) {
	if (max(net) > 1 | min(net) < 0) {
		net = invlogit(net)
		_diag(net,0)
	}
	return(net)
}
end

