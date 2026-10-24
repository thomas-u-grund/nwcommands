*! version 0.1.0 23oct2026 nwcommands: nwsaom describe - the data description that comes before a SAOM fit
/*
	nwsaom describe, waves(net1 net2 ...) [behavior(var1 var2 ...)]

	What RSiena prints before estimation (its data report): for every wave the number of
	ties, the density and the average degree; for every period the numbers of ties created,
	dissolved and kept, the Jaccard index and the Hamming distance; for a behavior the mean
	and the numbers of actors who move up, down or stay between the waves. The Jaccard
	index of a period is kept / (kept + created + dissolved); RSiena's rule of thumb is
	that values below about 0.3 give little information about the process.
*/
capture program drop nwsaom_describe
program define nwsaom_describe, rclass
	version 14
	syntax , WAVES(string) [ BEHavior(string) ]
	local nw : word count `waves'
	if `nw' < 2 {
		di as err "waves() needs at least two networks."
		exit 198
	}
	tempname P W
	local n0 = .
	matrix `P' = J(`=`nw'-1', 6, .)
	matrix `W' = J(`nw', 3, .)
	forvalues w = 1/`nw' {
		local nm : word `w' of `waves'
		_nwsyntax `nm', max(1)
		local nodes`w' = `nodes'
		local dir`w' = ("`directed'" == "true")
		local obj`w' `netobj'
		if `w' == 1 local n0 = `nodes'
		if `nodes' != `n0' {
			di as err "all waves need the same number of nodes."
			exit 198
		}
		if `dir`w'' != `dir1' {
			di as err "all waves must be directed or all undirected."
			exit 198
		}
	}
	local div = cond(`dir1', 1, 2)
	tempname MA MB
	forvalues w = 1/`nw' {
		mata: `MA' = (*`obj`w''->get_matrix_mod(0, `dir1')) :!= 0
		mata: _diag(`MA', 0)
		mata: st_numscalar("__nwsd_ties", sum(`MA') / `div')
		local ties = scalar(__nwsd_ties)
		matrix `W'[`w', 1] = `ties'
		matrix `W'[`w', 2] = `ties' / (`n0' * (`n0' - 1) / `div')
		matrix `W'[`w', 3] = `ties' * `div' / `n0'
	}
	forvalues w = 1/`=`nw'-1' {
		local w2 = `w' + 1
		mata: `MA' = (*`obj`w''->get_matrix_mod(0, `dir1')) :!= 0
		mata: `MB' = (*`obj`w2''->get_matrix_mod(0, `dir1')) :!= 0
		mata: _diag(`MA', 0)
		mata: _diag(`MB', 0)
		mata: st_numscalar("__nwsd_k", sum(`MA' :& `MB') / `div')
		mata: st_numscalar("__nwsd_c", sum(!`MA' :& `MB') / `div')
		mata: st_numscalar("__nwsd_d", sum(`MA' :& !`MB') / `div')
		local kept = scalar(__nwsd_k)
		local cre = scalar(__nwsd_c)
		local dis = scalar(__nwsd_d)
		matrix `P'[`w', 1] = `kept'
		matrix `P'[`w', 2] = `cre'
		matrix `P'[`w', 3] = `dis'
		matrix `P'[`w', 4] = cond(`kept' + `cre' + `dis' > 0, `kept' / (`kept' + `cre' + `dis'), .)
		matrix `P'[`w', 5] = `cre' + `dis'
		matrix `P'[`w', 6] = cond(`kept' + `dis' > 0, `kept' / (`kept' + `dis'), .)
	}
	capture mata: mata drop `MA' `MB'
	di
	di as txt "Network data: " as res `nw' as txt " waves, " as res `n0' as txt " actors, " as res cond(`dir1', "directed", "undirected")
	di as txt "{hline 58}"
	di as txt %-8s "wave" %10s "ties" %12s "density" %14s "avg. degree"
	forvalues w = 1/`nw' {
		di as res %-8s "`w'" %10.0f `W'[`w', 1] %12.4f `W'[`w', 2] %14.3f `W'[`w', 3]
	}
	di as txt "{hline 58}"
	di as txt %-8s "period" %8s "kept" %9s "created" %10s "dissolved" %9s "Jaccard" %10s "Hamming"
	forvalues w = 1/`=`nw'-1' {
		di as res %-8s "`w'->`=`w'+1'" %8.0f `P'[`w', 1] %9.0f `P'[`w', 2] %10.0f `P'[`w', 3] %9.3f `P'[`w', 4] %10.0f `P'[`w', 5]
		if `P'[`w', 4] < 0.3 di as txt "  (Jaccard below 0.3: few ties stay, so the data say little about the change process; see the SAOM literature)"
	}
	di as txt "{hline 58}"
	matrix colnames `P' = kept created dissolved jaccard hamming persistence
	matrix colnames `W' = ties density avgdegree
	return matrix periods = `P'
	return matrix waves = `W'
	if "`behavior'" != "" {
		local nb : word count `behavior'
		if `nb' != `nw' {
			di as err "behavior() needs one variable per wave (`nw')."
			exit 198
		}
		tempname Bh
		matrix `Bh' = J(`nw', 3, .)
		di as txt %-8s "wave" %12s "mean" %12s "sd" %10s "missing"
		forvalues w = 1/`nw' {
			local v : word `w' of `behavior'
			qui count if missing(`v') in 1/`n0'
			local nmiss = r(N)
			qui summarize `v' in 1/`n0'
			matrix `Bh'[`w', 1] = r(mean)
			di as res %-8s "`w'" %12.3f r(mean) %12.3f r(sd) %10.0f `nmiss'
		}
		tempname Bc
		matrix `Bc' = J(`=`nw'-1', 3, .)
		di as txt "{hline 58}"
		di as txt %-8s "period" %10s "up" %10s "down" %10s "same"
		forvalues w = 1/`=`nw'-1' {
			local v1 : word `w' of `behavior'
			local v2 : word `=`w'+1' of `behavior'
			qui count if `v2' > `v1' & !missing(`v1', `v2') in 1/`n0'
			local up = r(N)
			qui count if `v2' < `v1' & !missing(`v1', `v2') in 1/`n0'
			local dn = r(N)
			qui count if `v2' == `v1' & !missing(`v1', `v2') in 1/`n0'
			local sm = r(N)
			matrix `Bc'[`w', 1] = `up'
			matrix `Bc'[`w', 2] = `dn'
			matrix `Bc'[`w', 3] = `sm'
			di as res %-8s "`w'->`=`w'+1'" %10.0f `up' %10.0f `dn' %10.0f `sm'
		}
		matrix colnames `Bc' = up down same
		return matrix behchange = `Bc'
	}
	capture scalar drop __nwsd_ties __nwsd_k __nwsd_c __nwsd_d
end
