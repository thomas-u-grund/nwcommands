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
capture _nwsyntax dup1
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

* --- hop(k) multi-hop/lagged exposure (harmonisation unit 28): 5-node
* undirected chain A-B-C-D-E, srcvar = node position (A=1,...,E=5). From
* A: hop(1) alter is B (value 2), hop(2) alter is C (value 3), hop(3)
* alter is D (value 4) - a chain has exactly one node at each distance,
* so these are exactly, not just approximately, checkable. hop(1) with
* no hop() option at all must give bit-identical results to the
* explicit hop(1) case (confirms the default truly is 1, not merely
* documented as such).
nwclear
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(chainnet) undirected labs(A,B,C,D,E)
gen chainpos = _n
nwaltergen hopdefault = mean(alter.chainpos)
nwaltergen hop1 = mean(alter.chainpos), hop(1)
nwaltergen hop2 = mean(alter.chainpos), hop(2)
nwaltergen hop3 = mean(alter.chainpos), hop(3)
assert _rc == 0
assert hopdefault[1] == hop1[1]
assert hop1[1] == 2
assert hop2[1] == 3
assert hop3[1] == 4
* C (position 3, the chain's middle) has no node at distance 3 in either
* direction (the chain only has 5 nodes) - missing, not spuriously 0.
assert missing(hop3[3])

* directed chain A->B->C: from A, the hop(2) out-alter is C.
nwclear
nwset, mat((0,1,0\0,0,1\0,0,0)) name(dchainnet) directed labs(A,B,C)
gen dsrcvar = _n * 10
nwaltergen dhop2 = sum(alter.dsrcvar), hop(2)
assert _rc == 0
assert dhop2[1] == 30
* C has no outgoing ties at all - hop(2) sum/count from C is 0, not
* missing (matching sum()'s own zero-alters convention elsewhere).
assert dhop2[3] == 0

* hop() combines with proportion().
nwclear
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(chainnet2) undirected labs(A,B,C,D,E)
gen cat2 = mod(_n, 2)
nwaltergen prophop = proportion(alter.cat2==1), hop(2)
assert _rc == 0

* invalid hop() is rejected explicitly.
capture noisily nwaltergen badhop = mean(alter.chainpos), hop(0)
assert _rc != 0

* nwgen's own dispatch passes hop() through correctly.
nwclear
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(chainnet3) undirected labs(A,B,C,D,E)
gen chainpos3 = _n
nwgen hop2b = mean(alter.chainpos3), hop(2)
assert _rc == 0
assert hop2b[1] == 3

* --- diversity(alter.srcvar): Blau's (1977) index of heterogeneity,
* 1-sum(p_k^2) - the ego-network composition/diversity capability
* nwego's own doc header originally left open (ROADMAP.md's Stage 3
* list). Star network A-B,A-C,A-D,A-E (undirected): B,C,D,E's category
* values are 1,1,2,3 - A's alters split 2/4 category 1, 1/4 category 2,
* 1/4 category 3, so Blau = 1-(.5^2+.25^2+.25^2) = 1-.375 = .625,
* hand-computed and verified directly against calculate_alterstat()'s
* Mata output before this test was written. Nodes B-E each have only A
* as an alter (a single value) - Blau=0 by definition (one category,
* p=1, no diversity), not missing.
nwclear
nwset, mat((0,1,1,1,1\1,0,0,0,0\1,0,0,0,0\1,0,0,0,0\1,0,0,0,0)) name(divnet) undirected labs(A,B,C,D,E)
gen divcat = .
replace divcat = 0 in 1
replace divcat = 1 in 2
replace divcat = 1 in 3
replace divcat = 2 in 4
replace divcat = 3 in 5
nwaltergen divscore = diversity(alter.divcat)
assert _rc == 0
assert reldif(divscore[1], .625) < 1E-8
forvalues i = 2/5 {
	assert divscore[`i'] == 0
}

* all-identical-category alters: Blau=0 exactly, not merely close to 0.
nwclear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(divnet2) undirected labs(A,B,C,D)
gen samecat = .
replace samecat = 5 in 2
replace samecat = 5 in 3
replace samecat = 5 in 4
nwaltergen divsame = diversity(alter.samecat)
assert divsame[1] == 0

* an isolate (zero alters) returns missing, matching mean/min/max/sd's
* own convention - diversity of nothing is undefined, not spuriously 0.
nwclear
nwset, mat((0,0\0,0)) name(diviso) undirected labs(A,B)
gen isocat = .
replace isocat = 1 in 1
replace isocat = 2 in 2
nwaltergen diviso = diversity(alter.isocat)
assert missing(diviso[1])
assert missing(diviso[2])

* nwgen's own dispatch recognizes diversity() too.
nwclear
nwset, mat((0,1,1,1,1\1,0,0,0,0\1,0,0,0,0\1,0,0,0,0\1,0,0,0,0)) name(divnet3) undirected labs(A,B,C,D,E)
gen divcat3 = .
replace divcat3 = 1 in 2
replace divcat3 = 1 in 3
replace divcat3 = 2 in 4
replace divcat3 = 3 in 5
nwaltergen divviaalter = diversity(alter.divcat3)
nwgen divviagen2 = diversity(alter.divcat3)
assert divviaalter == divviagen2

* moderate-severity pass, paths_distance group: error-code coherence -
* nwaltergen used 110 for its "variable already exists" guard, unlike
* every sibling command in the group (99, this package's own standard
* code for the identical situation).
capture noisily nwaltergen divviaalter = diversity(alter.divcat3)
assert _rc == 99
di "=== error-code coherence REGRESSION VERIFIED ==="

* --- wmean(alter.srcvar): tie-strength-weighted exposure mean
* (2026-09-02 addition, closing a self-flagged "Weighted: no" gap in
* docs/NETWORK_TYPE_MATRIX.md - tie strength never entered any
* nwaltergen statistic before this). Valued star network: A ties to B
* (weight 2) and C (weight 4); srcvar (e.g. income) B=10, C=20. Hand
* computed: wmean(A) = (2*10 + 4*20) / (2+4) = 100/6 = 16.666667 - NOT
* the plain unweighted mean, 15, confirming the weight actually enters
* the calculation, not just tolerated syntax that's silently ignored.
nwclear
nwset, mat((0,2,4\2,0,0\4,0,0)) name(wexpnet) undirected labs(A,B,C)
gen wsrcvar = .
replace wsrcvar = 10 in 2
replace wsrcvar = 20 in 3
nwaltergen wexp = wmean(alter.wsrcvar)
assert _rc == 0
assert reldif(wexp[1], 100/6) < 1E-6
di "=== wmean() weighted-exposure REGRESSION VERIFIED ==="

* --- on a BINARY (unvalued) network, every real tie has weight 1, so
* wmean() must reduce to the exact same result as plain mean() - not
* approximately, since edge_weight() returns exactly 1 for any
* present, unvalued tie.
nwclear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(binexpnet) undirected labs(A,B,C,D)
gen bsrcvar = .
replace bsrcvar = 10 in 1
replace bsrcvar = 1 in 2
replace bsrcvar = 2 in 3
nwaltergen bwexp = wmean(alter.bsrcvar)
nwaltergen bmean = mean(alter.bsrcvar)
assert reldif(bwexp[1], bmean[1]) < 1E-8
di "=== wmean() on a binary network matches plain mean() exactly REGRESSION VERIFIED ==="

* --- failure path: wmean() combined with hop() > 1 is rejected with a
* clear, disclosed-scope-limit error, not silently misinterpreted
* (which single tie weight would represent a multi-hop path has no
* single well-defined answer).
nwclear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(hopexpnet) undirected labs(A,B,C,D)
gen hsrcvar = .
replace hsrcvar = 10 in 1
capture noisily nwaltergen hwexp = wmean(alter.hsrcvar), hop(2)
assert _rc == 198

* --- nwgen's own dispatch recognizes wmean() too.
nwclear
nwset, mat((0,2,4\2,0,0\4,0,0)) name(wexpnet2) undirected labs(A,B,C)
gen wsrcvar2 = .
replace wsrcvar2 = 10 in 2
replace wsrcvar2 = 20 in 3
nwaltergen wexpviaalter = wmean(alter.wsrcvar2)
nwgen wexpviagen = wmean(alter.wsrcvar2)
assert wexpviaalter == wexpviagen
di "=== nwgen wmean() dispatch REGRESSION VERIFIED ==="
