cscript

* Core fixes found while testing the model packages (2026-11-12): network names longer than 32 characters,
* large numeric node ids, event data with missing values, two-mode string ids, "too many networks", one-tie
* exports, nwuse direction, registry error codes, nwplot helper networks. Run from the repository root.

do unw_core.do
local tmpd `"`c(tmpdir)'"'

* ---------------------------------------------------------------------------------------------------------------
* 1. network names: at most 32 characters (a Stata name); a longer one is refused and the other networks stay
nwclear
matrix A = (0,1\1,0)
nwset, mat(A) directed name(ok1)
capture noisily nwset, mat(A) directed name(abcdefghijabcdefghijabcdefgh_1_p1)
assert _rc == 198
nwds
assert "`r(netlist)'" == "ok1" | "`r(netlist)'" == " ok1"
nwsummarize ok1
assert r(nodes) == 2
capture noisily nwset, mat(A) name(1abc)
assert _rc == 198
* 32 characters are fine
nwset, mat(A) name(abcdefghijabcdefghijabcdefghij32)
nwsummarize abcdefghijabcdefghijabcdefghij32
* a collision with a 32-character name suggests a name of at most 32 characters
nwvalidate abcdefghijabcdefghijabcdefghij32
assert "`r(exists)'" == "true"
assert ustrlen("`r(validname)'") <= 32
assert "`r(validname)'" == "abcdefghijabcdefghijabcdefghij_1"
* rename, generate()
capture noisily nwrename ok1 abcdefghijabcdefghijabcdefghijabc
assert _rc == 198
nwsummarize ok1
capture noisily nwtranspose ok1, generate(abcdefghijabcdefghijabcdefghijabc)
assert _rc == 198
capture noisily nwpermute ok1, generate(abcdefghijabcdefghijabcdefghijabc)
assert _rc == 198
capture noisily nwgen abcdefghijabcdefghijabcdefghijabc = ok1
assert _rc == 198
nwds
assert wordcount("`r(netlist)'") == 2
* edge list
clear
input s r
1 2
2 3
end
capture noisily nwset s r, edgelist name(abcdefghijabcdefghijabcdefghijabc)
assert _rc == 198
nwds
assert wordcount("`r(netlist)'") == 2

* ---------------------------------------------------------------------------------------------------------------
* 2. large numeric ids: exact labels n<id>, event lists point at the right nodes
foreach base in 10000000 1000000000 4000000000 {
    nwclear
    clear
    set obs 4
    gen double s = `base' + cond(_n == 4, 1, _n)
    gen double r = `base' + cond(_n == 1, 2, cond(_n == 2, 3, cond(_n == 3, 1, 3)))
    gen double t = _n
    nwset s r, eventtime(t) directed name(ev)
    _nwsyntax ev
    mata: st_local("lab1", `netobj'->get_nodenames()[1])
    mata: st_local("lab3", `netobj'->get_nodenames()[3])
    assert "`lab1'" == "n" + strofreal(`base' + 1, "%18.0g")
    assert "`lab3'" == "n" + strofreal(`base' + 3, "%18.0g")
    mata: E = *(`netobj'->get_eventlist())
    mata: assert(E == (1,2,1 \ 2,3,2 \ 3,1,3 \ 1,3,4))
    * static edge list: the same labels
    clear
    set obs 2
    gen double s = `base' + _n
    gen double r = `base' + _n + 1
    nwset s r, edgelist name(st)
    _nwsyntax st
    mata: st_local("lab2", `netobj'->get_nodenames()[2])
    assert "`lab2'" == "n" + strofreal(`base' + 2, "%18.0g")
}
* two-mode, numeric: mode-1 ids >= 1e7, mode-2 ids small (offset applied in double precision)
nwclear
clear
input double p float o double t
10000001 1 1
10000002 2 2
10000003 1 3
end
nwset p o, twomode eventtime(t) name(tm)
nwsummarize tm
assert r(nodes) == 5
_nwsyntax tm
mata: assert(`netobj'->get_modes() == ("1","1","1","2","2"))
mata: E = *(`netobj'->get_eventlist())
mata: assert(E[., 1] == (1\2\3))
mata: assert(E[., 2] == (4\5\4))
* mixed numeric/string ids keep the full number
nwclear
clear
input double s str3 r
10000001 "a"
10000002 "b"
end
nwset s r, edgelist name(mix)
_nwsyntax mix
mata: assert(anyof(`netobj'->get_nodenames(), "10000001"))

* ---------------------------------------------------------------------------------------------------------------
* 3./4. event data: a missing time, sender or receiver is refused (r(416)) and the data stay as they are
foreach what in t s r {
    nwclear
    clear
    set obs 3
    gen s = _n
    gen r = cond(_n == 3, 1, _n + 1)
    gen t = _n
    replace `what' = . in 2
    capture noisily nwset s r, eventtime(t) directed name(d)
    assert _rc == 416
    assert _N == 3
    confirm variable s r t
    capture nwds
    assert _rc != 0 | "`r(netlist)'" == ""
    capture noisily nwset s r, twomode eventtime(t) name(d2)
    assert _rc == 416
}
nwclear
clear
input str2 s str2 r t
"a" "b" 1
" " "c" 2
end
capture noisily nwset s r, eventtime(t) name(d)
assert _rc == 416
* static edge lists keep the isolate rule (a missing id declares an isolate)
nwclear
clear
input s r
1 2
3 .
end
nwset s r, edgelist name(iso)
nwsummarize iso
assert r(nodes) == 3

* ---------------------------------------------------------------------------------------------------------------
* 5. two-mode networks with string ids: mode-1 nodes come first whatever the sort order of the labels
nwclear
clear
input str3 sender str3 receiver double t
"P1" "O2" 1
"P2" "O1" 2
"P3" "O1" 3
"P1" "O1" 4
end
nwset sender receiver, twomode eventtime(t) name(tms)
_nwsyntax tms
mata: assert(`netobj'->get_nodenames() == ("P1","P2","P3","O1","O2"))
mata: assert(`netobj'->get_modes() == ("1","1","1","2","2"))
mata: E = *(`netobj'->get_eventlist())
mata: assert(E == (1,5,1 \ 2,4,2 \ 3,4,3 \ 1,4,4))
nwsummarize tms
assert r(nodes1) == 3
* static: the matrix follows the same order (ties P->O in rows 1-3, columns 4-5)
clear
input str3 sender str3 receiver
"P1" "O2"
"P2" "O1"
"P3" "O1"
"P1" "O1"
end
nwset sender receiver, twomode name(tss) xvars
_nwsyntax tss
mata: assert(`netobj'->get_nodenames() == ("P1","P2","P3","O1","O2"))
nwtomata tss, mat(M)
mata: assert(M[1,4] == 1 & M[1,5] == 1 & M[2,4] == 1 & M[3,4] == 1 & M[2,5] == 0)
mata: assert(M[4,1] == 1 & M[5,1] == 1)
* the node rows of the data follow the node order
assert _nwnode[1] == "P1" & _nwnode[4] == "O1" & _nwnode[5] == "O2"
* string mode 1, numeric mode 2 (numbers sort before letters)
nwclear
clear
input str3 person org
"a" 1
"b" 2
"c" 1
end
nwset person org, twomode name(tmx)
_nwsyntax tmx
mata: assert(`netobj'->get_nodenames() == ("a","b","c","1","2"))
mata: assert(`netobj'->get_modes() == ("1","1","1","2","2"))

* ---------------------------------------------------------------------------------------------------------------
* 6. two networks where one is allowed: "too many networks", r(198); an unknown name is still r(482)
nwclear
nwset, mat((0,1\1,0)) name(g)
nwset, mat((0,1\1,0)) name(h)
capture noisily nwtomata g h, mat(X)
assert _rc == 198
capture noisily nwtomata nosuchnet, mat(X)
assert _rc == 482

* ---------------------------------------------------------------------------------------------------------------
* 7. one value in nw_realstr(); GML export of a network with exactly one tie
mata: assert(nw_realstr(2.5) == "2.5")
mata: assert(nw_realstr(0.1) == ".1" | nw_realstr(0.1) == "0.1")
mata: assert(rows(nw_realstr(J(0, 1, .))) == 0)
nwclear
nwset, mat((0,3\0,0)) name(onetie) directed
local gmlout `"`tmpd'/nwcore_xt_onetie"'
capture erase `"`gmlout'.gml"'
nwexport onetie, type(gml) fname(`"`gmlout'"') replace
confirm file `"`gmlout'.gml"'
assert strpos(fileread(`"`gmlout'.gml"'), "value 3")
nwimport `"`gmlout'.gml"', type(gml) name(back) nwclear clear
nwsummarize back
assert r(nodes) == 2

* ---------------------------------------------------------------------------------------------------------------
* 8. nwuse: a network comes back exactly as saved; a directed network with a symmetric matrix stays directed
nwclear
nwset, mat((0,1,0\1,0,1\0,1,0)) name(symdir) directed
nwset, mat((0,1,0\1,0,1\0,1,0)) name(symund) undirected
local f `"`tmpd'/nwcore_xt_dir"'
nwsave `"`f'"', replace
nwuse `"`f'"', nwclear
nwsummarize symdir
assert "`r(directed)'" == "true"
assert r(arcs) == 4
nwsummarize symund
assert "`r(directed)'" == "false"

* ---------------------------------------------------------------------------------------------------------------
* 9. error codes of help nwerrorcodes
nwclear
nwset, mat((0,1,0\1,0,1\0,1,0)) name(tri) labs(a,b,c)
capture noisily nwdropnodes tri, nodes(zz)
assert _rc == 485
capture noisily nwdropnodes tri, nodes(0)
assert _rc == 485
capture noisily nwdropnodes tri, nodes(9)
assert _rc == 485
capture noisily nwkeepnodes tri, nodes(9)
assert _rc == 485
nwsummarize tri
assert r(nodes) == 3
capture noisily nwsym tri, mode(median)
assert _rc == 6556
nwset, mat((0,1,0\1,0,1\0,1,0)) name(tri2)
capture noisily nwpermute tri, generate(tri2)
assert _rc == 483
capture noisily nwstack tri tri2, name(tri2)
assert _rc == 483

* ---------------------------------------------------------------------------------------------------------------
* 10. nwplot's helper networks cannot remove a user's network whose name begins with __temp
nwclear
nwset, mat((0,1,0\1,0,1\0,1,0)) name(pl)
nwset, mat((0,1\1,0)) name(__temp_keep)
nwset, mat((0,1\1,0)) name(_temp_in)
clear
set obs 3
gen x = _n
nwplot pl if x < 3
nwplot pl in 1/2
nwds
local nm "`r(netlist)'"
assert strpos("`nm'", "__temp_keep") & strpos("`nm'", "_temp_in")
assert wordcount("`nm'") == 3

di "test_core_xt_fixes: all checks passed"
