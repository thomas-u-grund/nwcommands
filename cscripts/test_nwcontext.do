cscript

do unw_core.do

nwclear
nwset, mat((0,1,0,2\0,0,0,0\1,4,0,0\0,2,0,0)) name(mynet1)
nwset, mat(J(4,4,1)) labs(x1, x2, x3, x4) name(mynet2)
nwload mynet2
nwload mynet1

// Test two context for two different networks in memory
gen attr = _n
nwcontext mynet1, attribute(attr)
sum _context_attr

assert reldif( r(sum)    , 7.133333206176758 ) <  1E-8
assert reldif( r(max)    , 3.333333253860474 ) <  1E-8
assert reldif( r(min)    , 1.799999952316284 ) <  1E-8
assert reldif( r(sd)     , .8335554969074795 ) <  1E-8
assert reldif( r(Var)    , .6948147664246752 ) <  1E-8
assert reldif( r(mean)   , 2.377777735392252 ) <  1E-8
assert         r(sum_w) == 3
assert         r(N)     == 3



nwcontext mynet2, attribute(attr)
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

nwcontext mynet, attribute(x)
assert _context_x[1] == 2.5
assert _context_x[3] == .

nwcontext mynet, attribute(x) stat(max)
assert _context_x[1] == 3

nwcontext mynet, attribute(x) stat(min)
assert _context_x[1] == 2

nwcontext mynet, attribute(x) stat(minego)
assert _context_x[1] == 1

// Test different network contexts
nwcontext mynet, attribute(x) mode(both)
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




