cscript

do unw_core.do

// Pinned to match nwpermute.ado's own `version 9.0` so nwrandom's draw and
// nwtabulate's QAP permutations (unorder() in Mata) stay reproducible across
// Stata releases; without it, the RNG algorithm selected differs and the
// asserts below (calibrated under version 9) fail.
version 9
set seed 123
nwrandom 10, prob(.2)
set seed 123
capture nwpermute
assert _rc != 0
capture nwpermute, replace
assert _rc == 0

nwset
assert `"`r(nets)'"' == `" random"'
assert         r(networks) == 1

set seed 123
nwpermute random, generate(perm)
nwset
assert `"`r(nets)'"' == `" random perm"'
assert         r(networks) == 2

nwtabulate random perm
assert `"`r(netname2)'"' == `"perm"'
assert `"`r(netname1)'"' == `"random"'

assert reldif( r(EI_pvalue)  , .2199999988079071 ) <  1E-8
assert reldif( r(EI_index)   , -.4666666686534882) <  1E-8
assert         r(c)         == 2
assert         r(r)         == 2
assert         r(N)         == 90



