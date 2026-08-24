cscript

do unw_core.do

nwclear
set obs 4
gen v1 = 0
gen v2 = (_n == 3)
gen v3 = (_n < 3)
gen v4 = 0
gen v5 = (_n < 3)
nwset v*, name(netfromvar1)

nwcorrelate
assert `"`r(context)'"'  == `"outgoing"'
assert `"`r(corrname)'"' == `"_corr"'
assert `"`r(name)'"'     == `"netfromvar1"'
assert reldif( r(avg_corr)  , -.3333333333333333) <  1E-8

nwsummarize _corr

assert `"`r(valued)'"'   == `"true"'
assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"_corr"'
assert `"`r(name)'"'     == `"_corr"'
assert `"`r(labs)'"'     == `"n1,n2,n3,n4"'
assert `"`r(directed)'"' == `"true"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"n1 n2 n3 n4"'

assert         r(nodes)         == 4
assert         r(density)       == 1
assert         r(arcs_value)    == -4
assert         r(arcs)          == 12
assert         r(maxval)        == 1
assert         r(minval)        == -1
assert         r(missing_edges) == 4
assert         r(selfloops)     == 0
assert         r(id)            == 2

nwdrop _corr

drop _all
set obs 4
gen v1 = 1
gen v2 = (_n == 3)
gen v3 = (_n < 2)
gen v4 = 0
gen v5 = (_n < 2)
nwset v*, name(netfromvar2)

nwcorrelate netfromvar1 netfromvar1
assert `"`r(name_1)'"' == `"netfromvar1"'
assert `"`r(name_2)'"' == `"netfromvar1"'
assert         r(corr) == 1

nwset
assert `"`r(nets)'"' == `" netfromvar1 netfromvar2"'
assert         r(networks) == 2

nwcorrelate netfromvar1 netfromvar2
assert `"`r(name_1)'"' == `"netfromvar1"'
assert `"`r(name_2)'"' == `"netfromvar2"'
assert reldif( r(corr)  , .2927700218845599 ) <  1E-8

gen x = _n

nwcorrelate netfromvar1, attribute(x) mode(absdistinv)


assert `"`r(name_1)'"' == `"netfromvar1"'
assert `"`r(name_2)'"' == `"absdistinv_x"'
assert reldif( r(corr)  , .2581988897471612 ) <  1E-8

* nwcorrelate_nodes (single-network node-similarity correlation
* matrix, also nwsimilar's own type(pearson) default) had two
* genuine, independent pre-existing bugs found while sparsifying its
* backing correlate_nodes() (unw_core.do) for performance
* (docs/CERTIFICATION.md): context(incoming) referenced a
* declared-but-never-assigned variable (a typo), and context(both)
* used cols() instead of rows() on a column vector - always 1,
* regardless of the vector's actual length - causing a hard
* conformability crash for any network with more than 3 nodes. Both
* are exercised here for the first time; a directed, asymmetric
* network confirms context() genuinely changes the result (rather
* than e.g. all three silently computing the same thing).
nwclear
nwset, mat((0,1,1,0\0,0,1,0\0,0,0,1\1,0,0,0)) name(dircorr) directed labs(A,B,C,D)

nwcorrelate dircorr, context(outgoing) name(_cout)
assert _rc == 0
nwtomatafast _cout
mata: Cout = `r(mata)'
mata: assert(max(Cout) <= 1 + 1e-8 & min(Cout) >= -1 - 1e-8)

nwcorrelate dircorr, context(incoming) name(_cin)
assert _rc == 0
nwtomatafast _cin
mata: Cin = `r(mata)'
mata: assert(max(Cin) <= 1 + 1e-8 & min(Cin) >= -1 - 1e-8)
* context(incoming) must give a genuinely different matrix from
* context(outgoing) on this asymmetric network - the pre-fix bug
* made this branch crash outright, so this also confirms it now
* actually uses the incoming ties, not silently reusing outgoing.
mata: assert(max(abs(Cout :- Cin)) > 1e-8)

nwcorrelate dircorr, context(both) name(_cboth)
assert _rc == 0
nwtomatafast _cboth
mata: Cboth = `r(mata)'
mata: assert(max(Cboth) <= 1 + 1e-8 & min(Cboth) >= -1 - 1e-8)

* moderate-severity pass, stat_models group: a misspelled/nonexistent
* network name used to crash with a raw Mata error (r3301) instead of a
* clean message.
nwclear
nwrandom 5, prob(.5) name(realnetcorr)
capture noisily nwcorrelate typobogus typobogus
assert _rc == 482
di "=== misspelled network name REGRESSION VERIFIED ==="

* an undefined observed correlation (zero-variance network) used to
* crash the QAP permutation branch with a confusing, low-level Mata
* syntax error ("unexpected end of line <istmt> incomplete", r3000).
nwclear
nwrandom 5, prob(1) name(constnet)
gen distinctattr = _n
capture noisily nwcorrelate constnet, attribute(distinctattr) permutations(10)
assert _rc == 198
di "=== undefined correlation REGRESSION VERIFIED ==="







