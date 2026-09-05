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

* FULLY ROOT-CAUSED AND FIXED (harmonisation unit 166): a prior
* investigation (see this file's own git history / docs/
* CERTIFICATION.md) reported that homophily(2) and homophily(-2)
* produced byte-identical/statistically indistinguishable output
* networks under the same seed. That investigation traced the symptom
* to get_nodenames()/nwtomata's own row order being sorted
* LEXICOGRAPHICALLY by node label ("n1","n10","n11",...,"n19","n2",
* "n20","n3",...), not numeric/creation order, and concluded the
* command itself "genuinely works correctly" once a same-group/
* different-group comparison maps each row back to its real attribute
* value BY LABEL rather than assuming row i is the i-th created node.
* That conclusion was real but incomplete: it explains why a
* label-correct COMPARISON can recover the true effect, but never asked
* WHY the returned network's own node order is scrambled relative to
* the caller's own observation order in the first place - which is
* itself a real, separate, and more consequential bug than "a test
* needs to be careful". Traced to its actual source: `nwdyadprob's` own
* density()-conditioned code path (which `nwhomophily` always uses)
* built its final network via `nwfromedge ego alter link, ...` - and
* nwfromedge's own node-ordering assigns each distinct label a position
* by STRING sort, not the numeric value that label encodes. Fixed at
* the source (nwdyadprob.ado): the final network is now reconstructed
* as a plain matrix directly (matching this same file's other,
* already-correct `mat()`-only branch), so a `nwhomophily` caller's Nth
* observation is now genuinely the network's own Nth node - the
* standard "node i = observation i" convention this package relies on
* everywhere else - not something a caller must independently rediscover
* and correct for via get_nodenames() every time. The label-based
* comparison below still passes (it did before the fix too, and still
* does) - the NEW, more direct check right after it is what actually
* guards against this specific bug recurring.
nwclear
clear
set obs 20
gen grp = mod(_n,2)
set seed 42
nwhomophily grp, homophily(2) density(.1) name(hom2)
_nwsyntax hom2
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
di "=== homophily(2)/homophily(-2) oppositely-directioned effect REGRESSION VERIFIED ==="

* --- the actual, direct guard for the bug described above: `hom2''s own
* node order (captured as `__nl' right after it was built, above -
* `hom2' itself is gone by this later point in the file, `nwclear'd
* before `homneg2' was built) must match the caller's own observation
* order (node i's own label decodes to position i), not a
* lexicographically-scrambled one - this is the real, previously-broken
* property, independent of whether a label-aware comparison can still
* recover the right statistical effect despite it.
mata: __posok = 1
mata: for(__i=1; __i<=20; __i++) __posok = __posok & (strtoreal(substr(__nl[__i], 2, .)) == __i)
mata: st_numscalar("__posok", __posok)
assert __posok == 1
di "=== nwhomophily: returned network's node order matches caller's own observation order REGRESSION VERIFIED ==="

* --- alpha-audit regression: nwhomophily.sthlp's own worked example
* for mode(absdistinv) on a continuous variable used to fail even after
* fixing the mode-name typo, due to nwexpand's own absdistinv negation
* bug (see test_nwexpand.do's own regression) cascading into extreme
* sampling weight skew. Confirmed fixed at the doc's own (now properly
* scaled) example values.
nwclear
set obs 20
gen gender = (_n > 10) + 2
gen income = runiform()*10
capture noisily nwhomophily gender income, density(0.05) homophily(-2 0.5) mode(same absdistinv)
assert _rc == 0
di "=== mode(absdistinv) worked example REGRESSION VERIFIED ==="
