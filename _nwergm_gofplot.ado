*! _nwergm_gofplot.ado -- one panel of the estat gof plot
capture program drop _nwergm_gofplot
program define _nwergm_gofplot
	args obsvec summvec xlabel graphname startval ncat lastlabel

	preserve
	qui drop _all
	// Direct st_addvar()/st_store() rather than svmat, whose default
	// column-naming convention (matrix-name plain vs. matrix-name+index)
	// differs depending on whether the source matrix has one column or
	// several - exactly the ambiguity that broke the first attempt at
	// estat mcmcdiag's own plot support. Explicit names throughout here
	// avoids relying on that convention at all.
	mata: st_addobs(`ncat' - st_nobs())
	mata: st_store(., st_addvar("double", "observed"), `obsvec'')
	mata: st_store(., st_addvar("double", "ymin"), `summvec'[.,1])
	mata: st_store(., st_addvar("double", "yp25"), `summvec'[.,2])
	mata: st_store(., st_addvar("double", "ymedian"), `summvec'[.,3])
	mata: st_store(., st_addvar("double", "yp75"), `summvec'[.,4])
	mata: st_store(., st_addvar("double", "ymax"), `summvec'[.,5])
	qui gen xval = `startval' + _n - 1

	local xlabopt ""
	local __lastval = `startval' + `ncat' - 1
	forvalues i = `startval'/`=`__lastval'-1' {
		local xlabopt `"`xlabopt' `i' "`i'""'
	}
	local xlabopt `"`xlabopt' `__lastval' "`lastlabel'""'

	// Grayscale by design, not merely by accident of the default scheme:
	// the Stata Journal requires figures to remain legible in black and
	// white, so the observed-network line is distinguished from the
	// median marker by shape (triangle vs. diamond) and line pattern
	// (dashed vs. solid), not by color - color is not a legend the
	// figure is allowed to depend on.
	twoway (rcap ymin ymax xval, lcolor(gs10)) ///
		(rbar yp25 yp75 xval, barwidth(0.5) fcolor(gs14) lcolor(gs8)) ///
		(scatter ymedian xval, mcolor(black) msymbol(diamond)) ///
		(connected observed xval, lcolor(black) lpattern(dash) mcolor(black) msymbol(triangle)), ///
		xlabel(`xlabopt', angle(45) labsize(vsmall)) ///
		xtitle("`xlabel'") ytitle("Proportion") ///
		title("`xlabel'", size(small)) legend(off) nodraw name(`graphname', replace)
	restore
end
