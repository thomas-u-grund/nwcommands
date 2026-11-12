* xt_meas_qap_correlate.do -- extended tests for nwcorrelate (two networks) and nwqap.
* Run with Stata 17; every check passes since the fixes of the measure suite (fixes-xt).
*
* Covers: nwcorrelate of a network with itself (1), with its complement (-1), the 3-node example of
* sna::gcor (0.25), size mismatch (6056), a missing network (482), a network without variance (198),
* permutations() results (p-value, bounds), attribute() and the user's own network called same_<attr>;
* nwqap: the observed coefficients equal logit / regress on the dyads built by hand (cross-route), e()
* results (N = n(n-1), cmd, depvar, permutations, pvalues), predict(), an attribute term, error codes
* (482, 6056, 198), and the user's own network called _tempexpand.
* Run from the repository root.

clear all
set more off
set graphics off
do unw_core.do
run cscripts/xt_meas_00_helpers.do
xt_minit xt_meas_qap_correlate
nwclear

* ---------------------------------------------------------------- (1) nwcorrelate
nwclear
clear
set seed 31
nwrandom 8, prob(.4) name(a)
nwduplicate a, name(a2)
nwcorrelate a a2
xa reldif(r(corr), 1) < 1e-12
xa "`r(name_1)'" == "a" & "`r(name_2)'" == "a2"
* the complement off the diagonal: -1
nwtomata a, mat(A)
mata: C = (J(8,8,1) - I(8)) :- (A :!= 0)
mata: _diag(C, 0)
nwset, mat(C) name(ac) directed
nwcorrelate a ac
xa reldif(r(corr), -1) < 1e-12
* 3 nodes: 1 -> 2, 2 -> 3 against 1 -> 2, 3 -> 1; sna::gcor(m1, m2) = 0.25 (diagonal excluded).
* correlate_nets() in unw_core.do correlates ALL cells; Mata's correlation() drops rows with missing values,
* so this holds only if the stored diagonal is missing.  With a 0 diagonal the result is 5/14 = .357 (and the
* complement test above is not -1): that would be a deviation from sna::gcor (diag = FALSE).
nwset, mat((0,1,0\0,0,1\0,0,0)) name(m1) directed
nwset, mat((0,1,0\0,0,0\1,0,0)) name(m2) directed
nwcorrelate m1 m2
xa reldif(r(corr), .25) < 1e-12
* errors
nwset, mat((0,1\1,0)) name(small) directed
capture nwcorrelate a small
xa _rc == 6056
capture nwcorrelate a nosuchnet
xa _rc == 482
nwset, mat(J(8,8,0)) name(empty8) directed
capture nwcorrelate a empty8
xa _rc == 198
* permutations: a p-value in [0, 1] and lb <= ub
set seed 5
nwcorrelate a a2, permutations(20)
xa r(pvalue) >= 0 & r(pvalue) <= 1
xa r(lb) <= r(ub)
xa reldif(r(corr), 1) < 1e-12
graph drop _all
mata: mata drop A C
di "(1) nwcorrelate: ok"

* ---------------------------------------------------------------- (2) nwcorrelate, attribute()
nwclear
clear
nwset, mat((0,1,0,0\1,0,0,0\0,0,0,1\0,0,1,0)) name(u4) undirected
set obs 4
gen g = cond(_n <= 2, 1, 2)
* the ties are exactly the same-group pairs: correlation 1 (off the diagonal; see the note on the diagonal above)
nwcorrelate u4, attribute(g)
xa reldif(r(corr), 1) < 1e-12
* the expanded network is removed again, unless keepexpand
capture nwname same_g
xa _rc != 0
nwcorrelate u4, attribute(g) keepexpand
nwname same_g
* SUSPECTED BUG: nwcorrelate drops any network called same_<attribute> before it builds its own, so a user
* network of that name is lost.  Expected: an error or a different name, never the loss of the user's network.
nwdrop same_g
nwset, mat((0,1\1,0)) name(same_g) undirected
nwcorrelate u4, attribute(g)
capture nwname same_g
xa _rc == 0    // fixed: CONFIRMED BUG M12
xa r(nodes) == 2    // fixed: CONFIRMED BUG M12
di "(2) nwcorrelate attribute: ok"

* ---------------------------------------------------------------- (3) nwqap: observed coefficients = logit / regress on the dyads
nwclear
clear
set seed 77
nwrandom 8, prob(.4) name(y)
nwrandom 8, prob(.5) name(x)
nwtomata y, mat(Y)
nwtomata x, mat(X)
nwqap y x, permutations(3)
matrix B = e(b)
xa e(N) == 56
xa "`e(cmd)'" == "nwqap" & "`e(depvar)'" == "y" & "`e(qap_regcmd)'" == "logit"
xa e(permutations) == 3
matrix P = e(pvalues)
xa colsof(P) == 2
* the same model on the 56 ordered pairs i != j, built by hand
preserve
clear
mata: off = vec(J(8,8,1) - I(8))
mata: yy = select(vec(Y), off)
mata: xx = select(vec(X), off)
getmata yy xx
qui logit yy xx
xa reldif(_b[xx], B[1,1]) < 1e-6
xa reldif(_b[_cons], B[1,2]) < 1e-6
restore
* type(regress)
nwqap y x, permutations(3) type(regress)
matrix B = e(b)
preserve
clear
getmata yy xx
qui regress yy xx
xa reldif(_b[xx], B[1,1]) < 1e-9
xa reldif(_b[_cons], B[1,2]) < 1e-9
restore
mata: mata drop Y X off yy xx
* predict(): a network of the fitted values, same size
nwqap y x, permutations(2) predict(yhat)
nwsummarize yhat
xa r(nodes) == 8
di "(3) nwqap cross-route: ok"

* ---------------------------------------------------------------- (4) nwqap: errors and helper names
nwclear
clear
set seed 78
nwrandom 8, prob(.4) name(y)
nwrandom 8, prob(.5) name(x)
nwrandom 5, prob(.5) name(x5)
capture nwqap nosuchnet x, permutations(2)
xa _rc == 482
capture nwqap y x5, permutations(2)
xa _rc == 6056
capture nwqap, permutations(2)
xa _rc == 198
* the data in memory are restored after nwqap (a first call may sync the data with the network)
set obs 8
gen g = mod(_n, 2)
nwqap y x g, permutations(2)
qui datasignature
local sig0 "`r(datasignature)'"
nwqap y x g, permutations(2)
qui datasignature
xa "`r(datasignature)'" == "`sig0'"
* SUSPECTED BUG: an attribute term goes through a network called _tempexpand, which is dropped afterwards;
* a user network of that name must survive
nwset, mat((0,1\1,0)) name(_tempexpand) undirected
capture noisily nwqap y x g, permutations(2)
local rcq = _rc
capture nwname _tempexpand
xa _rc == 0
xa r(nodes) == 2
xa `rcq' == 0    // fixed: CONFIRMED BUG M13
* the attribute is matched to the nodes by node name (_nwnode), not by row position: rows out of node order
* (here left by the sync of a 5-node network) must give the same coefficients as the sorted rows.
* CONFIRMED BUG N3: nwqap passes the attribute to nwexpand (positional read, nwexpand.ado:92) without
* _nwdatasync first; the first call pairs row 7 (node n8) with node 7, a second call (rows now synced) differs.
nwclear
clear
set seed 78
nwrandom 8, prob(.4) name(y)
nwrandom 8, prob(.5) name(x)
nwrandom 5, prob(.5) name(x5)
set obs 8
gen g = mod(_n, 2)
nwqap y x g, permutations(2)
local b1 = _b[same_g]
nwqap y x g, permutations(2)
local b2 = _b[same_g]
xa reldif(`b1', `b2') < 1e-6    // fixed: CONFIRMED BUG N3
di "(4) nwqap errors: ok"

nwclear
xt_mend
di "ALL PASS"
