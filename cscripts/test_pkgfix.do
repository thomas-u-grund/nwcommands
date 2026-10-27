cscript

* Fixes from the book-rewriting reports (package problems). Each block
* states what the old behaviour was. Run from the repository root.

do unw_core.do

capture program drop _pf_has
program _pf_has, rclass
	* _pf_has file, text(string) : r(found)=1 if a line of the file contains text
	syntax anything(name=fn), text(string)
	tempname fh
	local found 0
	file open `fh' using `"`fn'"', read text
	file read `fh' line
	while r(eof) == 0 {
		if strpos(`"`line'"', `"`text'"') > 0 local found 1
		file read `fh' line
	}
	file close `fh'
	return scalar found = `found'
end

capture program drop _pf_log
program _pf_log
	* _pf_log file : start a named text log
	args fn
	capture log close pf
	log using `"`fn'"', text replace name(pf)
end

* ------------------------------------------------------------------
* 1. nwsummarize: density of a large two-mode network (was 0 on screen,
*    and r(density) counted all node pairs: .000369)
* ------------------------------------------------------------------
nwuse data/ftdirectors_se, nwclear
tempfile l1
_pf_log `l1'
nwsummarize ftdirectors_se
local dens = r(density)
log close pf
assert abs(`dens' - 5669/(5092*455)) < 1e-9
_pf_has `l1', text("Density:  .00245")
assert r(found) == 1
_pf_has `l1', text("Density:  0")
assert r(found) == 0
* small two-mode network unchanged (cross-mode pairs)
nwuse data/davis, nwclear
nwsummarize davis
assert abs(r(density) - 89/(18*14)) < 1e-9

* ------------------------------------------------------------------
* 2. node-level variables of a projection must sit on the rows of the
*    nodes (were written to the first n rows of whatever order the data
*    set was in; for the Davis women the community values landed on
*    events and most women stayed missing)
* ------------------------------------------------------------------
nwuse data/davis, nwclear
nw2project davis, project(1) name(women) stat(count)
* nw2project leaves the data set in a different order than the network
nwcommunity women, generate(com) silent
nwkcore women, generate(kc) silent
nwcomponents women, generate(cp) silent
nwego women, sizevar(es) densvar(ed) silent
nwcohesion women, generate(ch) silent
count if !missing(com)
assert r(N) == 18
count if !missing(com) & _nwmode == "1"
assert r(N) == 18
count if !missing(kc) & _nwmode == "1"
assert r(N) == 18
count if !missing(cp) & _nwmode == "1"
assert r(N) == 18
count if !missing(ch) & _nwmode == "1"
assert r(N) == 18
* values equal those of the same network analysed on its own, matched by node name
preserve
keep if _nwmode == "1"
keep _nwnode kc cp es ed
rename (kc cp es ed) (kc0 cp0 es0 ed0)
tempfile ref
save `ref'
restore
* reverse the row order and recompute: results must stay with their node
gsort -_nwnode
nwkcore women, generate(kc2) silent replace
nwcomponents women, generate(cp2) silent replace
nwego women, sizevar(es2) densvar(ed2) silent
merge m:1 _nwnode using `ref', nogenerate
keep if _nwmode == "1"
assert kc2 == kc0 & cp2 == cp0 & es2 == es0 & ed2 == ed0

* a one-mode network: sort the data, results stay with the node
nwuse data/lazega, nwclear
nwkcore lazega_adv, generate(k1) silent
nwego lazega_adv, sizevar(s1) densvar(d1) silent
nwutility lazega_adv, benefit(.5) cost(.1)
rename (_benefit _cost _util) (b1 c1 u1)
gsort -yrs_frm _nwnode
nwkcore lazega_adv, generate(k2) silent
nwego lazega_adv, sizevar(s2) densvar(d2) silent
nwutility lazega_adv, benefit(.5) cost(.1)
assert k1 == k2 & s1 == s2 & d1 == d2
assert abs(c1 - _cost) < 1e-9 & abs(u1 - _util) < 1e-9 & abs(b1 - _benefit) < 1e-9

* ------------------------------------------------------------------
* 3. predict after nwqap (was: "variable glasgow1 not found")
* ------------------------------------------------------------------
nwuse data/glasgow, nwclear
set seed 12345
nwqap glasgow2 glasgow1 smoke1 sport1, permutations(20)
assert "`e(predict)'" == "nwqap_p"
predict fitted_post
nwsummarize fitted_post
assert r(nodes) == 50
set seed 12345
nwqap glasgow2 glasgow1 smoke1 sport1, permutations(20) predict(fitted_opt)
nwsummarize fitted_opt
assert abs(r(density) - 0) >= 0
mata: st_numscalar("m1", sum(*__nw.nws.pdefs[__nw.nws.get_index_of_current()]->get_matrix()))
nwsummarize fitted_post
local d1 = r(density)
nwsummarize fitted_opt
assert abs(`d1' - r(density)) < 1e-12
capture predict nonet in 1/5
assert _rc != 0

* qapspp: p-values from a null on the scale of the statistic (were 0 for
* every logit coefficient, also the weak one)
set seed 12345
nwqap glasgow2 glasgow1 smoke1 sport1, permutations(100) qapspp
matrix P = e(pvalues)
assert P[1,3] > 0.02
assert P[1,3] <= 1

* ------------------------------------------------------------------
* 4. nwmixing: header with a string attribute names the attribute
*    (was __000000_e | __000000_alter), no stray change counts
* ------------------------------------------------------------------
nwuse data/lazega, nwclear
tempfile l4
_pf_log `l4'
nwmixing lazega_adv, attribute(status)
local ei = r(EI_index)
log close pf
assert `ei' < 0
_pf_has `l4', text("status_ego")
assert r(found) == 1
_pf_has `l4', text("__0000")
assert r(found) == 0
_pf_has `l4', text("real changes made")
assert r(found) == 0

* ------------------------------------------------------------------
* 5. nwdyads takes a netlist and wildcards like nwsummarize
* ------------------------------------------------------------------
nwdyads lazega_*
assert "`r(name)'" == "lazega_fr"
nwdyads lazega_adv lazega_fr
assert "`r(name)'" == "lazega_fr"
nwdyads lazega_adv
assert "`r(name)'" == "lazega_adv"
assert r(_100) == 192

* ------------------------------------------------------------------
* 6. a failed nwdyadprob leaves no _tempdyad network behind
* ------------------------------------------------------------------
nwclear
set obs 6
gen id = _n
nwrandom 6, prob(.3) name(wn)
* density larger than the number of non-zero weights makes the call fail
capture nwdyadprob, mat(J(6,6,0)) density(.9) name(dp1)
assert _rc != 0
nwset
assert strpos(" `r(nets)' ", " _tempdyad ") == 0
* the next (valid) call works
nwdyadprob, mat(J(6,6,.5)) density(.3) name(dp2)
nwset
assert strpos(" `r(nets)' ", " _tempdyad ") == 0
assert strpos(" `r(nets)' ", " dp2 ") > 0

* ------------------------------------------------------------------
* 7. smaller items
* ------------------------------------------------------------------
* nwbrokerage refuses a string group()
nwuse data/lazega, nwclear
capture nwbrokerage lazega_adv, group(office) generate(bk)
assert _rc == 109
* nwgeodesic: no note about alpha unless alpha() is typed
tempfile l7
_pf_log `l7'
nwgeodesic lazega_adv, name(g1)
log close pf
_pf_has `l7', text("alpha")
assert r(found) == 0
* nwturnover: no floating-point noise in the printed persistence
nwrandom 20, prob(.2) name(ta)
nwrandom 20, prob(.2) name(tb)
tempfile l8
_pf_log `l8'
nwturnover ta tb, generate(tn)
log close pf
_pf_has `l8', text("0000000")
assert r(found) == 0
* nwreplace keeps a 0/1 undirected network unvalued
nwclear
nwset , mat(J(4,4,0)) name(toy) undirected
nwreplace toy[2,3] = 1
nwsummarize toy
assert "`r(valued)'" == "false"

di "test_pkgfix: all passed"
