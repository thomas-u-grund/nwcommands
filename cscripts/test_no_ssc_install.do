cscript

/*
	Regression test: the core commands never install anything into the
	user's PLUS directory. nwdyadprob (and nwhomophily through it) used to
	`ssc install' gsample and moremata, nwplot labellist, nwtabulate
	tabplot, on first use. Run with an EMPTY scratch PLUS (this file makes
	one itself and points PLUS at it), then check that no file appeared.
	Run from the repository root.
*/

clear mata
quietly do unw_core.do
set more off

* empty scratch PLUS (never the user's real one)
tempfile stem
local plus "`stem'_plus"
capture mkdir "`plus'"
local oldplus "`c(sysdir_plus)'"
sysdir set PLUS "`plus'"

capture program drop _nwcountfiles
program _nwcountfiles, rclass
	args dir
	local n 0
	local f : dir "`dir'" files "*"
	local n = `n' + `: word count `f''
	local d : dir "`dir'" dirs "*"
	foreach x of local d {
		_nwcountfiles "`dir'/`x'"
		local n = `n' + r(n)
	}
	return scalar n = `n'
end

_nwcountfiles "`plus'"
assert r(n) == 0

* the user-written packages must not be there, so a hidden dependency
* would be exposed (it would try to install them)
foreach c in gsample labellist {
	capture which `c'
	assert _rc != 0
}
capture mata: mata which mm_sample()
assert _rc != 0

* 1. nwdyadprob: weighted sampling (formerly gsample + moremata)
nwclear
set seed 11
mata: pm = J(8,8,1)
nwdyadprob, mat(pm) density(.3) name(dp1)
nwsummarize dp1
assert r(nodes) == 8
assert reldif(r(density), .3) < 0.2

* 2. nwhomophily (through nwdyadprob)
nwclear
set obs 20
gen att = mod(_n,2)
set seed 12
nwhomophily att, homophily(.8) density(.3)
nwsummarize
assert r(nodes) == 20
assert reldif(r(density), .3) < 1E-8

* 3. nwplot with a value-labelled colour variable (formerly labellist)
nwclear
clear
set obs 4
gen grp = mod(_n,2)
label define grplab 0 "zero group" 1 "one group"
label values grp grplab
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) name(n4) undirected
nwplot n4, color(grp)
graph drop _all

* 4. nwtabulate without plot works; plot without tabplot gives a clear error
nwclear
clear
set obs 3
gen grp = mod(_n,2)
nwset, mat((0,1,1\1,0,1\1,1,0)) name(a) undirected
nwset, mat((0,1,0\1,0,0\0,0,0)) name(b) undirected
nwtabulate a b
capture noisily nwtabulate a b, plot
assert _rc == 199
capture noisily nwmixing a, attribute(grp) plot
assert _rc == 199

* nothing was installed
_nwcountfiles "`plus'"
assert r(n) == 0
quietly sysdir set PLUS "`oldplus'"
display "test_no_ssc_install: all assertions passed"
