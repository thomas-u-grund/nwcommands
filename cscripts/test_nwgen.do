cscript

do unw_core.do

* nwgen had no dedicated test coverage of its own - its own unique
* behavior (a regex check on the expression text that dispatches
* "= stat(alter.var)" expressions to nwaltergen, on top of everything
* else nwgenerate already covers) was only ever exercised incidentally
* via test_nwgenerate.do (ordinary, non-alter expressions) and a single
* proportion() case buried in test_nwaltergen.do. This file certifies
* the dispatch layer itself, cross-checked against nwaltergen called
* directly on the same network/attribute.

nwclear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(starnet) undirected labs(A,B,C,D)
gen srcvar = .
replace srcvar = 10 in 1
replace srcvar = 1 in 2
replace srcvar = 2 in 3

* --- nwgen's regex dispatch recognizes each of the six base keywords
* (mean|sum|min|max|sd|count) followed by "(alter." and routes the
* WHOLE expression to nwaltergen, rather than nwgenerate (which has no
* awareness of the alter. syntax at all - confirmed directly in
* test_nwgenvar.do). Every dispatched result must match calling
* nwaltergen directly on the identical expression.
nwgen viamean = mean(alter.srcvar)
assert _rc == 0
nwaltergen directmean = mean(alter.srcvar)
assert viamean[1] == directmean[1]
assert reldif(viamean[1], 1.5) < 1E-8

nwgen viasum = sum(alter.srcvar)
nwaltergen directsum = sum(alter.srcvar)
assert viasum[1] == directsum[1]
assert viasum[1] == 3

nwgen viacount = count(alter.srcvar)
nwaltergen directcount = count(alter.srcvar)
assert viacount[1] == directcount[1]
assert viacount[1] == 2

* --- an expression that merely CONTAINS the substring "alter." but
* does not match one of the six recognized keywords must NOT be
* diverted to nwaltergen (the regex anchors on a specific keyword list,
* not a bare "alter." substring check).
capture noisily nwgen notdispatched = bogusfcn(alter.srcvar)
assert _rc != 0

* --- ordinary (non-alter) expressions still forward to nwgenerate
* exactly as before - the regex must not misfire on unrelated syntax.
nwgen doubled = 2 * starnet
assert _rc == 0
nwvalue doubled, ego("A") alter("B")
assert r(value) == 2

di "=== nwgen's alter. dispatch layer REGRESSION VERIFIED ==="
