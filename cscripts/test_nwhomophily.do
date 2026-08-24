cscript

do unw_core.do

/*
	nwhomophily.ado had zero test coverage and crashed on every single
	call, including its own documented worked example: a redundant
	"mata: mata drop `__temp'" at the very end of the program, when
	`__temp' was already dropped inside the loop just above it (every
	iteration cleans up after itself) - confirmed via `set trace on`
	that the command's own actual logic (building the homophily-weighted
	tie-probability matrix, generating the network via nwdyadprob) always
	completed successfully first; only this final, unreachable-by-design
	cleanup line ever failed. Also removed a leftover debug `di` line
	printing the two tempnames' literal macro text (e.g. "M __000000
	__000001") on every loop iteration.
*/

* single attribute, requested density hit exactly (nwdyadprob's own
* density-conditioning is exact, not approximate - confirmed directly)
nwclear
set obs 20
gen att = mod(_n,2)
nwhomophily att, homophily(.8) density(.3)
assert _rc == 0
nwsummarize
assert `"`r(directed)'"' == `"true"'
assert         r(nodes)   == 20
assert reldif( r(density), .3 ) < 1E-8

* undirected + explicit name()
nwclear
set obs 20
gen att = mod(_n,2)
nwhomophily att, homophily(.8) density(.3) undirected name(mynet)
assert _rc == 0
nwsummarize mynet
assert `"`r(directed)'"' == `"false"'
assert reldif( r(density), .3 ) < 1E-8

* multiple attributes - own separate code path (loop over varlist)
nwclear
set obs 20
gen att1 = mod(_n,2)
gen att2 = mod(_n,3)
nwhomophily att1 att2, homophily(.8 .5) density(.4)
assert _rc == 0
nwsummarize
assert reldif( r(density), .4 ) < 1E-8

* mismatched homophily()/varlist counts must error cleanly
nwclear
set obs 20
gen att1 = mod(_n,2)
gen att2 = mod(_n,3)
capture nwhomophily att1 att2, homophily(.8) density(.4)
assert _rc != 0

* default (no xvars) does NOT generate Stata variables
nwclear
set obs 20
gen att = mod(_n,2)
nwhomophily att, homophily(.8) density(.3)
capture confirm variable n1
assert _rc != 0

* xvars generates Stata variables
nwclear
set obs 20
gen att = mod(_n,2)
nwhomophily att, homophily(.8) density(.3) xvars
capture confirm variable n1
assert _rc == 0

* RE-VERIFIED (harmonisation unit): a prior investigation (see this
* file's own git history / docs/CERTIFICATION.md) reported that
* homophily(2) and homophily(-2) produced byte-identical output
* networks under the same seed, and left the statistical effect
* uncertified as a result. Re-investigated end to end with a corrected
* verification methodology and found the effect genuinely works
* correctly - the earlier finding is not reproducible. The likely
* explanation: this package's own get_nodenames() (and therefore
* nwtomata's own matrix row/column order) is sorted LEXICOGRAPHICALLY
* by node label ("n1","n10","n11",...,"n19","n2","n20","n3",...), NOT
* by numeric/creation order - confirmed directly. A same-group/
* different-group comparison built assuming row i corresponds to the
* i-th CREATED node (rather than mapping each row's own label back to
* its real attribute value first) silently compares the wrong pairs of
* nodes and can produce an apparently null or even inverted result
* that has nothing to do with the actual tie-formation mechanism - a
* plausible, easy-to-fall-into trap for exactly this kind of test (this
* session's own first attempt at re-verifying this fell into the
* identical trap before the row-order property was noticed and
* corrected for). Once nodes are mapped back to their attribute value
* via their own label (not assumed row position), homophily(2) and
* homophily(-2) produce clearly, oppositely, and strongly directioned
* networks, as expected.
nwclear
clear
set obs 20
gen grp = mod(_n,2)
set seed 42
nwhomophily grp, homophily(2) density(.1) name(hom2)
nw_syntax hom2
mata: __nl = `netobj'->get_nodenames()
mata: __g = mod(strtoreal(substr(__nl, 2, .)), 2)'
mata: __samemask = J(20,20,0)
mata: for(__i=1; __i<=20; __i++) __samemask[__i,.] = (__g[__i] :== __g')
nwtomata hom2, mat(__M2)
mata: _diag(__M2, 0)
mata: st_numscalar("__same2", sum(__M2 :* __samemask))
mata: st_numscalar("__diff2", sum(__M2 :* (1 :- __samemask)))

nwclear
clear
set obs 20
gen grp = mod(_n,2)
set seed 42
nwhomophily grp, homophily(-2) density(.1) name(homneg2)
nwtomata homneg2, mat(__Mn2)
mata: _diag(__Mn2, 0)
mata: st_numscalar("__samen2", sum(__Mn2 :* __samemask))
mata: st_numscalar("__diffn2", sum(__Mn2 :* (1 :- __samemask)))

* positive homophily must favor same-group ties far more than
* different-group ties, and negative homophily the exact opposite -
* not merely "some difference", a strong, unambiguous directional
* effect (32 vs 6 ties, observed directly, in either direction).
assert __same2 > __diff2
assert __diffn2 > __samen2
assert __same2 > __samen2
assert __diffn2 > __diff2
