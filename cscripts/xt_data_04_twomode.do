* xt_data_04_twomode.do
* Two-mode networks: nwset ..., twomode (numeric ids with overlapping ranges, string ids used in both modes,
* values), nwset, mat() bipartite, nwfromedge ..., twomode, nw2fromedge, the edge list of a two-mode network
* (default = ties only, allpairs), round trip edge list -> network with modes, labels and level names kept,
* nwaddnodes with mode(), nwname new2mode(), nwreplacemat with a same-mode tie, and the error paths
* (option conflicts, name in use) with data and networks unchanged.
* Expected numbers are derived by hand.
clear all
set more off
run cscripts/xt_data_00_helpers.do
xt_init xt_data_04_twomode
nwclear

* --- A. declaration from an edge list
clear
input p o
1 1
2 1
3 2
end
tempfile eln
save `eln'
nwset p o, twomode name(tn)
quietly nwname tn
xt_chk `=("`r(mode2)'" == "true")' "numeric ids: two-mode"
xt_chk `=(r(nodes) == 5 & r(nodes1) == 3 & r(nodes2) == 2)' "overlapping numeric ids 1-3 and 1-2: 3 + 2 nodes (got `r(nodes1)' + `r(nodes2)')"
xt_mat tn __xt_A
mata: st_local("s", strofreal(sum(__xt_A)))
xt_chk `=("`s'" == "6")' "3 ties stored in both directions: 6 cells (got `s')"
clear
input str6 p str6 o
"x" "x"
"y" "x"
"y" "z"
end
nwset p o, twomode name(ts)
quietly nwname ts
xt_chk `=(r(nodes1) == 2 & r(nodes2) == 2)' "string ids: 2 + 2 nodes (got `r(nodes1)' + `r(nodes2)')"
mata: st_local("ok", strofreal(xt_sorteq(st_global("r(labs)"), "m1_x,m1_y,m2_x,m2_z")))
xt_chk `ok' "a string used in both modes gets the prefixes m1_/m2_ (got `r(labs)')"
clear
input str6 p str6 o v
"a" "k" 2
"b" "k" -1.5
end
nwset p o v, twomode name(tv)
quietly nwname tv
xt_chk `=("`r(valued)'" == "true")' "two-mode with values: valued"
xt_mat tv __xt_A
mata: st_local("ok", strofreal(sum(__xt_A :== 2) == 2 & sum(__xt_A :== -1.5) == 2))
xt_chk `ok' "two-mode values 2 and -1.5 kept (both directions)"
* one node per mode
clear
input str1 p str1 o
"a" "b"
end
nwset p o, twomode name(t11)
quietly nwname t11
xt_chk `=(r(nodes1) == 1 & r(nodes2) == 1)' "one node in each mode"
di "PASS A declaration"

* --- B. bipartite matrix: columns are mode 1, rows mode 2
nwset, mat((1,0,1\0,1,0)) bipartite name(bip)
quietly nwname bip
xt_chk `=(r(nodes) == 5 & r(nodes1) == 3 & r(nodes2) == 2)' "bipartite 2 x 3 matrix: 3 + 2 nodes"
xt_mat bip __xt_A
mata: st_local("s", strofreal(sum(__xt_A)))
xt_chk `=("`s'" == "6")' "bipartite: 3 ties, 6 cells (got `s')"
nwtomata bip, mat(__xt_B)
mata: st_local("m", strofreal(missing(__xt_B[|1,1 \ 3,3|]) == 9 | sum(xt_od(__xt_B[|1,1 \ 3,3|])) == 0))
xt_chk `m' "bipartite: no tie inside mode 1"
di "PASS B bipartite"

* --- C. edge list of a two-mode network
nwtoedge bip
xt_chk `=(_N == 3)' "two-mode edge list: the 3 ties only by default (got `=_N')"
* nw2toedge.sthlp: nwtoedge with allpairs also lists the pairs inside one mode (one row per pair incl. the
* diagonal, 5 nodes: 15), nw2toedge with allpairs only the pairs of different modes (3 x 2 = 6)
nwtoedge bip, allpairs
xt_chk `=(_N == 15)' "nwtoedge two-mode edge list, allpairs: every pair, 5 * 6 / 2 = 15 rows (got `=_N')"
nw2toedge bip, allpairs
xt_chk `=(_N == 6)' "nw2toedge two-mode edge list, allpairs: 3 x 2 = 6 rows (got `=_N')"
di "PASS C edge list"

* --- D. round trip: edge list -> two-mode network keeps modes, labels, ties, level names
nwclear
clear
input str8 person str8 org v
"Thomas" "Oxford" 1
"Peter" "Oxford" 2
"Tim" "LiU" 3
"Anna" "LiU" .5
end
nwset person org v, twomode name(aff)
quietly nwname aff
local l0 `"`r(labs)'"'
local n10 = r(nodes1)
local n20 = r(nodes2)
local d10 `"`r(mode1desc)'"'
local d20 `"`r(mode2desc)'"'
xt_mat aff __xt_A0
nwtoedge aff
* nwtoedge of a two-mode network lists the mode-1 node as _ego and the mode-2 node as _alter (owner's decision
* on N4); the swap below is then a no-op, kept as a guard.
quietly count if _nwmode_ego != "1"
xt_chk `=(r(N) == 0)' "nwtoedge of a two-mode network: the mode-1 node is always _ego (`r(N)' rows not)"
gen __e = cond(_nwmode_ego == "1", _ego, _alter)
gen __a = cond(_nwmode_ego == "1", _alter, _ego)
drop _ego _alter
rename (__e __a) (_ego _alter)
nw2fromedge _ego _alter aff, name(aff2)
quietly nwname aff2
xt_chk `=("`r(mode2)'" == "true" & r(nodes1) == `n10' & r(nodes2) == `n20')' "round trip: two-mode with `n10' + `n20' nodes (got `r(nodes1)' + `r(nodes2)')"
xt_chk `=(`"`r(mode1desc)'"' == `"`d10'"' & `"`r(mode2desc)'"' == `"`d20'"')' "round trip: names of the levels kept (`d10'/`d20', got `r(mode1desc)'/`r(mode2desc)')"
local l1 `"`r(labs)'"'
mata: st_local("ok", strofreal(xt_sorteq(st_local("l0"), st_local("l1"))))
xt_chk `ok' "round trip: same labels"
xt_mat aff2 __xt_A1
mata: st_local("ok", strofreal(xt_reorder(__xt_A1, st_local("l1"), st_local("l0")) == __xt_A0))
xt_chk `ok' "round trip: same ties and values"
di "PASS D round trip"

* --- E. errors: data and networks unchanged
nwclear
use `eln', clear
nwset p o, twomode name(tn)
use `eln', clear
xt_snap e1
capture noisily nwset p o, twomode bipartite name(x1)
xt_chk `=(_rc == 198)' "twomode with bipartite: r(198) (got `=_rc')"
xt_same e1 "twomode with bipartite"
capture noisily nwset p, twomode name(x2)
xt_chk `=(_rc == 198)' "twomode with one variable: r(198) (got `=_rc')"
xt_same e1 "twomode with one variable"
capture noisily nwfromedge p o, twomode undirected name(x3)
xt_chk `=(_rc == 198)' "nwfromedge twomode undirected: r(198) (got `=_rc')"
xt_same e1 "nwfromedge twomode undirected"
capture noisily nw2fromedge p o, name(tn)
xt_chk `=(_rc == 483)' "nw2fromedge, name() in use: r(483) (got `=_rc')"
xt_same e1 "nw2fromedge, name() in use"
capture noisily nwset p o, twomode name(tn)
xt_chk `=(_rc == 483)' "nwset twomode, name() in use: r(483) (got `=_rc')"
xt_same e1 "nwset twomode, name() in use"
capture noisily nwfromedge p o, twomode name(tn)
xt_chk `=(_rc == 483)' "nwfromedge twomode, name() in use: r(483) (got `=_rc')"
xt_same e1 "nwfromedge twomode, name() in use"
di "PASS E errors"

* --- F. nwaddnodes with mode(); nwname new2mode(); nwreplacemat
nwclear
use `eln', clear
nwset p o, twomode name(tn)
xt_snap f1
capture noisily nwaddnodes tn, nodenames(newp)
xt_chk `=(_rc == 198)' "nwaddnodes on two-mode without mode(): r(198) (got `=_rc')"
xt_same f1 "nwaddnodes without mode()"
capture noisily nwaddnodes tn, nodenames(a, b) mode(1 2 1)
xt_chk `=(_rc == 198)' "nwaddnodes: 3 modes for 2 names: r(198) (got `=_rc')"
xt_same f1 "nwaddnodes with too many modes"
capture noisily nwaddnodes tn, nodenames(a) mode(3)
xt_chk `=(_rc == 198)' "nwaddnodes: mode(3): r(198) (got `=_rc')"
xt_same f1 "nwaddnodes mode(3)"
nwaddnodes tn, nodenames(newo) mode(2)
quietly nwname tn
xt_chk `=(r(nodes1) == 3 & r(nodes2) == 3)' "nwaddnodes mode(2): mode 2 grows to 3 (got `r(nodes1)' + `r(nodes2)')"
nwaddnodes tn, nodenames(p1, o1) mode(1 2)
quietly nwname tn
xt_chk `=(r(nodes1) == 4 & r(nodes2) == 4)' "nwaddnodes mode(1 2): one node per mode"
nwset, mat((0,1,1\1,0,1\1,1,0)) name(tri) undirected
xt_snap f2
capture noisily nwname tri, new2mode(true)
xt_chk `=(_rc == 459)' "new2mode(true) on a triangle without modes: r(459) (got `=_rc')"
xt_same f2 "new2mode(true) refused"
nwtomata tn, mat(__xt_T)
mata: __xt_T = editmissing(__xt_T, 0)
mata: __xt_T[1, 2] = 1
mata: __xt_T[2, 1] = 1
xt_snap f3
capture noisily nwreplacemat tn, newmat(__xt_T)
xt_chk `=(_rc == 459)' "nwreplacemat with a tie inside mode 1: r(459) (got `=_rc')"
xt_same f3 "nwreplacemat with a same-mode tie"
di "PASS F changes"

* --- G. node operations keep the two-mode flag
nwclear
use `eln', clear
nwset p o, twomode name(tn)
nwdropnodes tn, nodes(1)
quietly nwname tn
xt_chk `=("`r(mode2)'" == "true" & r(nodes1) == 2 & r(nodes2) == 2)' "nwdropnodes keeps two-mode and the modes (got `r(nodes1)' + `r(nodes2)')"
nwduplicate tn, name(tnc)
quietly nwname tnc
xt_chk `=("`r(mode2)'" == "true" & r(nodes1) == 2)' "nwduplicate keeps two-mode"
nwpermute tn, generate(tnp)
quietly nwname tnp
xt_chk `=("`r(mode2)'" == "true" & r(nodes1) == 2 & r(nodes2) == 2)' "nwpermute generate() keeps two-mode and the mode sizes"
di "PASS G node operations"

capture mata: mata drop __xt_A __xt_B __xt_A0 __xt_A1 __xt_T
xt_end
di "ALL PASS"
