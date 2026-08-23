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

* NOT asserted here (see docs/CERTIFICATION.md's own Pending row for
* this): whether the homophily coefficient's actual statistical effect
* on tie formation is correct. Investigated directly - homophily(2) and
* homophily(-2) produce byte-identical output networks under the same
* seed, despite the underlying weight construction (nwhomophily's own
* exp(homophily * same-group indicator), correctly and oppositely
* signed for +2 vs -2, confirmed by hand) being genuinely different and
* correctly directioned. Root cause traced to nwdyadprob.ado's own
* density()-conditioned branch, which hands the weight matrix to the
* third-party `gsample` package (`gsample `ties' [aweight=_tempdyad],
* generate(link) wor`) for weighted sampling without replacement - the
* actual selection gsample performs does not appear to vary with the
* weights at all in this environment, a third-party-package behaviour
* this session cannot inspect or fix directly. This is a real, deeper,
* separate concern from the crash this unit actually fixes (nwhomophily
* could not complete a single call before; it reliably does now) - not
* silently asserted as correct, and not blocking this unit's own crash
* fix, which is what was actually in scope.
