
capture program drop nwturnover
program nwturnover, rclass
	version 12
	syntax anything(name=netnames) [, GENerate(string) REPlace silent]
	set more off

	_nwsyntax `netnames', max(2) min(2)
	local netname1 : word 1 of `netname'
	local netname2 : word 2 of `netname'

	_nwsyntax `netname1'
	local nodes1 `nodes'
	local directed1 `directed'
	local netobj1 `netobj'

	_nwsyntax `netname2'
	local nodes2 `nodes'
	local directed2 `directed'
	local netobj2 `netobj'

	if `nodes1' != `nodes2' {
		di "{err}Networks of different size."
		error 6056
	}
	if "`directed1'" != "`directed2'" {
		di "{err}{bf:`netname1'} and {bf:`netname2'} must both be directed or both be undirected."
		error 198
	}
	local isdirected = ("`directed1'" == "true")

	if "`generate'" == "" {
		di "{err}option {bf:generate()} required."
		error 198
	}
	local netgenerate "`generate'"
	capture confirm variable `netgenerate', exact
	if _rc == 0 & "`replace'" == "" {
		noi di "{err}Variable {bf:`netgenerate'} already exists; specify {bf:replace}"
		err 99
	}

	mata: st_rclear()
	qui if _N < `nodes1' {
		set obs `nodes1'
	}
	_nwsyntax `netname1'
	local netobj1 `netobj'
	_nwsyntax `netname2'
	local netobj2 `netobj'

	tempname __nw_A1 __nw_A2 __nw_pernode __nw_turnrate
	mata: `__nw_A1' = (*`netobj1'->get_matrix_mod(0,`isdirected')) :!= 0
	mata: `__nw_A2' = (*`netobj2'->get_matrix_mod(0,`isdirected')) :!= 0
	mata: _diag(`__nw_A1', 0)
	mata: _diag(`__nw_A2', 0)

	mata: `__nw_pernode' = J(`nodes1', 3, 0)
	mata: `__nw_pernode'[.,1] = rowsum(`__nw_A1' :& `__nw_A2')
	mata: `__nw_pernode'[.,2] = rowsum(`__nw_A2' :& !`__nw_A1')
	mata: `__nw_pernode'[.,3] = rowsum(`__nw_A1' :& !`__nw_A2')

	local divisor = cond(`isdirected', 1, 2)
	mata: st_numscalar("nw_stable", sum(`__nw_pernode'[.,1]) / `divisor')
	mata: st_numscalar("nw_formed", sum(`__nw_pernode'[.,2]) / `divisor')
	mata: st_numscalar("nw_dissolved", sum(`__nw_pernode'[.,3]) / `divisor')

	mata: `__nw_turnrate' = J(`nodes1', 1, .)
	mata: nw_denom_total = rowsum(`__nw_pernode')
	mata: `__nw_turnrate'[selectindex(nw_denom_total :> 0)] = `__nw_pernode'[selectindex(nw_denom_total :> 0),1] :/ nw_denom_total[selectindex(nw_denom_total :> 0)]
	mata: mata drop nw_denom_total

	capture drop `netgenerate'
	qui gen `netgenerate' = .
	mata: st_store((1::`nodes1'), "`netgenerate'", `__nw_turnrate')
	mata: mata drop `__nw_A1' `__nw_A2' `__nw_pernode' `__nw_turnrate'

	local total = nw_stable + nw_formed + nw_dissolved
	local jaccard = cond(`total' > 0, nw_stable / `total', .)
	local persistdenom = nw_stable + nw_dissolved
	local persistence = cond(`persistdenom' > 0, nw_stable / `persistdenom', .)

	return scalar stable = nw_stable
	return scalar formed = nw_formed
	return scalar dissolved = nw_dissolved
	return scalar jaccard = `jaccard'
	return scalar persistence = `persistence'

	// see nwbrokerage.ado's own header comment: the "already exists"
	// probe above leaves _rc stale even after a fully successful run -
	// reset explicitly and silently.
	capture confirm variable `netgenerate', exact

	if "`silent'" == "" {
		noi di "{hline 40}"
		noi di "{txt}  Networks: {res}`netname1'{txt} -> {res}`netname2'"
		noi di "{txt}  Stable: {res}`=nw_stable'{txt}  Formed: {res}`=nw_formed'{txt}  Dissolved: {res}`=nw_dissolved'"
		noi di "{txt}  Jaccard index: {res}`=round(`jaccard',0.001)'"
		if `persistdenom' > 0 {
			noi di "{txt}  Persistence: {res}`=round(`persistence',0.001)'"
		}
		noi di " "
	}
end
