cscript
// regression tests for the pkgfix2 round of small fixes
clear all
set more off
set seed 123

* 1. nw2project / nwproject: ties = number of edges
nwclear
input str10 ego str10 alter
"a" "x"
"a" "y"
"b" "x"
"b" "y"
"c" "y"
end
nw2fromedge ego alter, name(aff)
nw2project aff, project(1) name(pj)
* a, b, c: a-b share x and y, a-c and b-c share y: 3 edges
assert r(ties) == 3
assert r(nodes) == 3

* 2. nwmixing: long labels survive
clear
set obs 20
gen str25 place = cond(_n<=10, "Providence Heights", "Other Quarter Town")
encode place, gen(pl)
nwrandom 20, prob(.4) undirected name(u)
log using "pkgfix2_mix.log", replace text name(mixlog)
nwmixing u, attribute(pl) permutations(2)
log close mixlog
tempname fh
local found 0
file open `fh' using "pkgfix2_mix.log", read text
file read `fh' line
while r(eof)==0 {
	if strpos(`"`line'"', "Providence Heights") > 0 local found 1
	file read `fh' line
}
file close `fh'
erase "pkgfix2_mix.log"
assert `found' == 1

* 3. nwaltergen announces the network it uses
gen x = runiform()
nwaltergen m = mean(alter.x)
nwaltergen m = mean(alter.x), net(u) replace

* 4. nopaths / silent
nwpath u, egoid(1) alterid(5) nopaths
assert r(paths) != .
nwcloseness u, generate(c f n) replace silent

* 5. directed no-op
nwrandom 10, prob(.3) directed name(d1)
nwsummarize d1, silent
assert "`r(directed)'" == "true"
capture nwrandom 10, prob(.3) directed undirected name(d2)
assert _rc == 198

* 7. nwpermute nwreplace
nwpermute u, generate(up)
capture nwpermute u, generate(up)
assert _rc == 99
nwpermute u, generate(up) nwreplace

* 11. nwqap quiet progress without detail
nwrandom 15, prob(.3) name(q1)
nwrandom 15, prob(.3) name(q2)
log using "pkgfix2_qap.log", replace text name(qlog)
nwqap q1 q2, permutations(60)
log close qlog
file open `fh' using "pkgfix2_qap.log", read text
local bad 0
file read `fh' line
while r(eof)==0 {
	if strpos(`"`line'"', "Permutation:") > 0 local bad 1
	file read `fh' line
}
file close `fh'
erase "pkgfix2_qap.log"
assert `bad' == 0

* 12. nwcug census warning (reciprocity is fixed by the census)
nwcug d1, stat(nwsummarize ##net##, detail silent) rname(reciprocity) reps(5) condition(census)

* 13. nwsummarize detail on undirected: stored value kept
nwsummarize u, detail
assert r(reciprocity) != .

* 16. listall and the 30-row cap
nwrandom 80, prob(.01) undirected name(sparse)
nwcomponents sparse, generate(cmp) replace
nwcomponents sparse, generate(cmp) replace listall silent
nwcommunity u, generate(cm) replace listall

* dialogs
foreach d in nwcommunity nwcomponents nwpath nwcloseness nwpermute nwrandom {
	capture db `d'
	assert _rc == 0
}
di "PASS test_pkgfix2"
