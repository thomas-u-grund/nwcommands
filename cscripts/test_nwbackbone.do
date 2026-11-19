* nwbackbone: backbone extraction (3.28.0)
* fixture (cscripts/nwbackbone_fixture, made by make_fixture.R): R 4.6, backbone 3.0.4
clear all
set more off
nwclear
local fx "cscripts/nwbackbone_fixture"
local nfail = 0
* run the ado file (the test calls its Mata functions directly; the working directory is the repository root)
run nwbackbone.ado
mata: up = J(0, 0, .); lo = J(0, 0, .); ntr = .

mata:
real matrix nwtest_csv(string scalar f)
{
	real scalar fh
	string scalar line
	real matrix X
	fh = fopen(f, "r")
	X = J(0, 0, .)
	while ((line = fget(fh)) != J(0, 0, "")) {
		if (rows(X) == 0) X = strtoreal(tokens(subinstr(line, ",", " ")))
		else X = X \ strtoreal(tokens(subinstr(line, ",", " ")))
	}
	fclose(fh)
	return(X)
}
// number of cells where a and b disagree: missing pattern, or values beyond 1e-8 + 1e-6 relative
real scalar nwtest_cmp(real matrix a, real matrix b)
{
	real matrix both
	if (rows(a) != rows(b) | cols(a) != cols(b)) return(-1)
	both = (a :< .) :& (b :< .)
	return(sum((a :< .) :!= (b :< .)) + sum(both :& (abs(a :- b) :> 1e-8 :+ 1e-6 :* abs(b))))
}
end

capture program drop nwt_net
program nwt_net
	args nm file
	nwtomatafast `nm'
	mata: st_local("dd", strofreal(nwtest_cmp(editmissing(`r(mata)', 0), nwtest_csv("`file'"))))
	c_local d "`dd'"
end

* ---- p-values and backbones against R: one-mode valued networks ----
foreach nm in wu wd {
	mata: A = nwtest_csv("`fx'/`nm'.csv")
	mata: st_matrix("Am", A)
	if "`nm'" == "wu" nwset, mat(Am) name(`nm') undirected
	else nwset, mat(Am) name(`nm') directed
	nwsummarize `nm'
	foreach m in disparity lans mlf {
		mata: nw_bb_pvals("`m'", A, 1, 0, 0, 0.05, "none", up, lo, ntr)
		mata: st_local("d1", strofreal(nwtest_cmp(up, nwtest_csv("`fx'/p_`nm'_`m'_upper.csv"))))
		mata: st_local("d2", strofreal(nwtest_cmp(lo, nwtest_csv("`fx'/p_`nm'_`m'_lower.csv"))))
		mata: nw_bb_pvals("`m'", A, 0, 1, 0, 0.05, "none", up, lo, ntr)
		mata: st_local("d3", strofreal(nwtest_cmp(up, nwtest_csv("`fx'/p_`nm'_`m'_mz_upper.csv"))))
		if `d1' + `d2' + `d3' > 0 {
			di as err "FAIL pvalues `nm' `m': `d1' `d2' `d3'"
			local ++nfail
		}
		foreach a in 0.05 0.21 {
			foreach mtc in none holm BH {
				qui nwbackbone `nm', method(`m') alpha(`a') mtc(`mtc') generate(bb) replace silent
				nwt_net bb "`fx'/b_`nm'_`m'_a`a'_`mtc'.csv"
				if `d' != 0 {
					di as err "FAIL backbone `nm' `m' a=`a' mtc=`mtc': `d' cells"
					local ++nfail
				}
			}
		}
		qui nwbackbone `nm', method(`m') alpha(0.1) signed generate(bb) replace silent
		nwt_net bb "`fx'/b_`nm'_`m'_signed.csv"
		if `d' != 0 {
			di as err "FAIL signed `nm' `m': `d'"
			local ++nfail
		}
		qui nwbackbone `nm', method(`m') alpha(0.1) mtc(BY) missingaszero generate(bb) replace silent
		nwt_net bb "`fx'/b_`nm'_`m'_mz_BY.csv"
		if `d' != 0 {
			di as err "FAIL mz BY `nm' `m': `d'"
			local ++nfail
		}
	}
	qui nwbackbone `nm', method(global) threshold(3) generate(bb) replace silent
	nwt_net bb "`fx'/b_`nm'_global3.csv"
	if `d' != 0 {
		di as err "FAIL global `nm': `d'"
		local ++nfail
	}
	qui nwbackbone `nm', method(global) threshold(5 2) generate(bb) replace silent
	nwt_net bb "`fx'/b_`nm'_global25.csv"
	if `d' != 0 {
		di as err "FAIL global two thresholds `nm': `d'"
		local ++nfail
	}
}

* ---- projections of two-mode networks ----
foreach nm in bip bip2 {
	mata: I = nwtest_csv("`fx'/`nm'.csv")
	mata: st_matrix("Bm", I')
	nw2set, mat(Bm) name(`nm')
	if "`nm'" == "bip" {
		mata: pr = nw_bb_bicm(I)
		mata: st_local("d", strofreal(nwtest_cmp(pr, nwtest_csv("`fx'/bicm_`nm'.csv"))))
		* the probabilities themselves to 1e-6 (the iteration stops at a gradient of 1e-12)
		if `d' != 0 {
			di as err "FAIL bicm `nm': `d'"
			local ++nfail
		}
	}
	foreach m in sdsm fixedrow fixedcol fixedfill {
		mata: nw_bb_pvals("`m'", I, 1, 0, 0, 0.05, "none", up, lo, ntr)
		mata: st_local("d1", strofreal(nwtest_cmp(up, nwtest_csv("`fx'/p_`nm'_`m'_upper.csv"))))
		mata: st_local("d2", strofreal(nwtest_cmp(lo, nwtest_csv("`fx'/p_`nm'_`m'_lower.csv"))))
		mata: nw_bb_pvals("`m'", I, 0, 1, 0, 0.05, "none", up, lo, ntr)
		mata: st_local("d3", strofreal(nwtest_cmp(up, nwtest_csv("`fx'/p_`nm'_`m'_mz_upper.csv"))))
		if `d1' + `d2' + `d3' > 0 {
			di as err "FAIL pvalues `nm' `m': `d1' `d2' `d3'"
			local ++nfail
		}
		foreach a in 0.05 0.21 {
			foreach mtc in none holm BH hommel {
				qui nwbackbone `nm', method(`m') alpha(`a') mtc(`mtc') generate(bb) replace silent
				nwt_net bb "`fx'/b_`nm'_`m'_a`a'_`mtc'.csv"
				if `d' != 0 {
					di as err "FAIL backbone `nm' `m' a=`a' mtc=`mtc': `d' cells"
					local ++nfail
				}
			}
		}
		qui nwbackbone `nm', method(`m') alpha(0.1) signed generate(bb) replace silent
		nwt_net bb "`fx'/b_`nm'_`m'_signed.csv"
		if `d' != 0 {
			di as err "FAIL signed `nm' `m': `d'"
			local ++nfail
		}
		qui nwbackbone `nm', method(`m') alpha(0.05) mtc(bonferroni) project(2) generate(bb) replace silent
		nwt_net bb "`fx'/b_`nm'_`m'_col.csv"
		if `d' != 0 {
			di as err "FAIL column projection `nm' `m': `d'"
			local ++nfail
		}
	}
}

* ---- fdsm: Monte Carlo p-values against the R reference (40,000 draws); seeds differ, so a tolerance ----
mata: I = nwtest_csv("`fx'/bip2.csv")
set seed 12345
timer clear 1
timer on 1
mata: nw_bb_pvals("fdsm", I, 0, 0, 3000, 0.05, "none", up, lo, ntr)
timer off 1
qui timer list 1
di "fdsm: 3000 draws took " r(t1) " seconds"
mata: ref = nwtest_csv("`fx'/p_bip2_fdsm_upper.csv")
mata: st_local("pat", strofreal(sum((up :< .) :!= (ref :< .))))
mata: st_local("mx", strofreal(max(abs(editmissing(up, 0) :- editmissing(ref, 0)))))
mata: st_local("mn", strofreal(sum(abs(editmissing(up, 0) :- editmissing(ref, 0))) / sum(ref :< .)))
mata: st_local("ntr", strofreal(ntr))
di "fdsm: missing pattern differences `pat', max abs diff of p `mx', mean abs diff `mn', draws `ntr'"
if `pat' != 0 | `mx' > 0.05 | `mn' > 0.01 | `ntr' != 3000 {
	di as err "FAIL fdsm p-values"
	local ++nfail
}
* the default number of draws follows power.prop.test as in R (R: 80,000 draws at alpha = 0.05 without correction)
mata: st_local("nd", strofreal(nw_bb_ntrials(I * I', 0.05, "none", 0, 0)))
if `nd' < 70000 | `nd' > 90000 {
	di as err "FAIL default number of fdsm draws: `nd'"
	local ++nfail
}
qui nwbackbone bip2, method(fdsm) trials(2000) seed(7) alpha(0.05) mtc(none) generate(bbf) replace silent
assert r(trials) == 2000
* edges kept by the Monte Carlo test have a clearly small reference p-value, edges not kept a clearly large one
nwtomatafast bbf
mata: Bf = editmissing(`r(mata)', 0)
mata: st_local("badk", strofreal(sum((Bf :== 1) :& (editmissing(ref, 1) :> 0.12))))
mata: st_local("badn", strofreal(sum((Bf :== 0) :& (editmissing(ref, 1) :< 0.015) :& (ref :< .))))
if `badk' + `badn' > 0 {
	di as err "FAIL fdsm backbone: `badk' kept with large p, `badn' dropped with small p"
	local ++nfail
}

* ---- results, options, error paths ----
nwclear
nwset, mat((0,3,1,0\3,0,6,2\1,6,0,9\0,2,9,0)) name(v4) undirected
nwset, mat((0,3,1,0\0,0,6,2\1,0,0,9\0,2,0,0)) name(d4) directed
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) name(bin4) undirected
nwset, mat((0,2.5,0,0\2.5,0,1,0\0,1,0,1\0,0,1,0)) name(frac4) undirected
nwset, mat((0,-3,1,0\-3,0,6,2\1,6,0,9\0,2,9,0)) name(neg4) undirected
nwbackbone v4, method(global) threshold(2.5) generate(g1) replace
assert r(ties_in) == 5 & r(ties) == 3 & r(nodes) == 4 & "`r(method)'" == "global" & "`r(backbone)'" == "g1"
nwtomatafast g1
mata: assert(editmissing(`r(mata)', 0) == (0, 1, 0, 0 \ 1, 0, 1, 0 \ 0, 1, 0, 1 \ 0, 0, 1, 0))
_nwsyntax g1
assert "`directed'" == "false"
* keepvalues: the tie values of the kept ties
nwbackbone v4, method(global) threshold(2.5) keepvalues generate(g2) replace silent
nwtomatafast g2
mata: assert(editmissing(`r(mata)', 0) == (0, 3, 0, 0 \ 3, 0, 6, 0 \ 0, 6, 0, 9 \ 0, 0, 9, 0))
* a directed network stays directed
nwbackbone d4, method(global) threshold(2.5) generate(g3) replace silent
assert r(ties) == 3
_nwsyntax g3
assert "`directed'" == "true"
* signed backbone of a directed network
nwbackbone d4, method(disparity) alpha(0.5) signed generate(g4) replace silent
* replace
capture nwbackbone v4, method(global) threshold(2.5) generate(g1)
assert _rc == 483
nwbackbone v4, method(global) threshold(2.5) generate(g1) replace silent
* the two-mode case keeps the labels of the projected mode
mata: st_matrix("Bm", nwtest_csv("`fx'/bip2.csv")')
nw2set, mat(Bm) name(bip3)
nwbackbone bip3, method(fixedrow) alpha(0.5) generate(pj) replace silent
_nwsyntax pj
assert `nodes' == 30 & "`is2mode'" == "false" & "`directed'" == "false"
nwbackbone bip3, method(sdsm) alpha(0.5) generate(pj2) replace silent project(2)
_nwsyntax pj2
assert `nodes' == 20
* errors
capture nwbackbone v4
assert _rc == 198
capture nwbackbone v4, method(magic)
assert _rc == 198
capture nwbackbone v4, method(global)
assert _rc == 198
capture nwbackbone v4, method(global) threshold(1) mtc(holm)
assert _rc == 198
capture nwbackbone v4, method(global) threshold(1) signed
assert _rc == 198
capture nwbackbone v4, method(disparity) threshold(1)
assert _rc == 198
capture nwbackbone v4, method(disparity) mtc(none2)
assert _rc == 198
capture nwbackbone v4, method(disparity) alpha(2)
assert _rc == 198
capture nwbackbone v4, method(disparity) alpha(-0.1)
assert _rc == 198
capture nwbackbone bin4, method(disparity)
assert _rc == 198
capture nwbackbone neg4, method(disparity)
assert _rc == 198
capture nwbackbone frac4, method(mlf)
assert _rc == 198
capture nwbackbone v4, method(sdsm)
assert _rc == 198
capture nwbackbone bip3, method(disparity)
assert _rc == 198
capture nwbackbone bip3, method(sdsm) trials(5)
assert _rc == 198
capture nwbackbone v4, method(disparity) trials(5)
assert _rc == 198
capture nwbackbone bip3, method(sdsm) project(3)
assert _rc == 198
capture nwbackbone v4, method(disparity) project(2)
assert _rc == 198
capture nwbackbone nosuchnet, method(disparity)
assert _rc != 0
* a two-mode network with tie values other than 0 and 1
mata: Bv = (1, 2, 0 \ 0, 1, 3 \ 1, 1, 1 \ 0, 0, 1)
nw2set, mat(Bv) name(bipv)
capture nwbackbone bipv, method(sdsm)
assert _rc == 198
* a network with fewer than 3 nodes
nwset, mat((0,2\2,0)) name(n2) undirected
capture nwbackbone n2, method(global) threshold(1)
assert _rc == 198

di
if `nfail' == 0 di "PASS nwbackbone results, options and error paths"
if `nfail' == 0 di "PASS nwbackbone matches R backbone 3.0.4 (p-values and retained ties)"
else di as err "FAIL: `nfail' comparisons"
