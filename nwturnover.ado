
capture program drop nwturnover
program nwturnover, rclass
	version 12
	syntax anything(name=netnames) [, GENerate(string) REPlace silent]
	set more off

	_nwsyntax `netnames', max(2) min(2)
	local netname1 : word 1 of `netname'
	local netname2 : word 2 of `netname'
	local __vnquiet = cond("`silent'" != "", "quiet", "")
	local __vndone 0
	foreach __vn in `netname1' `netname2' {
		if `__vndone' == 0 {
			_nwvaluednote `__vn', `__vnquiet'
			if r(shown) == 1 {
				noi di `"`r(msg)'"'
				local __vndone 1
			}
		}
	}

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

	// a two-mode network holds MISSING in the blocks inside a mode (no tie can exist there); a copy with 0 there
	// counts only the ties between the modes (missing != 0 would be read as a tie that is in both networks)
	local orig1 "`netname1'"
	local orig2 "`netname2'"
	local made2 0
	foreach __k in 1 2 {
		_nwsyntax `netname`__k''
		if "`is2mode'" == "true" {
			capture nwdrop __nwt`__k'
			qui nwduplicate `netname`__k'', name(__nwt`__k')
			qui _nwsyntax __nwt`__k'
			mata: `netobj'->set_2mode(0)
			mata: `netobj'->set_edge(editmissing(*`netobj'->get_matrix(), 0))
			local netname`__k' "__nwt`__k'"
			local made2 1
		}
	}
	if `made2' qui nwcurrent `orig1'

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
	// align row i of the data set with node i of the network before the positional
	// read/write below (see nwcommunity.ado)
	_nwsyncrows `netname1'
	mata: st_rclear()
	_nwsyntax `netname1'
	local netobj1 `netobj'
	_nwsyntax `netname2'
	local netobj2 `netobj'

	tempname __nw_pernode __nw_turnrate
	mata: `__nw_pernode' = nw_turnover_counts(`netobj1', `netobj2', `isdirected')

	local divisor = cond(`isdirected', 1, 2)
	mata: st_numscalar("nw_stable", sum(`__nw_pernode'[.,1]) / `divisor')
	mata: st_numscalar("nw_formed", sum(`__nw_pernode'[.,2]) / `divisor')
	mata: st_numscalar("nw_dissolved", sum(`__nw_pernode'[.,3]) / `divisor')

	mata: `__nw_turnrate' = J(`nodes1', 1, .)
	mata: __nwturnover_denom_total = rowsum(`__nw_pernode')
	mata: `__nw_turnrate'[selectindex(__nwturnover_denom_total :> 0)] = `__nw_pernode'[selectindex(__nwturnover_denom_total :> 0),1] :/ __nwturnover_denom_total[selectindex(__nwturnover_denom_total :> 0)]
	mata: mata drop __nwturnover_denom_total

	capture confirm new variable `netgenerate'
	if _rc capture drop `netgenerate'
	qui gen `netgenerate' = .
	mata: st_store((1::`nodes1'), "`netgenerate'", `__nw_turnrate')
	mata: mata drop `__nw_pernode' `__nw_turnrate'

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
	capture nwdrop __nwt1
	capture nwdrop __nwt2
	capture confirm variable `netgenerate', exact

	if "`silent'" == "" {
		noi di "{hline 40}"
		noi di "{txt}  Networks: {res}`orig1'{txt} -> {res}`orig2'"
		noi di "{txt}  Stable: {res}`=nw_stable'{txt}  Formed: {res}`=nw_formed'{txt}  Dissolved: {res}`=nw_dissolved'"
		noi di "{txt}  Jaccard index: {res}`=strtrim(string(round((`jaccard')*1000)/1000,"%9.0g"))'"
		if `persistdenom' > 0 {
			noi di "{txt}  Persistence: {res}`=strtrim(string(round((`persistence')*1000)/1000,"%9.0g"))'"
		}
		noi di " "
	}
	capture mata: mata drop __nwturnover_*
	capture confirm number 0
end
