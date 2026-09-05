cscript

do unw_core.do

nwclear
nwset, mat((0,1,0,2\0,0,0,0\1,4,0,0\0,2,0,0)) name(mynet1)
nwset, mat(J(4,4,1)) labs(x1, x2, x3, x4) name(mynet2)
nwload mynet2
nwload mynet1

// Test two context for two different networks in memory
gen attr = _n
nwcontext mynet1, attribute(attr) generate(_context_attr)
sum _context_attr

assert reldif( r(sum)    , 7.133333206176758 ) <  1E-8
assert reldif( r(max)    , 3.333333253860474 ) <  1E-8
assert reldif( r(min)    , 1.799999952316284 ) <  1E-8
assert reldif( r(sd)     , .8335554969074795 ) <  1E-8
assert reldif( r(Var)    , .6948147664246752 ) <  1E-8
assert reldif( r(mean)   , 2.377777735392252 ) <  1E-8
assert         r(sum_w) == 3
assert         r(N)     == 3



nwcontext mynet2, attribute(attr) generate(_context_attr) replace
sum _context_attr


assert         r(sum)   == 26
assert         r(max)   == 7
assert         r(min)   == 6
assert reldif( r(sd)     , .4303314418723446 ) <  1E-8
assert reldif( r(Var)    , .1851851498639311 ) <  1E-8
assert reldif( r(mean)   , 6.5               ) <  1E-8
assert         r(sum_w) == 4
assert         r(N)     == 4



// Test different stats
nwclear
nwset, mat((0,1,1\1,0,0\0,0,0)) name(mynet)
gen x = _n

nwcontext mynet, attribute(x) generate(_context_x)
assert _context_x[1] == 2.5
assert _context_x[3] == .

nwcontext mynet, attribute(x) stat(max) generate(_context_x) replace
assert _context_x[1] == 3

nwcontext mynet, attribute(x) stat(min) generate(_context_x) replace
assert _context_x[1] == 2

nwcontext mynet, attribute(x) stat(minego) generate(_context_x) replace
assert _context_x[1] == 1

// Test different network contexts
nwcontext mynet, attribute(x) mode(both) generate(_context_x) replace
assert _context_x[3] == 1

// "either" is the package-wide canonical term for this concept (matches
// nwneighbor's own mode()); "both" is kept working as a legacy alias.
// Regression test: both spellings must give identical results.
nwcontext mynet, attribute(x) mode(either) generate(ctxeither)
assert ctxeither[3] == 1
mata: assert(max(abs(st_data(.,"_context_x") - st_data(.,"ctxeither"))) < 1E-8)

capture nwcontext mynet, attribute(x) mode(bogus)
assert _rc != 0

// Generate
nwcontext mynet, attribute(x) generate(z)
assert z[1] == 2.5

nwload mynet
replace x = . in 1
nwcontext mynet, attribute(x) generate(z2) replace
assert z2[1] == 2.5
assert z2[2] == .
assert z2[3] == .

nwreplace mynet[1,2] = 3
nwname mynet, newvalued(true)
nwcontext mynet, attribute(x) generate(z3) replace
assert z3[1] == 2.25

nwcontext mynet, attribute(x) generate(z4) noweight replace
assert z4[1] == 2.5


* --- alpha-audit regression: stat(maxego) was a Mata syntax error on
* every call (a stray trailing "4" character after `_diag(__contextNet,
* 1)'), and stat(meanego) always failed with "variable not found"
* (referenced the undeclared Mata locals `contextNet'/`attr' instead of
* `__contextNet'/`__attr'). Hand-computed on a fresh 3-node network
* (A->B,A->C undirected star, x=1,2,3): each node's own ego-inclusive
* neighborhood (self + direct ties) is A={1,2,3}, B={1,2}, C={1,3}.
nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) name(egonet)
gen xe = _n
nwcontext egonet, attribute(xe) stat(maxego) generate(zmaxego)
assert _rc == 0
assert zmaxego[1] == 3
assert zmaxego[2] == 2
assert zmaxego[3] == 3

nwcontext egonet, attribute(xe) stat(meanego) generate(zmeanego)
assert _rc == 0
assert zmeanego[1] == 2
assert zmeanego[2] == 1.5
assert zmeanego[3] == 2
di "=== maxego/meanego REGRESSION VERIFIED ==="

* moderate-severity pass, misc_analysis group: mat() was documented
* (nwgen.sthlp's own context() shortcut) and had a fully-written but
* dead code path (`if "`mat'" != "" { mata: `mat' = __context }`) -
* the syntax line simply never declared the option, so passing it
* always errored as unrecognized. Now a real option; must match the
* generate()-based result exactly on the same call.
nwcontext egonet, attribute(xe) generate(zmatcmp)
assert _rc == 0
nwcontext egonet, attribute(xe) generate(zmatcmp_dummy) mat(Mctx)
assert _rc == 0
mata: assert(max(abs(st_data(.,"zmatcmp") - Mctx)) < 1E-8)
di "=== mat() OPTION REGRESSION VERIFIED ==="

* --- failure paths: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482); attribute()
* is a required option (rejected by Stata's own syntax parser without
* it).
capture noisily nwcontext nonexistent, attribute(xe)
assert _rc == 482

capture noisily nwcontext egonet
assert _rc != 0
