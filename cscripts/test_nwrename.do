cscript

do unw_core.do

nwclear
nwrandom 5, prob(1) name(mynet)
nwrename mynet newname
nwname
assert "`r(netname)'" == "newname"

* moderate-severity pass, manipulation_transform group: renaming to an
* already-existing network name used to surface Stata's raw built-in
* rename error (phrased entirely in terms of "variable") and left the
* dataset in a corrupted mid-preserve state on failure.
nwclear
nwrandom 4, prob(.3) name(coll1)
nwrandom 4, prob(.3) name(coll2)
gen mydata = 99
capture noisily nwrename coll1 coll2
assert _rc == 110
assert _N == 4
assert mydata[1] == 99
nwset
assert `"`r(nets)'"' == `" coll1 coll2"'
di "=== name collision REGRESSION VERIFIED ==="




