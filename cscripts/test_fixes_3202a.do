cscript

* Fixes after 3.20.1 (code read against the help files): _nwevalnetexp; nwgenerate sym() and large();
* labs() with ntimes() in nwring and nwsmall; nwdropnodes keepmat() of the wrong size; nwdegree on a list
* of one- and two-mode networks; nwplot iterations(); nwnoderename error code; animate graphs(_all), mag()
* and clean-up; options that were accepted but unused; nwreplacemat r(directed); nwclustering
* r(symmetrized); the valued note of nwtabulate; no stray r() from nwexport, nwimport, _nwdatasync; no
* scalars or matrices left by nwfactions, nwkcomponents, nwkplex, nwnclan, nwnclique; nwsummarize r().
clear mata
do unw_core.do
set more off
clear all
set seed 12345

* 1 _nwevalnetexp: an empty expression gives the documented error
nwclear
capture _nwevalnetexp , nodes(5)
assert _rc == 6077
di "PASS evalnetexp"

* 2 nwgenerate: sym() and large()
nwclear
nwset, mat((0,1,0,0,0\0,0,1,0,0\0,0,0,0,0\0,0,0,0,1\0,0,0,0,0)) name(d) directed
nwgen s = sym(d)
nwtomata s, mat(S)
mata: _editmissing(S, 0)
mata: assert(S == S')
mata: assert(S[2,1] == 1 & S[1,2] == 1)
nwtomata d, mat(D)
mata: _editmissing(D, 0)
mata: assert(D[2,1] == 0)
nwgen l = large(d)
nwsummarize l
assert r(nodes) == 3
nwsummarize d
assert r(nodes) == 5
di "PASS nwgenerate"

* 3 labs() is used by every network of ntimes()
foreach c in "nwring 4, k(1)" "nwsmall 4, k(1) prob(.1)" {
	nwclear
	`c' ntimes(2) labs(a,b,c,d) name(r)
	nwname r_2
	assert `"`r(labs)'"' == "a,b,c,d"
	nwname r_1
	assert `"`r(labs)'"' == "a,b,c,d"
}
di "PASS ntimes labs"

* 4 nwdropnodes keepmat() of the wrong size: error, the matrix of the user is not changed
nwclear
nwrandom 5, prob(.5) name(k)
mata: K = J(3, 1, 0)
capture nwdropnodes k, keepmat(K)
assert _rc == 503
mata: assert(K == J(3, 1, 0))
nwsummarize k
assert r(nodes) == 5
mata: K = (1\0\1\1\1)
nwdropnodes k, keepmat(K)
nwsummarize k
assert r(nodes) == 4
di "PASS dropnodes"

* 5 nwdegree on a list of a two-mode and one-mode networks
nwclear
clear
input str10 person str10 org
"Thomas" "Oxford"
"Peter" "Oxford"
"Tim" "Oxford"
"Peter" "LiU"
"Tim" "LiU"
end
nwset person org, twomode name(tm)
nwrandom 5, prob(.5) undirected name(om)
nwrandom 5, prob(.5) name(om2)
nwdegree tm om om2, generate(deg ideg)
confirm variable deg_tm deg_om deg_om2 ideg_om2, exact
di "PASS degree mixed"

* 6 nwplot: iterations() of nwplot is used; layout(..., iterations()) takes precedence
nwclear
clear
nwrandom 15, prob(.2) name(p)
set seed 1
nwplot p, layout(frucht) iterations(2) generate(x1 y1)
set seed 1
nwplot p, layout(frucht, iterations(2)) generate(x2 y2)
set seed 1
nwplot p, layout(frucht) generate(x3 y3)
set seed 1
nwplot p, layout(frucht, iterations(2)) iterations(500) generate(x4 y4)
assert x1 == x2 & y1 == y2
assert x4 == x2 & y4 == y2
count if x1 != x3 | y1 != y3
assert r(N) > 0
graph drop _all
di "PASS plot iterations"

* 7 nwnoderename: error code
nwclear
nwrandom 4, prob(1) name(rn)
capture nwnoderename rn, old(zzz) new(y1)
assert _rc == 198
assert r(success) == 0
di "PASS noderename"

* 8 animate: graphs(_all) ends with the last graph; mag(); .eps files erased
local here `"`c(pwd)'"'
tempfile tf
local adir = substr(`"`tf'"', 1, strrpos(`"`tf'"', "/")) + "nwanim3202a"
capture mkdir `"`adir'"'
qui cd `"`adir'"'
graph drop _all
sysuse auto, clear
scatter price mpg, name(ga)
scatter price weight, name(gb)
scatter mpg weight, name(gc)
qui graph dir
local glist `r(list)'
local glast : word 3 of `glist'
tempfile alog
log using `alog', text replace name(anim)
animate movie, graphs(_all) showcommand keepeps mag(50)
log close anim
tempname fh
file open `fh' using `alog', read
local found 0
file read `fh' line
while r(eof) == 0 {
	if strpos(`"`line'"', "-delay 50 `glast'.eps -loop") local found 1
	file read `fh' line
}
file close `fh'
assert `found' == 1
confirm file ga.eps
animate movie, graphs(ga gb)
capture confirm file ga.eps
assert _rc != 0
capture confirm file gb.eps
assert _rc != 0
capture erase gc.eps
capture erase movie.gif
graph drop _all
qui cd `"`here'"'
di "PASS animate"

* 9 options accepted but unused before
* nwplotmatrix labelopt() and legendopt()
nwclear
clear
nwrandom 8, prob(.4) name(pm)
nwplotmatrix pm, labelopt(labsize(tiny)) legendopt(rows(2))
graph drop _all
* nwtabulate two networks: unvalued and save()
nwclear
clear
nwset, mat((0,2,3,0\2,0,0,1\3,0,0,4\0,1,4,0)) name(v1) undirected
nwset, mat((0,1,1,0\1,0,0,1\1,0,0,1\0,1,1,0)) name(v2) undirected
nwtabulate v1 v2, unvalued permutations(1)
mata: assert(all(st_matrix("r(row)") :== 0 :| st_matrix("r(row)") :== 1))
nwtabulate v1 v2, permutations(1)
mata: assert(any(st_matrix("r(row)") :> 1))
tempfile qs
nwtabulate v1 v2, permutations(5) save(`qs')
preserve
use `qs', clear
assert _N == 5
confirm variable EI_simulated EI_observed
restore
* nwtabulate network by attribute: save()
nwclear
clear
nwrandom 10, prob(.4) name(ta)
gen g = mod(_n, 2)
tempfile qs3
nwtabulate ta, attribute(g) permutations(5) save(`qs3')
preserve
use `qs3', clear
assert _N == 5
restore
* nwgeodesic noreplace protects _geodesic too
nwclear
nwrandom 6, prob(.5) name(gd)
nwgeodesic gd
capture nwgeodesic gd, noreplace
assert _rc == 99
nwgeodesic gd
di "PASS options"

* 10 nwreplacemat r(directed)
nwclear
nwrandom 4, prob(.5) name(rm)
mata: Ms = (0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)
nwreplacemat rm, newmat(Ms)
assert r(directed) == 0
nwname rm
assert "`r(directed)'" == "false"
mata: Ma = (0,1,0,0\0,0,1,0\0,0,0,1\1,0,0,0)
nwreplacemat rm, newmat(Ma)
assert r(directed) == 1
nwname rm
assert "`r(directed)'" == "true"
di "PASS replacemat"

* 11 nwclustering symmetrize: r(symmetrized) = true
nwclear
nwrandom 10, prob(.3) name(cl)
nwclustering cl, symmetrize generate(cc)
assert "`r(symmetrized)'" == "true"
di "PASS clustering"

* 12 nwtabulate: the note about tie values only for the table by attribute()
nwclear
clear
nwset, mat((0,2,3,0\2,0,0,1\3,0,0,4\0,1,4,0)) name(w) undirected
gen a = mod(_n, 2)
foreach c in "w" "w w, permutations(1)" "w, attribute(a) permutations(1)" {
	tempfile nlog
	log using `nlog', text replace name(note)
	nwtabulate `c'
	log close note
	tempname fn
	file open `fn' using `nlog', read
	local note 0
	file read `fn' line
	while r(eof) == 0 {
		if strpos(`"`line'"', "tie values are ignored") local note 1
		file read `fn' line
	}
	file close `fn'
	if strpos("`c'", "attribute") assert `note' == 1
	else assert `note' == 0
}
di "PASS tab note"

* 13 no stray r() from nwexport, nwimport and _nwdatasync
nwclear
clear
nwrandom 6, prob(.4) name(ex)
tempfile xf
nwexport ex, type(pajek) fname(`xf') replace
assert "`r(nodes)'" == "" & "`r(has)'" == "" & "`r(N)'" == ""
nwimport `"`xf'.net"', type(pajek) nwclear
assert "`r(nodes)'" == "" & "`r(networks)'" == "" & "`r(is_symmetric)'" == ""
nwclear
nwrandom 5, prob(.4) name(ds)
qui count
_nwdatasync ds
assert "`r(nodes)'" == ""
* the slow path (data sorted, so not known to be in sync) leaves the caller's r() as it was
gen double x = 10 - _n
sort x
qui summarize x
local m0 = r(mean)
local n0 = r(N)
_nwdatasync ds
assert r(N) == `n0' & r(mean) == `m0' & "`r(nodes)'" == ""
_nwdatasync ds, force
assert r(N) == `n0' & r(mean) == `m0'
* an error inside still stops with its code
capture _nwdatasync nosuchnet_zz
assert _rc != 0
di "PASS no stray r()"

* 14 no scalars or matrices left behind
nwclear
clear
scalar drop _all
matrix drop _all
nwrandom 10, prob(.5) undirected name(kk)
nwkcomponents kk, generate(kc)
assert r(kcomponents) >= 0
nwkplex kk, k(2) generate(kp)
nwkplex kk, k(2) countonly
assert r(kplexes) > 0
nwnclan kk, n(2) generate(ncl)
nwnclan kk, n(2) countonly
nwnclique kk, n(2) generate(ncq)
nwnclique kk, n(2) countonly
nwfactions kk, generate(fa)
assert r(fitness) < .
* nomatrix gives the same per-node variable as the matrix path (a single set was an error in Mata, r(3200))
nwnclique kk, n(2) nomatrix generate(ncq2)
assert ncq2 == ncq
nwkplex kk, k(2) nomatrix generate(kp2)
assert kp2 == kp
nwnclan kk, n(2) nomatrix generate(ncl2)
assert ncl2 == ncl
nwclear
nwset, mat(J(5, 5, 1) - I(5)) name(full) undirected
nwnclique full, n(2) generate(fm)
nwnclique full, n(2) nomatrix generate(fn)
assert fn == fm & fn == 5 in 1/5
nwkplex full, k(2) nomatrix generate(fk)
assert fk == 5 in 1/5
mata: assert(rows(st_dir("global", "numscalar", "nw_*")) == 0)
mata: assert(rows(st_dir("global", "numscalar", "faction_*")) == 0)
mata: assert(rows(st_dir("global", "matrix", "nw_*")) == 0)
di "PASS leftovers"

* 15 nwsummarize without detail stores no detail measures; with detail it does
nwclear
nwrandom 10, prob(.3) undirected name(su)
nwsummarize su
assert "`r(dg_central)'" == "" & "`r(transitivity)'" == "" & "`r(reciprocity)'" == ""
nwsummarize su, detail
assert r(dg_central) < . & r(transitivity) < .
nwrandom 10, prob(.3) name(sd)
nwsummarize sd
assert "`r(indg_central)'" == ""
nwsummarize sd, detail
assert r(indg_central) < . & r(outdg_central) < .
di "PASS summarize"

di "ALL PASS"
