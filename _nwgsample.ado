*! version 3.1.1  24oct2026
// _nwgsample: built-in replacement for the one use nwdyadprob makes of the
// user-written -gsample- (SSC, Ben Jann): weighted sampling WITHOUT
// replacement of n observations, with inclusion probabilities
// n*w/sum(w), returning a 0/1 indicator variable. Same algorithm as
// -gsample ..., wor generate()- (random order of the observations, then
// systematic sampling along the cumulated normalised weights), same use of
// the uniform() stream, same errors; so it gives the same sample as the
// real package for the same seed. No external package is needed.
program define _nwgsample
	version 14
	syntax anything(name=n id="sample size") [if] [in] [aw iw], Generate(name)

	confirm new variable `generate'
	capture confirm number `n'
	if _rc {
		di as err "n must be a number"
		exit 198
	}
	if `n' < 0 {
		di as err "n must be 0 or larger"
		exit 198
	}
	local n = round(`n')

	marksample touse, zeroweight
	qui count if `touse'
	local N = r(N)
	if `N' == 0 error 2000

	tempvar wgt
	qui generate double `wgt' `exp' if `touse'
	capture assert (`wgt' >= 0) if `touse'
	if _rc error 402
	capture assert (`wgt' == 0) if `touse'
	if _rc == 0 {
		di as err "weights all zero"
		exit 499
	}

	tempname W P UB R
	tempvar ind
	qui generate long `ind' = 0
	if `N' == 1 {
		// a single observation: no sampling (as in -gsample-)
		if `n' > 1 {
			di as err "n may not be larger than N"
			exit 3300
		}
		qui replace `ind' = `n' if `touse'
	}
	else {
		if `n' > `N' {
			di as err "n may not be larger than rows(w)"
			exit 3300
		}
		mata: `W' = st_data(., "`wgt'", "`touse'")
		mata: `P' = order(uniform(`N', 2), (1, 2))
		mata: `UB' = `W'[`P'] / colsum(`W') * `n'
		mata: st_local("z", strofreal(colsum(`UB' :> 1)))
		if `z' == 1 {
			mata: mata drop `W' `P' `UB'
			di as err "1 case has w_i*n/sum(w)>1"
			exit 3300
		}
		if `z' > 1 {
			mata: mata drop `W' `P' `UB'
			di as err "`z' cases have w_i*n/sum(w)>1"
			exit 3300
		}
		mata: `UB' = runningsum(`UB')
		// systematic sampling: the n points u, u+1, ..., u+n-1 (u uniform)
		// fall into the bins of the cumulated weights `UB'; the count in
		// bin m is the number of points in (UB[m-1], UB[m]]. Done by
		// sorting points and bin bounds together (points first on ties,
		// as in "first bin whose bound is >= the point").
		mata: _nwgs_u = uniform(1, 1)
		mata: `R' = (`n' > 0 ? runningsum((_nwgs_u \ J(max((`n' - 1, 0)), 1, 1))) : J(0, 1, 0))
		mata: _nwgs_f = (J(rows(`R'), 1, 0) \ J(`N', 1, 1)); _nwgs_o = order(((`R' \ `UB'), _nwgs_f), (1, 2)); _nwgs_f = _nwgs_f[_nwgs_o]
		mata: `R' = select(runningsum(1 :- _nwgs_f), _nwgs_f :== 1)
		mata: `R' = `R' - (0 \ `R'[|1 \ `N' - 1|])
		mata: `R' = `R'[invorder(`P')]
		mata: st_store(., "`ind'", "`touse'", `R')
		mata: mata drop `W' `P' `UB' `R' _nwgs_u _nwgs_f _nwgs_o
	}
	rename `ind' `generate'
end
