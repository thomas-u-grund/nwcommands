cscript

do unw_core.do

* --- Star network A-B, A-C, A-D (undirected). srcvar: A=10, B=1, C=2, D=missing.
nwclear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(starnet) undirected labs(A,B,C,D)
gen srcvar = .
replace srcvar = 10 in 1
replace srcvar = 1 in 2
replace srcvar = 2 in 3

nwaltergen expmean = mean(alter.srcvar)
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
