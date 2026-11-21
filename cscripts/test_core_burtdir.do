cscript

do unw_core.do

* nwburt, direction(both|out|in). Run from the repository root.
*  1. direction(both) is the default (every number and r() result identical).
*  2. direction(out) on lazega_adv reproduces the numbers of version 3.32.1 (the last version before Burt's two-direction
*     convention), node by node, 1e-9: cscripts/burt_dir_fixture/lazega_adv_v3321.csv (produced with the v3.32.1 tag).
*  3. direction(in) equals direction(out) on the transposed network, node by node.
*  4. Valued: all-ones values equal the binary result for each direction; a random valued directed network against an
*     independent dense Mata computation of Burt's measures for out and in.
*  5. Undirected networks: the option has no effect; an invalid value is r(198); dyadic options.

local tol 1e-9

* ---- 1 and 2: Lazega advice
nwuse data/lazega, nwclear
qui nwburt lazega_adv, replace silent
mata: bd_def = st_data(., ("_effsize", "_efficiency", "_constraint", "_hierarchy"))
qui nwburt lazega_adv, replace silent direction(both)
assert "`r(direction)'" == "both"
mata: bd_both = st_data(., ("_effsize", "_efficiency", "_constraint", "_hierarchy"))
mata: assert(bd_def == bd_both)

qui nwburt lazega_adv, replace silent direction(out)
assert "`r(direction)'" == "out"
mata: bd_out = st_data(., ("_effsize", "_efficiency", "_constraint", "_hierarchy"))
qui sum _effsize
assert abs(r(mean) - 9.186876) < 1e-5
qui sum _constraint
assert abs(r(mean) - .1709716) < 1e-6
preserve
qui import delimited using "cscripts/burt_dir_fixture/lazega_adv_v3321.csv", clear
mata: bd_ref = st_data(., ("_effsize", "_efficiency", "_constraint", "_hierarchy"))
restore
mata: assert(rows(bd_ref) == 71 & rows(bd_out) == 71)
mata: st_local("d", strofreal(max(abs(editvalue(bd_ref, ., -99) - editvalue(bd_out, ., -99)))))
di "lazega_adv out vs 3.32.1: max abs difference `d'"
assert `d' < `tol'
* both differs from out (the data are not symmetric)
mata: assert(max(abs(bd_both[., 3] - bd_out[., 3])) > 0.01)

* ---- 3: in = out on the transposed network
qui nwburt lazega_adv, replace silent direction(in)
mata: bd_in = st_data(., ("_effsize", "_efficiency", "_constraint", "_hierarchy"))
nwtomata lazega_adv, mat(bd_A)
mata: bd_A = editmissing(bd_A, 0)
nwset, mat(bd_A') name(lazega_advT)
qui nwburt lazega_advT, replace silent direction(out)
mata: bd_outT = st_data(., ("_effsize", "_efficiency", "_constraint", "_hierarchy"))
mata: st_local("d", strofreal(max(abs(editvalue(bd_in, ., -99) - editvalue(bd_outT, ., -99)))))
di "lazega_adv in vs out on transposed: max abs difference `d'"
assert `d' < `tol'
nwtranspose lazega_adv, name(lazega_advT2)
qui nwburt lazega_advT2, replace silent direction(out)
mata: bd_outT2 = st_data(., ("_effsize", "_efficiency", "_constraint", "_hierarchy"))
mata: st_local("d", strofreal(max(abs(editvalue(bd_in, ., -99) - editvalue(bd_outT2, ., -99)))))
assert `d' < `tol'
mata: assert(max(abs(bd_in[., 3] - bd_out[., 3])) > 0.01)

* ---- without the native kernels (NW_NOFASTKERNELS) the Mata routine gives the same numbers
global NW_NOFASTKERNELS 1
foreach dd in out in {
	qui nwburt lazega_adv, replace silent direction(`dd')
	mata: bd_s = st_data(., ("_effsize", "_efficiency", "_constraint", "_hierarchy"))
	mata: st_local("d", strofreal(max(abs(editvalue(bd_s, ., -99) - editvalue(bd_`dd', ., -99)))))
	di "no native kernels, `dd': `d'"
	assert `d' < 1e-6
}
global NW_NOFASTKERNELS

* ---- dyadic options: out = dense formulas of versions before 3.33.0, in = out on the transposed network
foreach dd in out in {
	qui nwburt lazega_adv, replace silent dyadredundancy dyadconstraint direction(`dd')
	mata: bd_s = st_data(., ("_effsize", "_efficiency", "_constraint", "_hierarchy"))
	mata: st_local("d", strofreal(max(abs(editvalue(bd_s, ., -99) - editvalue(bd_`dd', ., -99)))))
	di "dyadic `dd' vs fast route: `d'"
	assert `d' < 1e-6
	nwtomata dyadconstraint, mat(bd_DC)
	mata: bd_DC = editmissing(bd_DC, 0)
	mata: assert(max(abs(rowsum(bd_DC) - bd_s[., 3])) < 1e-6)
}

* ---- 4: valued networks
local n 9
set seed 20261121
mata: bd_Z = (runiform(`n', `n') :< .35) :* ceil(runiform(`n', `n') * 6) / 4
mata: _diag(bd_Z, 0)
mata: bd_Z[1, .] = J(1, `n', 0)
mata: bd_Z[2, .] = J(1, `n', 0); bd_Z[2, 3] = 2
mata: bd_Z[., 4] = J(`n', 1, 0)
mata: bd_Z[4, 5] = 1.5; bd_Z[5, 4] = .5
* dense Burt for the ties of ego as rows of Z (out); in = transposed
mata:
real matrix bd_dense(real matrix Z)
{
	real scalar n, i, j, d, es, con, avgc, z, h
	real matrix P, M, R, C, res
	real colvector s, mx, c2
	real rowvector cj
	n = rows(Z)
	s = rowsum(Z); mx = rowmax(Z)
	P = Z :/ (s + (s :== 0))
	M = Z :/ (mx + (mx :== 0))
	R = P * M
	C = P + P * P
	res = J(n, 4, .)
	for (i = 1; i <= n; i++) {
		cj = selectindex(Z[i, .] :> 0)
		d = cols(cj)
		if (d == 0) {
			res[i, .] = (0, 0, 0, .)
			continue
		}
		es = d - sum(R[i, cj])
		c2 = (C[i, cj]') :^ 2
		con = sum(c2)
		avgc = con / d
		z = sum((c2 :/ avgc) :* ln(c2 :/ avgc))
		if (d == 1) h = 1
		else h = z / (d * ln(d))
		res[i, .] = (es, es / d, con, h)
	}
	return(res)
}
end
foreach dd in out in {
	nwclear
	if "`dd'" == "out" mata: bd_Zd = bd_Z
	else mata: bd_Zd = bd_Z'
	nwset, mat(bd_Z) name(rv) valued
	qui nwburt rv, replace silent direction(`dd')
	assert r(weighted) == 1
	mata: bd_g = st_data((1::`n'), ("_effsize", "_efficiency", "_constraint", "_hierarchy"))
	mata: bd_e = bd_dense(bd_Zd)
	mata: st_local("d", strofreal(max(abs(editvalue(bd_g, ., -99) - editvalue(bd_e, ., -99)))))
	di "random valued `dd' vs dense Mata: `d'"
	* tie values are stored in single precision (nwset): compare against the stored values
	assert `d' < 1e-5
	* binary option on the valued network equals the binary network (compared below)
	qui nwburt rv, replace silent direction(`dd') binary
	mata: bd_gr = st_data((1::`n'), ("_effsize", "_efficiency", "_constraint", "_hierarchy"))
	* all-ones valued network equals the binary network, for the direction
	mata: bd_B = (bd_Z :> 0)
	nwclear
	nwset, mat(bd_B) name(bnet)
	qui nwburt bnet, replace silent direction(`dd')
	mata: bd_gb = st_data((1::`n'), ("_effsize", "_efficiency", "_constraint", "_hierarchy"))
	nwset, mat(bd_B) name(onesv) valued
	qui nwburt onesv, replace silent direction(`dd')
	mata: bd_go = st_data((1::`n'), ("_effsize", "_efficiency", "_constraint", "_hierarchy"))
	mata: st_local("d", strofreal(max(abs(editvalue(bd_gb, ., -99) - editvalue(bd_go, ., -99)))))
	di "all-ones valued vs binary `dd': `d'"
	assert `d' < 1e-9
	mata: st_local("d", strofreal(max(abs(editvalue(bd_gb, ., -99) - editvalue(bd_gr, ., -99)))))
	di "binary option vs binary network `dd': `d'"
	assert `d' < 1e-9
	* dense (binary) formulas for the binary network
	if "`dd'" == "out" mata: bd_e = bd_dense(bd_B)
	else mata: bd_e = bd_dense(bd_B')
	mata: st_local("d", strofreal(max(abs(editvalue(bd_gb, ., -99) - editvalue(bd_e, ., -99)))))
	di "binary network vs dense formulas `dd': `d'"
	* variables are stored in single precision
	assert `d' < 1e-6
}

* ---- 5: undirected networks, invalid value
nwclear
nwset, mat((0,1,1,0,0\1,0,1,1,0\1,1,0,0,1\0,1,0,0,0\0,0,1,0,0)) name(u5) undirected
qui nwburt u5, replace silent
mata: bd_u = st_data(., ("_effsize", "_efficiency", "_constraint", "_hierarchy"))
foreach dd in both out in {
	qui nwburt u5, replace silent direction(`dd')
	mata: bd_u2 = st_data(., ("_effsize", "_efficiency", "_constraint", "_hierarchy"))
	mata: assert(bd_u == bd_u2)
}
tempfile lg
log using "`lg'", text replace name(bdlog)
nwburt u5, replace direction(out)
log close bdlog
mata: st_local("hit", strofreal(any(strpos(cat(st_local("lg")), "directed network"))))
assert `hit' == 0
capture nwburt u5, replace direction(sideways)
assert _rc == 198
capture nwburt u5, replace direction(OUT)
assert _rc == 198
nwset, mat((0,1,1,0,0\0,0,1,1,0\1,0,0,0,1\0,0,1,0,0\0,0,0,1,0)) name(d5)
capture nwburt d5, replace direction(x)
assert _rc == 198
* header lines
tempfile lg2
log using "`lg2'", text replace name(bdlog2)
nwburt d5, replace
nwburt d5, replace direction(out)
nwburt d5, replace direction(in)
log close bdlog2
mata: bd_t = cat(st_local("lg2"))
mata: assert(any(strpos(bd_t, "(directed network: both directions of a tie count)")))
mata: assert(any(strpos(bd_t, "(directed network: ties sent by ego only)")))
mata: assert(any(strpos(bd_t, "(directed network: ties received by ego only)")))

di "burt direction: all equal"
