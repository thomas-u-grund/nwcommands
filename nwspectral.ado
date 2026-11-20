
capture program drop nwspectral
program nwspectral, rclass
	version 12
	syntax [anything(name=netname)][, GENerate(string) bipartition measure(string) replace silent force ONEmode ///
		PLOT EMBedding NAME(string asis) SAVing(string asis) EXPort(string asis) *]
	set more off

	// plot: scree of the Laplacian eigenvalues (embedding adds the picture of the 2nd and 3rd eigenvector)
	_nw_gfinish check, plot(`plot') name(`name') saving(`saving') export(`export') gopts(`"`options'"') default(spectral) cmd(nwspectral)
	local __gname `"`r(name)'"'
	local __gsv `"`r(saving)'"'
	local __gex `"`r(export)'"'
	if "`embedding'" != "" & "`plot'" == "" {
		di as err "{p 0 0 2}nwspectral: option {bf:embedding} needs {bf:plot}.{p_end}"
		exit 198
	}

	_nwsyntax `netname', max(1)
	if "`plot'" != "" {
		if "`is2mode'" == "true" {
			di as err "{p 0 0 2}nwspectral: {bf:plot} is not available for the two-mode network {bf:`netname'}: the eigenvalues belong to the Laplacian of the bipartite graph read as a one-mode graph. Use a one-mode network (for example from {help nw2project}).{p_end}"
			exit 198
		}
		if "`directed'" == "true" {
			di as err "{p 0 0 2}nwspectral: {bf:plot} needs an undirected network (the Laplacian spectrum is that of a symmetric matrix); {bf:`netname'} is directed. Symmetrize it first with {help nwsym}.{p_end}"
			exit 198
		}
		if "`embedding'" != "" & `nodes' < 3 {
			di as err "{p 0 0 2}nwspectral: {bf:embedding} needs at least 3 nodes.{p_end}"
			exit 198
		}
	}
	_nw2guard `netname', cmd(nwspectral) allowone `onemode'
	local __nw1m = r(copied)
	local __origname "`netname'"
	local netname "`r(net)'"
	_nwsyntax `netname'

	local netmeasure "`measure'"
	if "`netmeasure'" == "" {
		if "`valued'" == "true" {
			local netmeasure "valued"
		}
		else {
			local netmeasure "binary"
		}
	}
	_opts_oneof "binary valued" "measure" "`netmeasure'" 6556
	local val = ("`netmeasure'" == "valued")

	if "`generate'" == "" {
		di "{err}option {bf:generate()} required."
		exit 198
	}
	local netgenerate "`generate'"
	local signvar = "`netgenerate'" + "sign"

	capture confirm variable `netgenerate', exact
	if _rc == 0 & "`replace'" == "" {
		noi di "{err}Variable {bf:`netgenerate'} already exists; specify {bf:replace}"
		exit 110
	}
	if "`bipartition'" != "" {
		capture confirm variable `signvar', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`signvar'} already exists; specify {bf:replace}"
			exit 110
		}
	}

	// BUGFIX: a single-node network's Laplacian is a 1x1 matrix with
	// only one eigenvalue, but this command's own algebraic-connectivity
	// step below unconditionally indexes the SECOND eigenvalue
	// (`__nw_EV'[1,2]', the Fiedler value) - crashing with a raw,
	// uncaught Mata "subscript invalid" (r3301) instead of a clean,
	// validated error. Sibling command nwhierarchy already handles the
	// identical degenerate input cleanly (via clustermat's own "1x1
	// matrix not allowed" error); nwspectral had no equivalent guard at
	// all.
	if `nodes' < 2 {
		di "{err}{p 0 0 2}Network {bf:`netname'} has fewer than 2 nodes; spectral decomposition needs at least 2 nodes.{p_end}"
		exit 198
	}

	// the complete eigendecomposition of the dense Laplacian is O(n^3): 5,000 nodes take about 4 minutes, 10,000 nodes
	// more than 30 minutes and 3 GB (measured 1,000 nodes 1.5 s, 2,000 14 s, 3,000 50 s)
	if `nodes' > 6000 & "`force'" == "" {
		di "{err}{p 0 0 2}nwspectral decomposes the complete dense `nodes' x `nodes' Laplacian completely: about `=round(50*(`nodes'/3000)^3/60)' minutes and `=round(`nodes'^2*8*4/1e9, .1)' GB. It is refused above 6,000 nodes; option {bf:force} runs it anyway.{p_end}"
		exit 484
	}

	mata: st_rclear()
	qui if _N < `nodes' {
		set obs `nodes'
	}
	// align row i of the data set with node i of the network before the positional
	// read/write below (see nwcommunity.ado)
	_nwsyncrows `netname'
	mata: st_rclear()
	_nwsyntax `netname', max(1)

	tempname __nw_L __nw_EC __nw_EV __nw_ord __nw_fiedler
	// the complete eigendecomposition of the dense Laplacian is O(n^3)
	// (measured in Stata/BE: 1,000 nodes 1.5 s, 5,000 nodes about 3 minutes)
	if "`silent'" == "" & `nodes' > 2000 {
		di "{txt}{p 0 0 2}(note: nwspectral decomposes the dense `nodes' x `nodes' Laplacian completely and takes minutes above about 4,000 nodes){p_end}"
	}
	mata: `__nw_L' = `netobj'->calculate_laplacian(`val')
	mata: symeigensystem(`__nw_L', `__nw_EC' = ., `__nw_EV' = .)
	mata: `__nw_ord' = order((`__nw_EV'', (1::cols(`__nw_EV'))), (1, 2))
	mata: `__nw_EV' = (`__nw_EV''[`__nw_ord'])'
	mata: `__nw_EC' = `__nw_EC'[.,`__nw_ord']
	mata: st_matrix("nw_spectral_eigenvalues", `__nw_EV')
	mata: st_numscalar("nw_spectral_components", sum(abs(`__nw_EV') :< 1E-8))
	mata: st_numscalar("nw_spectral_algconn", `__nw_EV'[1,2])
	mata: `__nw_fiedler' = `__nw_EC'[.,2]
	if "`embedding'" != "" {
		mata: st_matrix("nw_spectral_embed", `__nw_EC'[.,(2,3)])
	}

	capture confirm new variable `netgenerate'
	if _rc capture drop `netgenerate'
	qui gen `netgenerate' = .
	mata: st_store((1::`nodes'), "`netgenerate'", `__nw_fiedler')
	if "`bipartition'" != "" {
		capture drop `signvar'
		qui gen `signvar' = .
		mata: st_store((1::`nodes'), "`signvar'", sign(`__nw_fiedler'))
	}
	mata: mata drop `__nw_L' `__nw_EC' `__nw_EV' `__nw_ord' `__nw_fiedler'

	tempname __ev
	if "`plot'" != "" matrix `__ev' = nw_spectral_eigenvalues'
	return scalar algebraic_connectivity = nw_spectral_algconn
	return scalar components = nw_spectral_components
	return matrix eigenvalues = nw_spectral_eigenvalues
	local lalgconn = nw_spectral_algconn
	local lcomponents = nw_spectral_components

	// see nwbrokerage.ado's own header comment: the "already exists"
	// probes above leave _rc stale even after a fully successful run -
	// reset explicitly and silently.
	capture confirm variable `netgenerate', exact

	if `__nw1m' local netname "`__origname'"
	if "`silent'" == "" {
		noi di "{hline 40}"
		noi di "{txt}  Network name: {res}`netname'"
		noi di "{txt}  Connected components: {res}`lcomponents'"
		noi di "{txt}  Algebraic connectivity: {res}`=strtrim(string(round((`lalgconn')*1000)/1000,"%9.0g"))'"
		noi sum `netgenerate'
		noi di " "
	}
	if `__nw1m' capture nwdrop __nw1m
	if "`plot'" != "" {
		_nwspectral_plot `__ev', netname(`netname') name(`__gname') nodes(`nodes') measure(`netmeasure') ///
			`=cond("`embedding'" != "", "embed(nw_spectral_embed)", "")' saving(`"`__gsv'"') export(`"`__gex'"') gopts(`"`options'"')
		capture matrix drop nw_spectral_embed
	}
end

// the scree of the Laplacian eigenvalues (ascending: the second is the algebraic connectivity); embedding: the second and third
// eigenvector, the markers show the sign of the second (the bipartition)
capture program drop _nwspectral_plot
program _nwspectral_plot
	version 15
	syntax anything(name=ev), NETname(string) NAME(string) NODES(integer) MEASure(string) [EMBed(name) SAVing(string asis) EXPort(string asis) GOPTS(string asis)]
	if strpos(`"`gopts'"', char(96) + char(34)) == 1 gettoken gopts : gopts
	local lap = cond("`measure'" == "valued", "valued Laplacian", "Laplacian")
	tempname gs ge
	preserve
	quietly {
		drop _all
		svmat double `ev', names(__e)
		generate double __k = _n
		replace __e1 = 0 if abs(__e1) < 1e-9
		if "`embed'" != "" {
			svmat double `embed', names(__m)
			rename __m1 __x
			rename __m2 __y
			generate byte __s = (__x >= 0)
		}
	}
	local np = cond("`embed'" != "", 2, 1)
	local gs0 `name'
	local gopt1 `"`gopts'"'
	local nodraw ""
	if `np' == 2 {
		local gs0 `gs'
		local gopt1 ""
		local nodraw "nodraw"
	}
	_nw_gfinish blk "Index of the eigenvalue", kind(xtitle) gopts(`"`gopt1'"')
	local xt `"`r(t)'"'
	_nw_gfinish blk "Eigenvalue of the `lap'", kind(ytitle) gopts(`"`gopt1'"')
	local yt `"`r(t)'"'
	if `np' == 2 _nw_gfinish title "Eigenvalues", size(medsmall)
	else _nw_gfinish title "Laplacian eigenvalues: `netname'", gopts(`"`gopts'"')
	local tt `"`r(t)'"'
	local stp = 5 * ceil(`nodes' / 50)
	local xl "xlabel(1 `stp'(`stp')`nodes', format(%9.0f))"
	if `nodes' <= 15 local xl "xlabel(1(1)`nodes', format(%9.0f))"
	quietly twoway (connected __e1 __k, msymbol(O) msize(small) lcolor(gs8) mcolor(gs4) lwidth(thin)) ///
		(scatter __e1 __k if __k == 2, msymbol(D) msize(medlarge) mcolor(black) mlabel(__e1) mlabformat(%5.3f) mlabposition(12) mlabgap(*6) mlabcolor(black)), ///
		legend(order(2 "Algebraic connectivity") position(6) size(vsmall) region(lcolor(none)) ///
		title("", size(small))) ylabel(, angle(0)) `xl' `xt' `yt' `tt' graphregion(color(white)) `nodraw' name(`gs0', replace) `gopt1'
	if `np' == 2 {
		_nw_gfinish blk "Second eigenvector", kind(xtitle)
		local xt2 `"`r(t)'"'
		_nw_gfinish blk "Third eigenvector", kind(ytitle)
		local yt2 `"`r(t)'"'
		_nw_gfinish title "Spectral embedding", size(medsmall)
		quietly twoway (scatter __y __x if __s == 1, msymbol(O) mcolor(gs4) msize(medsmall)) ///
			(scatter __y __x if __s == 0, msymbol(Dh) mcolor(gs4) mlcolor(gs4) msize(medsmall)), ///
			legend(order(1 "2nd eigenvector >= 0" 2 "2nd eigenvector < 0") position(6) rows(2) size(vsmall) symxsize(*0.6) region(lcolor(none))) ///
			ylabel(, angle(0) format(%4.2f)) `xt2' `yt2' `r(t)' graphregion(color(white)) nodraw name(`ge', replace)
		_nw_gfinish title "Spectral decomposition: `netname'", gopts(`"`gopts'"')
		graph combine `gs' `ge', cols(2) `r(t)' graphregion(color(white)) name(`name', replace) `gopts'
		graph drop `gs' `ge'
	}
	restore
	_nw_gfinish save, name(`name') saving(`"`saving'"') export(`"`export'"')
end
