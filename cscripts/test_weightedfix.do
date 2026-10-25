* Weighted-network fixes (weighted audit, 2026-10-25).  Run from the repository root.
* Every check is independent of the code under test (Mata brute force, hand values).
* Prints "test_weightedfix: all passed" or the failing checks, and exits with an error if any failed.
clear all
set more off

capture program drop _chk
program _chk
	args ok label
	if `ok' {
		di "  ok:   `label'"
	}
	else {
		di as err "  FAIL: `label'"
		global WF_FAILS = $WF_FAILS + 1
	}
end
global WF_FAILS 0

capture program drop _isval
program _isval, rclass
	_nwsyntax `0', max(1)
	return local valued "`valued'"
	return local directed "`directed'"
end

capture program drop _countnote
program _countnote, rclass
	args cmd
	tempfile lg
	qui log using "`lg'", text replace name(wfnote)
	capture noisily `cmd'
	qui log close wfnote
	local found 0
	file open fh using "`lg'", read text
	file read fh line
	while r(eof) == 0 {
		if strpos(`"`line'"', "tie values are ignored") local ++found
		file read fh line
	}
	file close fh
	return scalar found = `found'
end

* ---------------------------------------------------------------- (A) Valued flag rule
di as txt _n "(A) Valued flag"
nwclear
nwset, mat((0,.2,.9,0\.2,0,.5,0\.9,.5,0,.3\0,0,.3,0)) name(p) undirected
_isval p
_chk `=("`r(valued)'" == "true")' "values in (0,1] are valued"
nwset, mat((0,.5,.5\.5,0,.5\.5,.5,0)) name(pc) undirected
_isval pc
_chk `=("`r(valued)'" == "true")' "one constant value 0.5 is valued"
nwset, mat((0,2,2\2,0,2\2,2,0)) name(c2) undirected
_isval c2
_chk `=("`r(valued)'" == "true")' "one constant value 2 is valued"
nwset, mat((0,1,1\1,0,1\1,1,0)) name(b1) undirected
_isval b1
_chk `=("`r(valued)'" == "false")' "all ties 1 is binary"
nwset, mat((0,1,0\1,0,1\0,1,0)) name(b2) undirected
_isval b2
_chk `=("`r(valued)'" == "false")' "0/1 network is binary"
nwset, mat((0,-1,0\-1,0,1\0,1,0)) name(neg) undirected
_isval neg
_chk `=("`r(valued)'" == "true")' "signed network is valued"
nwset, mat((0,1,0\1,0,1\0,1,0)) name(fv) undirected valued
_isval fv
_chk `=("`r(valued)'" == "true")' "option valued forces valued"
nwset, mat((0,3,0\3,0,2\0,2,0)) name(fu) undirected unvalued
_isval fu
_chk `=("`r(valued)'" == "false")' "option unvalued forces unvalued"
preserve
clear
input str3 e str3 a double w
"n1" "n2" .3
"n1" "n3" .6
"n2" "n3" .9
end
nwfromedge e a w, name(share) undirected
restore
_isval share
_chk `=("`r(valued)'" == "true")' "nwfromedge with shares is valued"
qui nwclustering p, generate(cc_b) measure(binary)
qui nwclustering p, generate(cc_d)
qui mata: st_numscalar("__diff", mreldif(st_data(., "cc_d"), st_data(., "cc_b")))
_chk `=(scalar(__diff) > 1e-6)' "nwclustering default differs from the binary coefficient on shares"

* ---------------------------------------------------------------- (B) weighted betweenness ties
di as txt _n "(B) weighted betweenness"
mata:
real colvector wf_bruteforce(real matrix W, real scalar directed)
{
	real scalar n, k, i, j, v, L
	real matrix C, D, S
	real colvector bc, ord
	n = rows(W); L = 12
	C = J(n, n, .)
	for (i = 1; i <= n; i++) for (j = 1; j <= n; j++) if (i != j & W[i,j] > 0) C[i,j] = L / W[i,j]
	D = C
	for (i = 1; i <= n; i++) D[i,i] = 0
	for (k = 1; k <= n; k++) for (i = 1; i <= n; i++) for (j = 1; j <= n; j++) {
		if (D[i,k] < . & D[k,j] < . & (D[i,j] == . | D[i,k] + D[k,j] < D[i,j])) D[i,j] = D[i,k] + D[k,j]
	}
	S = J(n, n, 0)
	for (i = 1; i <= n; i++) {
		S[i,i] = 1
		ord = order(D[i,.]', 1)
		for (j = 1; j <= n; j++) {
			v = ord[j]
			if (v == i | D[i,v] == .) continue
			for (k = 1; k <= n; k++) {
				if (k != v & C[k,v] < . & D[i,k] < . & D[i,k] + C[k,v] == D[i,v]) S[i,v] = S[i,v] + S[i,k]
			}
		}
	}
	bc = J(n, 1, 0)
	for (v = 1; v <= n; v++) for (i = 1; i <= n; i++) for (j = 1; j <= n; j++) {
		if (i != v & j != v & i != j & D[i,j] < . & D[i,v] < . & D[v,j] < . & D[i,v] + D[v,j] == D[i,j]) {
			bc[v] = bc[v] + S[i,v] * S[v,j] / S[i,j]
		}
	}
	if (!directed) bc = bc / 2
	return(bc)
}
real matrix wf_randnet(real scalar n, real scalar directed)
{
	real matrix W
	real scalar i, j
	W = (runiform(n, n) :< 0.3) :* ceil(4 :* runiform(n, n))
	_diag(W, 0)
	if (!directed) {
		for (i = 1; i <= n; i++) for (j = i + 1; j <= n; j++) W[j,i] = W[i,j]
	}
	return(W)
}
end

set seed 20261025
local worst 0
forvalues r = 1/60 {
	local dir = (`r' > 30)
	qui nwclear
	mata: WFW = wf_randnet(12, `dir')
	if `dir' qui nwset, mat(WFW) name(rn) directed
	else qui nwset, mat(WFW) name(rn) undirected
	if `dir' qui nwbetween rn, generate(bw) weighted nosym replace
	else qui nwbetween rn, generate(bw) weighted replace
	qui mata: st_numscalar("__d", max(abs(st_data((1::12), "bw") - wf_bruteforce(WFW, `dir'))))
	if scalar(__d) > `worst' local worst = scalar(__d)
}
_chk `=(`worst' < 1e-4)' "weighted betweenness equals exact brute force on 60 random networks (max diff `worst')"

nwclear
capture nwuse data/sampson.nwdta
if _rc == 0 {
	qui nwbetween samplike, generate(bw) weighted nosym replace
	qui sum bw if _nwnode == "Berthold"
	_chk `=(abs(r(mean) - 14.0667) < 1e-3)' "Sampson Berthold weighted betweenness = 14.0667 (got `=r(mean)')"
}
else {
	_chk 0 "could not load data/sampson.nwdta"
}

* ---------------------------------------------------------------- (C) notes, crossproduct
di as txt _n "(C) notes, crossproduct"
nwclear
nwset, mat((0,3,1,0\3,0,2,0\1,2,0,5\0,0,5,0)) name(v4) undirected
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) name(b4) undirected
foreach cmd in "nwclique v4, generate(q1) replace" "nwkcore v4, generate(k1) replace" {
	_countnote `"`cmd'"'
	_chk `=(r(found) == 1)' "one note: `cmd'"
}
foreach cmd in "nwclique b4, generate(q1) replace" "nwkcore b4, generate(k1) replace" ///
	"nwclique v4, generate(q1) silent replace" "nwkcore v4, generate(k1) silent replace" {
	_countnote `"`cmd'"'
	_chk `=(r(found) == 0)' "no note: `cmd'"
}
nwset, mat((0,3,1,0\0,0,2,0\1,0,0,5\0,0,5,0)) name(d4) directed
qui nwsimilar d4, type(crossproduct) name(xp) mode(outgoing)
qui nwtomata xp, mat(XP)
mata: Wd = (0,3,1,0\0,0,2,0\1,0,0,5\0,0,5,0)
mata: st_numscalar("__xd", max(abs(editmissing(XP, 0) - Wd * Wd')))
_chk `=(scalar(__xd) < 1e-12)' "nwsimilar crossproduct uses tie values (W W')"

* ---------------------------------------------------------------- (D) data damage
di as txt _n "(D) data damage"
nwclear
nwset, mat((0,0.123456789,1234567,12345678,123456789,1.23456789e-7,-98765432.1 \ 0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0)) name(big) directed valued
tempfile f
qui nwsave "`f'.nwdta", replace
nwclear
qui nwuse "`f'.nwdta"
qui nwtomata big, mat(M)
mata: E = (0.123456789,1234567,12345678,123456789,1.23456789e-7,-98765432.1)
mata: st_numscalar("__bd", max(abs(M[1,2..7] :- E) :/ abs(E)))
_chk `=(scalar(__bd) < 1e-14)' "nwsave/nwuse keeps large and small values (rel. error `=scalar(__bd)')"
preserve
clear
input str3 e str3 a double w
"a" "b" 16777217
"a" "c" 123456789
"b" "c" 0.1
end
qui nwfromedge e a w, name(dbl) directed
restore
qui nwtomata dbl, mat(M)
mata: st_numscalar("__fd", abs(M[1,2] - 16777217) + abs(M[1,3] - 123456789) + abs(M[2,3] - 0.1))
_chk `=(scalar(__fd) < 1e-12)' "nwfromedge stores double precision"
nwclear
nwset, mat((0,3,1,0,0,0\3,0,5,2,0,0\1,5,0,2,4,0\0,2,2,0,4,1\0,0,4,4,0,2\0,0,0,1,2,0)) name(u) undirected
qui nwkeepnodes u, nodes(1 2 3 4) generate(k)
_isval k
_chk `=("`r(valued)'" == "true")' "nwkeepnodes generate(): Valued kept"
qui nwdropnodes u, nodes(5 6) generate(k2)
_isval k2
_chk `=("`r(valued)'" == "true")' "nwdropnodes generate(): Valued kept"
tempfile g
qui nwexport u, type(gml) fname("`g'") replace
qui nwimport "`g'.gml", type(gml) name(ub) nwclear
_isval ub
_chk `=("`r(valued)'" == "true" & "`r(directed)'" == "false")' "GML import keeps values and undirected"
qui nwtomata ub, mat(MB)
qui nwtomata u, mat(MU)
mata: st_numscalar("__gd", max(abs(editmissing(MB, 0) - editmissing(MU, 0))))
_chk `=(scalar(__gd) < 1e-12)' "GML round trip reproduces the matrix"
nwclear
nwset, mat((0,2,0\0,0,3\1,0,0)) name(dg) directed
qui nwexport dg, type(gml) fname("`g'2") replace
qui nwimport "`g'2.gml", type(gml) name(dgb) nwclear
_isval dgb
_chk `=("`r(directed)'" == "true")' "GML import keeps directed"
nwclear
nwset, mat((0,3,1,0\3,0,5,2\1,5,0,2\0,2,2,0)) name(cu) undirected
gen byte grp = _n > 2
qui nwcollapse cu, by(grp) generate(cu2)
_isval cu2
_chk `=("`r(directed)'" == "false")' "nwcollapse keeps an undirected network undirected"
nwset, mat((0,3,1,0\0,0,5,2\1,0,0,2\0,2,0,0)) name(cd) directed
qui nwcollapse cd, by(grp) generate(cd2)
_isval cd2
_chk `=("`r(directed)'" == "true")' "nwcollapse keeps a directed network directed"
nwclear
nwset, mat((0,3,0,0,0,0\3,0,5,2,0,0\0,5,0,2,4,0\0,2,2,0,4,-3\0,0,4,4,0,-2\0,0,0,-3,-2,0)) name(sg2) undirected
capture nwconcor sg2, generate(cc)
_chk `=(_rc == 0)' "nwconcor on a signed network (node with negative tie sum) runs (rc `=_rc')"

di _n
if $WF_FAILS == 0 {
	di "test_weightedfix: all passed"
}
else {
	di as err "test_weightedfix: $WF_FAILS check(s) failed"
	exit 9
}
