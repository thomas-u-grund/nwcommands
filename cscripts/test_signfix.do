cscript

* Signed (negative-valued) undirected networks keep their negative ties through every path that builds an
* undirected network from a tie list: nwfromedge, nwset, nwsave/nwuse/nwappend, nwexport/nwimport, and the three
* signed example data sets. Before the fix nwuse/nwfromedge symmetrised with "max", which compares a tie of -1 with
* the 0 of the absent direction and kept the 0. Run from the repository root.

do unw_core.do

capture program drop sfsum
program sfsum
	args net edges sum minv maxv
	qui nwsummarize `net'
	assert "`r(directed)'" == "false"
	assert r(edges) == `edges'
	assert r(edges_sum) == `sum'
	assert r(minval) == `minv'
	assert r(maxval) == `maxv'
end

capture program drop sfload
program sfload
	nwclear
	use "$SFEL", clear
end

tempfile el
global SFEL "`el'"
* 5 nodes, each pair listed once: 2 positive and 3 negative ties
clear
input str2 a str2 b sg
A B 1
B C -1
A C -1
C D 1
D E -1
end
save "$SFEL", replace

* ---- nwfromedge, undirected, each tie listed once
sfload
nwfromedge a b sg, undirected name(g1)
sfsum g1 5 -1 -1 1
* triangle A B C: + - - is balanced
nwbalance g1
assert r(closed_triad) == 1 & r(balanced_triad) == 1
* a triangle with one negative tie is unbalanced
nwclear
clear
input str2 a str2 b sg
A B 1
B C 1
A C -1
end
nwfromedge a b sg, undirected name(u3)
nwbalance u3
assert r(closed_triad) == 1 & r(balanced_triad) == 0

* ---- forceundirected
sfload
nwfromedge a b sg, forceundirected name(g2)
sfsum g2 5 -1 -1 1

* ---- both directions listed (older files): unchanged
sfload
preserve
rename (a b) (b a)
tempfile rv
save `rv'
restore
append using `rv'
tempfile both
save `both'
nwfromedge a b sg, undirected name(g3)
sfsum g3 5 -1 -1 1
use `both', clear
nwfromedge a b sg, name(g3b)
sfsum g3b 5 -1 -1 1

* ---- mixed: one direction listed for some pairs, both for others, conflicting values keep the larger value
nwclear
clear
input str2 a str2 b sg
A B 1
B A 1
B C -1
C D 1
D C -1
end
nwfromedge a b sg, undirected name(g4)
nwsummarize g4
assert r(edges) == 3
* (C D conflicting +1 / -1: the larger value, +1, as documented for nwsym mode max)
nwvalue g4, ego(C) alter(D)
assert r(value) == 1
nwvalue g4, ego(B) alter(C)
assert r(value) == -1

* ---- nwset with a tie list
sfload
nwset a b sg, edgelist undirected name(g5)
sfsum g5 5 -1 -1 1

* ---- nwtoedge then nwfromedge
nwclear
sfload
nwfromedge a b sg, undirected name(g1)
nwtoedge g1, ego(e) alter(r) compress
qui keep if g1 != 0
nwfromedge e r g1, undirected name(g6)
sfsum g6 5 -1 -1 1

* ---- nwsave / nwuse / nwappend
sfload
nwfromedge a b sg, undirected name(g7)
nwsave g7, replace
nwuse g7, nwclear
sfsum g7 5 -1 -1 1
nwbalance g7
assert r(balanced_triad) == 1
nwclear
sfload
nwfromedge a b sg, undirected name(other)
nwappend using g7
sfsum g7 5 -1 -1 1
sfsum other 5 -1 -1 1
erase g7.nwdta

* ---- a file written by the old nwsave workaround (each tie in both directions) still loads the same
sfload
nwfromedge a b sg, undirected name(old1)
nwsave old1, replace
use old1.nwdta, clear
preserve
qui keep if _nw_match_old1_nw_ego == 1
rename (_nw_ego _nw_alter) (x y)
rename (x y) (_nw_alter _nw_ego)
tempfile rv2
qui save `rv2'
restore
append using `rv2'
save old1.nwdta, replace
nwclear
nwuse old1, nwclear
sfsum old1 5 -1 -1 1
erase old1.nwdta

* ---- edge list file: nwexport then nwimport (once per tie in the file)
sfload
nwfromedge a b sg, undirected name(g8)
nwexport g8, type(edgelist) fname("sfex") replace
nwimport sfex.txt, type(edgelist) nwclear name(g9) forceundirected
sfsum g9 5 -1 -1 1
nwimport sfex.txt, type(edgelist) nwappend name(g10) undirected
sfsum g10 5 -1 -1 1
erase sfex.txt

* ---- pajek and ucinet (nwimport of gml does not read tie values at all; that is a separate limitation)
foreach t in pajek ucinet {
	sfload
	nwfromedge a b sg, undirected name(h1)
	nwexport h1, type(`t') fname("sfex") replace
	nwimport sfex.`=cond("`t'" == "pajek", "net", "dl")', type(`t') nwclear name(h2)
	sfsum h2 5 -1 -1 1
	capture erase sfex.net
	capture erase sfex.dl
}

* ---- nwsym on a directed signed network (documented semantics, unchanged)
sfload
nwfromedge a b sg, directed name(d1)
nwsym d1, generate(smax) mode(max)
sfsum smax 2 2 0 1
nwsym d1, generate(smin) mode(min)
sfsum smin 3 -3 -1 0
nwsym d1, generate(ssum) mode(sum)
sfsum ssum 5 -1 -1 1

* ---- signed example data sets (tie stored once)
nwuse data/gahuku, nwclear
nwsummarize gahuku
assert r(edges) == 58 & r(edges_sum) == 0 & r(minval) == -1
nwbalance gahuku
assert r(closed_triad) == 68 & r(balanced_triad) == 59
nwuse data/senate114, nwclear
nwbalance senate114
assert r(closed_triad) == 74140 & r(balanced_triad) == 72139
nwsummarize senate114
assert r(edges) == 3696 & r(edges_sum) == 1435 - 2261
nwuse data/senate93, nwclear
nwbalance senate93
assert r(closed_triad) == 25355 & r(balanced_triad) == 13947
nwsummarize senate93
assert r(edges) == 2439

di "test_signfix: done"
