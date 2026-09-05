cscript

do unw_core.do

* nwgenvar had no dedicated test coverage of its own - it was only ever
* reached indirectly via nwgen's own tests (test_nwgenerate.do), which
* is misleading: unlike nwgen, nwgenvar is a pure 1-line forwarder
* straight to nwgenerate (nwgenvar.ado has no regex dispatch of its
* own), so it deliberately lacks nwgen's alter.srcvar shortcut.

nwclear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(starnet) undirected labs(A,B,C,D)
gen srcvar = .
replace srcvar = 10 in 1
replace srcvar = 1 in 2
replace srcvar = 2 in 3

* --- ordinary shortcuts forward correctly to nwgenerate.
nwgenvar deg1 = degree(starnet)
assert _rc == 0
assert deg1[1] == 3
assert deg1[2] == 1

* --- nwgenvar does NOT support nwgen's alter.srcvar shortcut (no regex
* dispatch to nwaltergen - goes straight to nwgenerate, which has no
* awareness of the alter. syntax at all).
capture noisily nwgenvar expmean = mean(alter.srcvar)
assert _rc != 0
di "=== nwgenvar lacks nwgen's alter.srcvar shortcut, as documented ==="

* --- failure path: a name that isn't a loaded network is rejected via
* nwgenerate's own _nwsyntax passthrough (error 482).
capture noisily nwgenvar deg2 = degree(nonexistent)
assert _rc != 0
