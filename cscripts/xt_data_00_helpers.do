* xt_data_00_helpers.do
* Shared helper programs and Mata functions for the extended data-management suite cscripts/xt_data_*.do
* (creating, importing, exporting and changing networks).
*
* Use:  clear all  first (it drops programs), then
*           run cscripts/xt_data_00_helpers.do
*           xt_init <filename>
*       ... checks with xt_chk ...
*           xt_end
*           di "ALL PASS"
*
* xt_chk does not stop at the first failure: it counts failures, and xt_end stops with r(9) and lists every
* failed check. A label that starts with [policy] marks a check of behaviour the author of the suite expects
* (help file, registry of error codes in unw_defs.ado, or the conventions in GOTCHA.md) where the code
* currently does something else or is silent; the owner decides. [suspected] marks a check written against a
* suspected bug found while reading the code (see cscripts/xt_data_NOTES.md).
*
* Programs:
*   xt_init name           reset the failure counter
*   xt_chk ok "label"      ok must be the text 1 (use `=(expression)'); anything else is a failure, except
*                          for a label starting with [policy]: listed by xt_end, but not a failure
*   xt_end                 stop with r(9) if any check failed
*   xt_snap tag            snapshot of _N, c(k), datasignature, the list of networks, their matrices and metadata
*   xt_same tag "label" [nosig]  compare the current state with snapshot tag (one check per component);
*                          nosig: without the data signature (rows re-sorted by the documented data sync)
*   xt_hasnet net          c_local has = 1 if a network of exactly that name exists (no abbreviation)
*   xt_mat net mname       Mata matrix mname = matrix of net, missing set to 0, diagonal set to 0
*   xt_rmark / xt_emark    put known values into r() / e()
*   xt_rcheck "label"      check that the r() and e() of xt_rmark / xt_emark are still there
*   xt_nostray "label"     check that no r(nodes), r(id), r(netname), r(networks) is left behind
* Mata:
*   xt_od(M)               missing -> 0, diagonal -> 0
*   xt_toks(s)             "a,b,c" -> ("a","b","c")
*   xt_nuniq(s)            number of distinct labels in a comma list
*   xt_sorteq(s1, s2)      1 if the two comma lists hold the same labels (any order)
*   xt_reorder(M, l, ref)  M (whose nodes are labelled l) permuted into the node order of ref; J(0,0,.) if the
*                          label sets differ
*   xt_edgebad(M, E)       number of rows (ego id, alter id, value) of E whose value is not missing and differs
*                          from M[ego, alter] (or whose ids are out of range)

capture program drop xt_init
program xt_init
	global XT_FAILS 0
	global XT_FAILLIST ""
	global XT_POLS 0
	global XT_POLLIST ""
	global XT_FILE `"`0'"'
end

capture program drop xt_chk
program xt_chk
	args ok label
	if "`ok'" == "1" {
		di as txt "  ok:   `label'"
	}
	else if substr(`"`label'"', 1, 8) == "[policy]" {
		* a [policy] check (the owner decides) is reported, but does not fail the file
		di as res "  POLICY (not counted as failure): `label'"
		global XT_POLS = $XT_POLS + 1
		global XT_POLLIST `"$XT_POLLIST [`label']"'
	}
	else {
		di as err "  FAIL: `label'"
		global XT_FAILS = $XT_FAILS + 1
		global XT_FAILLIST `"$XT_FAILLIST [`label']"'
	}
end

capture program drop xt_end
program xt_end
	if $XT_POLS > 0 {
		di as res "$XT_POLS [policy] check(s) differ from the expected behaviour (owner decides, not failures):"
		di as res `"$XT_POLLIST"'
	}
	if $XT_FAILS > 0 {
		di as err "$XT_FAILS check(s) failed in $XT_FILE:"
		di as err `"$XT_FAILLIST"'
		exit 9
	}
	di as txt "all checks of $XT_FILE passed"
end

capture program drop xt_snap
program xt_snap
	args tag
	quietly count
	global XT_`tag'_N = r(N)
	global XT_`tag'_k = c(k)
	capture quietly datasignature
	if _rc == 0 {
		global XT_`tag'_sig "`r(datasignature)'"
	}
	else {
		global XT_`tag'_sig "none"
	}
	quietly nwset
	global XT_`tag'_nets "`r(nets)'"
	local i 0
	foreach n of global XT_`tag'_nets {
		local ++i
		quietly nwtomata `n', mat(__xt_`tag'_`i')
		quietly nwname `n'
		global XT_`tag'_m`i' `"`r(nodes)'|`r(directed)'|`r(valued)'|`r(mode2)'|`r(selfloop)'|`r(nodes1)'|`r(labs)'"'
	}
	global XT_`tag'_n = `i'
end

capture program drop xt_same
program xt_same
	* optional 3rd argument nosig: skip the data signature (for commands that only re-sort the node rows into
	* the order of the network they read, the documented data sync of _nwdatasync)
	args tag label nosig
	quietly count
	local N = r(N)
	xt_chk `=(`N' == ${XT_`tag'_N})' "`label': _N unchanged (`N' vs ${XT_`tag'_N})"
	xt_chk `=(c(k) == ${XT_`tag'_k})' "`label': number of variables unchanged"
	local sig "none"
	capture quietly datasignature
	if _rc == 0 local sig "`r(datasignature)'"
	if "`nosig'" == "" xt_chk `=("`sig'" == "${XT_`tag'_sig}")' "`label': data signature unchanged"
	quietly nwset
	local nets "`r(nets)'"
	xt_chk `=("`nets'" == "${XT_`tag'_nets}")' "`label': networks in memory unchanged (now: `nets')"
	if "`nets'" == "${XT_`tag'_nets}" {
		local i 0
		foreach n of local nets {
			local ++i
			quietly nwtomata `n', mat(__xt_cmp)
			mata: st_local("eq", strofreal(__xt_cmp == __xt_`tag'_`i'))
			xt_chk `=("`eq'" == "1")' "`label': matrix of `n' unchanged"
			quietly nwname `n'
			local meta `"`r(nodes)'|`r(directed)'|`r(valued)'|`r(mode2)'|`r(selfloop)'|`r(nodes1)'|`r(labs)'"'
			xt_chk `=(`"`meta'"' == `"${XT_`tag'_m`i'}"')' "`label': flags and labels of `n' unchanged"
		}
		capture mata: mata drop __xt_cmp
	}
end

capture program drop xt_hasnet
program xt_hasnet
	args net
	quietly nwset
	local nets "`r(nets)'"
	local p : list posof "`net'" in nets
	c_local has `=(`p' > 0)'
end

capture program drop xt_mat
program xt_mat
	args net mname
	quietly nwtomata `net', mat(`mname')
	mata: `mname' = xt_od(`mname')
end

capture program drop xt_rmark
program xt_rmark, rclass
	return scalar xtmark = 4711
	return local xtmarkl "keep me"
end

capture program drop xt_emark
program xt_emark, eclass
	ereturn clear
	ereturn scalar xtmark = 17
	ereturn local xtmarkl "keep me too"
end

capture program drop xt_rcheck
program xt_rcheck
	args label
	local okr = (r(xtmark) == 4711 & "`r(xtmarkl)'" == "keep me")
	local oke = (e(xtmark) == 17 & "`e(xtmarkl)'" == "keep me too")
	xt_chk `okr' "`label': the caller's r() is kept"
	xt_chk `oke' "`label': the caller's e() is kept"
end

capture program drop xt_nostray
program xt_nostray
	args label
	local ok = ("`r(nodes)'" == "" & "`r(id)'" == "" & "`r(netname)'" == "" & "`r(networks)'" == "")
	* r() left behind by helper programs of a non-rclass command is ordinary Stata behaviour: owner decides
	xt_chk `ok' "[policy] `label': no stray r(nodes)/r(id)/r(netname)/r(networks)"
end

capture mata: mata drop xt_od()
capture mata: mata drop xt_toks()
capture mata: mata drop xt_nuniq()
capture mata: mata drop xt_sorteq()
capture mata: mata drop xt_reorder()
capture mata: mata drop xt_edgebad()
mata:
real matrix xt_od(real matrix M)
{
	real matrix A
	A = editmissing(M, 0)
	if (rows(A) == cols(A) & rows(A) > 0) _diag(A, 0)
	return(A)
}

string rowvector xt_toks(string scalar s)
{
	string rowvector t
	if (s == "") return(J(1, 0, ""))
	t = tokens(s, ",")
	if (cols(t) == 0) return(J(1, 0, ""))
	return(select(t, t :!= ","))
}

real scalar xt_nuniq(string scalar s)
{
	string rowvector t
	t = xt_toks(s)
	if (cols(t) == 0) return(0)
	return(rows(uniqrows(t')))
}

real scalar xt_sorteq(string scalar s1, string scalar s2)
{
	string colvector a, b
	a = xt_toks(s1)'
	b = xt_toks(s2)'
	if (rows(a) != rows(b)) return(0)
	if (rows(a) == 0) return(1)
	return(sort(a, 1) == sort(b, 1))
}

real matrix xt_reorder(real matrix M, string scalar labsM, string scalar labsRef)
{
	string rowvector a, b
	real rowvector p
	real scalar i, j
	a = xt_toks(labsM)
	b = xt_toks(labsRef)
	if (cols(a) != cols(b) | cols(a) != rows(M)) return(J(0, 0, .))
	p = J(1, cols(b), 0)
	for (i = 1; i <= cols(b); i++) {
		for (j = 1; j <= cols(a); j++) {
			if (a[j] == b[i]) {
				p[i] = j
				break
			}
		}
	}
	if (any(p :== 0)) return(J(0, 0, .))
	return(M[p, p])
}

real scalar xt_edgebad(real matrix M, real matrix E)
{
	real scalar i, bad, n
	n = rows(M)
	bad = 0
	for (i = 1; i <= rows(E); i++) {
		if (E[i, 3] >= .) continue
		if (E[i, 1] < 1 | E[i, 1] > n | E[i, 2] < 1 | E[i, 2] > n | E[i, 1] >= . | E[i, 2] >= .) {
			bad = bad + 1
			continue
		}
		if (E[i, 3] != M[E[i, 1], E[i, 2]]) bad = bad + 1
	}
	return(bad)
}
end

