cscript

do unw_core.do

* --- Star network A-B, A-C, A-D (undirected). srcvar: A=10, B=1, C=2, D=missing.
nwclear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(starnet) undirected labs(A,B,C,D)
gen srcvar = .
replace srcvar = 10 in 1
replace srcvar = 1 in 2
replace srcvar = 2 in 3

* _rc regression: a genuinely fresh (first-time) variable creation must
* leave _rc == 0, not the stale 111 ("variable not found") left behind
* by the internal "capture drop <newvarname>" no-op on a variable that
* doesn't exist yet - quietly/mata:/label-variable commands afterward
* do not refresh _rc on their own (see nwbrokerage.ado's own header
* comment for the full explanation). This bug predated proportion()
* (harmonisation unit 26) and was never caught here because every
* existing assertion in this file either checked a replace() call
* (where the prior variable existing makes "capture drop" succeed,
* masking the bug) or never checked _rc at all.
nwaltergen expmean = mean(alter.srcvar)
assert _rc == 0
nwaltergen expsum = sum(alter.srcvar)
nwaltergen expmin = min(alter.srcvar)
nwaltergen expmax = max(alter.srcvar)
nwaltergen expsd = sd(alter.srcvar)
nwaltergen expcount = count(alter.srcvar)

* Node A: alters B,C,D -> values {1,2,.} -> drop missing -> {1,2}
assert reldif(expmean[1], 1.5) < 1E-8
assert expsum[1] == 3
assert expmin[1] == 1
assert expmax[1] == 2
assert reldif(expsd[1], sqrt(0.5)) < 1E-6
assert expcount[1] == 2

* Nodes B,C,D: alters = {A} -> value {10}, single value -> sd undefined (missing)
forvalues i = 2/4 {
	assert expmean[`i'] == 10
	assert expsum[`i'] == 10
	assert expmin[`i'] == 10
	assert expmax[`i'] == 10
	assert expsd[`i'] == .
	assert expcount[`i'] == 1
}


* --- Directed network A->B, A->C, B->C: alter = out-neighbors only
nwclear
nwset, mat((0,1,1\0,0,1\0,0,0)) name(dirnet) directed labs(A,B,C)
gen dsrc = .
replace dsrc = 5 in 1
replace dsrc = 7 in 2
replace dsrc = 9 in 3

nwaltergen dexp = mean(alter.dsrc)
assert reldif(dexp[1], 8) < 1E-8
assert dexp[2] == 9
assert dexp[3] == .


* --- Isolate node: sum/count = 0, mean/min/max/sd = missing
nwclear
nwset, mat((0,1,0\1,0,0\0,0,0)) name(isonet) undirected labs(A,B,C)
gen isrc = .
replace isrc = 1 in 1
replace isrc = 2 in 2
replace isrc = 3 in 3

nwaltergen iexp = mean(alter.isrc)
nwaltergen isum = sum(alter.isrc)
nwaltergen icnt = count(alter.isrc)
assert iexp[3] == .
assert isum[3] == 0
assert icnt[3] == 0


* --- nwgen dispatch shortcut equivalence
nwclear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(starnet2) undirected labs(A,B,C,D)
gen srcvar2 = .
replace srcvar2 = 10 in 1
replace srcvar2 = 1 in 2
replace srcvar2 = 2 in 3

nwaltergen viaalter = mean(alter.srcvar2)
nwgen viagen = mean(alter.srcvar2)
assert viaalter == viagen

nwgen viagen2 = sum(alter.srcvar2)
nwaltergen viaalter2 = sum(alter.srcvar2)
assert viagen2 == viaalter2


* --- replace guard
capture nwaltergen viaalter = mean(alter.srcvar2)
assert _rc != 0
nwaltergen viaalter = mean(alter.srcvar2), replace
assert _rc == 0


* --- invalid stat function errors cleanly
capture nwaltergen badvar = bogus(alter.srcvar2)
assert _rc != 0

* --- missing source variable errors cleanly
capture nwaltergen badvar2 = mean(alter.doesnotexist)
assert _rc != 0

* --- existing nwgenerate shortcuts still dispatch correctly (no regression
* from the new nwgen.ado regexm pre-check)
nwclear
nwset, mat((0,1\1,0)) name(basenet)
nwgen dup1 = duplicate(basenet)
capture nw_syntax dup1
assert _rc == 0

* --- proportion(alter.srcvar==value) / proportion(alter.srcvar!=value)
* (harmonisation unit 26): star network A-B,A-C,A-D,A-E (undirected).
* category: B=3, C=1, D=3, E=missing. A's alters with non-missing
* category are {B=3, C=1, D=3} - 2 of 3 equal 3, so proportion(==3) is
* exactly 2/3 and proportion(!=3) is exactly 1/3. A first implementation
* attempt used Mata's bare == operator, which tests *whole-matrix*
* identity (collapsing to a single scalar) rather than comparing
* elementwise - the elementwise operators are :== / :!= - caught by a
* downstream conformability error, not silently wrong output, but fixed
* here and regression-tested directly.
nwclear
nwset, mat((0,1,1,1,1\1,0,0,0,0\1,0,0,0,0\1,0,0,0,0\1,0,0,0,0)) name(propnet) undirected labs(A,B,C,D,E)
gen category = .
replace category = 3 in 2
replace category = 1 in 3
replace category = 3 in 4
nwaltergen prop3 = proportion(alter.category==3)
assert _rc == 0
assert reldif(prop3[1], 2/3) < 1e-6
nwaltergen propnot3 = proportion(alter.category!=3)
assert _rc == 0
assert reldif(propnot3[1], 1/3) < 1e-6

* mean(alter.x) on an already-binary indicator gives the same answer as
* proportion() on the underlying category - confirms proportion() is a
* genuine convenience wrapper, not a different computation.
gen is3 = (category == 3) if !missing(category)
nwaltergen meanis3 = mean(alter.is3)
assert reldif(meanis3[1], prop3[1]) < 1e-6

* nwgen's own shortcut dispatch recognizes proportion() too.
nwgen prop3b = proportion(alter.category==3), replace
assert _rc == 0
assert reldif(prop3b[1], prop3[1]) < 1e-6

* a non-numeric comparison value is rejected explicitly, not left to
* fail confusingly deep inside the Mata call.
capture nwaltergen propbad = proportion(alter.category=="x")
assert _rc != 0
