
capture program drop nwturnover
program nwturnover, rclass
	version 12
	syntax anything(name=netnames) [, GENerate(string) REPlace silent FORMation]
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

	// formation (3.20.1): two-paths and returned ties are defined inside one mode only
	if "`formation'" != "" {
		foreach __k in 1 2 {
			_nwsyntax `netname`__k''
			if "`is2mode'" == "true" {
				di "{err}option {bf:formation} is not available for two-mode networks."
				error 198
			}
		}
	}

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

	// formation (3.20.1): among the ties formed, the share that return a tie of net1 (j had named i)
	// and the share that close a two-path of net1 (i -> k -> j); the same shares among all pairs
	// without a tie in net1, from which every formed tie comes
	if "`formation'" != "" {
		tempname __nw_form
		mata: `__nw_form' = nw_turnover_formation(*`netobj1'->get_matrix(), *`netobj2'->get_matrix())
		mata: st_local("f_n", strofreal(`__nw_form'[1]))
		mata: st_local("f_rec", strofreal(`__nw_form'[2], "%18.0g"))
		mata: st_local("f_clo", strofreal(`__nw_form'[3], "%18.0g"))
		mata: st_local("a_n", strofreal(`__nw_form'[4]))
		mata: st_local("a_rec", strofreal(`__nw_form'[5], "%18.0g"))
		mata: st_local("a_clo", strofreal(`__nw_form'[6], "%18.0g"))
		mata: mata drop `__nw_form'
		if !`isdirected' {
			local f_n = `f_n' / 2
			local a_n = `a_n' / 2
		}
	}

	return scalar stable = nw_stable
	return scalar formed = nw_formed
	return scalar dissolved = nw_dissolved
	return scalar jaccard = `jaccard'
	return scalar persistence = `persistence'

	if "`formation'" != "" {
		return scalar absent = `a_n'
		return scalar formed_closure = `f_clo'
		return scalar absent_closure = `a_clo'
		if `isdirected' {
			return scalar formed_recip = `f_rec'
			return scalar absent_recip = `a_rec'
		}
	}

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
		if "`formation'" != "" {
			noi di " "
			noi di "{txt}  Formed ties, compared with all pairs without a tie in {res}`orig1'{txt}:"
			noi di "{txt}{col 26}{ralign 10:Formed}{ralign 10:No tie}"
			noi di "{txt}    Pairs{col 26}{res}{ralign 10:`=string(`f_n', "%9.0f")'}{ralign 10:`=string(`a_n', "%9.0f")'}"
			if `isdirected' {
				noi di "{txt}    Return a tie{col 26}{res}{ralign 10:`=string(`f_rec', "%9.3f")'}{ralign 10:`=string(`a_rec', "%9.3f")'}"
			}
			noi di "{txt}    Close a two-path{col 26}{res}{ralign 10:`=string(`f_clo', "%9.3f")'}{ralign 10:`=string(`a_clo', "%9.3f")'}"
		}
		noi di " "
	}
	capture mata: mata drop __nwturnover_*
	capture confirm number 0
end

capture mata: mata drop nw_turnover_formation()
mata:
// (formed, share returning, share closing, absent, share returning, share closing); a missing
// entry counts as no tie, and the diagonal is never a pair
real rowvector nw_turnover_formation(real matrix A10, real matrix A20)
{
	real matrix A1, A2, ab, f, r, c
	real scalar nf, na

	A1 = (editmissing(A10, 0) :!= 0)
	A2 = (editmissing(A20, 0) :!= 0)
	_diag(A1, 0)
	_diag(A2, 0)
	ab = (A1 :== 0)
	_diag(ab, 0)
	f = ab :* A2
	r = A1'
	c = ((A1 * A1) :> 0)
	nf = sum(f)
	na = sum(ab)
	return((nf, (nf ? sum(f :* r) / nf : .), (nf ? sum(f :* c) / nf : .),
		na, (na ? sum(ab :* r) / na : .), (na ? sum(ab :* c) / na : .)))
}
end
