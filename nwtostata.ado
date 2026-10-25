capture program drop nwtostata
program nwtostata
version 9
syntax, mat(string) [ gen(namelist min=1) stub(string) ]

	mata: st_numscalar("r(rows)", rows(`mat'))
	local rows = r(rows)
	if `rows' > `=_N' {
		set obs `rows'
	}
	// BUGFIX: referenced the undefined local `sub' (the real option is
	// named `stub') so this was always a no-op regardless of whether
	// both gen()/stub() were actually specified - caused no user-
	// visible defect only because the manual check immediately below
	// already enforces the real mutual exclusivity correctly.
	opts_exclusive "`"`gen'"' `"`stub'"'"
	
	if "`gen'" != "" & "`stub'" != "" {
		dis as error "Either option gen or option stub needs to be specified, but not both."
		error 184
	}
	
	
	if "`gen'" == "" & "`stub'" == "" {
		dis as error "Either option gen or option stub needs to be specified."
		error 198
	}

	if "`gen'" != "" {
		foreach x of newlist `gen' {
			quietly gen `x' = .
		}
		mata: st_view(nwtostataview=.,(1,rows(`mat')),tokens("`gen'"))
	}
	
	if "`stub'" != "" {
		mata: st_numscalar("r(cols)", cols(`mat'))
		local cols = r(cols)
		// each column becomes a Stata variable: fail early and clearly when the flavour cannot hold them
		if `cols' + c(k) > c(max_k_theory) {
			dis as error "nwtostata would create `cols' variables, but `c(flavor)' Stata allows at most `c(max_k_theory)' variables (`c(k)' in use)."
			dis as error "Use the Mata matrix directly (nwtomata) or a larger Stata flavour."
			error 900
		}
		forvalues i = 1/`cols' {
			quietly gen `stub'`i' =.
		}
		unab vars : `stub'*
		mata: st_view(nwtostataview=.,(1,rows(`mat')),tokens("`vars'"))
	}
	mata: nwtostataview[.,.] = `mat'
	capture quietly compress `gen'
	capture quietly compress `stub'*
	mata: mata drop nwtostataview
end
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
